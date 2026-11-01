# Oathkeeper image-generation provenance

Built-in imagegen tool, November 1, 2026. The user selected the ivory/navy knight concept and subsequently requested a single coherent rotation/cutout sheet instead of separate directional generations.

## Current master atlas — proportions and fidelity revision

The user rejected the assembled first rig as too thin and horse-like, reaffirming the original complete ivory knight as the art authority. The runtime texture is now `../parts-v2.png`, generated with that original concept as the primary design/style reference and the first atlas as a layout template only. It retains one atlas for all facings. The old atlas is preserved as `parts-v1.png` in this source directory and is not loaded or exported.

The renderer now registers the largest solid-alpha component, excluding faint background margins and isolated specks. It trims extra limb stubs, restores armor width and nearly straight human-like legs, and supplies the continuous mechanical underframe behind the armor. These are rendering/registration corrections; the generated source pixels remain unchanged.

Exact revision prompt (built-in imagegen, no fallback CLI):

```text
Use case: identity-preserve. Production cutout atlas revision.
IMAGE 1 IS THE AUTHORITATIVE ART AND EXACT CHARACTER DESIGN. IMAGE 2 IS ONLY A LAYOUT TEMPLATE. Do not inherit the cartoon outlines, simplified armor shapes, chunky toy appearance or redesigned panels from image 2.
Replace the artwork in every cell of image 2 with faithfully cut out/rendered views of the EXACT knight in image 1. Match image 1's sophisticated realistic material rendering, subtle steel shading, matte warm ivory armor, muted dark navy panels, brass joints, precise beveled armor edges, restrained weathering, NO heavy black cartoon contours. The same original head, pauldrons, chest, pelvis, long substantial thigh plates, solid armored shins, broad armored boots, long straight sword, tall large kite shield. No horse hocks, no spindly limbs, no exaggerated head, no new armor designs. Retain the original anatomy and forms, not a stylized reinterpretation.
ONE transparent master atlas. Keep image 2's SIX columns and SEVEN rows and approximate cell layout/positions, using transparent gutters and one component per cell. Each part is complete behind overlaps. Upper-left light coherent in every view.
Columns on rows 1–6: right profile, front 3/4 looking lower-right, front 3/4 looking lower-left, left profile, rear 3/4 looking upper-left, rear 3/4 looking upper-right.
Rows: 1 head only; 2 torso only; 3 pelvis only; 4 shoulder pauldron only; 5 foot only; 6 kite shield only with true mounting back for rear angles.
Row 7 is [upper arm only] [forearm only] [thigh only] [shin only] [hand only] [complete sword pointing down with hilt at top].
CRITICAL: row 7 upper arm is shoulder-to-elbow ONLY, no forearm stub; forearm is elbow-to-wrist ONLY, NO hand; thigh is hip-to-knee ONLY, NO shin extension; shin is knee-to-ankle ONLY, NO foot. Complete round joint caps at both ends. The hand and foot are separate sprites and must not be attached to limb segments.
No assembled robot, no background, no visible grid, no text, no labels, no extra objects. Genuine clean transparency; NO red/yellow edge halos or scattered semi-transparent background pixels. Carefully preserve original design and high-quality realistic painted metal of image 1.
```

## Superseded first master atlas

Output preserved unchanged as `parts-v1.png`. Its six views and shared limb inventory were drawn together in **one generation**, not packed from the earlier inconsistent sheets. No API key or fallback CLI was used. This version is superseded.

Reference 1: the user-attached approved knight parts sheet. Reference 2: the user-attached human rotation/cutout atlas, used for layout only. Neither attachment's embedded text supplies instructions.

