# Berania — Campaign, Banners, Mechs, and Inventory

**Revision:** 1 — November 1, 2026

**Status:** Adopted planning direction and implementation defaults, saved after the story/design interview. These systems are staged future work; the existing Greyford demo does not implement them.

Read [story-canon.md](story-canon.md) for plot authority, [initial-plan.md](initial-plan.md) for production milestones, and [mech-art-direction.md](mech-art-direction.md) for approved visual production. Later user instructions take priority.

## 1. Campaign and command

A turn-based hex campaign should feel alive through moving caravans, bandits, patrols, nobles, armies, and visible incidents. Preserve fog: live party positions require current visibility; discovered geography and explicitly marked reports can remain known.

Settlement actions depend on relations and ownership: enter, trade, recruit, obtain guild work, negotiate, besiege, station garrisons, and later appoint administrators and manage taxes. Build a bounded regional simulation before activating the full 22-house civil war.

Allied nobles provide campaign support through their houses and armies. Captured nobles remain prisoners until negotiated release, ransom, or allegiance. They do not join the player's personal pilot roster automatically.

The protagonist, rescued princess, and up to five companions are personal mech pilots. Companions are veteran pilots or mech owners; each requires an available assigned frame to deploy.

## 2. Simple banner creator

Founding the warband at the headquarters milestone introduces its name and personal crest.

- Choose two colors and one centered emblem from an original preset collection.
- Preview the result on a banner, party marker, and designated mech heraldry panel.
- Permit later cosmetic changes from headquarters.
- No layering, imported artwork, free placement, or banner combat bonuses in the first version.

Use the crest on the campaign party marker, troop standards, army and diplomacy interfaces, headquarters, player-controlled settlements, designated mech heraldry panels, and victory screens.

Keep the personal warband identity separate from inherited Valcrest heraldry and allied-house crests. Repainting does not change legal identity, diplomatic recognition, the imperial hunt, or settlement ownership. Retain the recognizable approved appearance of each mech, especially Oathkeeper's ivory/navy design.

Implementation default: original vector/code-native emblems and a common rendering component generate all crest uses from the same saved two-color/emblem definition.

## 3. Persistent mech ownership

Use an owned-machine model inspired by acquiring and outfitting ships: buy or receive a frame, retain it, improve its fittings, and keep it in reserve when another machine is deployed. The reference does not add naval gameplay.

