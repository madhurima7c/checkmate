// Supabase Edge Function: notify-task
// Triggered via Database Webhook on INSERT into public.tasks
// Set up in: supabase.com → Database → Webhooks → New webhook
//   Table: tasks, Events: INSERT, URL: <this function URL>
//
// Required env vars (supabase.com → Edge Functions → Secrets):
//   APNS_KEY_ID       — Apple key ID from Developer portal
//   APNS_TEAM_ID      — Apple Team ID
//   APNS_PRIVATE_KEY  — Contents of your .p8 key file (replace \n with actual newlines)
//   APNS_BUNDLE_ID    — e.g. com.yourname.checkmate

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const supabase = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
);

Deno.serve(async (req) => {
  const body = await req.json();
  const task = body.record;

  // Only notify for collaborative tasks (receiver exists)
  if (!task.receiver_id) {
    return new Response("Personal task, no push needed", { status: 200 });
  }

  // Fetch receiver's APNs token and sender's name
  const [{ data: receiver }, { data: sender }] = await Promise.all([
    supabase.from("profiles").select("apns_token").eq("id", task.receiver_id).single(),
    supabase.from("profiles").select("name").eq("id", task.sender_id).single(),
  ]);

  if (!receiver?.apns_token) {
    return new Response("No APNs token for receiver", { status: 200 });
  }

  const senderName = sender?.name ?? "Someone";
  await sendPush(receiver.apns_token, senderName, task.text);

  return new Response("Push sent", { status: 200 });
});

async function sendPush(token: string, senderName: string, taskText: string) {
  const keyId = Deno.env.get("APNS_KEY_ID")!;
  const teamId = Deno.env.get("APNS_TEAM_ID")!;
  const privateKey = Deno.env.get("APNS_PRIVATE_KEY")!;
  const bundleId = Deno.env.get("APNS_BUNDLE_ID")!;

  const jwt = await makeAPNsJWT(keyId, teamId, privateKey);
  const apnsUrl = `https://api.push.apple.com/3/device/${token}`;

  const payload = {
    aps: {
      alert: {
        title: senderName,
        body: taskText,
      },
      sound: "default",
      badge: 1,
    },
  };

  const response = await fetch(apnsUrl, {
    method: "POST",
    headers: {
      authorization: `bearer ${jwt}`,
      "apns-topic": bundleId,
      "apns-push-type": "alert",
      "content-type": "application/json",
    },
    body: JSON.stringify(payload),
  });

  if (!response.ok) {
    const err = await response.text();
    throw new Error(`APNs error: ${response.status} ${err}`);
  }
}

async function makeAPNsJWT(
  keyId: string,
  teamId: string,
  privateKeyPEM: string
): Promise<string> {
  const header = { alg: "ES256", kid: keyId };
  const payload = { iss: teamId, iat: Math.floor(Date.now() / 1000) };

  const encode = (obj: object) =>
    btoa(JSON.stringify(obj)).replace(/\+/g, "-").replace(/\//g, "_").replace(/=/g, "");

  const signingInput = `${encode(header)}.${encode(payload)}`;

  const keyData = privateKeyPEM
    .replace(/-----BEGIN PRIVATE KEY-----/, "")
    .replace(/-----END PRIVATE KEY-----/, "")
    .replace(/\n/g, "");

  const keyBuffer = Uint8Array.from(atob(keyData), (c) => c.charCodeAt(0));
  const cryptoKey = await crypto.subtle.importKey(
    "pkcs8",
    keyBuffer,
    { name: "ECDSA", namedCurve: "P-256" },
    false,
    ["sign"]
  );

  const signature = await crypto.subtle.sign(
    { name: "ECDSA", hash: "SHA-256" },
    cryptoKey,
    new TextEncoder().encode(signingInput)
  );

  const sig = btoa(String.fromCharCode(...new Uint8Array(signature)))
    .replace(/\+/g, "-").replace(/\//g, "_").replace(/=/g, "");

  return `${signingInput}.${sig}`;
}
