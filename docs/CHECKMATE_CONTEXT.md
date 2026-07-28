# Checkmate — Living Context

> **Source of truth for product thinking, design system, and implementation decisions.**  
> Agents and humans must update this file when Checkmate behavior, tokens, Figma mapping, or architecture changes.  
> Last reviewed: 2026-07-25

## Product

**Checkmate** is a playful sticky-note todo app for iOS: personal todos plus assign-to-friends, with a home-screen widget.

| Pillar | Intent |
|--------|--------|
| Feel | Fluid, springy, sticky-note paper — not a generic list app |
| Core loop | Add sticky → assign (Myself / friend) → check off with boop + strike → progress dial updates |
| Surfaces | My todo (date carousel + 2-col grid), Friends tab (sent tasks), Add todo sheet, medium/large widget |
| Modes | Prototype (local, no Secrets.plist) → Cloud (Supabase) → Push (paid Apple, off by default) |

### Product principles (Madhurima)

- Never invent or implement a new visual design without explicit user approval.
  If no design is supplied, ask for one or ask permission to design before
  implementation.
- Pixel-match Figma when a node is cited; prefer exact pt values over “close enough.”
- Selection strokes must look **proportionate** across color dots, assignee ring, and By-when chips.
- App and widget stay **separate implementations** (no Shared UI module unless explicitly requested again).
- Never ship multi-MB avatars into App Group / UserDefaults — names only in widget snapshot; photos from Contacts on demand.
- Prototype mode must stay launch-safe (jetsam / SIGKILL from bloated local data is a known failure mode).

### Design taste (how Madhurima wants agents to design)

- **Authorization:** supplied Figma designs must be inspected through Figma MCP
  and replicated. Without a supplied design, stop and ask before making visual
  design decisions.
- **Feel:** fluid, playful sticky-note paper—not generic list UI. Soft shadows, pastels, one accent blue (`#0088FF`).
- **Fidelity:** Figma node or “target” screenshot wins; use MCP; exact pts; cross-check sibling controls together.
- **Weight:** size ≠ stroke—shrinking a dial keeps stroke bold unless she says otherwise; white halos must stay visible.
- **Motion:** `Theme` springs only; celebrate check-off, keep everyday actions light; no motion that fights scroll/keyboard.
- **Handoff bar:** build + visual compare to her reference before calling done; no “close enough” on deadline work.
- **Avoid:** purple/glow AI chrome, inventing badges Figma doesn’t show, thinning strokes to “fix” scale, Shared UI without asking.
- Full agent brief: `.cursor/skills/checkmate/SKILL.md`

### Out of scope / deferred (from MVP plan)

- Paid Apple: Sign in with Apple + Push re-enable
- Matched-geometry Add→grid travel (partially deferred)
- Friends tab final distinct visuals
- Sticky-toss animation toward tab icon
- iMessage extension polish (target exists; v1.1)

## Architecture (current)

```
Checkmate/          main app (SwiftUI)
CheckmateWidget/    WidgetKit extension (own layout + palette)
CheckmateMessages/  iMessage extension (early)
supabase/           schema + edge functions
```

| Concern | Where |
|---------|--------|
| Design tokens | `Checkmate/Views/Theme.swift`, `StickyColor.swift` |
| DialKit sandboxes (Settings → DialKit) | `DialKitTuning.swift`, `CheckmateDialKit.swift`, `CardFocusTuning.swift`, `CardFocusDialKit.swift`, `OnboardingDialKit.swift`, `OnboardingDialKitTuning.swift` — Home, To-Do Sheet, Press & Hold, Onboarding |
| Tasks | `TaskStore` (+ cloud extension), `CheckmateTask` |
| Widget bridge | `AppGroupStore` (`group.com.madhurima.checkmate`) |
| Friends / assignees | `FriendsStore`, `ContactsService`, `AssigneeCarousel` |
| Auth / config | `AuthService`, `CheckmateConfig`, `Secrets.plist` (gitignored) |
| Setup guide | `SETUP.md` |

**Product Figma file:** `UQufnoBL4RZ5imvjq323AO` (Personal-projects)

**Figma foundations mirror:** `nhwbsb7xw8sjde427W85sR`, page
`2010:4462` (`system`). Keep this page limited to **colors, typography, and
shadows**; components remain authoritative in production SwiftUI unless
explicitly requested in Figma.

