import { decodeProtectedHeader, importX509, jwtVerify } from "npm:jose@6.2.18";
import { createHandler, RequestError } from "./handler.ts";

const certUrl =
  "https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com";
const projectId = Deno.env.get("FIREBASE_PROJECT_ID");
const geminiSecretName = Deno.env.get("GEMINI_SECRET_NAME");
const geminiKey = geminiSecretName
  ? Deno.env.get(geminiSecretName)
  : Deno.env.get("GEMINI_API_KEY") || Deno.env.get("GEMINI_KEY");
const model = Deno.env.get("GEMINI_MODEL") ?? "gemini-3.5-flash-lite";
const supabaseUrl = Deno.env.get("SUPABASE_URL");
const serverKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

let certs: { expires: number; values: Record<string, string> } | undefined;
let certRequest: Promise<NonNullable<typeof certs>> | undefined;

async function fetchCertificates(signal: AbortSignal) {
  const response = await fetch(certUrl, { signal });
  if (!response.ok) throw new RequestError(503, "auth_unavailable");
  const seconds = Number(
    response.headers.get("cache-control")?.match(/max-age=(\d+)/)?.[1] ?? 300,
  );
  return {
    expires: Date.now() + seconds * 1000,
    values: await response.json() as Record<string, string>,
  };
}

async function verifyUser(
  token: string,
  signal: AbortSignal,
): Promise<string | null> {
  if (!projectId) throw new RequestError(503, "auth_not_configured");
  let kid: string | undefined;
  try {
    const header = decodeProtectedHeader(token);
    if (header.alg !== "RS256" || !header.kid) return null;
    kid = header.kid;
  } catch {
    return null;
  }
  if (!certs || certs.expires <= Date.now()) {
    certRequest ??= fetchCertificates(signal).finally(() => {
      certRequest = undefined;
    });
    certs = await certRequest;
  }
  const pem = Object.hasOwn(certs.values, kid) ? certs.values[kid] : undefined;
  if (!pem) return null;

  try {
    const { payload } = await jwtVerify(token, await importX509(pem, "RS256"), {
      algorithms: ["RS256"],
      issuer: `https://securetoken.google.com/${projectId}`,
      audience: projectId,
      requiredClaims: ["exp", "iat", "sub", "auth_time"],
    });
    const now = Math.floor(Date.now() / 1000);
    if (
      payload.aud !== projectId || !payload.sub || payload.sub.length > 128 ||
      typeof payload.iat !== "number" || payload.iat > now ||
      typeof payload.auth_time !== "number" || payload.auth_time > now
    ) return null;
    return payload.sub;
  } catch {
    return null;
  }
}

async function consumeQuota(
  uid: string,
  signal: AbortSignal,
): Promise<boolean> {
  if (!geminiKey || !serverKey || !supabaseUrl) {
    throw new RequestError(503, "summary_not_configured");
  }
  const response = await fetch(
    new URL("/rest/v1/rpc/consume_summary_quota", supabaseUrl),
    {
      method: "POST",
      headers: {
        apikey: serverKey,
        Authorization: `Bearer ${serverKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ p_user_id: uid }),
      signal,
    },
  );
  if (!response.ok) throw new RequestError(503, "quota_unavailable");
  return await response.json() === true;
}

async function generate(
  instruction: string,
  note: string,
  signal: AbortSignal,
): Promise<string> {
  const response = await fetch(
    `https://generativelanguage.googleapis.com/v1beta/models/${
      encodeURIComponent(model)
    }:generateContent`,
    {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "x-goog-api-key": geminiKey!,
      },
      body: JSON.stringify({
        systemInstruction: { parts: [{ text: instruction }] },
        contents: [{ role: "user", parts: [{ text: note }] }],
        generationConfig: { maxOutputTokens: 3000 },
      }),
      signal,
    },
  );
  if (!response.ok) {
    const failure = await response.json().catch(() => null) as {
      error?: { details?: { reason?: string }[] };
    } | null;
    const reason = failure?.error?.details?.find((detail) => detail.reason)
      ?.reason;
    const googleReason = reason && /^[A-Z_]{1,64}$/.test(reason)
      ? reason
      : "unknown";
    console.warn(`Gemini request failed (${response.status}, ${googleReason})`);
    if (response.status === 429) throw new RequestError(429, "quota_exceeded");
    throw new RequestError(502, "gemini_unavailable");
  }
  const result = await response.json() as {
    candidates?: {
      content?: { parts?: { text?: string; thought?: boolean }[] };
    }[];
  };
  return result.candidates?.[0]?.content?.parts
    ?.filter((part) => !part.thought && typeof part.text === "string")
    .map((part) => part.text)
    .join("") ?? "";
}

Deno.serve(createHandler({ verifyUser, consumeQuota, generate, model }));
