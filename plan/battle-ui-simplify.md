# Battle UI Simplification — Mobile-First, Landscape-Only

**Status:** Draft  
**Prepared:** November 1, 2026  
**Reference:** Knights of Ages, Warhammer 40K: Tacticus  
**Target:** Landscape orientation (16:9), mobile-first, touch-friendly  
**Orientation:** **Landscape only** — the game is designed and laid out exclusively for landscape (horizontal) display. Portrait orientation is not supported.

---

## Problem

The current battle screen has three heavy chrome regions that crowd the map:

1. **Top bar** (full-width, 104 px) — title, round/turn info, speed/pause buttons  
2. **Right sidebar** (360 × 633 px) — objectives, unit roster buttons, field notes, combat log, restart  
3. **Bottom bar** (full-width, 92 px) — selected unit stats, Guard/Face buttons, keyboard legend  

Together they consume ~40% of the 1600 × 900 viewport. On a mobile phone the map is cramped and the text-heavy panels are unreadable.

**Goal:** Map fills the screen. UI appears as small, contextual overlays — only when relevant. Selected-unit detail appears as a compact card. Actions use large, thumb-friendly buttons at screen edges. All layout assumes **landscape orientation**.

---

## Orientation policy

This UI redesign targets **landscape (horizontal) orientation only**:

- Viewport is 1600 × 900 (16:9 widescreen), stretched via `canvas_items`
- All overlay positions, button placements, and card anchors assume a wide, short screen
- Portrait (vertical) orientation is **not planned or supported** — the hex map, unit cards, and action buttons are arranged for landscape usability
- Mobile devices are expected to be held sideways (landscape lock recommended)

---

## Inspiration distilled

| Element | Knights of Ages | Tacticus | Berania target |
|---------|----------------|----------|----------------|
| Map coverage | ~90 % of screen | ~85 % of screen | **≥ 85 %** |
| Selected unit info | Floating card: portrait, Lv, HP bar, ATK/DEF | Top-left card: portrait + name + icons | **Compact card** anchored top-left |
| Action buttons | Small icons bottom | Large circular bottom corners | **2–3 large buttons** bottom-right |
| Round / objective | Tiny bottom-right text | Top-right resource bar | **Minimal pill** top-center |
| Unit roster list | None on screen | None on screen | **Remove** — tap units on map directly |
| Combat log | None visible | None visible | **Remove from HUD** — damage floaters on map |
| Keyboard legend | N/A (touch) | N/A (touch) | **Remove from HUD** — help modal only |

---

## Proposed new layout (landscape)

```
┌──────────────────────────────────────────────────────────────────┐
│  ┌─ Unit Card ─┐                    ┌── Round Pill ──┐          │
│  │ ⚔ Oathkeeper│                    │  R1 · Your Turn│   ⏸  ⚡  │
│  │ HP ████░░ 30│                    └────────────────┘          │
│  │ ATK 9 ARM 2 │                                                │
│  │ MOV 3 RNG 1 │                                                │
│  │ 🛡 Guard    │                                                │
│  └─────────────┘                                                │
│                                                                  │
│                        *** MAP ***                               │
│                 (fills ~85-90% of landscape screen)              │
│                                                                  │
│                                                                  │
│                                                                  │
│                                                  ┌───┐  ┌───┐  │
│  ┌─ Objective ──────────┐                        │ 🛡 │  │ ↻ │  │
│  │ Route all enemies.   │                        │Grd │  │Fce│  │
│  │ Oathkeeper must live.│                        └───┘  └───┘  │
│  └──────────────────────┘                              ┌─────┐  │
│                                                        │ END  │  │
│                                                        │ TURN │  │
│                                                        └─────┘  │
└──────────────────────────────────────────────────────────────────┘
```

### What stays on screen

| Zone | Position | Content | When visible |
|------|----------|---------|--------------|
| **Unit Card** | Top-left (anchored) | Name, HP bar, ATK/ARM/MOV/RNG, status (Guard/Shaken/Done) | When a friendly unit is selected |
| **Enemy Inspect** | Top-left (replaces card) or floating near enemy | Same card layout, RED-tinted | On hover/tap an enemy |
| **Round Pill** | Top-center | "R1 · YOUR TURN" or "R2 · ENEMY TURN" | Always during battle |
| **Speed / Pause** | Top-right, small buttons | Speed toggle + Pause | Always during battle |
| **Action Buttons** | Bottom-right, stacked | Guard, Face, End Turn — large touch targets (≥ 56 px) | Guard/Face: only when unit selected; End Turn: always |
| **Objective** | Bottom-left, semi-transparent | 1–2 line objective text | Always (small, unobtrusive) |
| **Damage floaters** | On map above target | "−5 REAR +3" rising text | On attack, auto-dismiss |
| **Message toast** | Top, slim bar | Tutorial / instruction text | Context-only |

