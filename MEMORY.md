# Persistent Project Memory

**Updated:** November 3, 2026. Explicit user decisions take precedence over older plans. Read this before design, art, equipment or gameplay changes.

## Latest instruction — core functions and detailed 2D

- The battle design in `plan/battle-phases.md` specifies five phases per side, confirmed player unit actions, charge movement, automatic limited melee counterattacks and contested capture objectives with an encounter-authored target of 1–10 points (default 3). A specific holder scores after surviving the opponent's complete turn; both sides retain earned points and race to the target. On November 4 the user authorized running Godot and exercising these changes; targeted battle, controller and isolated campaign-save exercises passed. Preserve real saves and artwork.

- The user requested a **new chat session**, a return from pixel art to the good detailed artwork, implementation of the main functions first, removal of all 3D work and unnecessary planning, and **no more QA**.
- Active roadmap: `plan/initial-plan.md`, revision 2.1. Implement its remaining functions in order; do not substitute further planning or animation experiments for coding.
- Detailed painted/inked whole-character 2D art is active again. `scripts/mech_art.gd` loads the existing `assets/art/mechs/oathkeeper/fullbody/v004/` atlas and its original left-facing source convention. Pixel art is historical/offline.
- No 3D work, model/rig/render pipeline, full rotations, segmented bodies, modular/custom weapons or new pixel-vs-detailed comparisons. Retired 3D, pixel, review, QA and build resources were removed from the workspace.
- The earlier no-QA instruction was superseded for the November 4 Godot exercise by the user's explicit request. Ordinary runtime validation, save backups, eligibility checks and transaction guards remain functional requirements.
- Complete campaign functions before further art production. The detailed walking/attack limitations have not been solved or newly approved by restoring the art. Do not claim smoothness from source counts or historical results.
- Preserve unrelated user edits, original artwork and real saves. Never reset the dirty checkout or rewrite player saves during implementation.
- Zero spending: no paid API, subscriptions, purchases, upgrade or external service dependency. Use the existing Godot/GDScript project and available local art.

## Game and presentation decisions

- Single-player medieval-magitech strategy RPG. Turn-based hex travel and tactical battles, painted continuous scenery, hidden grid by default, temporary path/target overlays, fixed 2D viewpoint and optional battle focus.
- Desktop, Android and iPhone targets; landscape layout. Main functions take priority over platform/performance exercises.
- Fixed complete mechs and permanent weapon sets. Oathkeeper retains its ivory/navy/gold knight design, sword and shield. Only left/right whole-image mirroring is required; six hex-facing sectors remain a separate combat rule.
- No weapon buying/swapping, custom sockets or body-part assembly. Buy/receive/store/swap frames, repair, refit hulls and fit internal stat modules. Keep legacy save weapon fields readable without exposing customization.
- Shared frame/module reserves are available at friendly workshops. Carried trade goods obey cargo capacity. Required quest items are protected; no individual human armor/helmet/boot equipment inventory.
- Ordinary formations show four soldiers, mage circles five mages, cannon one gun plus two crew, and mechs one complete machine. Every formation/cannon/mech counts as one commandable unit.
- Ten units per side ordinarily; fifteen in major encounters/sieges, including allies, settlement defenders and all personal mechs. No free companion slots or hidden reinforcement bypass.
- One player warband/army. Bounded NPC party jobs, trade, rescue incidents, house diplomacy and a simple siege/conquest model; no elaborate construction, upkeep or production-chain simulation.
- Banner scope is two colors and one centered original emblem, with warband naming at headquarters. It does not change legal house identity or diplomatic recognition.
- Oathkeeper is the starter; Cinderjack, Kestrel and Bastion remain approved future concepts, not completed animated units. Supporting unit symbols are temporary while functions are built.

## Story authority

Read `plan/story-canon.md` for the full plot and draft house/cast register. Preserve these settled decisions:

- Player-named male archduke's son; fixed noble history and existing mutual love with the eldest princess; the second prince was his close childhood friend.
- The old emperor secretly has the prince's mother assassinated, then plans to kill the initially innocent prince out of paranoia. The archduke knew nothing. The prince strikes first, imprisons his sister, wrongly accuses the protagonist/father, and orders their hunt.
- An imperial commander kills the father during the escape. The protagonist escapes alone, penniless, in damaged Oathkeeper. A treacherous relative takes the family seat.
- Exactly 22 noble seats: ten independent competing breakaway houses, twelve initially loyalist seats. The dead father is not an extra living ruler; the imperial family is separate.
- Nobles supply campaign support, not automatic personal pilot recruitment. Personal pilots are protagonist, restored princess and up to five companions, each needing a distinct assigned frame.
- A required investigation reveals the old emperor's crimes before the midpoint bargain; optional companions cannot gate it.
- Three loyalist houses offer four veteran formations, one advanced unassigned frame and gold for abandoning restoration. Acceptance permanently locks the self-crowning route and grants assets once. Refusal leads to the elite force and the midpoint prison rescue.
- Restoration rescue does not itself capture the capital. The princess leads politically and can pilot a frame. On dominion she organizes an independent escape and survives in exile.
- Both routes settle the whole civil war through explicit house recognition, diplomacy/submission/conquest and the final confrontation. Coalition settlements can avoid repetitive conquest.
- The prince refuses surrender and dies fighting. Restoration crowns the princess empress with the protagonist prince-consort, marriage and destruction of the throne mechanism. Dominion crowns the protagonist while the princess survives abroad. The throne amplifies choices/dependence rather than removing responsibility.
- Names, ages, companion biographies and detailed scenes are authored drafts unless specifically user-established. Preserve canon without treating all prose/art as separately approved.

## Current implementation boundary

The November 3 implementation adds connected source functions for P1–P6: persistent journal and defense → camp → explicit permission → headquarters; warband/banner and formal troops; categorized inventory/loot and field medicine; funded merchant caravan/rescue; solo tournament; distinct pilot/formation/frame progression; five optional personal pilots with exclusive assignments; 22-seat diplomacy, counteroffers, custody/succession, war/peace, domain sieges/control/taxes; required investigation; permanent sponsor bargain; restoration rescue or independent exile; explicit recognition/coalitions; final confrontation and both canon endings with bounded epilogues.

New focused models are `quest_model.gd`, `economy_model.gd`, `pilot_model.gd`, `politics_model.gd` and `chronicle_model.gd`; `campaign_panel.gd` connects ordinary menus, and `landscape_layout.gd` fits the mobile canvas to display safe areas. Regional controls include next-unit navigation, touch drag/pinch and zoom/pan/fit. Schema 4 preserves schemas 1/2/3 through conservative migration and retains runtime validation, one-time claims and failed-save rollback.

The November 4 targeted Godot exercises covered battle rules, controller confirmation, schema-1/2/3 migration, isolated deployment checkpoints and one-time first-chapter rewards. This is not a complete campaign playthrough or device validation. Actual player saves were not opened or rewritten. No packaged build remains in the workspace.

Read `plan/implementation-state.md` for the exact connected path, authored balance defaults and remaining boundary. New faces, fuller ruler/companion scenes, additional scenery and detailed non-Oathkeeper unit animation are not finished. Bounded portrait choices currently use available original heraldic emblems, clearly labeled. The existing detailed walk/attack limitations remain; do not restart QA or art experiments.

The previous planning archive, QA captures, stale build, 3D/pixel/review pipelines, tests and generated editor cache were removed to reduce workspace size. Preserve unrelated existing dirty changes, active original art, internal save isolation and real player saves. Numerical balance values and generic domain/ruler/mission details added during implementation are authored defaults, not newly approved user canon.
