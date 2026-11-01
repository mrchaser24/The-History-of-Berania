# Ivory Knight — Model Once, Render to 2D

**Updated:** November 1, 2026  
**Status:** User adopted 3D source model → 2D rendered sprites after rejecting both cutout assemblies. Previous functional QA does not constitute art approval.  
**Authoritative reference:** `assets/art/mechs/concepts/oathkeeper.png`  
**Persistent decisions:** `MEMORY.md`

## Goal and first delivery

Reproduce the approved ivory/navy knight as one coherent, carefully modeled and textured 3D source asset. Prove a matching still before expanding animation or replacing the current renderer. The first model is a visual study until compared and refined against the reference. Preserve rejected 2D studies as history, without representing them as approved final art.

**Source groundwork:** `assets/models/oathkeeper/oathkeeper-study.blend` and `tools/oathkeeper/build_model.py` now provide an editable blockout, packed original reference, material/camera setup and separate equipment attachments. Source checks verify independent body/equipment meshes and moving replacement gear through the other hand without changing the body. The model still needs a detailed visual pass; it is not an approved matching still, not animated and not integrated into the game. See the source directory's README for rebuilding and limitations.

The game, battlefield camera and tactical rules remain 2D. The 3D scene is an offline production source. This supersedes the older plan's restriction on animated 3D source assets; runtime 3D combat is not introduced.

## Model and interchangeable equipment

- Match silhouette, head-to-body ratio, shoulder mass, mechanical waist, substantial armored legs, grounded feet, armor layering, ivory/navy/brass materials and reference lighting.
- Keep body, sword, shield and future equipment separate. Provide `hand_r` and `hand_l` attachment points with explicit grip alignment and consistent model units. Start with sword/right hand and kite shield/left hand.
- Changing equipment must not remodel the torso/limbs, bake gear permanently into body geometry, or change the mech's identity.
- Reuse body animation; provide equipment-specific attack/hold variants when required. Shields are replaceable items, not permanently painted guard frames.
- First exports render complete equipped frames per supported loadout to preserve correct overlap. Keep source attachments editable for future equipment. One baked sheet does not support arbitrary weapon swaps.

## Production order

1. Build an editable Blender source model and a still beside the original reference. Inspect enlarged and battle-size silhouettes; refine the art before animation. Technical tests do not replace visual review.
2. Complete the reusable rig. Verify equipment removal/replacement without changing the body, grip scale or handedness. Gameplay inventory/equipment options remain a separate feature.
3. Animate idle, walk, sword attack, normal hit, guard entry/hold and guarded hit. Preserve starting-loadout timings: attack 0.75 seconds; impact 48%; travel 0.18 seconds per hex; guard entry 0.28 seconds.
4. Render six tactical directions from the same model, fixed elevated camera, lights, scale, frame bounds and foot anchor. Export transparent frames and pack atlases with animation/facing/loadout metadata.
5. Integrate rendered frames through the presentation registry, preserving captured guard state, selection bounds, speeds, reduced motion, markers, health labels and defeat fallback. Keep combat, saves, rewards and campaign time independent of playback.

## Acceptance

- Visual: faithful reference silhouette, proportions and materials; clean joints; human-like stance; readable at battle size; no arbitrary stretching or toy-like redesign.
- Equipment: body stays intact when gear is hidden or changed; both attachments retain correct grips, scale, orientation and handedness; rendered frames show the actual equipped items.
- Animation: grounded feet, clear attacks, distinct normal/guarded hits, safe pause/restart/speed/reduced-motion behavior; no extra damage/actions/rewards.
- Packaging: editable model, scripts and references stored locally; source assets excluded from game data; exported sprites included and checked in the PCK.

## Boundaries

Only Oathkeeper enters production now. Other approved concepts remain future work. This stage does not add equipment inventory/UI, new weapons' combat rules, body-part customization, save migrations, encounters or roster expansion. Retain the demo while the replacement model is proven. See `docs/mech-production-brief.md`.
