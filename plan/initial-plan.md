# The History of Berania — Main Implementation Plan

**Revision:** 2.1 — November 3, 2026  
**Priority:** Finish the main game functions. Use the existing detailed 2D artwork.  
**Authority:** Latest user instructions, then [story canon](story-canon.md), this roadmap, [campaign rules](campaign-refinement.md), and [art direction](mech-art-direction.md).

This replaces the older production roadmap and its superseded art experiments. Retired historical planning, review and QA files were removed from the workspace; they are not additional tasks.

## Current direction

- Detailed, inked/painted 2D art is the selected presentation. The existing illustrated Oathkeeper v004 sheet is restored; the pixel experiment is offline.
- Fixed complete mechs with permanent weapons. Only left/right visual facings; each frame contains the complete machine, sword and shield.
- Remove all 3D work, model/rig/render pipelines, full-rotation work and interchangeable weapons from production scope.
- The user authorized targeted Godot exercises of the current changes on November 4, superseding the earlier no-QA instruction for this work. Retain ordinary runtime input/save validation and transaction guards as functional game code.
- Main gameplay implementation comes before further art/animation production. The existing detailed walk/attack are not newly approved or claimed fixed. Their limitations must not stall campaign work.
- Preserve source artwork, existing user edits and real player saves. Old experiments and reports are not active requirements.
- Zero spending and no paid service dependencies. Use the existing Godot/GDScript project and local resources.
- Single player; desktop, Android and iPhone targets; landscape interface. Preserve the current playable project while extending it.

## Intended game

A hunted archduke's son escapes alone in damaged Oathkeeper, earns repairs and pay, builds a warband and headquarters, recruits personal mech pilots, negotiates with nobles and settles Berania's civil war. The required midpoint bargain permanently selects restoration of the princess or the protagonist's own claim to the throne.

The core loop is **travel → work/trade → prepare troops and frames → fight/intervene → receive consequences → repair/recruit → gain territory and political support**. A complete campaign must support both established endings rather than ending at the current regional demo.

## Implemented source boundary

The opening and regional framework now connect to the chapter/HQ flow, categorized inventory and loot, funded caravan, tournament, separate formation/pilot/frame progression, five optional personal pilots, the 22-seat diplomatic/siege model, required investigation, permanent bargain, rescue/exile, recognition and both endings. The new campaign menus connect these models to ordinary play.

[Implementation state](implementation-state.md) records the concrete paths, authored defaults, migration and remaining content/presentation boundary. Targeted battle, controller and isolated first-chapter persistence exercises passed in Godot on November 4. The full campaign and device layouts have not been exercised; real player saves were not rewritten and no package was rebuilt.

## Implementation order

Implement these in order, connecting each feature to the real campaign and existing save/transaction flow. Reuse existing encounters, maps, portraits and unit drawings while functions are incomplete. Do not replace delivery with more planning or art experiments.

### Next priority — battle gameplay

- [x] Implement the agreed five-phase turn, per-action confirmations, melee counterattacks and contested capture objectives with encounter-configurable targets, following [battle phases](battle-phases.md). Targeted battle and controller exercises passed in Godot on November 4; a full campaign and device playthrough remain outstanding.

### P0 — Production reset

- [x] Restore the illustrated Oathkeeper atlas and its original facing convention.
- [x] Remove development review launchers from the ordinary title screen.
- [x] Replace the conflicting roadmap with this gameplay-first plan.
- [x] Remove obsolete validation, pixel, 3D, review and historical planning resources from the workspace and export preset.

### P1 — Finish the first playable chapter

- [x] Add a persistent quest journal with required/optional status, prerequisites, objectives, outcomes and one-time rewards.
- [x] Add the required bandit-camp mission after Greyford. Clearing it grants the remaining required trust and suppresses recurring camp raids.
- [x] Make the required path Greyford defense → bandit camp → explicit headquarters permission. Default permission requires camp cleared and local trust at least 3. Optional jobs, tournament, trading and companion quests cannot gate it.
- [x] Add a real headquarters location/menu: found/name the warband, create/edit its two-color one-emblem banner, manage the party, shared reserves and formal recruitment.
- [x] Give the first formal soldier formation through the headquarters story event once, distinct from Greyford's temporary allies and earlier hired detachments.
- [x] Keep the regional world playable after founding headquarters. Required jobs remain retryable, and free essential recovery stays available at zero gold.
- [x] Add player naming and bounded heraldic portrait selection using available original emblems; preserve the fixed noble history and romance. No new face artwork is implied.

