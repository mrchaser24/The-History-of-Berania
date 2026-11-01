# QA review — Dawn at Greyford prototype 0.1

Reviewed November 1, 2026 against **the entire project plan, sections 0–12**, and the request for a short playable Godot intro/demo. The original implementation review produced plan 1.6; the latest story correction is now recorded in plan 1.7 and `plan/story-canon.md`. This report distinguishes a working demo from later roadmap requirements.

## Verdict

The short prologue is implemented and playable in the existing Godot project. The scoped rule/application suites pass **260 checks: 227 model/persistence/animation checks and 33 application-flow checks**. The intro, optional dialogue branch, campaign travel, NPC turn movement, battle, victory, reward return, and free repairs were also exercised through the actual Godot UI using the Computer tool. A legal UI playthrough won in round 4, matching the model walkthrough.

This is **not completion of M0–M7 or a release-ready game**. Standalone export templates are absent; fresh-player reviews and measured performance gates remain open. The demo's art, names and balance remain prototype content. The user-established coup, family history, succession, political split and restoration goal are canon; only explicitly listed story details remain open.

## Environment and repository

- Verified engine: **4.7.2.stable.mono.official.ed1daf0bf**. Game implementation: **GDScript**, not C#.
- Development/playtest host: macOS, Apple Silicon; the native Godot renderer reported **Apple M4**, OpenGL/Metal, Compatibility renderer.
- Layout reference: 1600 × 900. Native UI inspected in the editor's approximately 1280 × 720 embedded viewport. Minimum configured desktop window: 1280 × 720. Other operating systems/resolutions have not been verified.
- Existing parent Git root: `/Users/chase.hermosisima/Desktop/Projects`. Retained it for this task; no new repository, branch, staging, commit, reset, or unrelated project changes were performed. A future repository split needs its own deliberate task.
- The editor's pre-existing empty Node2D scene was preserved as `preserved_editor_scratch.tscn`. The demo uses a separate `scenes/main.tscn` and the project's main-scene setting.
- The cited original design document is still missing. Its exact text cannot be validated. The user's latest story correction is authoritative: second-son assassination/usurpation, imprisoned rightful heir, archduke's sacrifice, solitary mech escape, ten secessionists/twelve usurper loyalists, imperial hunt and restoration goal are fixed. Names, motives and exact later scenes remain open.

## Full-plan review and scoped disposition

| Plan area | QA finding / resolution | Demo disposition |
| --- | --- | --- |
| 0. Workspace/repository | Original scaffold existed; editor version and Git boundary needed evidence | Inspected; current scaffold retained and documented |
| 1. Objective/story | Generic exile draft omitted the user's central relationship, betrayal, sacrifice and goal | Four-memory canon intro, Mira pursuit branch, solo/zero-gold opening; ten secessionists plus twelve usurper loyalists; named demo cast remains provisional |
| 2. Production assumptions | Mono configuration does not imply a C# implementation; platform/capacity assumptions needed separation | GDScript/macOS selected; no dates or team-capacity claims |
| 2. Art/animation | Beautiful stills alone do not prove playable animation or legibility | Three original painted assets plus functional code-drawn figures; visual states/quality limits documented |
| 3. Combat scope | Nine archetypes and faction variants cannot all be prototype prerequisites | Three roles, six definitions, six commanded entities; later roles retained in the roadmap |
| 3. Campaign scope | World turns, fog, contact behavior and persistent jobs need staged implementation | 30 hexes, three-point travel, patrol/bandit movement and sight; only Greyford launches an authored encounter |
| 3. Trade/diplomacy/war | Moving markers must not be mistaken for a complete strategic simulation | Trade, caravans, recruitment, pacts, war and siege remain staged; portrait story dialogue is a presentation sample |
| 4. Milestones | Intro/travel precede formal fresh-player M1 exit review in this request | Bounded demo integration authorized by the latest user request; no automatic milestone-gate completion claimed |
| 5. Architecture | Rendering/timing cannot be authoritative for damage or rewards | Independent hex/battle/campaign/save models; resolved presentation records |
| 5. Saves/recovery | Interrupted transitions, corrupt saves and zero-gold losses are major progression risks | Checkpoints, validated temp writes, backup recovery, single reward guard, free recovery and tested retry |
| 6. Content | Scope counts and formal soldiers versus temporary allies can conflict | One village defense; two temporary formations; no claim of headquarters/formal recruitment |
| 7. Verification | Automated tests do not establish enjoyment, final visuals or broad platform support | Rule/flow evidence plus native visual playthrough; remaining human/export/performance checks explicit |
| 8. Risks | Adding visual content can outrun the playable loop | Shared figures/effects and small map; no added combat/logistics complexity |
| 9. Decisions | Proposed defaults needed concrete implementation choices | Prototype decisions below; unresolved creative/production decisions retained |
| 10. Expansion | Sieges and politics could be silently dropped or implemented too early | Kept as the next staged slices, not represented by inactive demo buttons |
| 11. Handoff | Original kickoff prompt would restart an already implemented scaffold | Updated to run/verify current demo and finish open review gates |
| 12. History | Plan should reflect implementation and latest story authority | Versions 1.6/1.7 and evidence links distinguish original baseline, corrected story, and later systems |

