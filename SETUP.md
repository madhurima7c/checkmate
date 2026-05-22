# Checkmate — Pre-launch setup

Get cloud sync, contacts, invites, and realtime working **before** you buy the $99/year Apple Developer account. Push is wired but turned off until then.

## Modes

| Mode | When | What works |
|------|------|------------|
| **Prototype** (default) | No `Secrets.plist` | Local todos, demo friends, full UI |
| **Cloud** | `Secrets.plist` + sign in | Supabase sync, contacts, invites, realtime |
| **Push** | Paid Apple + `pushEnabled = true` | APNs + Edge Function |

## Phase 1 — Supabase (free tier)

1. Create a project at [supabase.com](https://supabase.com).
2. Run [`supabase/schema.sql`](supabase/schema.sql) in **SQL Editor**.
3. **Settings → API** → copy Project URL and `anon` key.
4. Copy the example secrets file:
   ```bash
   cp Checkmate/Secrets.example.plist Checkmate/Secrets.plist
   ```
5. Paste your URL and anon key into `Secrets.plist` (do not commit this file).
6. **Authentication → Providers** → enable Email; add Apple when you have a paid account.
7. **Database → Replication** → confirm `tasks` is in the realtime publication.

The app automatically leaves prototype mode when `Secrets.plist` is valid.

## Phase 2 — Test two users (no push needed)

1. Build to Simulator or your iPhone (Personal Team is fine).
2. Sign up as User A (email/password in the app).
3. Sign up as User B in another simulator or browser incognito.
4. User A: **Add todo** → **Choose from Contacts** or pick a friend → assign.
5. If B has an account with matching email, the task uses `receiver_id` and **Realtime** updates B’s grid.
6. If B is not on Checkmate yet, the task stores `invite_contact` and opens the **share sheet** with an invite link.

## Phase 3 — Contacts & invites

- **Choose from Contacts** uses the system contact picker (email or phone).
- Invites are stored in `public.invites` keyed by normalized contact.
- When the friend signs up with the same email, extend the schema with a redeem function (see migration comments in `schema.sql`).

## Phase 4 — After Apple Developer Program

1. Set `CheckmateConfig.pushEnabled = true` in `CheckmateConfig.swift`.
2. Xcode → **Signing & Capabilities** → add **Push Notifications**.
3. Supabase → deploy [`supabase/functions/send-task-push`](supabase/functions/send-task-push/index.ts).
4. Add APNs key to Supabase secrets; hook a Database Webhook on `tasks` INSERT.
5. Enable **Sign in with Apple** in Supabase + Xcode.

## Files to know

| File | Purpose |
|------|---------|
| `Checkmate/Secrets.plist` | Supabase URL/key (gitignored) |
| `Checkmate/CheckmateConfig.swift` | Prototype vs cloud vs push flags |
| `Checkmate/Services/TaskStore+Cloud.swift` | Supabase CRUD |
| `Checkmate/Services/RealtimeService.swift` | Live updates without push |
| `Checkmate/Services/ContactsService.swift` | Device contacts picker |
| `Checkmate/Services/InviteService.swift` | Invite rows + share sheet |

## Home screen widget

The **CheckmateWidget** extension is included in the Xcode project. After building and running the main app once:

1. Long-press the home screen → **Edit** → **Add Widget**
2. Search for **Checkmate**
3. Choose the small or medium sticky-note widget

If Checkmate does not appear:

- In Xcode, select the **Checkmate** target → **Signing & Capabilities** → add **App Groups** → `group.com.madhurima.checkmate`
- Repeat for the **CheckmateWidget** target
- Delete the app from the device/simulator, **Clean Build Folder**, run again

The widget reads today's **My todo** tasks from the shared App Group (updated whenever you add, edit, or complete todos).

## Staying on prototype only

Delete or don’t add `Secrets.plist` — the app keeps using local storage with no sign-in required.

## Force prototype while testing cloud

```swift
UserDefaults.standard.set(true, forKey: "ForcePrototypeMode")
```
