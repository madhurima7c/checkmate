# Checkmate — Living Context

> **Source of truth for product thinking, design system, and implementation decisions.**  
> Agents and humans must update this file when Checkmate behavior, tokens, Figma mapping, or architecture changes.  
> Last reviewed: 2026-07-22

## Product

**Checkmate** is a playful sticky-note todo app for iOS: personal todos plus assign-to-friends, with a home-screen widget.

| Pillar | Intent |
|--------|--------|
| Feel | Fluid, springy, sticky-note paper — not a generic list app |
| Core loop | Add sticky → assign (Myself / friend) → check off with boop + strike → progress dial updates |
| Surfaces | My todo (date carousel + 2-col grid), Friends tab (sent tasks), Add todo sheet, medium/large widget |
| Modes | Prototype (local, no Secrets.plist) → Cloud (Supabase) → Push (paid Apple, off by default) |

### Product principles (Madhurima)

- Pixel-match Figma when a node is cited; prefer exact pt values over “close enough.”
- Selection strokes must look **proportionate** across color dots, assignee ring, and By-when chips.
- App and widget stay **separate implementations** (no Shared UI module unless explicitly requested again).
- Never ship multi-MB avatars into App Group / UserDefaults — names only in widget snapshot; photos from Contacts on demand.
- Prototype mode must stay launch-safe (jetsam / SIGKILL from bloated local data is a known failure mode).

### Design taste (how Madhurima wants agents to design)

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
| Tasks | `TaskStore` (+ cloud extension), `CheckmateTask` |
| Widget bridge | `AppGroupStore` (`group.com.madhurima.checkmate`) |
| Friends / assignees | `FriendsStore`, `ContactsService`, `AssigneeCarousel` |
| Auth / config | `AuthService`, `CheckmateConfig`, `Secrets.plist` (gitignored) |
| Setup guide | `SETUP.md` |

**Figma file:** `UQufnoBL4RZ5imvjq323AO` (Personal-projects)

| Screen | Node |
|--------|------|
| Add todo | `573:2413` |
| Assignee selected | `650:2520` / ring `650:2522` |
| Medium widget | `684:3486` / dial `684:3386` |
| Large widget | `681:3165` |

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

### Medium widget layout (`FigmaMediumWidget`, artboard 338×158)

Padding 16; left column 118; task column 188; rows 38 / spacing 6; task font 13; progress block ~41.8; pending rows first, done last; strikethrough via AttributedString; no NEW badge on medium.

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
- [ ] Plan file in `~/.cursor/plans/` is stale vs current product (see skill)

## Changelog (context)

| Date | Change |
|------|--------|
| 2026-07-22 | Initial living context: tokens, Figma nodes, dials, selection strokes, architecture |
| 2026-07-22 | Skill enriched with Madhurima design taste; taste summary mirrored here |