## Adopted prototype decisions

| ID | Concrete choice | Reason / limit |
| --- | --- | --- |
| D01 | Godot 4.7.2, GDScript, GL Compatibility, macOS/arm64 first | Matches inspected installation and available test host |
| D02 | 8 × 8 pointy hex battlefield; one hex per entity; fixed elevated 2D presentation | Small readable battle; no permanent outlines |
| D03 | Side turns; one move, then one attack/guard; moved unit retains activation | No ambiguous switching/action economy; explicit skip via End Turn |
| D04 | Terrain blocks movement/sight; occupied cells block movement, not shooting | Deterministic targeting; no friendly fire or reaction attacks |
| D05 | LOS cube rounding uses a fixed epsilon and is symmetric | Resolves edge/tie behavior; shared validator powers previews and execution |
| D06 | Six facing indices; relative front sectors 0/5, side 1/4 (+2), rear 2/3 (+3) | One explicit mapping; gold chevron and exact damage preview; artwork is still simplified |
| D07 | Damage: rounded strength-scaled attack + flank bonus − armor − guard, minimum 1 | Mechs do not lose attack with hull damage; formations scale 100% / 80% / 60% at ≥75% / ≥50% / below 50% strength |
| D08 | Guard absorbs 2 until the unit's next own-side turn | Expires in one predictable place |
| D09 | Infantry cohesion steady → shaken → routed | A damaging flank/rear hit or crossing below half causes at most one drop per attack; no morale recovery inside battle |
| D10 | Defeat if the protagonist falls; otherwise victory when all enemies are defeated/routed | Protagonist defeat wins ties; no permanent losses in this demo |
| D11 | 30 world hexes, 3 travel points, uniform cost 1, vision radius 2 | Rough-terrain costs and general hostile-party contacts are future M2 work |
| D12 | One authored defense with pending/checkpoint and rewarded flags | Safe for a single one-time encounter; general mission/run IDs and casualty/inventory ledgers remain required before expansion |
| D13 | Start alone with zero gold and 18/30 hull; village repair to 30 is free; victory +40 gold/+1 trust once | Corrected fugitive opening; local formations belong to Greyford; older saved resources remain valid |
| D14 | Painted 2D backdrop/portrait art, reusable procedural unit poses and effects | Rough unit art proves animation; finished six-view sprites and portrait expression rigs remain polish work |

### Starter content statistics

| Definition | HP / troops | Attack | Armor | Move | Range |
| --- | --- | --- | --- | --- | --- |
| Oathkeeper militia walker | 30 hull | 9 | 2 | 3 | 1 |
| Greyford Blades | 12 troops | 6 | 1 | 3 | 1 |
| Roadwardens | 12 troops | 6 | 0 | 2 | 4 |
| Ashen Raiders | 12 troops | 4 | 0 | 3 | 1 |
| Blackpowder Deserters | 10 troops | 4 | 0 | 2 | 3 |
| Cinderjack scavenged walker | 20 hull | 6 | 1 | 2 | 1 |

## Defects found and fixed

| Severity | Finding | Fix / verification |
| --- | --- | --- |
| P1 | A click on elevated unit artwork could select the hex behind its body | Front-to-back body hit testing; automated mech/formation hit tests and native attacks |
| P1 | A failed travel save could show an error overlay without constructing its Retry controls | Checkpoint failure refreshes modal UI; injected filesystem-failure test confirms rollback, visible Retry and hidden underlying controls |
| P1 | Replayed/stale results could change completed campaign state | Completed-result guard prevents duplicate rewards and stale defeat overwrite; model and whole-flow checks |
| P2 | JSON round trips change numeric representation; raw dictionary equality was an incorrect test boundary | Validate and restore the campaign before comparing semantic state; both suites pass |
| P2 | Malformed JSON produced engine error spam before backup recovery | Non-logging parser error handling and clear recovery message |
| P2 | Guard/AI activation, LOS ties and morale thresholds were underspecified | Adopted deterministic rules above; legal-action, rout, trapped-AI and termination checks |
| P2 | Map/side-panel labels and long log entries overlapped controls | Separated company/village labels, concise notes, bounded wrapping, and two recent log entries |
| P2 | Underlying controls remained visually bright above modal shading | Hide base controls while a modal's own controls intercept input |
| P2 | Title shading rectangles overlapped and created vertical stripes | Non-overlapping shade strips; corrected title inspected natively |
| P2 | The post-victory objective still asked the player to reach the village; returning to title retained travel hints | Completion/retry-specific objective and guidance; clear title messages on return; native recheck and two flow assertions |
| P2 | Starter narrative promised damage/repairs without an observable damaged state | 18/30 initial hull; free village repairs; 1.6 native 18→30→23→30 hull sequence and unchanged 60 gold verified; 1.7 starts at 0 and automated victory/recovery verifies 40 gold |
| P2 | Headless application-flow exit retained playing sound resources | Stop sound players on exit; QA fixtures run muted; final flow run has no leaked-object/resource warnings |

