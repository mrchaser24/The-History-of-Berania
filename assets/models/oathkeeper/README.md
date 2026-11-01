# Oathkeeper editable source study

This is the first Blender geometry/material study for the newly adopted 3D-to-2D production pipeline. It is **not approved final artwork**, not fully rigged/animated, and not integrated into the game. Compare the silhouette and armor with the packed original reference before expanding production.

The first still remains a blockout with an initial panel/detail pass. It does not yet reproduce the original illustration's detailed armor construction, weathering, mechanical density or final surface finish. Those visual issues must be refined before animation; the structural equipment checks below do not establish art fidelity.

- `oathkeeper-study.blend`: editable model, packed approved reference, separate body and equipment collections, hand attachment empties, camera and studio lighting.
- `oathkeeper-model-study.png`: first still render, when rendering completes.
- `model-study.json`: source status and structural equipment checks.
- Builder: `tools/oathkeeper/build_model.py`, executed with Blender's Python.

From the project root on this Mac:

```sh
/Applications/Blender.app/Contents/MacOS/Blender --background --factory-startup --python tools/oathkeeper/build_model.py -- --quick
```

Omit `--quick` for the larger render; add `--no-render` to rebuild the editable source without rendering. Regeneration replaces this study and its render, so preserve artist edits in a separate version before rerunning.

## Equipment contract

`Equipment_Sword` and `Equipment_Shield` are separate mesh collections parented through `hand_r` and `hand_l`. The body is not joined to either item. Socket-local geometry supplies grip alignment; item identifiers and attachment names are stored as custom properties. Hiding the gear leaves the body intact. Future replacements attach through the same sockets and may need equipment-specific hold/attack poses. This source organization does not implement a gameplay inventory or arbitrary swapping inside baked sprite frames.

Both source attachments can accept a weapon or shield through the item's grip/mount offset. Their starting equipment does not establish permanent handedness restrictions. The builder verifies independent body/equipment mesh data and temporarily attaches a copied weapon part to the other hand to confirm that it follows the attachment without altering the body.

Body components are tagged with intended future rig bones. Full rigging and animation follow the still-image visual review. `assets/models/.gdignore` and export exclusions keep these offline production assets out of Godot's resource imports and game data.
