# Berania — Campaign Function Contracts

**Updated:** November 3, 2026. Implement with [the main roadmap](initial-plan.md) and [story canon](story-canon.md). This document specifies behavior, not a separate production or QA backlog.

## World and time

Campaign travel and battles use hex rules on painted 2D maps with grid outlines hidden by default. Start from the existing three travel points and two-hex vision radius. Discovered geography persists; unseen live party positions are not disclosed. Roads/plain terrain and rough terrain have explicit movement costs; longer orders stop at budget exhaustion or contact.

Only End Turn advances strategic time. NPC movement, arrivals, incidents, trade transactions and sieges resolve once in a stable order and commit together. Menus, dialogue and tactical rounds do not age deadlines. Newly announced threats allow a response; party contacts reserve their participants before another job can move or pay them.

A party has an ID, owner, position, strength, destination and one job. Keep a bounded set of active caravans, patrols, bandits, envoys and war parties. Off-player skirmishes use bounded strength/loss rules and visible reports, not full tactical simulations. Main-story outcomes remain authored.

## Headquarters and identity

The required chapter path is village defense, bandit camp, then an explicit headquarters claim. Default claim requirements are camp cleared and trust at least 3. Village defense supplies the first trust and the required camp supplies the remainder, so optional work is never mandatory.

Headquarters opens real campaign warband naming, a banner with two colors and one centered original emblem, party/roster management, reserve access and a formal soldier award/recruitment source. The player may continue regional work afterwards. Cosmetic banner changes do not alter inherited identity, diplomacy, territorial ownership or recognition.

## Frames, pilots and troops

Each mech has a fixed complete design and permanent weapons. A frame instance stores identity, condition, refits, modules and optional pilot assignment. Module equipment has exactly one storage/fitting location. Friendly workshops share reserves; trade cargo is physically carried and does not teleport between caravans.

Buy/receive, retain, store, rename, repair, refit and sell frames. Two internal module slots support armor, movement, focus or utility choices without repainting parts or swapping weapons. At least one option changes a tactical choice. Protect the last usable required machine and retain free essential recovery.

The protagonist, restored princess and up to five companions are personal mech pilots. Each deployed pilot needs a distinct available frame. Early companion arcs include an affordable usable or loaned machine; recruitment never silently creates an extra mech. Pilot XP stays with pilots, refits/condition with frames and formation XP with formations. Early injuries/disablement are recoverable. Named story deaths remain authored.

Ordinary formations render four soldiers, mage circles five mages, cannon one gun plus two crew, and mechs one complete machine. Visible figures are not separate command slots. Preserve surviving strength and allow replenishment. Expand the ten core roles through reusable definitions rather than additional combat systems.

## Inventory, loot and trade

Keep garage, internal upgrades, carried goods and protected quest items distinct. Provide ownership/equipped status, categories, comparisons and prices. Frames and internal reserves do not consume cargo capacity.

Battle/quest loot is authored and claimable once; the player can take or leave items and handle overflow explicitly. Not every defeated mech becomes an intact owned machine. Required quest items cannot be sold.

A merchant route records terms, endpoints, goods, dispatch funding, current cargo, party identity and claims. Resolve delivery only on arrival, interruption on ambush and loss/recovery through the encounter outcome. A stationary NPC caravan marker is not this completed route function. Rescue is optional and still available after the camp is cleared through a bounded authored encounter.

## Command and combat

The [battle phase plan](battle-phases.md) governs movement, Guard, confirmation, counterattack and contested capture rules. Targeted Godot exercises passed on November 4; full campaign and device coverage remains outstanding.

Ten commandable units per side in ordinary battles, fifteen in major battles and sieges. Count every allied formation, mech, cannon, settlement defender and personal pilot within the same side cap. Reserve machines consume no deployed slot. No mid-battle additions bypass the cap.

Use the existing deterministic combat/cover/facing/cohesion framework, selected deployment and result application, adapted to the agreed battle phases. Normal, Fast, Quick and reduced motion change presentation rather than damage or rewards. Fixed sword action remains 0.75 seconds with impact at 48%.

Preparation snapshots select pilot/frame/formation instances before battle; workshop edits cannot mutate an ongoing encounter. Victory/defeat updates those same instances and claims its reward once. Defeat cannot remove the free required recovery route.

## Houses, diplomacy and settlement control

Begin with the canon 22 seats: ten independent competing breakaway houses and twelve loyalists, including the stolen Valcrest seat and the three bargain-makers. The imperial family is separate; the dead archduke is not a twenty-third seat.

House identity, ruler fate, faction membership, opinion, diplomatic stance, domain ownership and sovereign recognition are separate fields. Noble allies supply strategic support; prisoners do not automatically become personal pilots.

Use portrait/crest/name dialogue, two to four replies and an explicit terms panel. Offers are deterministic from displayed requirements. Repeated unchanged offers do not farm opinion. Recheck costs/authority/prerequisites at commitment and persist terms and payments together. Acceptance is never automatic through dialogue skip.

Support access, recruitment, funding, trade, non-aggression, peace/truce and bounded military obligations. Explain breaches and announced war changes. Custody supports release/ransom/submission and authored succession; execution consequences must be explicit wherever that option exists.

Start conquest with one reusable fort/siege flow, then connect domains, garrisons, simple taxes and administrator assignment. Preserve one player army and bounded NPC war activity. No elaborate building or production-chain simulation is required.

## Required story and victory

The old emperor's crimes must be revealed through a required investigation before the three-house bargain. Optional companions cannot supply the only required evidence or gate the rescue.

Rejecting the offer leads to its elite force and midpoint prison raid; rescuing the princess does not itself take the capital. Accepting atomically locks the permanent dominion route and claims four veteran formations, one advanced unassigned frame and a fixed gold grant once. Later sponsor betrayal cannot undo the branch or repeat the grant.

Successors/envoys preserve required bargain scenes if rulers are dead, captured or displaced. Off-screen wars and an early capital approach cannot consume or bypass investigation, branch, rescue, independent escape or final throne events.

The princess leads politically and may pilot an assigned frame after restoration rescue. On dominion she independently escapes with an established ally and survives in exile. Both routes settle the civil war through explicit recognition; alliances and ownership alone do not count. Coalition settlements can avoid 22 repetitive sieges.

Lucien refuses surrender and dies fighting. Commit the canon restoration or dominion ending with the recognition settlement so an unseen later world tick cannot undo it. Keep the two main routes and bounded epilogues rather than adding a hidden morality ending.

## Persistence

Schema 4 extends the prior schema-3 baseline, conservatively migrating schemas 1/2/3 without replaying paid rewards. Preserve earned resources and the owned starter condition. Default new fields conservatively; do not create unearned headquarters, branch rewards or companion machines in an existing save.

Use stable instance IDs, protected one-time claims, complete transactions, last-good backups and battle-boundary checkpoints. Runtime validation remains part of save/inventory functionality. The user authorized targeted Godot exercises of the current changes on November 4.

## Implementation reference

The bounded source implementation is documented in [implementation-state.md](implementation-state.md). Reusable domain/mission details, balance values, generic ruler names and the optional service-frame loans are authored defaults. Oathkeeper alone retains the existing detailed action art; other frame roles use supporting symbols. Targeted Godot exercises ran on November 4; no new package was built.
