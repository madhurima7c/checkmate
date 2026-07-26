---
name: checkmate
description: >-
  REQUIRED when working in /Users/madhurima/AI Repo/checkmate. Read
  docs/CHECKMATE_CONTEXT.md before any work; match Madhurima's design taste
  (Figma UQufnoBL4RZ5imvjq323AO, pixel-perfect strokes, fluid playful motion);
  update context on git commit when durable truth changes.
---

# Checkmate — Context & Design

## When to use

**REQUIRED** when:
- Working directory is `/Users/madhurima/AI Repo/checkmate`
- Any Checkmate iOS, widget, Figma, token, or product task

## 1. Before ANY work

**MANDATORY FIRST STEP:**
```
Read: /Users/madhurima/AI Repo/checkmate/docs/CHECKMATE_CONTEXT.md
```

Contains: file map, tokens, Figma nodes, architecture, common tasks, backlog, gotchas.

**Why:** Exact pt values, separate app/widget code, sync rules, and taste live there—not in stale Cursor plans.

## 2. After reading, you should know

- ✓ Tokens → `Checkmate/Views/Theme.swift`, `StickyColor.swift`
- ✓ Tasks → `TaskStore`, `CheckmateTask`, `AppGroupStore` (`group.com.madhurima.checkmate`)
- ✓ My todo → `MyTodoView`, `StickyNoteCardView`, `ProgressPill`
- ✓ Add todo → `AddTodoView`, `AssigneeCarousel`
- ✓ Widget → `CheckmateWidget/TaskWidgetView.swift` (separate from app UI)
- ✓ Figma → `UQufnoBL4RZ5imvjq323AO`; cite node IDs; use Figma MCP
- ✓ Ignore `~/.cursor/plans/checkmate_mvp_rebuild_*.plan.md` — context file is truth

## 3. How Madhurima designs (follow on every UI change)

- **Feel:** fluid, playful sticky notes—pastels, soft shadow, one accent blue `#0088FF`; not generic list UI or AI chrome
- **Fidelity:** Figma node or her target screenshot wins; exact pts (`1.119`, `1.6`, `53.739`); cross-check sibling strokes together
- **Weight:** size ≠ stroke—smaller dial keeps **5pt** ring; white halo on assignee/color must stay visible (outer `.stroke`, not `strokeBorder` eating gap)
- **Motion:** `Theme` springs only; boop on check-off; don't fight scroll/keyboard
- **Handoff:** build + compare to her reference before done—no "close enough" on deadline work

**Reject:** purple/glow clichés, thinning stroke to fix scale, Shared UI module without asking, avatar bytes in App Group, badges Figma doesn't show.

## 4. During implementation

- Follow patterns in context file and existing code
- App vs widget: **separate** implementations unless she asks otherwise
- UI task with Figma URL → `get_metadata` / `get_design_context` first
- Common tasks → **Common tasks** section in context (don't guess file paths)

## 5. Before git commit

1. `git status` && `git diff`
2. Did you change tokens, Figma mapping, strokes, dials, sync rules, architecture, or taste rules?
   - **Yes** → update `docs/CHECKMATE_CONTEXT.md` (+ this skill if workflow/taste rule changed)
   - Append one line to context **Changelog**
   - Include doc updates **in the same commit** as code
3. Skip doc updates for typos, formatting-only, reverted debug

## Workflow

```
START → READ context.md → IMPLEMENT (taste + patterns) → BUILD/QA
  → IF COMMITTING: diff → update context (+ skill if needed) → commit together → DONE
```

## Quick token reference (full tables in context)

| Item | Value |
|------|-------|
| Selection blue | `#0088FF` |
| Home dial | 16pt / 5pt stroke |
| Medium widget dial | 17pt / 5pt stroke; label 15pt |
| Color + assignee ring | 2pt; assignee gap 1.119 |
| By-when selected | 1.6pt; unselected 1pt `#E3E3E3` |

## Related

- [`SETUP.md`](../../../SETUP.md) — cloud / widget install
- `.cursor/rules/checkmate-context.mdc` — always-apply reminder