**TodoApp V1 token mapping:** page `49:180` in the same file. Local solid fills
and strokes with exact or very close scoped matches are bound to `Checkmate
Color`; unmatched colors remain raw. Typography is linked only when family,
weight, size, and line-height intent match; imported instances remain untouched.

| Screen | Node |
|--------|------|
| App icon | `2036:2686` |
| Settings icon | `2038:2710` |
| Add todo | `573:2413` |
| Assignee selected | `650:2520` / ring `650:2522` |
| Medium widget | `684:3486` / dial `684:3386` |
| Large widget | `681:3165` |
| Onboarding: stickies | `2050:2976` (Checkmate file `nhwbsb7xw8sjde427W85sR`) |
| Onboarding: assign dial | `598:2632` (same file) |
| Onboarding: add widget | `598:2655` (same file) |

## Design tokens

### Palette (`Theme.Palette`)

| Token | Hex / value | Use |
|-------|-------------|-----|
| canvas | `#F6F6F6` | App background |
| ink | `#0E0E0E` | Titles |
| body | `#2F2F2F` | Body / chip labels |
| dim | `#A9A9A9` | Section labels, progress caption |
| selectionBlue | `#0088FF` | Selection rings, chips, dials |
| selectionFill | `#0088FF` @ 7% | Selected By-when chip fill |
| assignLabelMuted | `#888888` | Assignee name under avatar |
| newRed | `#F83A00` | NEW badge |
| dark | `#2F3231` | Confirm button |
| chipBorder | `#E3E3E3` | Unselected chips |
| strike | black @ 38% | Done text |
| checkboxStroke | black @ 39% | Empty checkbox |

### Sticky colors (`StickyColor`)

| Color | Paper | Dot |
|-------|-------|-----|
| yellow | `#FFEEAE` | `#FFE3AE` |
| pink | `#FFC7EC` | `#FFC0EA` |
| blue | `#C7F0FF` | `#BFEEFF` |
| orange | `#FFDEC7` | `#FFD2B2` |

### Motion (`Theme`)

| Name | Spring |
|------|--------|
| spring | response 0.34, damping 0.78 |
| boop | 0.22 / 0.72 |
| snappy | 0.26 / 0.86 |
| colorFlip | 0.36 / 0.78 |
| checkPop | 0.32 / 0.62 |

### DialKit sandboxes

- Settings exposes independent, persistent enable flags:
  `dialkit.homePage.enabled`, `dialkit.todoSheet.enabled`,
  `dialkit.cardFocus.enabled`, and `dialkit.onboarding.enabled`.
- Enabled areas register with DialKit drawers and the built-in panel picker.
  Tuned values are session-only; disabling a panel immediately restores its
  shipped defaults.
- Home Page groups bottom navigation, top/bottom edge fades and optional
  progressive material blur, sticky-grid sizing, and check-burst motion.
- To-Do Sheet groups vertical spacing, preview shadow, separator, local sandbox
  colors, and the sticky preview's color-change pop/lift/tilt.
- Onboarding (one Settings toggle) registers three panels while the intro is
  open — `Onboarding 1 — Stickies`, `Onboarding 2 — Assign`,
  `Onboarding 3 — Widget`. Each panel includes shared chrome
  (typography/colors/glow/buttons/page spring; copy stays fixed) plus
  screen-specific interaction controls (per-card layout + confetti; dial
  geometry + snap motion; hero crop/fade/friend pin + entrance).
- DialKit overrides never mutate `Theme.swift` or `StickyColor.swift`; widget
  geometry and tokens remain fixed.

### Radii / strokes

| Token | Value |
|-------|-------|
| card / cardLarge / pill / panel | 16 / 24 / 19 / 20 |
| cardBorder / cardBorderLarge | 4 / 6 |
| progressRing (home dial) | **5pt** on **16pt** dial |

### Add todo selection strokes (Figma-aligned)

| Control | Blue stroke | Notes |
|---------|-------------|-------|
| Color selector | **2pt** | Dot 30.156; ring ~32.156 outside white border |
| Assignee ring | **2pt** | Avatar 53.739; white gap **1.119**; badge on avatar rim |
| By when selected | **1.6pt** | Fill selectionFill; unselected border **1pt** `#E3E3E3` |

### Progress dials

| Surface | Dial size | Stroke | Label |
|---------|-----------|--------|-------|
| Home `ProgressPill` | 16pt | 5pt | 20pt semibold |
| Medium widget | **17pt** (`mediumDialSize`) | **5pt** | **15pt** semibold |
| Large widget | ~19.8pt | 5pt (default) | 20pt |