### What gets removed from the battle HUD

| Removed | Where it goes |
|---------|---------------|
| Full-width top bar (crest, title, subtitle) | Title/crest stays on title & world screens only; round info → pill |
| Right sidebar panel (360 px wide) | Objectives → small bottom-left overlay; unit roster buttons → removed (tap on map); combat log → removed; field notes → removed |
| Bottom stats bar (92 px tall) | Unit stats → Unit Card; Guard/Face → action buttons; keyboard legend → help modal only |
| Unit roster buttons (1/2/3 labeled) | Tap unit on map directly; keep keyboard shortcuts |
| "Restart encounter" button | Moved to pause modal |
| Keyboard shortcut legend text | Moved to help modal |

---

## Implementation — all in `scripts/demo.gd`

### Todo 1: Expand battle map to full viewport
- Change `FIELD` from `Rect2(42, 142, 1134, 610)` to full bleed during battle phase
- Add a `_battle_field()` helper that returns full-viewport Rect2 when in battle, original FIELD otherwise
- Update `_draw_battle()` to use the expanded field
- Update `_pos()` and `_battle_cell_at()` to use the new battle field bounds

### Todo 2: Strip battle chrome from `_draw_game_shell()`
- Skip drawing the top bar background, sidebar panel, and bottom bar panel when `phase == "battle"`
- Remove: crest, "BERANIA" title, "DAWN AT GREYFORD", battle title text, round text from the old locations
- Remove: sidebar "WANTED BY THE CROWN", "Greyford", objectives, unit roster, "FIELD NOTES", combat log
- Remove: bottom bar unit stats line, keyboard legend line
- Keep all world-phase drawing unchanged

### Todo 3: Draw compact Unit Card overlay
- New `_draw_unit_card()` function — semi-transparent dark card (alpha ~0.8)
- Position: top-left, 16 px margin
- Content: unit name (bold), HP bar with numeric value, stat icons/text (ATK, ARM, MOV, RNG), status badge
- Show for selected friendly unit OR hovered enemy (enemy card tinted red)
- Size: ~220 × 150 px

### Todo 4: Draw Round Pill
- New `_draw_round_pill()` — centered at top, pill-shaped background
- Content: "ROUND {n} · YOUR TURN" / "ENEMY TURN"
- Size: ~240 × 36 px, semi-transparent

### Todo 5: Reposition action buttons (bottom-right, landscape layout)
- Move Guard [B], Face [F] buttons to bottom-right, stacked above End Turn
- Make buttons larger: ~140 × 56 px for landscape thumb reach
- Only show Guard/Face when a unit is selected and can act
- Move Speed [N] and Pause [Esc] to top-right as smaller buttons

### Todo 6: Add objective overlay (bottom-left)
- Small semi-transparent panel at bottom-left
- Shows objective text: "Route every enemy. Oathkeeper must survive."

### Todo 7: Replace bottom message bar with top toast
- Tutorial/instruction messages appear as slim top toast instead of the thick bottom bar
- Auto-dismiss or tap-dismiss behavior

### Todo 8: Move "Restart encounter" to pause modal
- Remove standalone Restart button from battle HUD
- Add as option in existing pause modal

### Todo 9: Verify and test
- Keyboard shortcuts still work (1/2/3, B, F, Space, G, N, Esc)
- Hover/inspect shows enemy stats in card form
- Damage preview on hover still works
- Attack animations and floaters work with expanded map
- World phase UI unchanged
- Run existing test suite

---

## Files changed

| File | Change |
|------|--------|
| `scripts/demo.gd` | All UI drawing and button layout changes |

No changes to: `project.godot`, `battle_model.gd`, `unit_art.gd`, `hex_grid.gd`, `scenes/main.tscn`

---

## Out of scope

- Portrait orientation support (not planned)
- Touch gestures (pan/pinch-zoom)
- Portrait art in Unit Card (needs new assets)
- World map UI simplification (separate task)
- Mobile export configuration
