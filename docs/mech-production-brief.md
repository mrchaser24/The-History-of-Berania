# Oathkeeper production brief

**Authority:** Original approved concept at assets/art/mechs/concepts/oathkeeper.png; explicit decisions in [MEMORY.md](../MEMORY.md) and the current [mech art direction](../plan/mech-art-direction.md).

**Clarification:** Keep the game 2D. Model, rig, and animate the complete character in Blender, then render complete equipped sprites. Both prior cutout rigs remain rejected; runtime 3D battle scenes are not the chosen replacement.

## Visual target

An imposing ivory/navy armored knight. Match the small angular visor helmet with two slender crests, broad faceted pauldrons, layered breastplate over an exposed mechanical waist, substantial thigh/shin armor, human-like knees, and planted armored boots. Matte worn ivory dominates, restrained navy defines panels, and brass identifies joints/fittings. Wear must not overwhelm the silhouette at battle size.

The existing procedural study is an unapproved blockout. Complete the still-image comparison before animation production. Keep all sides derived from the same model, without arbitrary limb stretching or disconnected generated body pieces.

## Editable source structure

- Body: separate coherent armor shells and mechanical frame in consistent meter-based units.
- Rig: reusable anatomical/mechanical body and hand rig, stable pivots, named sides, and hand_r / hand_l attachments.
- Equipment_Sword: separate initial sword, attached through its grip.
- Equipment_Shield: separate initial kite shield, attached through its mount.
- Render_Setup: common orthographic camera, lights, scale, foot anchor, transparent stage, and fixed bounds.
- Heraldry export: occlusion-aware panel masks/UV data aligned to beauty frames for later common crest compositing.

Never join weapons or shields into body geometry. Keep attachment names, equipment IDs, transforms, and supported loadout IDs editable. Gameplay compatibility comes from campaign equipment definitions; the source sockets do not silently authorize every weapon combination.

## Review sequence

1. Large still and battle-size sample against the original.
2. Short normal-speed idle/walk/attack sample proving weight, grounded feet, stable equipment, and usable sprite sampling.
3. All six facings, ordinary/guarded hit, guard, and disabled presentation.
4. Starting loadout plus one separately reviewed alternate configuration.
5. In-engine visual playback and standalone export check.

View actual game-size motion, not only enlarged stills or a contact sheet. Functional rig tests do not establish art approval.

## Export and runtime

Render complete equipped characters in six tactical directions. Initial action sampling review range is 24–30 fps; preserve the starter action durations and impact timing separately from frame count. Export a manifest containing frame timing, facing, action/loadout IDs, anchors, bounds, and impact cues.

Pack atlases with alpha-edge padding and measure decoded memory. Do not render every theoretical inventory combination. Maintain an explicit supported-loadout registry and compatible animation set for each visible weapon class; module changes without exterior geometry can initially reuse the same rendered body.

Do not rebake the complete atlas for each banner design. Validate the separate heraldry masks/compositing before extending banners to animated armor panels.

The 2D renderer plays resolved model events without owning combat, rewards, saves, or campaign time. Existing Blender sources stay outside runtime imports; only approved sprite/metadata outputs enter the exported game.

Current work remains planning and source study until the visual gates pass. See [validation-review.md](../plan/validation-review.md) for unresolved production gates and measured full-army checks.