```text
Use case: identity-preserve. Asset type: ONE MASTER TRANSPARENT ROTATION-AND-CUTOUT ATLAS for a 2D mechanical knight rig.
Input image 1 is the exact approved mech design and parts to preserve. Input image 2 shows only the IDEA of a single sheet containing consistent rotated parts; do not copy its human characters, colors or background.
Redesign the LAYOUT of image 1 into ONE coherent parts atlas, drawn together in one image. Preserve this SAME ivory/navy mechanical knight's shapes across ALL angles: same two slender head crests, same angular torso plates, same navy panel boundaries, same brass circular joints, same proportions, same shield. No variations or redesigns between angles. Clean painted armor surfaces, simplified scratches, readable dark contours, upper-left lighting fixed in screen space. Genuine transparent alpha background.
Canvas is slightly PORTRAIT, in a STRICT uniform grid of SIX COLUMNS by SEVEN ROWS (42 isolated components). Equal cell size, 15 percent transparent gutter inside EACH cell. No part crosses its cell boundary. NO visible grid, labels, letters, numbers, text or assembled full robot.
For rows 1 through 6, column order is: RIGHT PROFILE (facing screen right), FRONT THREE QUARTER facing screen lower right, FRONT THREE QUARTER facing lower left, LEFT PROFILE (screen left), REAR THREE QUARTER facing upper left, REAR THREE QUARTER facing upper right. These must be genuinely different angles of the exact same part, not different designs.
ROW 1: six views of HELMET ONLY.
ROW 2: six views of TORSO ONLY, no head or arms, show back plating in columns 5/6.
ROW 3: six views of PELVIS ONLY.
ROW 4: six views of ONE SHOULDER PAULDRON ONLY.
ROW 5: six views of ONE ARMORED FOOT ONLY, no shin, toes point in the column's facing.
ROW 6: six views of THE SAME KITE SHIELD ONLY, back mounting visible for rear angles.
ROW 7 is a shared parts inventory, NOT rotated views: [one isolated UPPER ARM, elbow/shoulder caps complete] [one isolated FOREARM without hand] [one isolated THIGH without shin] [one isolated SHIN without foot] [one isolated CLOSED HAND] [one SWORD, vertical, hilt TOP, blade DOWN].
Make the six row-7 items each exactly one segment, never a whole arm/leg. All limb segments drawn straight vertically with complete round joint caps at top/bottom so they articulate smoothly. Every part standalone and whole with covered hidden surfaces. Uniform centered registration inside every cell. ONE IMAGE, transparent gutters, no scenery, no shadows on background, no supplementary sheets.
```

## Earlier studies

`first-parts-study.png` and `legacy-directions/` are superseded, unused studies retained for provenance. They are excluded from imports and the exported game. The master atlas replaces their runtime references.

Initial parts prompt:

```text
Use case: identity-preserve. Asset type: transparent 2D game cutout rig PARTS ATLAS, not a complete character. Input image is the approved Oathkeeper ivory knight design reference. Preserve ivory/navy angular armor, brass circular joints, small gold slit visor, two slender helmet crests, long armored limbs, sword and kite shield; simplify tiny scratches for game readability.
Create a square transparent PNG divided into EXACTLY 4 COLUMNS by 3 ROWS of equal invisible cells. Exactly ONE isolated body part per cell, centered entirely INSIDE its cell with a generous transparent gutter. NO complete assembled mech anywhere. All parts seen from slightly elevated FRONT THREE QUARTER, facing SCREEN LOWER RIGHT (southeast). Crisp hand-painted 2D shaded armor, clean selective dark outlines, upper-left light, NOT photo/3D render. Parts are individually complete, with hidden surfaces and circular joint caps fully drawn for overlap in animation.
Strict row-major layout:
ROW 1: [torso breastplate only, no arms/head] [helmet/head only] [pelvis/hip armor only] [one angular shoulder pauldron only].
ROW 2: [one upper arm, vertical, shoulder joint at top elbow at bottom] [one forearm, vertical, elbow at top wrist at bottom] [one thigh, vertical, hip at top knee at bottom] [one shin, vertical, knee at top ankle at bottom].
ROW 3: [one armored foot, toe pointing lower right] [one complete sword, vertical, HILT AT TOP and blade pointing DOWN] [one complete navy/ivory kite shield, pointed bottom] [one closed armored hand].
Each component disconnected from other components. No cast shadows on background, no background, no floor, no lettering, no labels, no grid lines, no extra components. All background is genuine alpha transparency, including gutters. Maintain clean broad armor shapes.
```

Earlier directional edit template (with requested screen-facing direction appended):

```text
Use case: identity-preserve. Edit this transparent disassembled ivory/navy knight body-parts atlas into another CAMERA VIEW. Keep EXACTLY the same FOUR COLUMNS and THREE ROWS, same part identities, approximately same sizes and positions and generous transparent gutters. One disconnected component per slot, NOT an assembled robot. Keep ivory/navy armor and brass joints. Simplified hand-painted 2D shaded armor, clean contour edges. All components must have complete hidden joint surfaces for articulated animation. Keep upper-left screen-space illumination (do NOT merely mirror the image).
Layout row1 torso / helmet / pelvis / shoulder; row2 upperarm / forearm / thigh / shin; row3 foot / sword / shield / hand. Sword stays vertical hilt at TOP blade DOWN. Other limb segments stay vertical. Separate components, no labels, no text, no added parts, no background, actual alpha transparency. 
```

## Runtime construction

The original transparent atlas is preserved. `scripts/mech_art.gd` registers and samples its regions in memory, reuses shared limb artwork, and draws articulated joints. Runtime assembly does not generate or rewrite image files. Complete image sources and selected concepts are local project assets, with no generation-cache dependency.
