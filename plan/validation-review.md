# Berania — Plan validation review

**Reviewed:** November 1, 2026

**Baseline:** Roadmap 1.8, story canon 2, campaign systems 1, current Godot demo, mech source study, and the user's art clarification.

**Result:** The main requested story, campaign, banner, garage, inventory, and battle-size features are represented. The plan needed stronger production and edge-case contracts. Corrections below are documentation changes; they do not prove balance, finished art, successful animation, or full-campaign feasibility.

## User's clarified visual intent

Keep the game 2D. Use complete, coherently rigged and animated 3D source models to produce its sprites. The rejected cutout-body presentation does not meet the target. Live 3D gameplay is not selected.

The source method was already present in memory, but the roadmap still allowed generic layered-body animation and did not sufficiently describe sampling, equipment variants, or heraldry. The revised art direction now specifies the review sequence, complete-loadout rendering, timing/metadata, and measured asset budget.

## Findings and dispositions

| Priority | Gap or contradiction | Disposition |
| --- | --- | --- |
| P1 | Source-model quality was being conflated with finished smooth animation | Added still → motion → six-facing/loadout → in-engine/export gates. The current study remains unapproved. |
| P1 | Arbitrary gear combinations conflict with complete rendered sprites | Require an explicit supported-loadout registry; prove the starter and one alternate before expanding. Workshop availability follows render/animation support. |
| P1 | Custom banners could multiply every sprite/loadout variant | Add a separate occlusion-aware panel-mask/UV heraldry proof. Emblems/colors share a compositor rather than rebaking every body animation. |
| P1 | The new owned-mech migration contradicted the roadmap's earlier migration deferral | Require versioned migration when the new save schema is introduced; preserve legacy progress and current starter condition. |
| P1 | Optional companion pilots lacked a guaranteed affordable path to deployable frames | Pair the first two companion arcs with usable loaned/awarded frames or a validated guaranteed acquisition path. Recruitment alone does not manufacture a mech. |
| P1 | Defeat policy did not specify new owned-frame/hero consequences | Adopt recoverable hero injuries and disabled frames in the initial ownership version; prohibit permanent loss of the only required machine. Ordinary formation strength persists with replenishment rules. |
| P1 | Dynamic conquest/custody could remove required bargain-makers, rescue access, or the final antagonist | Add authored successors/envoys, protected story-event resolution, and route-aware variants. No optional or off-screen action may silently delete a main route. |
| P1 | All-house recognition could become an endless conquest/defection grind | Track explicit recognition separately from friendship, peace, and ownership; support treaty/coalition settlements and check the ending on a committed snapshot. |
| P2 | 10/15 command limits were not validated against the current 8×8 board or allied participants | Size future encounter maps for deployment and maneuvering, share the cap across all friendly participants, and test 10-v-10/15-v-15. |
| P2 | Cover and mage circles were requested but lacked adopted final combat rules | Keep the demo rules; require a small combined-arms rules sheet and counter-role test before either mechanic enters production battles. |
| P2 | Shared workshop access and carried cargo could be interpreted as remote cargo teleportation | Separate abstract shared reserves from physical carried trade cargo; buying/fitting still needs a friendly workshop. |
| P2 | Pilot experience and permanent frame progression were not distinguished | Pilot skills/XP stay with pilots; hull condition/refits/fittings stay with frames; troop experience stays with formations. First abilities remain a combat-sheet task. |
| P2 | Unlimited storage could be mistaken for unlimited field strength or preload residency | Separate ownership, roster, deployment, cargo, and loaded-asset budgets. Reserve frames consume no deployment or residency by default. |
| P2 | Current source, sprite references, and content counts were not a measured production estimate | Add a variant/frame/texture manifest and staffing/asset-cost estimate before larger armies or more frames. |
| P2 | Story facts and authored additions could be mistaken for approved dialogue/art | Preserve explicit draft labels for names, biographies, scene mechanics, and unapproved visuals. |
| Existing gate | Standalone export, measured performance, and unfamiliar-player evidence remain incomplete | Retain them as open milestone gates; historical QA counts do not close them or validate the new systems. |

P1 means resolve before the affected system is integrated. P2 means resolve before expanding that subsystem. This review does not assert these are discovered runtime defects.

## Coverage audit