Widget dial: same recipe as home (track @ 22% blue opacity, solid `#0088FF` arc, round caps, −90°). Do **not** thin the stroke when shrinking the dial.

### Design-system workflow

- `Theme.swift` and `StickyColor.swift` are the ultimate source of truth for
  design tokens. Production SwiftUI code is authoritative for components.
- Figma is a visual mirror for design and collaboration. Its `system` page is
  intentionally limited to color variables/swatches, typography
  styles/specimens, and production shadow styles. Do not add component,
  geometry, or motion libraries there unless Madhurima explicitly requests
  them.
- Reconcile Figma to code by default. If Madhurima explicitly approves a token
  change in Figma, update the matching `Theme.swift` or `StickyColor.swift`
  value in the same task.

### Onboarding (Figma 2050:2976 / 598:2632 / 598:2655)

- Three pages in `Checkmate/Views/Onboarding/`: draggable stickies with
  confetti check-off, assign-to-contacts dial, static "add widget" hero.
- Shown as a **ZStack overlay in `RootView`** gated by
  `CheckmateConfig.Onboarding.completedKey` (`onboarding.completed`) — an
  overlay, not `fullScreenCover`, because launch-time cover presentation can
  be dropped. Settings → Onboarding has "View onboarding" (fullScreenCover
  preview) and "Restart onboarding" (clears the flag; replays immediately and
  on every restart).
- Page 1 keeps its own top-falling confetti (`OnboardingConfettiView`); home
  grid uses a separate Lottie burst. Both share iMessage confetti sound +
  haptics via `ConfettiCelebration`. Bottom chrome: Skip 80×62 + 75pt gap +
  Next/Add widget 180×62 (`2061:4608` / `2063:4678`). Stickies 4pt white
  border; page 1 deals from center pile; page 2 dial shows selection only when
  centered with slow auto ping-pong (user can take over).
- Page 2 dial: avatars orbit an arc centered at (centerX, −68), radius 252,
  41° spacing; selected snaps to 90° (bottom). Ring/badge geometry matches
  `AssigneeCarousel`. Card avatar crossfades to the selection. People order in
  the array runs right-to-left on screen.
