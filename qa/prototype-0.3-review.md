# Prototype 0.3 — The Living March

**Completed implementation review:** November 2, 2026. User visual/usability approval remains open.

This is the next integrated regional prototype after the preserved prologue and Workshop review. It advances bounded travel, preparation and combined-arms systems. It does not complete the full campaign milestones or the art production gates.

## Play and review

Run `scenes/main.tscn` through `project.godot` in Godot 4.7.2. Choose **Regional review · prototype 0.3** to skip the opening in an isolated persistent slot. Its initial six formations cost 82 of its 130 review gold, leaving 48, with full Oathkeeper hull and 1 trust. It has no headquarters. The older **Workshop review · prototype 0.2** still starts separately with 180 gold and headquarters access.

1. Enter Greyford. Open the workshop, fit a module and return to settlement services. Buy two grain and accept the guild contract.
2. Travel to Millhaven and deliver the carried grain for 16 gold / 1 trust. Only End travel turn moves parties and ages attacks; dialogue, battle and animations do not.
3. Watch the currently visible caravan/patrol and explore toward noble retinues, bandits and the imperial army. Dim land remembers geography, not live party positions. Help a visible village/caravan attack by reaching its site and interacting before it expires.
4. Recruit or replenish formations. Choose **Road clearance · prepare**, adjust owned deployment and inspect the owned/local/allied participant list. Your fitted frame and troops share the ten-slot cap with support.
5. In battle, hover a hex for weighted path cost or an enemy for exact damage. Q selects the role ability, E selects mage healing, B guards, F turns and Tab cycles ready units. Directional walls protect their marked arcs; rocks block sight; rough ground costs two movement. Hold the supply crossing three turns or route the enemy; the hero must survive.
6. Return through results. Hull and deployed formation strength persist; reserves do not take damage. Retry after a loss at zero gold with the required frame recovered for free.
7. At 2 trust, visit Stonebridge's envoy and review the 20-gold road pact. It provides two pike formations when command slots remain; the noble never becomes a personal pilot. Emberwatch offers a contextual hostile supply raid rather than an implemented fort siege.
8. At a review settlement, try **10-v-10** or **15-v-15** capacity practice. Wheel zoom, arrows pan and Home fits the board. These practices do not change saved resources, casualties or time, and Pause offers **Return to region**.
9. Leave the review, then Continue the real campaign to confirm save separation. A fresh real game still begins alone, at zero gold, with 18/30 Oathkeeper hull. Win its original village defense to unlock the region with the actual 40-gold reward; no army or headquarters is gifted.

## Implemented contracts

- Regional state lives in `scripts/region_model.gd` and the existing campaign model; combat remains authoritative in `scripts/battle_model.gd`, independent of rendering/timers.
- The opening remains 3-v-3. Regional ordinary fields use 14×10; major practice uses 18×12 and up to 15 units on each side. All allies/local defenders count within the shared side cap. Overflow stays outside with no hidden bonuses or reinforcement waves.
- Seven roles: mech, swords, pikes, gunners, cavalry, cannon and mage circle. Distinct abilities, role guard, directional cover, movement terrain, deterministic AI, objectives and exact damage previews are documented in [the rules sheet](../docs/regional-combat-rules.md).
- Preparation locks frame ID, stats from actual fittings, hull, formation ownership/strength and participant/reward data. Continue or confirmed restart restores that setup. No mid-battle save is advertised.
- Owned troop strength survives results and costs gold to replenish. A defeated/routed formation remains at one strength. Required-frame recovery is free at zero gold. Local volunteers remain borrowed units.
- Schema 1 and 2 migrate to schema 3 while preserving existing resources, ownership, fittings, cargo, crest and progress. Pending regional snapshots validate their bound frame/loadout, duplicate IDs and owned troop references. Backup/temporary-file save behavior is preserved. Failed preparation/recruitment/trade writes roll back; result save errors retain the computed result for Retry save.
- Regional review uses `user://region_review.json`, the campaign uses `user://greyford_demo.json`, and workshop review keeps `user://workshop_review.json`. All QA/UI runs used `/tmp` saves. No real player save was replaced.

## Verification actually run