| Requested capability | Current planning location | State |
| --- | --- | --- |
| Childhood promise, coup, father's sacrifice, solo fugitive opening | story-canon.md | Established; current opening has earlier wording to align later |
| Prince's grievance, mistaken accusation, imprisonment motive, throne dependence | story-canon.md | Established plot; detailed scenes still to write |
| Ten breakaway factions and twelve loyalist seats | story-canon.md | 22-house draft register present |
| Three-house permanent bargain and midpoint rescue | story-canon.md; campaign-refinement.md | Established; variant/failure scenarios required |
| Princess's political agency, pilot role, or independent escape/exile | story-canon.md | Established route outcomes |
| Two major endings and whole-war settlement | story-canon.md | Established; recognition implementation required |
| Fogged turn-based world, roaming parties, caravan/village aid | initial-plan.md | Small demo slice; full jobs/events staged |
| Trade, diplomacy, war, siege, taxes/garrisons | initial-plan.md; campaign-refinement.md | Staged regional proof before full simulation |
| Personal banner | campaign-refinement.md | Two colors/one emblem; headquarters founding default |
| Owned/swappable/upgradable mechs | campaign-refinement.md | Shared workshop garage; fitted equipment/modules |
| Party gear, loot, cargo, protected quest items | campaign-refinement.md | Scope chosen; transactions and migration required |
| Personal mech pilots and campaign-support nobles | story-canon.md; campaign-refinement.md | Distinct roles; up to five companions |
| 10-unit ordinary / 15-unit major hex battles | campaign-refinement.md | Final ceilings selected; larger boards/content unproven |
| Faithful art and smooth motion | mech-art-direction.md | 3D sources → rendered 2D; visual/memory/export gates open |

## Open work before implementation or expansion

These are necessary specification or evidence tasks, not invitations to reopen settled user choices.

- **Combat sheet:** Define the first cover rule, mage role/ability/counter, weapon-class guards, existing deterministic damage interaction, and casualty/replenishment values before adding those mechanics. Avoid a new resource meter without a demonstrated need.
- **Economy sheet:** Price the first usable companion frames, repairs, fittings, recruitment, cargo, and rewards. Demonstrate required-path success, defeat recovery, and zero-gold recovery. Cap exploit-prone emergency rewards.
- **Story state graph:** Define required evidence, bargain eligibility, accept/refuse commitment, rescue/exile events, capital access, throne confrontation, successor/envoy fallbacks, and recognition. No secret romance/morality meter changes the main fork.
- **Full-army deployment:** Prove spawn capacity, maneuvering room, camera framing, targeting, objective access, friendly participant caps, and absence of reinforcement bypasses on major maps.
- **Art proof:** Finish Oathkeeper's faithful still; review animation at game size; validate two loadouts and banner masks before producing more frames or weapons.
- **Asset budget:** Record render sampling, six facings, clip/loadout counts, texture dimensions, decoded memory, load times, and reserve/deployed residency on the reference machine.
- **Build and usability:** Verify a standalone exported build, supported display sizes, performance, readable previews/controls, and unfamiliar-player understanding. Existing in-editor or headless checks alone do not establish these.
- **Production estimate:** Record development capacity and measure one complete asset/encounter before committing dates or building all 22 domains.

## Verification performed for this documentation pass

Read the actual project configuration and combat/campaign models. The current project uses a 2D main scene, Compatibility renderer, an 8×8 tactical board, six prototype combat units, and a schema-1 single-mech save snapshot. The source model README identifies an unapproved study with no finished rig or integration.

Local document links/headings, the 22-house ten/twelve split, the ten-slot example, revision markers, and removal of contradictory migration/cutout guidance passed document checks. Tracked plan changes passed git diff --check. Existing code, source models, player saves, QA artifacts, and user changes were preserved.

The audit is a design/consistency review. Runtime tests and new art generation are not required for these documentation-only edits and are not represented as having been run.


## Implementation follow-up — November 2, 2026

Prototype 0.3 supplies the bounded regional loop, a concrete cover/mage/guard/casualty rules sheet, shared 10/15 deployment with larger maps, locked owned-frame setup, persistent troop strength and versioned schema-3 migration. It has automated cap/layout/AI and native UI evidence; see `qa/prototype-0.3-review.md`. This narrows those audit gaps without closing final art/motion approval, rendered memory/performance, human playtest, companion acquisition, dynamic house/story continuity, recognition endings or standalone distribution gates.
