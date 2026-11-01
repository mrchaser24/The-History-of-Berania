# The History of Berania — Dawn at Greyford

**Prototype 0.3 — The Living March:** the existing 2D prologue and persistent workshop now connect to a bounded regional campaign: four settlements, five moving party types, fog, timed rescue incidents, guild work, trade, recruiting, one support pact and a hostile supply raid. Preparation locks owned and allied forces into larger hex battles with cover, mage circles, cavalry, pikes and artillery. This is a playable regional loop, not the full imperial campaign.

## Play

Open `project.godot` in **Godot 4.7.2** and choose **Run Project** (**⌘B** on the inspected Mac; **F5** on other default keymaps). The main scene is `scenes/main.tscn`. The existing macOS installation is `/Applications/Godot_mono.app`; all game code uses GDScript and does not require compiling a C# solution. The editor's pre-existing empty Node2D scene was saved separately as `preserved_editor_scratch.tscn`.

Choose **Begin the prologue** to read four brief memories: your childhood with the princess, her brother's coup, your father's sacrifice, and your escape into a divided empire. Then meet Captain Mira, travel east to Greyford, and enter the village. You start alone with a damaged walker and **zero gold**. Mira's two local formations assist only in the village defense; your walker is repaired free before the encounter. **Practice battle** starts the same encounter without changing campaign progress. New Game and restarting an encounter require confirmation.

You are an archduke's son, promised in marriage to the princess who is first in line to Berania's throne. The Emperor's second son murders him, takes the crown, and imprisons the princess. Your father dies helping you escape and charges you to save her and the empire. Ten of the twenty-two nobles secede; twelve join the usurper, whose forces are hunting you. Work, build an army, and return to restore the rightful heir. Full canon and open details are in [the story brief](plan/story-canon.md).

The initial desktop target is macOS/Apple Silicon with GL Compatibility rendering. Art/layout use a 1600 × 900 reference, displayed at 1280 × 720 or larger. Other release platforms have not been verified.

## Workshop review

Choose **Workshop review · prototype 0.2** on the title screen. This sandbox starts with a fully repaired Oathkeeper, 180 gold, and headquarters access for trying the banner creator. It uses its own save and does not grant these resources to your campaign.

- **Garage:** Buy a refurbished knight-pattern frame, assign your pilot, rename, repair, refit hull capacity, or sell a reserve frame while retaining its equipment.
- **Equipment:** Buy plating or actuators in Market, fit them into either module slot, and inspect the armor/movement tradeoff.
- **Market:** Trade grain and iron ore within a 20-good cargo limit. Reserve machines and gear do not occupy cargo.
- **Banner:** Choose two colors, one centered emblem, and a warband name. Save it and reopen the review to check persistence.
- **Art review:** Compare the approved original with the existing, unapproved 3D source study. This is a still-review view; the study is not rigged or animated.
- **Try this loadout:** Practice the village battle with the piloted frame's statistics. Results return to the workshop without changing gold, frame condition, or campaign progress.
- **Reset review:** Confirm to restore the separate sandbox to 180 gold and one frame.

The real campaign unlocks **Mech workshop** while at Greyford after its first defense. Purchases there use actual earned gold. Banner founding remains locked until a future headquarters milestone; the review mode previews it now.

Only the starting sword/shield visual set is supported. New weapon classes and the smooth 3D-rendered animation replacement await their visual gates. The existing battle uses legacy prototype art.

## Regional review and continued campaign

Choose **Regional review · prototype 0.3** on the title screen to try the overhaul directly in its own persistent save. It starts at defended Greyford with six hired formations and 48 remaining gold. Your real campaign and the 180-gold workshop review stay separate. Leaving the regional review returns to the real campaign's Continue slot.

In a real campaign, win the original Greyford defense first. Its 40-gold reward opens the regional roads and settlement services; no free army or headquarters is granted. Enter a friendly settlement to recruit, trade, replenish, repair or take guild work. Deliver two carried grain to Millhaven. Stonebridge's envoy offers a support pact at 2 trust and 20 gold; Emberwatch offers a contextual hostile supply raid. Only **End travel turn** moves the caravan, patrol, bandits, noble retinue and imperial army or ages attacks. Visible attack sites can be helped by reaching their hex and interacting.

