---
name: checkmate
description: >-
  Use when working in the Checkmate iOS repo (SwiftUI, WidgetKit, sticky notes,
  Add todo, assignee carousel, progress dial, App Group), Figma file
  UQufnoBL4RZ5imvjq323AO, or when matching Madhurima's Checkmate design taste
  (pixel-perfect Figma, proportionate strokes, fluid playful motion).
---

# Checkmate

## Overview

Build and refine **Checkmate** the way Madhurima designs: sticky-note personality, Figma-true numbers, visual rhythm that feels intentional—not “AI UI” or generic todos.

**Always:** read [`docs/CHECKMATE_CONTEXT.md`](../../../docs/CHECKMATE_CONTEXT.md) before UI/token/product work. Update that file + this skill when durable taste or tokens change.

## How Madhurima designs (agent must internalize)

### Feel

- **Fluid + playful**, never corporate listware. Paper stickies, soft shadows, pastel fills, spring motion.
- Personality lives in **motion and micro-detail** (boop check, dial trim, selection rings)—not decoration for its own sake.
- Prefer **calm canvas + one accent blue (`#0088FF`)** over gradients, glow, purple themes, or heavy chrome.

### Fidelity

- When a Figma node/URL is cited: **pixel-match**. Pull MCP `get_metadata` / `get_design_context`; use exact pt (e.g. `1.119`, `1.6`, `53.739`)—not “about 2.”
- If she attaches a screenshot labeled as the target (“right side,” “what I want”): that image **wins** over memory of earlier code.
- Cross-check related controls together (color ring + assignee ring + By-when chip) so weights look **proportionate**, not independently “correct but mismatched.”

### Visual weight

- Selection language is one family: same blue, coherent stroke hierarchy (circles often **2pt**; chips may be **1.6pt** selected / **1pt** idle—match Figma, don’t invent).
- **Halo / gap matters.** White gap between avatar/dot and blue ring must stay visible; never let `strokeBorder` eat it.
- **Size and stroke are independent.** Shrinking a dial/avatar must **not** thin the stroke unless she asks. Bold ring on a smaller frame is often the goal.
- Type and dial must **read as a pair**—if the dial dominates the “x of y done” label, shrink the dial first.

### Layout & density

- Medium widget: generous padding, clear left progress column vs task column, pending above done, strikethrough on done.
- Prefer breathing room and alignment over cramming extra chrome, badges, or “helpful” labels Figma doesn’t show.
- App vs widget: **separate implementations** unless she explicitly asks to share UI again.

### Motion

- Springs from `Theme` (`spring`, `boop`, `snappy`, `colorFlip`)—no linear “ease everything.”
- Celebrate rare moments (check-off boop/burst); keep frequent actions snappy and light.
- Don’t add motion that fights scrolling, hold-to-edit, or keyboard.

### Process bar (before handoff)

1. Figma or reference image loaded  
2. Tokens/strokes compared across sibling controls  
3. Build succeeds  
4. Visual QA against her reference (device/sim screenshot when possible)  
5. Context/skill updated if anything durable changed  

She often works on a deadline and says she trusts you—**don’t hand off “close enough.”** Fix proportion and fidelity first.

### Anti-patterns (reject)

- Generic todo-list / Settings-app aesthetics  
- Purple/indigo AI landing vibes, cream+terracotta clichés, glow stacks, pill spam  
- Approximating Figma then “tuning later” without saying so  
- Thinning stroke when only diameter should change  
- Putting full contact photos in App Group / UserDefaults  
- Reintroducing a Shared UI module without being asked  
- Shipping without checking that selection strokes match each other

## Product snapshot

Sticky-note todos; Myself + friends; Today widget. Prototype → Cloud → Push (off).  
Figma: `UQufnoBL4RZ5imvjq323AO` — Add todo `573:2413`, medium widget `684:3486`.

## Design system (short)

| Role | Value |
|------|-------|
| Selection blue | `#0088FF` |
| Canvas | `#F6F6F6` |
| Home dial | 16pt / **5pt** stroke |
| Medium widget dial | **17pt** / **5pt** stroke |
| Medium “x of y done” | **15pt** semibold |
| Color / assignee rings | **2pt**; assignee white gap **1.119** |
| By-when selected | **1.6pt**; unselected **1pt** `#E3E3E3` |

Full tables → context file. Code truth: `Theme.swift`, `StickyColor.swift`, `AssigneeCarousel`, `AddTodoView`, `TaskWidgetView`, `ProgressPill`.

## Architecture (hard rules)

- Widget snapshot: names only, **no** avatar image bytes; drop oversized App Group blobs  
- Don’t persist contact photo `Data` in `FriendsStore`  
- Launch must stay jetsam-safe

## Gotchas

| Symptom | Rule |
|---------|------|
| Missing white gap on assignee | Outer `.stroke` on larger diameter, not inward `strokeBorder` |
| Dial heavy vs caption | Smaller **size**, same stroke |
| SIGKILL at launch | Clean install; strip fat local/App Group data |
| Widget empty | App Group + `syncWidgetSnapshot` |

## Keep in sync

After durable design/product/token changes: update `docs/CHECKMATE_CONTEXT.md` **and** this skill (taste rules + numbers). Skip for typos / temporary debug.

## Related

- [`SETUP.md`](../../../SETUP.md) — cloud/widget setup  
- `.cursor/rules/checkmate-context.mdc` — always-apply maintenance  
- Prefer context + this skill over stale `~/.cursor/plans/checkmate_mvp_rebuild_*.plan.md`
