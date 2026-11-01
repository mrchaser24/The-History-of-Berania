# Ivory Knight — Model and Animate in 3D, Play in 2D

**Updated:** November 1, 2026

**Status:** The user clarified that the game should remain 2D, using coherent animated 3D source models to replace the rejected cutout presentation. Live runtime 3D battles are not the selected direction. The earlier model-once/render-to-sprites decision is retained and made more explicit.

**Authoritative visual reference:** assets/art/mechs/concepts/oathkeeper.png

**Persistent decisions:** [MEMORY.md](../MEMORY.md)

## Goal and approval sequence

Reproduce the original ivory/navy knight as one coherent modeled, textured, and rigged character. Good 3D source geometry alone does not establish beautiful motion: proportion, rig deformation, weight, grounded feet, timing, lighting, sprite sampling, and battle-size readability all need review.

1. Match a still render to the original, enlarged and at intended gameplay size.
2. Review a short animation loop at gameplay size before building the full set.
3. Review all six facings and the first supported loadouts.
4. Integrate the approved rendered asset into the existing 2D presentation.

Technical checks do not substitute for visual approval. Do not mass-produce animations from an unapproved blockout. Do not return to disconnected illustrated body parts stretched through a generic 2D skeleton.

## Existing source and implementation boundary

assets/models/oathkeeper/oathkeeper-study.blend and tools/oathkeeper/build_model.py provide an editable geometry/material study, packed reference, and separate equipment attachments. This is not an approved matching still, not a finished rig or animation set, and not integrated into the game. Preserve artist edits before rerunning the procedural builder.

Runtime remains Godot Node2D/CanvasItem-style 2D presentation. Blender models and rigs are offline sources. Source files stay excluded from the game; approved sprite atlases, metadata, and small presentation shaders are runtime assets.

The current demo continues to use its existing renderer until the replacement passes the visual and functional gates. This plan update does not modify models, generate animation, or replace that renderer.

## Model, rig, and interchangeable equipment

- Match the reference's silhouette, helmet, broad shoulders, layered armor, mechanical waist, substantial legs, grounded feet, ivory/navy/brass materials, and lighting.
- Keep body, sword, shield, and later equipment separate with consistent scale, anatomical naming, and stable hand_r / hand_l grip attachments.
- Use a reusable anatomical rig with properly pivoted mechanical joints. Armor must not stretch like rubber; limbs must not disconnect or change length between poses.
- Keep the starting sword/right and shield/left loadout editable. Body geometry and identity survive equipment removal and replacement.
- Future weapon classes can require their own hold, attack, recovery, and guard poses. Shield-dependent presentation must follow actual equipment and captured combat state.
- Render complete equipped characters from the 3D scene. The runtime swaps a supported complete loadout's animation set; it does not assemble cutout body parts or pretend an arbitrary weapon swap works inside a baked image.

## Animation and smoothness

Initial required states remain idle, walk, sword attack, ordinary hit, guard entry/hold, and guarded hit. Add a disabled presentation before persistent combat damage is integrated. Any new weapon class needs a reviewed compatible action set.

Preserve the current starter timing contract unless separately changed through combat review: attack 0.75 seconds, impact 48%, travel 0.18 seconds per hex, guard entry 0.28 seconds. Store timing independently of image count.

Use 24–30 sampled frames per second as the initial action-animation review range, then select the lowest sampling that passes normal-speed visual review at gameplay size. This is a production starting point, not a promise that a frame rate alone guarantees quality. Idle can use fewer frames if it remains smooth.

Walk loops need readable weight transfer, foot contacts, and stride matching the playback speed. Do not restart the cycle on every hex. Turning must not mirror asymmetric armor or teleport equipment; prototype rendered 60-degree transition clips where needed while retaining six legal game facings.

Use a consistent elevated orthographic camera, light rig, model scale, foot anchor, image bounds, and transparent background. Review enlarged loops and unzoomed battlefield captures; smooth playback must not blur targeting or silhouette.

Playback consumes already-resolved action records. Damage, rewards, AP, campaign turns, and facing legality do not come from animation callbacks. Pause, speed changes, Quick Resolve, reduced motion, interrupted clips, and missing-asset fallback must settle at the same authoritative final state.

## Sprite export and loadout budget

- Render six facings from the same source; do not generate disconnected directional illustrations.
- Export per-frame durations, foot/pivot anchor, bounds, facing, clip, loadout identity, and impact cue metadata.
- Pack lossless alpha atlases with padding/extrusion; review filtering, edge halos, mip/scale behavior, and texture limits in the target Godot build.
- Register supported chassis + weapons/shield + action-set combinations explicitly. Workshop UI exposes only combinations with a valid compatible presentation set.
- First prove Oathkeeper's starting loadout and one alternate equipment configuration. The alternate requires its own visual review; it is not automatic approval of another design.
- Render modules/refits that have no exterior geometry as internal/stat changes initially. Exterior changes require a registered visual variant.
- Prototype per-frame, occlusion-aware panel masks/UV data and shared crest compositing for heraldry. The banner's two colors and emblem must not require rebaking every animation. Keep complete body/equipment motion in the beauty render; the heraldry pass is a cosmetic surface treatment.
- Track directions × clips × visible loadouts × frames in a production manifest, together with atlas dimensions, decoded memory, disk size, and exported build residency. Six facings × six clip groups × two loadouts already means 72 directional clip groups before individual frames.
- Load only the deployed roster's needed sets for a battle; verify reserve machines do not make every atlas resident. Do not expand weapons or frames until measured memory, visual, and export gates pass.

## Acceptance and gates

- **Reference:** matching proportions/materials and readable silhouette against the original; no generic replacement accepted merely because it animates.
- **Motion:** planted feet, believable joints and weight, clean transitions, no equipment drift, correct ordinary/guarded reactions.
- **Equipment:** independent editable assets, stable grips, valid complete-loadout render sets, visible equipment matching equipped state.
- **Heraldry:** consistent crest placement/occlusion in every supported facing and clip while preserving Oathkeeper's appearance.
- **Playback:** unchanged outcomes across speed, skip, pause, and reduced-motion paths; missing clips release input locks safely.
- **Packaging:** source excluded; runtime atlases/metadata included; successful standalone export and launch with the selected Godot version.
- **Scale:** measure normal and worst-case 10-v-10 and 15-v-15 scenes before final roster/texture expansion. The current 8×8 battle board and 3-v-3 demo are not proof of full-scale readability, memory, or performance.

Only Oathkeeper enters detailed production now. Cinderjack, Kestrel, and Bastion remain approved future concepts. The same coherent-model approach is a proposed production default for later animated troops and horses; portraits, UI, and campaign art can stay authored 2D.

See [the production brief](../docs/mech-production-brief.md), [campaign systems](campaign-refinement.md), and [the validation review](validation-review.md).
