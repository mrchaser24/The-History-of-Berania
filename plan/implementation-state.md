# Campaign implementation state

**November 3, 2026 — source implementation, not an exercised build.** No Godot run, automated tests, QA, captures, benchmarks or packaging were performed. No packaged build remains in the workspace. Real player save files were not opened or rewritten by this work.

## Ordinary player path

1. Begin the prologue, choose a name and one of the available original heraldic portraits, then follow the existing memories. The protagonist remains the male Valcrest heir with the established romance. There is no new face artwork.
2. Defend Greyford for its existing 40 gold and 1 trust. Temporary militia stay local. The Journal records the outcome without repeating the payout.
3. Enter the marked bandit camp southeast of Greyford. Victory pays 30 gold and 2 trust once, suppresses its village raids and offers a cache through Inventory. Defeat returns the protagonist to free recovery; the camp stays retryable.
4. Explicitly request permission from Greyford's council. Camp clearance and trust ≥3 are sufficient. Optional jobs, companions, trade and the tournament do not gate permission.
5. Enter the watchhouse north of Greyford and explicitly found/name the warband with two banner colors and one emblem. Receive a formal sword formation and 1 additional trust once. Existing hired troops stay owned. Headquarters, Party, shared workshop reserves and formal recruitment remain connected to continued regional play.
6. Read the preserved orders at Millhaven, hear the physician at Stonebridge, then defeat Voss's courier encounter at Emberwatch. The evidence is protected inventory. The physician introduces Aurelia's independent efforts before the choice.
7. Review and explicitly commit the three-house bargain at headquarters. Acceptance permanently chooses dominion and delivers four rank-two veteran formations, an unassigned advanced Merrow frame and 120 gold once. Refusal permanently chooses restoration, then opens the sponsors' elite force and the capital prison raid. Ruler custody/succession cannot erase the envoys.
8. Restoration rescues Aurelia without capturing the capital. She leads politically, learns the complete evidence and can accept an explicit one-time frame loan; assignment and deployment remain separate. Dominion resolves her independently organized escape on a later End Turn and preserves her survival abroad.
9. Obtain explicit recognition from all 22 seats. Individual negotiation, custody/submission and two authored opening-bloc coalitions are available. A coalition requires two already-recognizing seats of that bloc and 5 trust; its reviewed terms settle the whole bloc without 22 repeated sieges.
10. Fight the final capital encounter. Lucien refuses surrender and dies fighting. Commit the canon restoration or dominion ending together with the chronicle, including bounded companion and house epilogues. The completed world no longer ticks; Continue opens its chronicle.

These are connected source paths, not a report of a completed playthrough. Numerical values and generic domain/ruler/mission details are authored implementation defaults, not newly approved canon or art.

## Optional and preparation systems