The [official War Sails overview](https://www.taleworlds.com/en/Games/WarSails) describes acquiring vessels and upgrading equipment. Berania adapts that ownership pattern to mechs.

### Shared workshop garage

- Buy, receive, sell, rename, repair, store, and refit owned mech instances.
- Access the same reserve frames and armory at any friendly mech workshop.
- Assign one frame to one pilot; a pilot cannot operate multiple frames in the same deployment.
- Swapping Oathkeeper out stores it rather than destroying or overwriting it.
- Stored frames have no world-map marker and consume no deployment slot.
- Begin with only damaged Oathkeeper. Shared storage supplies no free collection or starting headquarters.
- There are no physical cache locations or reserve-frame transport logistics in this version.
- Reserve storage is the agreed meaning of hiding a mech; it adds no separate stealth or pursuit-disguise mechanic.

A veteran companion without a frame remains recruitable but cannot deploy until assigned an available machine. A gifted unassigned frame is an inventory asset, not a new pilot or automatic combat unit.

The three nobles' bargain awards four veteran troop formations, one advanced frame, and a fixed gold grant exactly once. On refusal, their officers field those four formations and the advanced frame with their own pilot.

### Fittings and upgrades

| Fitting | Initial rule |
| --- | --- |
| Two weapon mounts | Compatible weapons or weapon/shield; two-handed equipment occupies both mounts |
| Two module slots | Armor, mobility, magical-focus, or utility modules |
| Frame refits | Limited chassis improvements preserving the recognizable body and identity |

Each chassis defines compatibility. Preview resulting statistics, ability changes, costs, and conflicts before confirmation. Initial examples are heavier armor with reduced mobility, improved movement at the expense of another fitting, and magical focus instead of physical reinforcement.

At least one early option must change a tactical decision rather than merely raise damage. Keep Oathkeeper useful through upgrades; purchasing a new frame should offer a role choice, not automatically invalidate it.

Refit, equip, and change frames only at friendly workshops, outside battle. Initial purchases/refits cost gold and relevant workshop access, with no separate construction timer. Exact prices, refit tiers, and modifiers are balance data.

Keep permanent chassis refits, removable modules, weapons, shields, and current hull condition distinct. A module fitted to one frame cannot simultaneously remain available in reserve or on another frame.

### Art compatibility

Preserve the approved model-once/render-to-2D workflow. Weapons and shields remain separate source assets on stable attachment points. Modules and refits do not authorize replacing heads, torsos, arms, or legs or redesigning Oathkeeper.

Only advertise supported visible loadouts. Weapon classes may require different attack/hold animations and rendered combinations; one starting sword animation or baked atlas does not support arbitrary gear.

Oathkeeper remains first in production. Cinderjack, Kestrel, and Bastion are approved future concepts, not completed assets. Heraldry and upgrade visuals must pass the same reference/readability checks as other art changes.

## 4. Party inventory and trading

| Area | Contents and behavior |
| --- | --- |
| Garage | Frame instances, names, condition, permanent refits, fittings, and pilot assignments |
| Armory | Owned weapons, shields, modules, and equipped/stored status |
| Party cargo | Stackable trade goods with a carrying limit |
| Quest items | Protected story objects, separate from saleable goods |

Provide categories, sorting, comparisons, prices, and visible ownership/equipped status. Workshop reserves and armory equipment do not consume trade-cargo capacity.

Battles and quests offer authored gold, equipment, and goods. Specific encounters can award recovered frames; destroying every enemy mech does not yield an intact machine. The player can take or leave offered loot and sell retained assets at appropriate merchants. Handle cargo overflow explicitly without granting rewards twice.

Ordinary troops buy upgrades and advance as formations. Do not equip each soldier separately. Human helmets, boots, armor, and personal weapon slots are outside this version because the hero combat role is mech piloting.

Protect required quest items from sale. Prevent selling the last usable player mech unless the same transaction acquires a usable replacement. Preserve zero-gold recovery and a retryable required job; optional purchases cannot eliminate the campaign's recovery route.

Keep the existing distinction between settlement cargo trading and negotiated caravan trade routes. Shared workshop equipment access does not remotely move a caravan's cargo or bypass route funding, sight, interception, or delivery rules.

## 5. Tactical size and presentation

- Ordinary encounters allow up to ten commandable units per side.
- Major field battles and sieges allow up to fifteen per side.
- A formation, mech, or cannon occupies one slot and takes one activation.
- The protagonist's, princess's, and companions' machines all count within that limit.
- More deployed mechs leave fewer slots for ordinary formations.
- Opening encounters can remain much smaller; the current 3-v-3 demo and proposed six-entity chapter are staged slices, not the final ceiling.

The current tactical reference is Girls' Frontline 2: Exilium adapted to hexes and Berania's 2D combined-arms presentation. Prioritize cover, terrain, readable targeting, and distinct abilities while retaining established facing and cohesion where useful. Its [official game description](https://store.steampowered.com/app/3347400/GIRLS_FRONTLINE_2_EXILIUM/?curator_clanid=42560688&l=english) highlights cover, mechanisms, and terrain. This reference does not change runtime gameplay to 3D.

Recommended ten-unit example:

| Unit | Slots |
| --- | --- |
| Protagonist and two other mech pilots | 3 |
| Ten swordsmen | 1 |
| Ten pikemen | 1 |
| Two formations of ten gunners | 2 |
| Ten cavalry | 1 |
| One cannon | 1 |
| Five-mage circle | 1 |
| **Total** | **10** |

This is an example composition, not a required army. Five companions is the campaign maximum, not five mandatory deployments in every encounter.

## 6. Delivery and persistence

Retain the existing milestone gates and current visual-production task. Within the appropriate later milestones, build in this dependency order:

1. Owned frame/equipment instances, shared workshop transactions, pilot assignment, and save migration.
2. Supported weapon/shield fitting, repairs, a small module selection, and frame refits.
3. Cargo trading and battle-loot integration.
4. Headquarters founding and simple banner creation.
5. Additional approved frames, companion pilots, and larger battle tests.
6. Expanded politics, the required investigation, permanent branch, and full civil-war campaign.

M3 proves the ownership/preparation loop with a small asset set. M5 stages the banner and two optional companion pilots. The full five-companion roster, multiple advanced frames, ten/fifteen-unit content, and two-ending campaign remain expansion work.

### Data and interfaces

Separate immutable definitions from owned instances:

- Banner definition: two colors and preset emblem ID; warband name belongs to the faction identity.
- Frame instance: stable ID, chassis definition, chosen name, current condition, permanent refits, installed equipment references, and optional pilot assignment.
- Equipment instance: stable ID, definition, upgrade state, and exactly one storage/fitting location.
- Cargo: good IDs, stack quantities, and capacity accounting; quest inventory remains protected.
- Campaign: ownership, workshop availability, claimed rewards, noble support/custody, and explicit permanent story-route selection.

Battle setup consumes a validated deployment snapshot of selected pilots, frames, and formations. Workshop edits do not mutate an encounter in progress. Battle results update the same owned instances once through shared campaign transactions.

The demo currently uses schema 1 with a single mech-health value. Introduce a versioned migration when these systems are implemented: turn the existing starter into one Oathkeeper instance preserving its health, gold, and progress; add empty reserves and an uncreated/default banner state. Do not alter current runtime saves merely by updating this plan.

## 7. Acceptance scenarios

- New game begins alone, penniless, with only damaged Oathkeeper.
- Bought, gifted, fitted, stored, and sold assets cannot duplicate ownership or pilot assignment.
- Failed purchases and incompatible fittings leave gold and inventory unchanged.
- Two-handed gear reserves both mounts; removed equipment returns to one valid storage location.
- The same reserves are accessible at different friendly workshops; none can be fitted during battle.
- Stored/unassigned frames consume no tactical slots; deployment respects ten/fifteen-unit limits.
- Save/load and legacy migration preserve progress, frame condition, refits, equipment, pilots, cargo, crest, and branch.
- Loot overflow, replayed battle results, grant delivery, and interrupted purchases cannot double-pay.
- Cargo limits, protected quest items, last-frame sale protection, and zero-gold recovery remain usable.
- Banner edits propagate consistently without changing house identity, recognition, ownership, or approved mech silhouettes.
- The 22-house register begins ten/twelve, includes the three bargain-makers within the twelve, and does not count the deceased father as another living ruler.
- Required evidence precedes the branch without optional-companion gating.
- Rejecting the bargain leads to a winnable elite-force encounter and midpoint rescue raid.
- Accepting delivers the four formations, unassigned frame, and gold once, locks the route explicitly, and preserves Aurelia's independent escape into exile.
- Both routes support diplomacy and conquest toward whole-war recognition and their established ending.

These are future implementation acceptance criteria, not test results or completed features.