## Verification evidence

**Automated:** `tests/run_tests.gd` passes 227 checks; `tests/demo_flow_test.gd` passes 33. Machine-readable summaries are in `qa/test-results.json` and `qa/flow-results.json`. `qa/autoplay-walkthrough.json` records a reproducible legal battle, ending in victory in round 4 after 24 model actions. These counts include repeated coordinate/edge-case checks; they are not 260 independent feature scenarios.

Coverage includes four memory-page button advances, Mira's optional pursuit dialogue without advancing campaign time, zero-gold New Game, preserved older saved gold, neighbor/path/LOS geometry, occupancy/action locks, exact preview damage, facing/guard/strength, rout and protagonist precedence, trapped AI, complete battle termination, fog memory, movement budgets, NPC ticks, reward idempotency, zero-gold recovery, malformed/incompatible saves, backup preservation, write failure, repeated clicks during playback, pause, equal speed-mode outcomes, whole intro/world/battle/result/save/retry flow, practice isolation and restart.

**Native UI using Computer — original 1.6 baseline:** title and dialogue branch; travel and movement budget; sight-limited NPC markers; entering the village/free initial repair; sword/gunner/mech movement and attacks; guard and enemy turns; round-4 victory; +40 gold/+1 trust; persistent 23/30 hull on return; free repair to 30/30 without a second payment. Visuals were inspected with permanent hex outlines off. Native editor output reported zero game errors/warnings in the inspected run. The final session also verified the completed-campaign objective and guidance, clean return to title, bounded help text, hidden underlying modal controls, Fast/Quick/Normal cycling and reduced-motion toggles; default settings were restored. The demo was left running at the title.

**Story correction 1.7 native pass:** inspected all four memories at the approximately 1280 × 720 viewport, including the complete childhood/betrothal, coup/dungeon, sacrifice/escape, 22 = 10 + 12 and hunt text. Inspected both Mira replies and the world start: zero gold, zero trust, 18/30 hull, a solo walker marker and Wanted by the Crown label. A header backing was added for contrast and inspected after restarting the final build. The demo was left on its first revised memory page. This pass did not repeat the unchanged full native battle; automated whole-flow verification covers its new 40-gold result. The existing checkpoint was preserved in `qa/pre-story-update-save.json` before starting the native QA journey.

**Packaging:** `export_presets.cfg` builds `builds/BeraniaDemo.pck` with Godot's data exporter, excluding tests, QA and plan folders. It includes imported art/audio, compiled scripts and the main scene. A `--main-pack` headless initialization smoke test exits successfully. The PCK requires the matching Godot executable; it is not a standalone macOS app.

**Environment note:** sandboxed Godot invocations emitted a macOS certificate-store access error; headless editor import initially also hit local editor-cache/messaging restrictions. Approved unsandboxed editor import completed successfully. This demo performs no network requests. The final approved normal-host verification passed both suites and the data-pack initialization with no engine errors or resource-leak warnings. An editor-only overlapping native-dialog error was resolved by preserving the scratch scene and restarting the editor; it was not a game runtime failure. The native command palette confirmed Run Project is ⌘B on this Mac.

## Open checks and remaining limitations

| Priority | Remaining item | Required before |
| --- | --- | --- |
| P1 gate | Matching export templates are not installed; standalone application launch/signing/distribution not verified | Claiming M0 export completion or sharing a standalone release |
| P1 gate | Two unfamiliar players have not tested the encounter | Claiming M1 review-gate completion or broad usability validation |
| P2 | Reference-machine frame-time/FPS target has not been measured over a session | Claiming the 60 FPS performance gate |
| P2 | Formation figures have simple mirrored poses with six-way rule chevrons, not finished six-direction paintings; portrait has subtle idle, not full expression/blink rigs | M5 visual-content completion |
| P2 | Camera fits the demo board; no player pan/zoom, general terrain-cost palette or general moving-party contact encounters | Full M2 implementation |
| P2 | Infantry reset per encounter; no roster inventory, upgrades, injury ledger or general encounter transaction IDs | M3/M4 expansion |
| P2 | Village defense currently uses route-enemies/survive; no village-health/protect timer or caravan extraction objective | M4 activities |
| P2 | Markets, caravans, diplomacy agreements, recruitment, two companions, headquarters and full chapter pacing are not implemented | M3–M6 |
| P2 | War/peace, conquest, noble custody/fates, fort assault and relief are not implemented | M7/political expansion |
| P2 | Missing original design document; unresolved names, motives, archduke-house accounting and exact rescue scenes | Author remaining details while preserving the user-established canon |
| P2 | Castle escape and imperial hunt are narrated; no playable escape, imperial chase AI or princess rescue exists in this slice | Later authored chapter/pursuit/liberation implementation |

The full roadmap remains intact. The next useful step is a fresh-player combat review and measured export/performance pass, followed by the smallest campaign feature the review supports. Do not expand the world to all 22 nobles or add more unit roles merely to make the prototype appear complete.
