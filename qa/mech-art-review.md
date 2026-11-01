# Oathkeeper single-atlas verification

**Historical status:** The user subsequently rejected this cutout result as well. These checks document functional behavior only. Current art production uses one faithful Blender source model rendered into 2D sprites; see `MEMORY.md` and `plan/mech-art-direction.md`. This report must not be treated as approval of the cutout artwork.

**Reviewed:** November 1, 2026  
**Engine:** Godot 4.7.2, GL Compatibility, Apple M4

## Delivered

- One runtime texture, `assets/art/mechs/oathkeeper/parts-v2.png`, revised as a coherent rotation/cutout atlas in one built-in imagegen call using the original complete knight as art authority. Six views of main armor parts share one limb inventory. Earlier atlas and directional generations are source studies only, excluded from imports and the PCK.
- Six articulated states: idle, walking, sword attack, ordinary hit, guard entry/hold, guarded hit. Only Oathkeeper receives the new rig; the other approved concepts are preserved for later work.
- Isolated gallery accessible through **Mech animations** on the title screen. Includes all-six-facing comparison, detail and gameplay scales, pause, speed, reduced motion and restart controls. No campaign save access.
- Existing combat values, action durations, guard mitigation and save schema preserved. Attack records now capture `guarded`; renderer consumes presentation context and registered art bounds.

## Evidence

- Model/persistence/animation suite: **582 checks, zero failures**. Includes solid foreground registration despite faint margins and isolated opaque specks, nonempty atlas regions, shared inventory reuse, all states/facings at five points, finite joints, no model mutation, planted-foot compensation, ordinary/guarded melee and ranged damage, impact timing, lethal guarded hits, guard expiration, and guarded-hit playback at every speed/reduced-motion setting, with pause and restart.
- Application-flow suite: **36 checks, zero failures**. Full prologue/travel/battle/reward/recovery flow, new helmet selection bound and walking path-segment orientation pass. Deterministic battle remains a round-4 victory.
- Native OpenGL gallery rendered and inspected at detail and actual battle scales. Six-facing comparison rendered from the single atlas. Captures: `mech-animation-preview.png` and `mech-rotation-preview.png`.
- All six states rendered inside the actual practice battle; `mech-battle-preview.png` captures a guarded hit with actual hull loss (28/30 after damage of two). Existing infantry and Cinderjack render through their original paths.
- Fresh `builds/BeraniaDemo.pck` exported. Export manifest includes the master atlas and rig, and excludes concepts/source studies. Both headless preview smoke and native six-facing capture from the PCK completed without script/resource errors.

## Limits and environment notes

The user rejected the original assembled rig's thin limbs and horse-like stance despite passing functional checks. The visual revision replaces the source atlas, uses solid-component registration, trims duplicate segment stubs, restores upright proportions and armor mass, and adds a continuous mechanical waist. `mech-reference-comparison.png` compares the original concept with the revised rig. The gallery now uses a neutral review surface. The functional test count is not a claim of user acceptance or an exact pixel match to the concept.

The atlas supplies six discrete tactical views, not a 3D model or arbitrary-angle turntable. Limb motion is interpolated; changing a tactical facing selects another view inside the same atlas. Final image-generated armor details still warrant artistic review if stricter turnaround accuracy is required. Runtime animation does not synthesize new perspectives.

The sandboxed Godot Mono editor emits unrelated certificate, IDE socket and editor-settings permission messages during import/export. Rendered checks ran outside the sandbox with authorization; gameplay/model suites and packaged-resource loading passed. Export remains a data PCK requiring the matching engine, not a signed standalone app. Broader performance and external-player gates from the project QA remain open.
