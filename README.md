# The History of Berania

A single-player medieval-magitech strategy RPG about a hunted archduke's son, his promise to the imprisoned princess, a growing warband and a divided empire.

## Current source

The existing Godot project now connects the opening to a persistent quest journal, required bandit camp and explicit headquarters founding, party/pilot assignments, categorized inventory and loot, a funded caravan, optional tournament and companion missions, the 22-house diplomatic/siege model, required investigation, permanent story choice, recognition and both canon endings.

Use detailed painted/inked 2D art and fixed complete mechs. Oathkeeper retains its existing illustrated v004 atlas; other frame roles use supporting symbols. Additional detailed art and fuller authored conversations/scenery remain outside this implementation. No 3D production, interchangeable weapons, paid services or QA workflow is active.

[Implementation state](plan/implementation-state.md) describes the actual connected functions, authored defaults and remaining boundary. [The roadmap](plan/initial-plan.md), [story canon](plan/story-canon.md) and [campaign contracts](plan/campaign-refinement.md) remain the authorities.

Targeted Godot exercises on November 4 covered battle rules, controller confirmation and isolated first-chapter persistence. They do not constitute a full campaign or device playthrough. No packaged build remains in the workspace. Actual player saves were not opened or rewritten during these exercises.

## Run and play

Open `project.godot` in the existing Godot installation and run `scenes/main.tscn`. Begin the prologue, choose a name/heraldic portrait and continue the memories. Start alone with zero gold and damaged Oathkeeper; Greyford's militia are temporary allies.

The required first chapter is **Greyford defense → bandit camp → Greyford council permission → watchhouse headquarters**. Defense grants 1 trust and the camp 2, covering the permission requirement without optional work. The watchhouse opens warband naming/banner, shared reserves, party management and one formal soldier award. Free essential recovery and retryable required work remain available.

Map buttons open Journal, Party, Inventory, Houses and Story. Enter locations for their services. The scrollable campaign menus also expose Headquarters, Trade, Contacts and Identity. Only **End travel turn** advances strategic time; dialogue, menus, tactical rounds and animations do not.

After headquarters, follow Story's required investigation through Millhaven, Stonebridge and Emberwatch. The reviewed three-house bargain permanently selects restoration or dominion. Rescue or independent exile precedes sovereign recognition and the final capital battle. Explicit coalition settlements can resolve the houses without repeating 22 sieges.

Optional regional jobs, merchant rescue, funded trade, a solo mech tournament and five personal pilot quests remain available. Each personal pilot needs a distinct assigned usable frame and a deployment preference. Owned condition, formation XP, pilot XP and frame improvements remain separate. Ordinary battles cap each side at ten units; major battles and sieges at fifteen, including all allies and personal mechs.

## Controls

| Input | Function |
| --- | --- |
| Click/tap | Select a unit, destination, target or menu action |
| Space | End battle side or travel turn |
| B / F | Guard / change tactical facing |
| Tab / Next ready | Next eligible unit |
| Q / E | Ability / mage Mend |
| Wheel, arrows, Home | Regional/major battle zoom, pan, fit |
| Drag / pinch | Regional/major battle pan / zoom |
| N / M | Animation speed / mute |
| G | Optional grid overlay |
| Esc | Pause/settings, or close campaign/workshop menu |

Native campaign menus scroll, the handset canvas fits display safe areas, and mobile orientation is landscape. Fixed frame weapons cannot be bought or swapped; friendly workshops handle reserves, assignment, repair, refits and internal modules. The existing detailed walk/attack limitations are unchanged by the gameplay work.

## Persistence and development

The campaign still uses `user://greyford_demo.json` and its last-good `.bak`. Schema 4 conservatively migrates schemas 1/2/3, retaining earned resources, ownership, condition, opening progress and interrupted deployments without granting new quest rewards. Runtime validation, one-time claims, battle-boundary checkpoints and failed-save rollback remain game functionality. Interrupted battles restart their committed deployment.

Read [MEMORY.md](MEMORY.md) before changes. Preserve unrelated dirty work, active original art and real player saves. Retired 3D, pixel, review, QA and build files were removed from the workspace and are not part of active delivery.

## Credits

Made with Godot Engine under the [MIT license](https://godotengine.org/license/). Existing artwork and sound provenance remain in the asset records.
