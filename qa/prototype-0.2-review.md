# Prototype 0.2 — Workshop review

**Date:** November 1, 2026  
**Purpose:** A bounded playable preparation prototype for user review, alongside the existing Greyford prologue.

## What is implemented

- Revised four-memory opening: the prince was a childhood friend; he claims the coup was necessary and falsely accuses the protagonist's family. His mother's persecution remains a later revelation.
- Title-screen Workshop review with a separate persistent save, 180 initial review gold, repaired Oathkeeper, and headquarters access for trying the banner.
- Owned frame instances with stable IDs, shared reserves, pilot assignment, rename, purchase, reserve sale, repair, and two hull-refit levels.
- Two module slots with plating/actuator tradeoffs, unique physical ownership, removal to storage, and prevention of double-fitting.
- Grain/ore buying and selling with a 20-good cargo limit.
- Warband naming, two preset colors, one centered sun/sword/tower emblem, and saved crest preview.
- Practice battle using the piloted frame's fitted stats, returning to the workshop after results or through Pause → Return to workshop. Practice does not damage or reward either save.
- Campaign workshop at Greyford after the village defense. It spends actual campaign gold; banner founding stays locked until the later headquarters milestone.
- Schema-1 to schema-2 migration preserving gold, campaign progress, and starting hull condition. Nested numeric inventory fields normalize after JSON load.
- Transaction validation and rollback when saving an order fails.
- Separate Art review comparing the approved concept with the existing unapproved Blender study.

## What to review

Open the project in Godot 4.7.2 and run it. Choose Workshop review on the title screen.

1. Buy a reserve frame for 90 gold and plating for 12.
2. Select frames, assign the pilot, and check that the old frame and its fittings remain owned.
3. Fit plating to Oathkeeper: armor becomes 3 and movement becomes 2.
4. Refits raise maximum hull without healing current damage; repairs are separate.
5. Trade goods, fill the hold, and verify an overflowing or unaffordable purchase leaves the state unchanged.
6. Create a two-color banner and reopen the review to verify persistence.
7. Use Try this loadout for a battle; leave through Pause and verify the workshop state is unchanged.
8. Inspect Art review before approving further model or animation work.
9. Reset review to restore its starting resources; this does not reset the real campaign.

## Verification

Automated suites pass: 582 model/combat/save/art-contract checks, 36 existing application-flow checks, and 45 new workshop checks, totaling 663. New coverage includes legacy migration, exact nested save round trips, duplicate/dangling IDs, capacity, purchases, module ownership, save-failure rollback, visible layout dimensions, all tabs, review isolation, practice results/exit, review reset, and earned campaign access.

Native Computer inspection verified title entry, full-width workshop layout, buying a frame/module, fitting armor and its resulting stats, persistence across restart, live color/emblem/name changes and banner save, and use of the fitted armor/movement values in battle. User review is still the art/usability approval gate.

The data PCK is rebuilt and smoke-tested with the matching engine. This is not a standalone macOS application; export templates/signing/distribution are still open work.

The sandboxed engine emits pre-existing macOS CA-certificate diagnostics. Headless editor/export also reports restricted C# IDE-listener/editor-settings access; no gameplay script errors or workshop layout warnings remain in the final test suites.

## Limits

This is a partial M3 preparation proof plus an isolated preview of the later banner milestone, not completion of M3/M5 or the full campaign. The real prologue still starts alone and penniless, with no headquarters or reserve frames.

Only one knight-pattern visual chassis and the original sword/shield equipment set are supported. Purchased reserve instances use that same approved chassis concept. New weapon classes, companion recruitment, caravan simulation, political support, 10/15-unit encounters, the permanent story branch, and endings remain roadmap work.

The battle renderer remains the rejected legacy cutout prototype. It is labeled as a legacy study in the gallery. No new rig, animation set, or art approval is claimed. The unapproved 3D study is presented for comparison, not substituted for the original reference.

Runtime review images are exact copies of the approved concept and existing model-study render. Blender sources and full concept/source directories remain excluded from runtime exports. No source models or artist edits were regenerated.
