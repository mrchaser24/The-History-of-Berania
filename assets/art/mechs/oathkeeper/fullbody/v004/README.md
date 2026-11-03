# Oathkeeper v004 — walk and sword-attack revision

The user accepts the v003 idle, guard, guarded-hit and ordinary-hit animation and rejects its walk and attack. This version replaces only those two actions. All 48 accepted source drawings, their complete-cell RGBA pixels, frame coordinates, anchors and timing are unchanged. Held guard and guard exit retain their exact references to those accepted cells.

[One transparent sprite sheet](oathkeeper-illustrated-actions.png) · [Runtime metadata](manifest.json) · [Refinement prompts](source/refinement-prompts.json)

The sheet is **3840 × 3520**, with **80 unique whole-character drawings**: 48 accepted poses, 12 new walk poses and 20 new attack poses. Normal cells remain 384px square. Four overhead sword poses use 384 × 448 cells in the last strip so that the full sword fits without shrinking the character. All frames retain at least 20px transparent padding. Runtime uses the per-frame rectangles and anchors from the manifest, including the taller cells. Decoded RGBA size is approximately 51.6 MiB without mipmaps; physical phone memory/performance remain unmeasured.

Walking now alternates supporting legs, includes both passing poses and is registered against the torso and a common row ground line. The cycle is 0.96s; distance-based phase and the existing movement rules are unchanged. Earlier text-only, guide and profile candidates repeated the leading leg and were discarded. They are source history, never runtime art. The selected walk comes only from `walk-opposite.png`, `walk-return-padded.png` and `walk-inbetweens.png`. The earlier clipped `walk-return.png` is a reference for refinement, not a packed source.

The attack uses a planted windup, an overhead sword arc, a downward strike and a gradual recovery. Its 20 unique poses produce 21 ordered samples: the vertical sword pose is revisited on the forward swing. The action remains 0.75s and impact remains at exactly 48% / 0.36s. Ready endpoints reuse the original accepted idle pose. Selected sources are `attack_a.png` through `attack_d.png` and `attack-inbetweens.png`.

All new artwork was drawn using the **built-in image_gen tool**, with the imagegen skill. No paid API, CLI, subscription, new dependency, 3D model rendering, body-part segmentation or cutout rig was used. The fixed sword and shield remain painted into every complete character; right-facing playback mirrors the whole image. The registered original drawings remain under ignored `source/`; registration selects whole connected silhouettes and uniformly resamples complete characters only.

`source/refinement-prompts.json` preserves the exact targeted walk and sword-arc refinement prompts. The initial attack segment brief was: four ready-to-chamber drawings, four chamber-to-strike drawings, four follow-through/braking drawings and four recovery-to-ready drawings; steady planted boots, fixed gear, same three-quarter camera, complete 2D illustrated characters with transparent gutters. That brief is a normalized production record rather than a verbatim transcript of the initial generation prompts.

Reproduce registration with `python3 tools/oathkeeper/register_motion_revision.py`, then run `tools/oathkeeper/pack_motion_revision.gd` in headless Godot. The packer copies v003, replaces only motion cells, adds the overhead strip and asserts the accepted-cell SHA-256 hashes. Sources remain untouched. The model suite independently checks the authored PNG hashes and unchanged accepted-state metadata. Godot's imported texture fills invisible RGB at alpha borders, so authored hashes intentionally precede that processing.

[Walk, both facings](../../../../../../qa/2d-sprites/v004/walk.gif) · [Attack, both facings](../../../../../../qa/2d-sprites/v004/attack.gif) · [QA evidence](../../../../../../qa/2d-sprite-review-v004.md)

The two revised motions await the user's judgment. The four previously accepted actions remain accepted; this does not imply approval of the full roster.