**Road clearance · prepare** and incident/supply encounters open deployment selection. Up to nine owned formations join your piloted frame; local volunteers and house support fill spare slots within the shared ten-unit cap. The selected frame's actual fitted stats and condition enter battle. Owned formation strength and hull damage persist through results. Free required-frame recovery and retryable work remain available at zero gold.

New regional battles use 14×10 fields; review settlement buttons offer isolated **10-v-10** and **15-v-15** capacity practices, the latter on 18×12. They use clearly labeled temporary 2D tactical symbols while mech still/motion approval remains open. Win by holding the gold crossing for three consecutive turns or routing every enemy; your hero must survive. Native camera controls and exact targeting previews support the larger board.

See [the rules and tunable defaults](docs/regional-combat-rules.md) and [prototype 0.3 review](qa/prototype-0.3-review.md) for mechanics, evidence and limits.

## Controls

| Input | Action |
| --- | --- |
| Left click | Select a formation, move to an available hex, or attack an enemy |
| Hover | Path/cost, enemy statistics, or exact legal attack damage |
| 1 / 2 / 3 | Select walker / swords / gunners |
| B | Guard; reduction depends on role in regional battles (2 in the original opening) |
| Tab | Select the next ready regional unit |
| Q / E | Regional special attack / mage Mend; click a legal target |
| Mouse wheel / Arrow keys / Home | Regional battle zoom / pan / fit |
| F | Change facing once during that activation |
| Space | End the battle side or travel turn |
| N | Cycle Normal / Fast / Quick animation playback |
| G | Toggle optional hex outlines; off by default |
| Esc | Pause, controls, sound and reduced-motion settings |
| M | Mute/unmute effects |

Each unit moves at most once, then attacks or guards. A unit that has moved must finish before another activates. Unspent actions may be skipped through End Turn. Rocks block movement and line of sight; other units block movement. Facing chevrons matter: flank/rear hits add damage and can break formation cohesion. Routing differs from destruction. Oathkeeper's defeat ends the encounter; otherwise defeat or route every enemy to win.

The map uses 3 travel points per turn and a 2-hex vision radius. Only End Turn moves NPC parties. Tactical rounds, dialogue reading, idles and animations do not advance campaign time. Regional encounters add weighted rough ground, directional cover and role abilities; the old opening retains its earlier rules.

## Saves and recovery

The single campaign slot is `user://greyford_demo.json`; settings are in `user://demo_settings.cfg`. On macOS the default folder is `~/Library/Application Support/Godot/app_userdata/TheHistoryOfBerania/`. Validated saves keep a `.bak` last-good backup and use a temporary file before replacement. A damaged current save can recover from the backup; incompatible/malformed files are preserved and explained.

The review slot is `user://workshop_review.json`. Campaign schema 3 adds parties, incidents, contracts, formations, support and locked regional deployments to schema 2's ownership data. Schema-1 and schema-2 campaigns migrate without losing gold, progress, fittings or condition; the next checkpoint writes schema 3. The regional review slot is `user://region_review.json`. Invalid inventory references or duplicate ownership are rejected.

Travel, End Turn, battle entry, battle results, and workshop purchases create checkpoints. Continue during an interrupted battle restarts its initial deployment; there is no mid-battle saving. Victory grants 40 gold and 1 local trust exactly once. Defeat returns the company to Greyford with free repairs and no permanent losses, including at zero gold. The opening's temporary local infantry resets; owned regional formation strength persists and replenishment costs 1 gold per missing strength. Existing saves retain their gold/progress; choose Begin the prologue for the corrected zero-gold opening. Returning after victory allows free repairs without another reward.

## Verify

From the project directory:

```sh
bash scripts/verify.sh
```

Or run the individual suites:

```sh
/Applications/Godot_mono.app/Contents/MacOS/Godot --headless --path . --log-file /tmp/berania-models.log --script tests/run_tests.gd -- --qa
/Applications/Godot_mono.app/Contents/MacOS/Godot --headless --path . --log-file /tmp/berania-flow.log --script tests/demo_flow_test.gd -- --qa
/Applications/Godot_mono.app/Contents/MacOS/Godot --headless --path . --log-file /tmp/berania-workshop.log --script tests/workshop_test.gd -- --qa
```

The four suites write summaries in `qa/test-results.json`, `qa/flow-results.json`, `qa/workshop-results.json`, and `qa/region-results.json`. The regional suite includes full 10-v-10/15-v-15 simulations and integrated preparation/results/save-failure checks. QA save fixtures are isolated in `/tmp/berania_model_qa.json` and `/tmp/berania_ui_qa.json`; they do not replace the player's save. The model suite also writes a legal deterministic walkthrough for reproducing the starter battle.

Read [the prototype 0.3 review](qa/prototype-0.3-review.md) for current verification; [the prototype 0.2 review](qa/prototype-0.2-review.md) records the preserved workshop baseline. Read `qa/qa-review.md` for the full-plan review, adopted rules, actual verification evidence, and remaining limits. Read `plan/initial-plan.md` for the full roadmap.

## Scope and art

**Current art direction:** The user rejected the cutout mech assemblies and adopted a faithful 3D source model rendered into 2D sprites, starting with a still-image comparison. Weapons and shields must remain interchangeable source assets. This production replacement is in progress; the existing cutout renderer is a rejected visual prototype. See [project memory](MEMORY.md), [the current art plan](plan/mech-art-direction.md) and [the production brief](docs/mech-production-brief.md).

The original opening uses six unit definitions across three roles; regional battles add four definitions, making seven roles in total. Existing assets include painted Oathkeeper cutout animation, code-drawn infantry/enemy figures, three painted backgrounds/portraits, and six original synthesized effects. Oathkeeper uses **one transparent master atlas** for six facings and a shared limb inventory: idle, walking, sword attack, normal hit, guarding, and guarded hit. Its animations preserve existing rules and action timings. Finished replacement sprites, portrait expressions/blinking and full audio mixing remain later polish. Regional camera pan/zoom is implemented. Art prompts and provenance are in `assets/art/PROVENANCE.md`.

Choose **Legacy art study** on the title screen to inspect the isolated gallery, or run `scenes/mech_preview.tscn`. It shows detail and actual battle size, all six clips, and a comparison of all six facings from the same atlas. F changes direction, N changes speed, M toggles reduced motion, Space pauses, and R restarts the loops. The gallery never reads or writes campaign saves. The selected concepts and implementation brief are in [the mech art plan](plan/mech-art-direction.md).

Workshop ownership, module/hull upgrades, cargo trading, banner review, a bounded moving-party region, recruitment, one support agreement and seven regional combat roles are implemented. Full caravan economics, strategic house AI, companion/princess recruitment, conquest/sieges, headquarters founding and the full 22-house campaign remain roadmap work. This slice now tells the user-established coup and escape: the second son is the assassin/usurper, the princess is the rightful heir, and the father's sacrifice leaves the player hunted and alone. Imperial pursuit, the castle escape battle, and the princess rescue are narrated or future content, not additional implemented systems. Greyford, Mira, and unit names are provisional.

The data-export preset produces a PCK for use with the matching Godot executable; it is not a standalone application. Standalone macOS export requires matching export templates, which were not installed in the inspected environment. No signing/distribution readiness is claimed.

## Credits

Made with **Godot Engine**, licensed under the [MIT license](https://godotengine.org/license/), copyright © 2014–present Godot Engine contributors and © 2007–2014 Juan Linietsky, Ariel Manzur. Runtime display fonts use local system fonts with an engine fallback; no third-party font files are bundled. Painted assets, mech concepts and the master atlas were generated using the built-in imagegen tool; prompts and source provenance are documented in the art directory. Sound effects, rigs and procedural unit drawings are original project assets.