### P2 — Complete the preparation and economic loop

- [x] Finish categorized party inventory, protected quest items, take/leave loot, cargo overflow choices and one-time battle/quest loot delivery.
- [x] Add a third useful trade good and settlement-specific prices/access without a global production-chain economy.
- [x] Add one merchant agreement and funded player caravan route: endpoints, goods, dispatch, travel, delivery, return, ambush, loss and reports. Cargo cannot deliver while reserved in an ambush.
- [x] Complete the authored caravan rescue without making it a required headquarters prerequisite; camp clearance must not erase this optional content.
- [x] Add a one-on-one mech tournament with an explicit optional fee/prize and one-time reward handling.
- [x] Add formation experience/upgrades and keep formation XP, pilot XP and owned-frame improvements separate.
- [x] Complete workshop ownership and module/refit flows for distinct fixed-design frames. Preserve Oathkeeper's usefulness; no weapon purchasing/swapping.

### P3 — Personal pilots and noble interaction

- [x] Add pilot instances, assignments, personal progression, recoverable injuries and deployment eligibility. One frame has one pilot, and one pilot has one deployed frame.
- [x] Implement two early optional companion arcs with affordable owned/loaned frames, then the remaining three companion arcs. The full personal roster is protagonist, restored princess and up to five companions.
- [x] Keep noble allies as strategic support rather than automatic personal pilot recruits.
- [x] Add reusable ruler dialogue: portrait/crest/name, topic, two to four replies, offer/counteroffer, visible terms and explicit commitment.
- [x] Finish the first noble support quest/pact, then data-driven access, recruitment, funding, trade and military support agreements. Opinion, stance, membership and recognition are distinct.
- [x] Add custody, release/ransom, negotiated submission and authored succession. Capture does not automatically recruit a noble; any execution choice has visible consequences.

### P4 — Living campaign, war and settlement control

- [x] Give each party an owner, strength, destination and one meaningful job. Patrols respond to threats, bandits raid/retreat/recover, caravans deliver and nobles attend meetings.
- [x] Add player/NPC contact choices, legal withdrawal and reserved participants. Off-player actions create visible incidents/reports rather than silently launching player battles.
- [x] Resolve campaign turns in stable order: move parties, reserve contacts, resolve eligible arrivals/expired incidents, progress sieges/trade/recovery, refresh visibility, commit state and present decisions.
- [x] Add the 22-house register from canon: ten independent opening factions and twelve loyalist seats. Keep house identity, ruler fate, faction membership and domain ownership separate.
- [x] Add data-driven peace, war, truce, alliance obligations and betrayal consequences. New declarations are announced before a party can attack under them.
- [x] Implement a constrained first fort siege: approach/warning, readiness, assault or surrender, a reusable major battlefield and capture objective.
- [x] Connect conquest to persistent settlement ownership, garrisons, simple taxes and an administrator choice. Expand through the canon house domains without a separate city-building game.
- [x] Use bounded off-player strength resolution and active party counts. Protect required story characters/events from being erased by off-screen outcomes.
- [x] Keep ordinary deployment at ten per side and major/siege deployment at fifteen, counting all allied and personal mech participants. No hidden reinforcement bypass.
- [x] Complete the ten core tactical archetypes through data and shared logic: swords, gunners, mage circle, cannon, shield/lance foot troops, sword/gun horsemen, shield mech, sword mech, lance mech and gunner mech. Faction access/doctrine must differ beyond recoloring. Existing role art can stand in until functions are complete.

### P5 — Required investigation and permanent story fork

- [x] Add the required evidence chain exposing the old emperor's assassination/persecution orders and corroborating testimony. It cannot require an optional pilot.
- [x] Introduce the princess's agency and the ally who enables her independent escape before the branch.
- [x] Add the Rothmar/Vaust/Merrow bargain with visible terms: abandon restoration in exchange for four veteran formations, one advanced unassigned frame and a fixed gold grant.
- [x] Rejecting leads to the sponsors' elite force and then the midpoint prison raid. The raid rescues the princess without capturing the capital.
- [x] Accepting atomically locks the dominion route and grants its assets once. Later behavior cannot reopen restoration or repeat the grant.
- [x] Add the restored princess as political leader and eligible assigned-frame pilot; on dominion, resolve her independent escape and continued survival in exile.
- [x] Handle displaced/captured/dead bargain-makers through house envoys/successors. Early capital access, sponsor betrayal and ordinary wars cannot bypass or erase the branch.

