// Supabase Edge Function: generate-learning-content
// Calls Google Gemini 2.5 Flash API with Structured Outputs (JSON Schema)

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const { contentType, count = 10, difficulty = "medium", topic, documentContext } =
      await req.json();

    if (!documentContext || documentContext.trim().length === 0) {
      return new Response(
        JSON.stringify({ error: "Nội dung tài liệu không được để trống" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    if (count < 5 || count > 20) {
      return new Response(
        JSON.stringify({ error: "Số lượng câu hỏi/thẻ phải từ 5 đến 20 (BR-04)" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const geminiApiKey = Deno.env.get("GEMINI_API_KEY");
    if (!geminiApiKey) {
      return new Response(
        JSON.stringify({ error: "GEMINI_API_KEY chưa được cấu hình trong Supabase Secrets" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const isQuiz = contentType === "quiz";
    const systemPrompt = `Bạn là trợ lý AI chuyên môn học tập của trường Đại học Thủy Lợi (TLU). Hãy tạo chính xác ${count} ${isQuiz ? "câu hỏi trắc nghiệm 4 lựa chọn (Quiz)" : "thẻ ghi nhớ (Flashcard)"
      } từ tài liệu được cung cấp. Mức độ khó: ${difficulty}. Chủ đề: ${topic || "Toàn bộ"}. Toàn bộ câu hỏi, giải thích và nội dung phải bằng Tiếng Việt chuẩn.`;

    // Structured JSON Schema for Gemini
    const responseSchema = isQuiz
      ? {
        type: "OBJECT",
        properties: {
          questions: {
            type: "ARRAY",
            items: {
              type: "OBJECT",
              properties: {
                question_text: { type: "STRING" },
                options: { type: "ARRAY", items: { type: "STRING" } },
                correct_index: { type: "INTEGER" },
                explanation: { type: "STRING" },
                topic: { type: "STRING" },
              },
              required: ["question_text", "options", "correct_index"],
            },
          },
        },
        required: ["questions"],
      }
      : {
        type: "OBJECT",
        properties: {
          flashcards: {
            type: "ARRAY",
            items: {
              type: "OBJECT",
              properties: {
                front_text: { type: "STRING" },
                back_text: { type: "STRING" },
                explanation: { type: "STRING" },
                topic: { type: "STRING" },
              },
              required: ["front_text", "back_text"],
            },
          },
        },
        required: ["flashcards"],
      };

    const endpoint = `https://generativelanguage.googleapis.com/v1beta/models/gemini-3.5-flash-lite:generateContent?key=${geminiApiKey}`;

    const geminiRes = await fetch(endpoint, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        contents: [
          {
            parts: [
              { text: systemPrompt },
              { text: `NỘI DUNG TÀI LIỆU NGUỒN:\n${documentContext.substring(0, 15000)}` },
            ],
          },
        ],
        generationConfig: {
          responseMimeType: "application/json",
          responseSchema: responseSchema,
          temperature: 0.4,
        },
      }),
    });

    if (!geminiRes.ok) {
      const errText = await geminiRes.text();
      return new Response(
        JSON.stringify({ error: `Gemini API error: ${errText}` }),
        { status: geminiRes.status, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const geminiData = await geminiRes.json();
    const rawContent = geminiData.candidates?.[0]?.content?.parts?.[0]?.text;
    const parsed = JSON.parse(rawContent || "{}");

    return new Response(JSON.stringify(parsed), {
      status: 200,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (error) {
    return new Response(
      JSON.stringify({ error: (error as Error).message }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