`bash scripts/verify.sh` passes **1,265 checks** on Godot **4.7.2-stable (official)**:

| Suite | Checks | Failures |
| --- | ---: | ---: |
| Models, original battle, saves and animation contracts | 580 | 0 |
| Original application flow | 36 | 0 |
| Workshop / migration / isolated loadout trial | 45 | 0 |
| Regional campaign, combined arms, cap and application flow | 604 | 0 |

The historical baseline was independently run before changes and passed 582 + 36 + 45. The old model suite includes one assertion per AI operation; the revised shared path/AI implementation wins that same starter battle in 22 rather than 24 actions, so its dynamic count is now 580. No baseline assertions were removed.

New coverage includes schema-2 migration, exact JSON normalization of locked deployments, frame-stat binding, duplicate/cross-side/dangling IDs, no-time shopping/travel, incident visibility and expiry, actual carried-cargo delivery, one-time diplomacy/payment/results, repeatable-job cooldowns, persistent hull/strength, zero-gold loss recovery, shared 10/15 caps, legal spawns and maneuvering paths, exact cover/special damage, mage armor counter/healing, pike guard, cavalry charge threshold, cannon move restrictions, cooldown timing, objective hold/reset, full-capacity AI completion, camera targeting transforms/clipping, fitted plating entering a regional encounter, failed saves, isolated capacity restart/exit and restoration of the real save store after review.

The final model autoplay ran 10-v-10 to victory in round 7 (133 actions, 397 ms), and 15-v-15 to defeat in round 5 (227 actions, 1,051 ms). These are complete **headless model simulation timings**, not frame-rate, memory-budget or balance approval. Earlier runs varied with host load. Reports are `qa/test-results.json`, `qa/flow-results.json`, `qa/workshop-results.json`, and `qa/region-results.json`.

Native Computer inspection at 1280×720 confirmed the regional map, settlement services, six-role recruitment layout, 9/10 preparation list, fitted frame information, legal movement and activation lock, guard/next-unit controls, enemy turn return, all thirty 15-v-15 markers, two command rows, pause and direct return to the region. Layout inspection exposed low-contrast battle messages and overlapping map labels, which were revised. Automated tests additionally cover all camera transform combinations used in the review. No unfamiliar-player study or measured rendered performance gate is claimed.

`builds/BeraniaDemo.pck` was rebuilt and smoke-tested both at the title and in the isolated regional 15-v-15 scene using the installed matching engine. Verification now rejects gameplay script errors in logs. The pack remains engine data, **not a standalone app**. Matching standalone export templates, signing and distribution remain open. A temporary copy of the installed engine was used only to make native QA separately targetable; it is not a delivered application build.

Headless runs still emit the environment's CA-certificate diagnostic. Headless export also reports restricted C# IDE-listener/editor-settings access. These are distinct from gameplay script failures; the final gameplay suites, pack smoke scenes and native final run have no GDScript errors.

## Limits and remaining gates

- Five NPC types follow bounded deterministic routes. Attacks alternate as authored regional incidents; there is no full economic/trade-route simulation, reactive strategic house AI, autonomous territorial war or 22-house simulation. Ignored incidents expire but do not destroy settlements or main-story events.
- A single paid support pact and a regional hostility counter prove the interaction. They do not implement imperial recognition, changing ownership, full diplomacy, siege/conquest, custody or succession.
- The personal roster still has only the protagonist as a mech pilot. Companion/princess recruitment, guaranteed companion frame acquisition, headquarters founding, the permanent bargain/rescue and both endings remain future content. The ten-independent/twelve-loyalist lore register is unchanged.
- Ordinary regional content is intentionally smaller than the maximum. Full-capacity practices prove deployment, UI and AI operation; they do not prove all encounter compositions balanced or every content map ready.
- New battles use explicitly temporary original **2D tactical symbols**, not new finished unit sprites. The old opening/trial still use the legacy cutout renderer. No Blender source was changed, no rig/animation set produced, no model/still/motion approval inferred, and no runtime 3D introduced.
- Background painting remains illustrative. Finished terrain art, sprite motion, audio/music polish, larger-player usability review, measured worst-case rendering/residency and standalone launch gates remain open.
