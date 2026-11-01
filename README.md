# The History of Berania — Dawn at Greyford

A short, playable **2D Godot prologue prototype**: illustrated intro → portrait dialogue → turn-based hex travel with moving NPCs and fog → an animated three-versus-three battle → victory/recovery → a persistent return to the village. It proves a small slice of the larger plan, not the full first chapter.

## Play

Open `project.godot` in **Godot 4.7.2** and choose **Run Project** (**⌘B** on the inspected Mac; **F5** on other default keymaps). The main scene is `scenes/main.tscn`. The existing macOS installation is `/Applications/Godot_mono.app`; all game code uses GDScript and does not require compiling a C# solution. The editor's pre-existing empty Node2D scene was saved separately as `preserved_editor_scratch.tscn`.

Choose **Begin the prologue** to read four brief memories: your childhood with the princess, her brother's coup, your father's sacrifice, and your escape into a divided empire. Then meet Captain Mira, travel east to Greyford, and enter the village. You start alone with a damaged walker and **zero gold**. Mira's two local formations assist only in the village defense; your walker is repaired free before the encounter. **Practice battle** starts the same encounter without changing campaign progress. New Game and restarting an encounter require confirmation.

You are an archduke's son, promised in marriage to the princess who is first in line to Berania's throne. The Emperor's second son murders him, takes the crown, and imprisons the princess. Your father dies helping you escape and charges you to save her and the empire. Ten of the twenty-two nobles secede; twelve join the usurper, whose forces are hunting you. Work, build an army, and return to restore the rightful heir. Full canon and open details are in [the story brief](plan/story-canon.md).

The initial desktop target is macOS/Apple Silicon with GL Compatibility rendering. Art/layout use a 1600 × 900 reference, displayed at 1280 × 720 or larger. Other release platforms have not been verified.

## Controls

| Input | Action |
| --- | --- |
| Left click | Select a formation, move to an available hex, or attack an enemy |
| Hover | Path/cost, enemy statistics, or exact legal attack damage |
| 1 / 2 / 3 | Select walker / swords / gunners |
| B | Guard: finish the activation and reduce incoming damage by 2 |
| F | Change facing once during that activation |
| Space | End the battle side or travel turn |
| N | Cycle Normal / Fast / Quick animation playback |
| G | Toggle optional hex outlines; off by default |
| Esc | Pause, controls, sound and reduced-motion settings |
| M | Mute/unmute effects |

Each unit moves at most once, then attacks or guards. A unit that has moved must finish before another activates. Unspent actions may be skipped through End Turn. Rocks block movement and line of sight; other units block movement. Facing chevrons matter: flank/rear hits add damage and can break formation cohesion. Routing differs from destruction. Oathkeeper's defeat ends the encounter; otherwise defeat or route every enemy to win.

The map uses 3 travel points per turn and a 2-hex vision radius. Only End Turn moves NPC parties. Tactical rounds, dialogue reading, idles and animations do not advance campaign time. The regional art is illustrative; Greyford is the demo's only interactive settlement.

## Saves and recovery

The single campaign slot is `user://greyford_demo.json`; settings are in `user://demo_settings.cfg`. On macOS the default folder is `~/Library/Application Support/Godot/app_userdata/TheHistoryOfBerania/`. Validated saves keep a `.bak` last-good backup and use a temporary file before replacement. A damaged current save can recover from the backup; incompatible/malformed files are preserved and explained.

Travel, End Turn, battle entry, and battle results create checkpoints. Continue during an interrupted battle restarts its initial deployment; there is no mid-battle saving. Victory grants 40 gold and 1 local trust exactly once. Defeat returns the company to Greyford with free repairs and no permanent losses, including at zero gold. Infantry strength currently resets with each encounter. Existing saves retain their gold/progress; choose Begin the prologue for the corrected zero-gold opening. Returning after victory allows free repairs without another reward.

## Verify

From the project directory:

```sh
bash scripts/verify.sh
```

Or run the individual suites:

```sh
/Applications/Godot_mono.app/Contents/MacOS/Godot --headless --path . --log-file /tmp/berania-models.log --script tests/run_tests.gd -- --qa
/Applications/Godot_mono.app/Contents/MacOS/Godot --headless --path . --log-file /tmp/berania-flow.log --script tests/demo_flow_test.gd -- --qa
```

The suites write summaries in `qa/test-results.json` and `qa/flow-results.json`. QA save fixtures are isolated in `/tmp/berania_model_qa.json` and `/tmp/berania_ui_qa.json`; they do not replace the player's save. The model suite also writes a legal deterministic walkthrough for reproducing the starter battle.

Read `qa/qa-review.md` for the full-plan review, adopted rules, actual verification evidence, and remaining limits. Read `plan/initial-plan.md` for the full roadmap.

## Scope and art

This demo includes six unit definitions across three roles, original code-drawn animated figures, three original painted images, and six original synthesized effects. Unit animation and six-way facing markers are functional prototype art; finished six-view sprites, portrait expressions/blinking, full audio mixing and camera pan/zoom are later polish. Art prompts and provenance are in `assets/art/PROVENANCE.md`.

Trading, caravans, recruitment, political agreements, sieges, the remaining unit roles, the headquarters chapter, and the full 22-noble campaign remain staged roadmap work. This slice now tells the user-established coup and escape: the second son is the assassin/usurper, the princess is the rightful heir, and the father's sacrifice leaves the player hunted and alone. Imperial pursuit, the castle escape battle, and the princess rescue are narrated or future content, not additional implemented systems. Greyford, Mira, and unit names are provisional.

The data-export preset produces a PCK for use with the matching Godot executable; it is not a standalone application. Standalone macOS export requires matching export templates, which were not installed in the inspected environment. No signing/distribution readiness is claimed.

## Credits

Made with **Godot Engine**, licensed under the [MIT license](https://godotengine.org/license/), copyright © 2014–present Godot Engine contributors and © 2007–2014 Juan Linietsky, Ariel Manzur. Runtime display fonts use local system fonts with an engine fallback; no third-party font files are bundled. The three painted assets were generated using the built-in imagegen tool; all prompts and saved asset paths are documented in the provenance file. Sound effects and procedural unit drawings are original project assets.