### P6 — Finish the civil war and both endings

- [x] Connect alliances, submission and conquest to explicit sovereign recognition for every major house seat. Friendship, peace and ownership alone do not imply recognition.
- [x] Add authored coalition settlements so completion does not require repeating 22 sieges.
- [x] Implement the final capital/throne encounter. Lucien refuses surrender and dies fighting; no invented final mercy/execution branch.
- [x] Implement restoration: princess becomes empress, protagonist becomes prince-consort, marriage and destruction of the throne's magical mechanism.
- [x] Implement dominion: protagonist takes his own crown, princess survives abroad, with the canon throne consequences.
- [x] Commit the ending and recognition settlement persistently so a subsequent unseen world update cannot undo completion. Add bounded companion/house epilogues within the two main routes.

### P7 — Ordinary player flows and remaining presentation

- [x] Connect the compact landscape interface in [battle-ui-simplify.md](battle-ui-simplify.md): world/HQ/party/quest/diplomacy access, contextual regional combat actions, scrollable menus, touch pan/pinch, safe-area fitting, settings and explicit outcomes. Device-specific refinement remains possible; no runtime exercise was performed.
- [x] Remove redundant development-only UI and disconnected prototype paths from ordinary play; preserve internal save-isolation safeguards and historical files outside active delivery.
- [ ] Integrate detailed 2D art into additional supported units only after the main campaign functions exist. Use whole-character animation, fixed weapons and left/right views. No new animation-production detours before then.
- [ ] Package the game when implementation needs a deliverable. Packaging is delivery work, not a QA or performance milestone.

## Runtime and persistence contracts

- Keep `scenes/main.tscn` as the entry point. Extend the existing project rather than starting another game or replacing its working opening.
- Split new quest, party, trade, house, headquarters and story state into focused GDScript models/data; avoid adding every system to `demo.gd`.
- Keep immutable definitions separate from owned frame/pilot/formation instances and one-time claims.
- Migrate schema 1/2/3 campaigns to the new schema without resetting gold, ownership, condition, cargo or completed opening progress. New flags get conservative defaults; old saves do not receive unearned quest completions or repeat rewards.
- Keep one campaign slot, last-good backup, stable campaign checkpoints and interrupted-battle restart from the committed deployment. Do not add mid-battle saving or cloud services.
- Lock selected pilots/frames/formations and allied participants before entering battle. Apply results and rewards to those same owned instances once.
- Advance strategic time only through End Turn, never through dialogue, menus, rendering, animations or tactical rounds.
- Commit purchases, agreements, loot, routes and branch rewards atomically. Required quest items are not saleable. Prevent selling the last usable required frame without a usable replacement.
- Retain free required-frame recovery, retryable required work, and recoverable early pilot/formation losses. Optional spending must not make the main route impossible.
- Keep hidden hexes by default, temporary movement/target previews, tactical facing indicators and deterministic gameplay independent of the sprite facing.

## Removed from the active backlog

All 3D production; pixel/detailed style switching experiments; segmented mech rigs; modular/custom weapons; six-view/full rotations; QA/testing/review/benchmark gates; repeated review builds and screenshot sessions; multiplayer; real-time combat; full voice acting; hunger/ammunition upkeep; multiple player armies; elaborate construction/production chains; individual human equipment; naval play; procedural political simulation; mod/cloud/achievement/localization infrastructure; unadopted optional role catalogues. Do not reintroduce these to make the core plan larger.

## Current implementation handoff

P1–P6 have connected source implementations; [the implementation state](implementation-state.md) describes their bounded scope and authored defaults. P7's ordinary menus and input functions are connected. Detailed art beyond Oathkeeper, richer authored conversations/scenery and a new delivery package remain separate work. Preserve real saves and unrelated dirty work; do not restart animation comparisons or historical review pipelines.
