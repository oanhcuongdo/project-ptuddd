// Edge Function notify-sos (UC-07 bước 5).
// Database Webhook gọi hàm này khi có INSERT vào public.sos_requests.
// Hàm lấy người nhận bằng RPC get_sos_recipients (06_sos_volunteer.sql) rồi gửi FCM HTTP v1.
//
// Secrets cần đặt (xem ../../README.md):
//   FIREBASE_SERVICE_ACCOUNT  JSON service account của project Firebase
//   SOS_WEBHOOK_SECRET        chuỗi bí mật, webhook gửi kèm header x-webhook-secret
// SUPABASE_URL và SUPABASE_SERVICE_ROLE_KEY do Supabase tự cung cấp.

import { createClient } from "jsr:@supabase/supabase-js@2";

type SosRecord = {
  id: string;
  rider_id: string;
  issue_type: string;
  latitude: number;
  longitude: number;
  status: string;
};

type WebhookPayload = {
  type: "INSERT" | "UPDATE" | "DELETE";
  table: string;
  schema: string;
  record: SosRecord | null;
};

type ServiceAccount = {
  project_id: string;
  client_email: string;
  private_key: string;
};

type Recipient = { user_id: string; fcm_token: string };

// Trùng channel tạo trong MainActivity.java.
const ANDROID_CHANNEL_ID = "sos_alerts";
const FCM_SCOPE = "https://www.googleapis.com/auth/firebase.messaging";
const TOKEN_URL = "https://oauth2.googleapis.com/token";

const supabase = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  { auth: { persistSession: false } },
);

Deno.serve(async (req) => {
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);

  const secret = Deno.env.get("SOS_WEBHOOK_SECRET");
  if (!secret || req.headers.get("x-webhook-secret") !== secret) {
    return json({ error: "Unauthorized" }, 401);
  }

  let payload: WebhookPayload;
  try {
    payload = await req.json();
  } catch {
    return json({ error: "Body không phải JSON" }, 400);
  }

  const sos = payload.record;
  if (
    payload.type !== "INSERT" ||
    payload.table !== "sos_requests" ||
    !sos ||
    sos.status !== "pending"
  ) {
    return json({ skipped: true });
  }

  const { data, error } = await supabase.rpc("get_sos_recipients", {
    p_sos_id: sos.id,
  });
  if (error) return json({ error: error.message }, 500);

  const recipients = (data ?? []) as Recipient[];
  if (recipients.length === 0) return json({ sent: 0, failed: 0, cleared: 0 });

  let account: ServiceAccount;
  try {
    account = JSON.parse(Deno.env.get("FIREBASE_SERVICE_ACCOUNT") ?? "");
  } catch {
    return json({ error: "Thiếu hoặc sai secret FIREBASE_SERVICE_ACCOUNT" }, 500);
  }

  let accessToken: string;
  try {
    accessToken = await getAccessToken(account);
  } catch (e) {
    return json({ error: `Không lấy được OAuth token: ${String(e)}` }, 500);
  }

  const results = await Promise.all(
    recipients.map((r) => sendToToken(account.project_id, accessToken, r.fcm_token, sos)),
  );

  // Token đã gỡ app / hết hạn: xóa để lần sau không gửi lại.
  const stale = recipients
    .filter((_, i) => results[i] === "stale")
    .map((r) => r.fcm_token);
  if (stale.length > 0) {
    await supabase.from("users").update({ fcm_token: null }).in("fcm_token", stale);
  }

  return json({
    sent: results.filter((r) => r === "sent").length,
    failed: results.filter((r) => r === "failed").length,
    cleared: stale.length,
  });
});

async function sendToToken(
  projectId: string,
  accessToken: string,
  token: string,
  sos: SosRecord,
): Promise<"sent" | "stale" | "failed"> {
  let res: Response;
  try {
    res = await fetch(
      `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
      {
        method: "POST",
        headers: {
          Authorization: `Bearer ${accessToken}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          message: {
            token,
            // Payload thống nhất trong src/README.md: {sos_id, issue_type, lat, lng}.
            data: {
              sos_id: sos.id,
              issue_type: sos.issue_type,
              lat: String(sos.latitude),
              lng: String(sos.longitude),
            },
            notification: {
              title: "Yêu cầu cứu hộ SOS gần bạn",
              body: `${sos.issue_type} – mở ứng dụng để tiếp nhận`,
            },
            android: {
              priority: "HIGH",
              ttl: "300s",
              notification: {
                channel_id: ANDROID_CHANNEL_ID,
                sound: "default",
                tag: sos.id,
              },
            },
          },
        }),
      },
    );
  } catch (e) {
    console.error("FCM lỗi kết nối", String(e));
    return "failed";
  }
  if (res.ok) return "sent";

  const body = await res.json().catch(() => null);
  const details: Array<{ errorCode?: string }> = body?.error?.details ?? [];
  if (res.status === 404 || details.some((d) => d.errorCode === "UNREGISTERED")) {
    return "stale";
  }
  console.error("FCM lỗi", res.status, JSON.stringify(body));
  return "failed";
}

// ===== OAuth2 cho service account (JWT RS256 ký bằng WebCrypto) =====

let cachedToken: { value: string; expiresAt: number } | null = null;

async function getAccessToken(account: ServiceAccount): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  if (cachedToken && cachedToken.expiresAt - 60 > now) return cachedToken.value;

  const header = { alg: "RS256", typ: "JWT" };
  const claims = {
    iss: account.client_email,
    scope: FCM_SCOPE,
    aud: TOKEN_URL,
    iat: now,
    exp: now + 3600,
  };
  const unsigned = `${base64UrlJson(header)}.${base64UrlJson(claims)}`;

  const key = await crypto.subtle.importKey(
    "pkcs8",
    pemToDer(account.private_key),
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    key,
    new TextEncoder().encode(unsigned),
  );
  const jwt = `${unsigned}.${base64Url(new Uint8Array(signature))}`;

  const res = await fetch(TOKEN_URL, {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt,
    }),
  });
  if (!res.ok) throw new Error(`${res.status} ${await res.text()}`);

  const body = await res.json();
  cachedToken = {
    value: body.access_token,
    expiresAt: now + Number(body.expires_in ?? 3600),
  };
  return cachedToken.value;
}

function pemToDer(pem: string): ArrayBuffer {
  const base64 = pem
    .replace(/-----BEGIN PRIVATE KEY-----/, "")
    .replace(/-----END PRIVATE KEY-----/, "")
    .replace(/\\n/g, "")
    .replace(/\s+/g, "");
  const bytes = Uint8Array.from(atob(base64), (c) => c.charCodeAt(0));
  return bytes.buffer;
}

function base64UrlJson(value: unknown): string {
  return base64Url(new TextEncoder().encode(JSON.stringify(value)));
}

function base64Url(bytes: Uint8Array): string {
  let binary = "";
  for (const b of bytes) binary += String.fromCharCode(b);
  return btoa(binary).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}
