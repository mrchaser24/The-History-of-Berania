# Berania — Player Interface Work

**Updated:** November 3, 2026. Gameplay implementation takes priority. Use a landscape interface with a map-focused layout and the existing detailed 2D art.

## Retain

The opening already has a full-viewport battlefield, selected-unit card, round indicator, contextual Guard/Face/End Turn buttons, speed/pause controls, objective overlay and help modal. Preserve working selection, previews, shortcuts and pause behavior rather than repeating that redesign.

## Connected source implementation

- [x] Remove development review launchers and redundant sandbox actions from ordinary player menus. The title review entries have been removed in the current reset.
- [x] Connect the actual headquarters, party/pilot assignment, quest journal, inventory, trade agreement and house dialogue screens as their models are implemented.
- [x] Apply the compact battle controls consistently to regional/major encounters. Remove the large regional roster strip in favor of on-map selection and next-ready-unit navigation, preserving keyboard shortcuts.
- [x] Show relevant ability/guard/face actions only for eligible selected units; retain exact movement/attack previews and contextual feedback.
- [x] Make overlays and touch targets respond to landscape viewport size/safe areas rather than expanding fixed desktop coordinates indefinitely.
- [x] Add touch pan/pinch equivalents for the existing battlefield camera and keep pause/menu focus from leaking input onto the map.
- [x] Present quest/loot/contract/diplomacy terms and outcomes clearly, including overflow choices, one-time claims and the permanent story-route commitment.
- [x] Keep basic sound, animation speed, reduced motion and controls settings accessible without review/debug UI.

Portrait orientation, another UI framework, new interface-art generation, QA/playtest/capture tasks and extra prototype menus are outside this plan. Reuse the current controls and art while completing the player-facing functions.

The campaign uses `campaign_panel.gd` for scrollable ordinary menus and explicit commitment panels. Regional/major battles use next-unit and on-map selection with touch drag/pinch; `landscape_layout.gd` fits the logical canvas within mobile safe areas. These changes were not exercised in Godot or on devices; no QA is requested. Further visual refinement is not a reason to restart review/capture workflows.
