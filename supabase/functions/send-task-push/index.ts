// Deploy after paid Apple Developer + APNs key in Supabase secrets.
// Trigger: Database webhook on tasks INSERT where receiver_id is set.
//
// Secrets: APNS_KEY_ID, APNS_TEAM_ID, APNS_BUNDLE_ID, APNS_PRIVATE_KEY

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

Deno.serve(async (req) => {
  const { record } = await req.json();
  if (!record?.receiver_id) {
    return new Response(JSON.stringify({ skipped: true }), { status: 200 });
  }

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
  );

  const { data: profile } = await supabase
    .from("profiles")
    .select("apns_token, name")
    .eq("id", record.receiver_id)
    .single();

  if (!profile?.apns_token) {
    return new Response(JSON.stringify({ skipped: "no_token" }), { status: 200 });
  }

  // TODO: send APNs alert using profile.apns_token when pushEnabled ships.
  console.log("Would push to", profile.apns_token, "task:", record.text);

  return new Response(JSON.stringify({ ok: true }), { status: 200 });
});