- Assets: `OnboardingAvatarMyself/Sarah/Victor/Friend`, `OnboardingWidgetHero`
  (Figma rasters). Top glow is a native gradient (#FF25B6→#FFCE1F @ 8%).
- QA hooks: `SIMCTL_CHILD_ONBOARDING_PAGE=<0|1|2>` env opens a specific page;
  `CheckmateUITests/OnboardingDriverTests` drives the whole flow for
  host-side screenshots.

### Medium widget layout (`FigmaMediumWidget`, artboard 338×158)

Padding 16; left column 118; task column 188; rows 38 / spacing 6; task font 13; progress block ~41.8; pending rows first, done last; strikethrough via AttributedString; no NEW badge on medium.

## Location map

| Task / area | Primary files |
|-------------|---------------|
| Design tokens | `Checkmate/Views/Theme.swift`, `Models/StickyColor.swift` |
| My todo grid | `MyTodoView.swift`, `StickyNoteCardView.swift`, `StickyNoteGridCell.swift`, `TodoTaskGrid.swift` |
| Home check confetti | `Components/CheckConfettiView.swift` (Lottie `ConfettiBurst.json`), `Services/ConfettiCelebration.swift` (iMessage sound/haptics), DialKit `checkConfetti` on Home Page |
| Progress dial (home) | `Components/ProgressPill.swift` |
| Add todo sheet | `AddTodoView.swift`, `Components/BottomAnchoredTextEditor.swift`, `ColorFlipCard` |
| Assignee carousel | `Components/AssigneeCarousel.swift`, `Components/PersonAvatarView.swift` |
| By-when chips | `AddTodoView.swift` (`DueDateChipMetrics`, `chipBackground`) |
| Friends tab | `FriendsTabView.swift`, `Services/FriendsStore.swift` |
| Task data + widget sync | `Services/TaskStore.swift`, `Services/AppGroupStore.swift` |
| Medium/large widget | `CheckmateWidget/TaskWidgetView.swift`, `TaskWidget.swift`, `TaskEntry.swift` |
| Onboarding flow | `Views/Onboarding/` (`OnboardingView` container + stickies / assign / widget pages, confetti) |
| Config / modes | `CheckmateConfig.swift`, `SETUP.md` |

## Common tasks

| Task | Where to edit | Context section |
|------|---------------|-----------------|
| Change selection stroke weights | `AddTodoView.swift`, `AssigneeCarousel.swift` | Add todo selection strokes |
| Resize progress dial (keep stroke) | `ProgressPill.swift`, `TaskWidgetView.swift` (`mediumDialSize`, `dialStrokeWidth`) | Progress dials |
| Fix widget not syncing | `TaskStore.syncWidgetSnapshot`, entitlements, `AppGroupStore` | Hard-won notes |
| Add sticky color | `StickyColor.swift` + context token table | Sticky colors |
| New Figma screen | Figma MCP → implement → add node to table below | Figma file |
| New reusable component | Implement in production SwiftUI; do not mirror in Figma unless explicitly requested | Design-system workflow |
| New color / typography / shadow token | Add to `Theme.swift` / `StickyColor.swift` first → mirror on Figma `system` page | Design-system workflow |
| Launch SIGKILL / jetsam | Strip avatar data in stores; delete app; clean build | Hard-won notes |

## Hard-won implementation notes

1. **Assignee ring:** Use white fill halo + `.stroke` on a larger diameter. Avoid `strokeBorder` on the same diameter as the halo (eats the white gap).
2. **Widget sync:** Strip `widgetAvatarImageData` on encode/decode; drop App Group payloads > ~512KB; don’t persist contact photos in `FriendsStore`.
3. **Launch SIGKILL:** Often jetsam or half-installed binary — clean build, delete app, clear bloated defaults/App Group.
4. **Shared UI:** User explicitly reverted a Shared compact module; keep app vs widget code separate unless asked.
5. **Widget “x of y done”:** medium = 15pt; large = 20pt.

## Open / watch list

- [ ] Confirm Add todo strokes still match Figma after device QA
- [ ] Widget medium dial 17pt + 5pt stroke visual QA on device
- [ ] Friends tab final design
- [ ] Ignore stale `~/.cursor/plans/checkmate_mvp_rebuild_*.plan.md` — this file is truth

## Changelog (context)

| Date | Change |
|------|--------|
| 2026-07-22 | Initial living context: tokens, Figma nodes, dials, selection strokes, architecture |
| 2026-07-22 | Skill enriched with Madhurima design taste; taste summary mirrored here |
| 2026-07-25 | Skill workflow restructure; location map + common tasks added |
| 2026-07-25 | Added Figma `system` foundations mirror; scope is colors, typography, and shadows |
| 2026-07-26 | Bound matching TodoApp V1 local colors and typography to the Figma system; unmatched values and imported instances stay untouched |
| 2026-07-26 | Simplified design-system workflow; `Theme.swift` and `StickyColor.swift` are authoritative |
| 2026-07-26 | Added explicit design authorization rule: replicate supplied Figma via MCP; otherwise ask before designing or implementing UI |
| 2026-07-26 | Added the production app icon from Figma node `2036:2686` |
| 2026-07-27 | Expanded Settings → DialKit into shared Home Page, To-Do Sheet, and Press & Hold panels; added settings icon node `2038:2710` |
| 2026-07-27 | Added Onboarding DialKit toggle with Screen 1/2/3 panels (chrome + stickies/assign/widget controls) |
| 2026-07-27 | Built 3-screen onboarding (stickies + confetti, assign dial, add widget) from Figma `2050:2976` / `598:2632` / `598:2655`; RootView overlay + Settings view/restart controls |
| 2026-07-27 | Home check-off: Lottie `ConfettiBurst.json` via `CheckConfettiView` + DialKit `checkConfetti`; iMessage `ConfettiSoundEffect.m4a` + Core Haptics in `ConfettiCelebration` (onboarding keeps falling confetti, shares sound/haptics) |
| 2026-07-27 | Onboarding bottom buttons match Figma `2061:4608`/`2063:4678` — compact 80×62 Skip + 75pt gap + 180×62 CTA; stickies deal-from-pile + 4pt borders; assign dial centered-only selection + auto ping-pong scroll |
| 2026-07-27 | Onboarding stickies: confetti zIndex front; checkbox/selection strokes 1.8pt; slower staggered pile→scatter deal (0.6s hold, 0.88s spring, per-card tilt + nudge) |
