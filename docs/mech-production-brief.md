# Oathkeeper production brief

**Authority:** User-approved original concept in `assets/art/mechs/concepts/oathkeeper.png`; decisions in `MEMORY.md`. Both previous cutout rigs were rejected.

## Visual target

An imposing ivory/navy armored knight, not a lanky animal-like walker. Match the small angular visor helmet with two slender crests, broad faceted pauldrons, layered breastplate over an exposed mechanical waist, substantial thigh/shin armor, human-like knees and planted armored boots. Matte worn ivory dominates, restrained navy panels define the armor, and brass identifies joints/fittings. Wear must not overwhelm the silhouette at battle size.

## Editable source structure

- `Body`: independent armor shells and mechanical frame in consistent meter-based units.
- `Rig`: reusable body/hand rig, named anatomical sides and attachments `hand_r` / `hand_l`.
- `Equipment_Sword`: separate starting sword attached through its grip, replaceable independently of the body.
- `Equipment_Shield`: separate starting kite shield attached through its mount, replaceable independently of the body.
- `Render_Setup`: camera, lights and neutral stage. Establish the reference still before producing animation/direction renders.

Never destructively join weapons or shields into body geometry. Store equipment identifiers/attachment names and keep transforms editable. Future handedness restrictions, dual wielding, inventory rules, ranged statistics and UI are not decided by this asset structure.

## First review

Produce one large still and a battle-size sample from the same scene. Compare proportions, armor shapes, stance, perspective and materials with the original. Treat the source as a model study until visually reviewed. Do not label an approximate procedural model a faithful finished asset or mass-produce animations because technical checks pass.

## Later export

Render six tactical angles from the same model with consistent feet/frame bounds and transparent backgrounds. Starting animations: idle, walk, sword attack, ordinary hit, guard, guarded hit. Export complete equipped frames per supported initial loadout, then pack atlases. The source remains modular for future weapons/shields; exported pixels remain tied to their named loadout. A baked sprite sheet does not imply arbitrary equipment swapping.