- **Inventory:** carried grain/ore/field medicine, protected evidence, owned frames and shared internal modules are separate. Battle loot stays pending across saves; take one/all, leave permanently, sell or discard carried goods to make room. A failed capacity check transfers nothing. Frames and modules use no cargo space.
- **Trade:** settlement prices differ; domain trade needs its charter or ownership. The optional persistent merchant rescue survives camp clearance. Its agreement funds six wholesale grain for 18 gold at Stonebridge, pays 36 once on Millhaven delivery and returns empty. Each funded route has an identity, position, cargo reservation, ambush deadline, rescue/loss and reports. Ambushed cargo cannot deliver.
- **Tournament:** optional Stonebridge one-on-one mech duel, 5-gold entry paid at deployment, 25-gold first-win purse once. No capture-objective shortcut. Defeat leaves it retryable.
- **Progression:** formation XP/rank, pilot XP/level and owned hull refits are distinct. Formation training costs 8 gold at 12/24 earned XP; pilot levels add attack at 12/24/36 XP. Owned damage survives battles; early losses remain recoverable.
- **Pilots:** protagonist, restored princess and up to five optional companions. Each authored companion mission offers an explicit usable service frame and joins the pilot in reserve. Assignment is exclusive; the protagonist's workshop assignment stays synchronized. Injuries recover through End Turn, carried medicine or free aid. Nobles do not become pilots.
- **Fixed frames:** knight, shield, fast sword, lance and gunner roles plus the advanced sponsor frame have different fixed stats/doctrines. Oathkeeper retains detailed v004 art; other roles use supporting symbols. No weapon customization or new animation/art production was added.
- **Politics:** exactly ten breakaway and twelve loyalist seats, persistent identity/faction/ruler fate/domain/stance/opinion/recognition, reviewed charter/support/funding/peace terms, earned-service counteroffers, recorded payments and deadlines. An optional Asterfell protection quest supplies a concrete early support job. Unchanged signed agreements do not farm opinion or funding.
- **Conflict:** declarations announce attacks for a later End Turn; truces, breaches and obligations have consequences. Domain locations support warning/readiness, major assault or conditional surrender, a maintained readiness-three blockade that gradually reduces defenders to a minimum of three, custody, ransom/release/submission, execution with successor and announced opinion costs, administrators, garrisons and bounded taxes. One announced off-player border front resolves bounded garrison losses later without erasing required actors.
- **Regional parties:** the bounded five parties have owners, strength, destinations, jobs and contact choices. Travel stops on contact or exhausted movement; rough ground costs two. Patrol response, caravan arrivals, meetings, bandit recovery and incident expiry produce reports. Committed player combat freezes strategic time and participants. Optional caravan ambushes continue after the required camp ends its village raids.
- **Controls:** scrollable native campaign menus, contextual regional abilities, on-map selection/next-unit controls in place of the large roster strip, battle zoom/pan/fit controls, touch drag/pinch, mobile landscape orientation and fitting the whole canvas within handset safe areas. Existing speed, pause, reduced motion and sound settings remain.

## Code and persistence

- `quest_model.gd`: immutable objectives, prerequisites, claims/outcomes, identity and chapter locations.
- `economy_model.gd`: protected inventory, loot claims and funded caravan lifecycle.
- `pilot_model.gd`: pilot instances, exclusive assignments, XP, injuries and formation stat progression.
- `politics_model.gd`: the 22 seats, contracts/counteroffers, war, custody/succession, sieges, taxes and bounded off-player fronts.
- `chronicle_model.gd`: investigation, permanent route, sponsor reward, rescue/exile and both endings.
- `campaign_model.gd`: conservative schema-4 migration, campaign commands, location access, locked deployment and atomic result integration.
- `campaign_panel.gd`: ordinary Location/Journal/HQ/Party/Inventory/Trade/Houses/Story/Contacts/Identity menus. `demo.gd` handles scene transitions, persistence and tactical presentation.
- `landscape_layout.gd`: handset safe-area canvas fitting; mouse/touch field coordinates are transformed into the fitted canvas.

Schemas 1/2/3 remain readable. Migration retains earned gold, trust, opening completion, owned frames/modules/cargo, strength and interrupted regional deployments. It records already-paid defense/delivery outcomes without granting new camp/HQ/branch/pilot rewards. New claims default conservatively. New snapshot guards validate pilot/frame uniqueness, protected evidence, formation stats, route flags and committed participants. Normal runtime save validation/backups and failed-save rollbacks remain game functionality.

## Remaining boundary

- Richer authored companion conversations, distinct ruler biographies/portraits and more varied mission/domain scenery are content expansion beyond these reusable functional flows. Existing heraldic portraits are identified honestly.
- Existing detailed walking/attack limitations remain. Additional complete detailed unit artwork is still deferred; supporting symbols are not finished mech animation or approval of new frame art.
- Further interface refinement for individual devices can be implementation work if requested; safe-area/touch code has not been exercised. Do not reopen QA, tests, captures or benchmarking under the current user instruction.
- No delivery package was rebuilt. Open the source project to use these changes; do not distribute the stale pixel-era PCK as this implementation.
