# The History of Berania — Project Plan

**Working subtitle:** Ironbound Crown  
**Current mech production override — November 1, 2026:** The user rejected the generated cutout assemblies and adopted a faithful Blender source model, validated as a still before animation, then rendered into 2D sprites. Weapons and shields are interchangeable assets attached to reusable hand sockets. See `MEMORY.md` and `mech-art-direction.md`; older cutout-production guidance below is superseded for mechs. Runtime gameplay remains 2D.

**Plan version:** 1.8 — refined story, two routes, banners, owned mechs, and shared inventory

**Prepared:** November 1, 2026  
**Reviewed:** November 1, 2026  
**Status:** Short Godot prologue implemented and played; scoped automated QA passes; standalone export, fresh-player review, and measured performance gates remain open  
**Creative source cited by the original plan:** `The_History_of_Berania_Game_Design_Document.md`, version 2; unavailable in the inspected workspace

This plan translates the stated game concept into an implementation roadmap. The latest user-authored story correction is authoritative. The missing design document may supply compatible details later, but cannot override that correction. Proposed technical choices, content limits, and acceptance criteria below are planning recommendations rather than previously settled design decisions. They become implementation defaults only when adopted in the decision register.

**Story authority:** [Story canon revision 2](story-canon.md) records the user-established family tragedy, innocent prince's persecution, coup, father's sacrifice, solo Oathkeeper escape, ten independent breakaway factions/twelve initial loyalists, and permanent midpoint rescue-versus-crown decision. The restoration route makes the princess empress and the protagonist prince-consort; the other makes him emperor while she survives in exile. Both settle the imperial war. Names and supporting lore are labeled authored drafts.

**Gameplay authority:** The user's subsequent November 1, 2026 gameplay request establishes turn-based hex-map travel, unobtrusive hex presentation, a Mount & Blade-like campaign, 2D battles visually inspired by Field of Glory II: Medieval, faction-specific units, trading, alliances, world-map fog of war, and village/caravan rescue events. The attached screenshot is a visual reference for readable terrain, settlements, and roads; its visible tile edges are not a requirement. The user's instruction to hide hexes takes priority. Exact rules, roster additions, and milestone limits below are recommendations, not extra user requirements.

**Latest refinement — November 1, 2026:** Adopt [the campaign refinement](campaign-refinement.md): ordinary battles up to ten units per side and major battles up to fifteen; every deployed mech counts within the cap. Allied nobles provide campaign support; the protagonist, princess, and up to five companions are personal mech pilots. Add a simple two-color/one-emblem warband crest, persistent owned frames, shared workshop storage, fitted modules, and party equipment/trade inventory. Girls' Frontline 2: Exilium is the latest tactical reference, adapted to hexes and the established 2D presentation. Earlier Field of Glory/Tacticus and portrait-diplomacy references remain compatible supporting references. These are planned additions, not implemented features.

**Document authority:** This file retains production history and milestone gates; story-canon.md controls plot and campaign-refinement.md controls the newly agreed campaign/equipment systems. Numerical prices, statistics, and exact scene content remain production/balance work. Existing prototype limits stay identified as staged limits, not the final campaign ceiling.

**Art and animation authority:** The user's latest request adds movement, attacks, and other animation, retains the 2D requirement, and delegates art decisions to the assistant. The painted style and fixed camera below are selected under that delegation. Animation budgets and timing targets are implementation recommendations to validate in the prototype; they do not add real-time combat or new tactical resources.

**Current implementation — prototype 0.1:** The user subsequently requested a full QA review followed by a prototype/short intro/demo in the existing Godot project. `scenes/main.tscn` now runs **Dawn at Greyford**: painted title, four short canon memories and portrait dialogue → a solo, zero-gold 30-hex travel slice with fog and two moving NPC markers → an animated three-versus-three defense → victory or free recovery → a saved return to the village. This bounded intro/travel integration precedes external M1 playtests under that request; it does not complete the full M2–M7 scope. See [the QA review and adopted rules](../qa/qa-review.md) and [launch/controls instructions](../README.md).

**Historical implementation evidence (unchanged by this documentation revision):** The 1.6 baseline passed 252 checks and a native round-4 victory with free repairs. Version 1.7 passes 260 checks (227 model/persistence/animation + 33 application flow), including intro navigation, zero-gold rewards and older-save preservation. Native review verified the four memories, pursuit dialogue and solo start; details are recorded in the QA report. A new-game victory now leaves 40 gold/1 trust. Older saves retain their existing resources. A data PCK exports and initializes with the matching engine; a standalone application is still unverified because export templates are absent. Keep milestone review gates separate from checked implementation tasks.

## 0. Review findings and priorities

The original plan has a sound combat-first sequence and useful boundaries around kingdom management. It is suitable for prototyping after the following implementation gaps are addressed. Full campaign feasibility, production dates, and fidelity to the missing design document are not yet validated.

| Priority | Finding | Recommendation and timing |
| --- | --- | --- |
| Implemented for 0.1 | Scaffold needed a main scene and concrete engine baseline | Existing configuration retained; Godot 4.7.2/GDScript verified; main scene added |
| Recorded for 0.1 | Git resolves to the parent `Projects` directory | Retain that checkout for the demo; no Git metadata or unrelated projects changed; repository separation is a future explicit task |
| Adopted for 0.1 | Combat and casualty rules needed exact values | Rules and statistics are recorded in `qa/qa-review.md`; full campaign tuning remains open |
| Before M2 exit | The first integration spans a whole region without an intermediate proof | First connect one village, one mission, one battle, and a minimal save/load cycle |
| Before M3 exit | Repair costs and losses can prevent further progress | Implement a guaranteed recovery path and test a zero-gold defeat scenario |
| Before M4 exit | Early infantry recruitment conflicts with the promised first soldiers at headquarters | Distinguish temporary/prototype allies, hired detachments, and the first formal soldier group |
| Before M4 exit | Trade, moving caravans, fog, and timed rescues share campaign state | Prove one turn-driven route/event lifecycle and persist it with the campaign before adding more routes |
| Before M5 exit | Optional ally quests could accidentally become progression requirements | Document a required story path and keep companion quests optional by default |
| Before M7 exit | A living campaign could grow into an unbounded simulation | Prove two NPC factions, one fort, capped parties, and one active war/siege before expanding |
| Throughout | Export, usability, and content validation arrive too late or lack evidence | Export in M0, test with fresh players in M1 and M4, and validate content as it is added |

**Initial workspace evidence, before prototype 0.1:** `project.godot` named the project `TheHistoryOfBerania`, advertised the `4.7` feature tag, and selected GL Compatibility rendering, with no main scene/gameplay code/README/export presets. The current implementation adds these files and runs under the inspected **4.7.2.stable.mono.official.ed1daf0bf** engine using GDScript. The source design document remains absent. Initial scaffold observations are historical, not a description of the now-playable project.

## 1. Project objective

Build a single-player PC strategy RPG in which a hunted archduke's son escapes alone in damaged Oathkeeper, earns his first pay, recruits an army and political allies, and either rescues the princess to restore her throne or abandons that promise for his own crown. He begins with no gold, troops, or secure home. The full campaign settles Berania's civil war; the first implementation remains a small village-to-headquarters chapter. The promised marriage, shared childhood friendship with the prince, and father's sacrifice give its politics a personal purpose.

Prove the early gameplay loop before building the full campaign:

**Explore → accept work or trade → prepare formations → travel by hex → fight or intervene → earn rewards → repair and recruit → gain allies and influence.**

The first playable chapter ends when the player earns permission to establish a small headquarters and recruit their first formal group of soldiers. Earlier combat may use temporary allies or small hired infantry detachments. It should demonstrate both the personal mech fantasy and the beginning of a larger military and political faction.

**Experience to validate:** A mech should feel powerful beside infantry, while infantry positioning and support remain useful. A village job should visibly improve either the player's fighting options or their standing in the region. These are the chapter's two main design hypotheses.

### Gameplay pillars and visual direction

- **Campaign fantasy:** Roam with a persistent warband, recruit faction troops, visit settlements, trade, escort caravans, earn reputation, and negotiate with nobles. Mount & Blade is the reference for this campaign freedom; Berania's travel and battles use turns.
- **Hidden hex world:** Terrain, roads, forests, coasts, and settlement art form a continuous illustrated 2D map. Logical movement follows six hex neighbors, but permanent hex outlines and tile seams are absent. Show a path ribbon, destination marker, travel cost, and temporary selection/reachability shading. A grid toggle may aid debugging or accessibility; it is off by default.
- **2D formation battles:** Use a fixed elevated three-quarter view with ranked groups of soldier sprites, banners, readable front lines, cavalry formations, and individually imposing mechs/cannons. A whole regiment receives one order; its visible soldiers are not separate turns. Use original 2D assets and test silhouettes at the intended zoom.
- **Tacticus contribution:** Favor compact encounters, distinct unit silhouettes, clear selection/target feedback, short animations, and a few memorable abilities. [Snowprint describes Tacticus as fast tactical skirmishes](https://snowprintstudios.com/); the specific 2D presentation, formation scale, and control limits here are Berania proposals. Keep Field of Glory's army appearance alongside this compact encounter direction.
- **Tactical direction:** Facing, flanking, terrain, ranged support, and morale should reward combined arms. Start with compact rules and small forces; the visual inspiration does not require reproducing every rule or the army size of Field of Glory. The [publisher's description](https://www6.slitherine.com/game/field-of-glory-ii-medieval/pc) identifies tile-based turns, varied troop organizations, and army formations; Berania's hex adaptation and specific mechanics below are design proposals.
- **Faction identity:** Each faction has its own authored roster, names, silhouettes, equipment, and battlefield strengths. Shared role logic keeps production manageable; faction differences must include tactical behavior or access, beyond color changes.
- **A changing world:** Caravans trade, patrols protect roads, bandits raid, and nobles travel or lead war parties. Fog limits current information. Village raids and caravan attacks invite intervention; later, war interrupts routes and armies threaten forts. The [Mount & Blade campaign-map reference](https://www.taleworlds.com/en/News/232) connects travel, trade, diplomacy, battles, and sieges; Berania uses a much smaller turn-driven model.
- **Character-led diplomacy:** Meet a recognizable ruler in a portrait dialogue scene, hear their motive, choose from a few concrete proposals, and inspect terms before accepting. House identity and remembered choices give political actions personality.

**Grid direction:** Both campaign movement and tactical battles use hexes, with permanent outlines hidden by default. The latest request explicitly establishes hex tactics. The two maps have different scales, costs, and rules even if they share coordinate helpers.

### Simplification contract

These are proposed production limits, not additional features to build:

- **Control a warband:** One player army. The chapter may retain a staged 8-slot roster and 6 deployed entities; M1 stays at 3 versus 3. The adopted full-game limit is up to 10 commandable units per side in ordinary battles and 15 in major battles/sieges. A formation, cannon, or deployed mech occupies one slot and takes one activation. Stored frames consume none. Companions do not add free slots; their machines count within the limit.
- **One understandable order:** Move, then attack or guard; one passive trait per unit at most. Add at most one special action per deployed entity after the base prototype works; it replaces the normal attack and is once per battle initially. Avoid ability bars, stacking status effects, and separate energy/heat resources.
- **Few visible numbers:** Unit strength/health, attack, armor, move, and range; simple facing/cohesion indicators. Gold pays for cargo, recruitment, and repairs. Show trust/opinion only where a decision uses them. Defer wages, food, ammunition, and detailed settlement budgets until playtests demonstrate a need.
- **Small world cast:** In the opening region, cap active NPC parties at one caravan, one patrol, one bandit party, and one visiting noble by M5, excluding the player. M7 permits one war party per pilot faction by temporarily assigning its existing patrol/noble party that role. Villagers and couriers may appear as flavor reports without simulated populations or extra pathfinding actors.
- **Small politics:** Neutral, allied, or at war per faction pair; a truce is a temporary bar on declaring war. Trade/access are explicit agreement terms, not extra diplomatic stance systems. Start with one authored motive per ruler and a five-step house opinion scale.
- **One siege at a time:** One fort, one siege progress meter, one reusable assault map, one capture objective in the M7 pilot. No wall-by-wall construction, siege-engine crafting, starvation economy, or command of several fronts.
- **Learn one layer at a time:** Combat → travel/fog/NPCs → preparation/trade → rescues → portrait alliance → small war/siege frontier. Each layer must reuse established controls and saves.
- **Polish a small asset set:** Share layered animation rigs, weapon effects, terrain families, and background paintings. Animate only units actually used in the current milestone; extra frame counts, cinematic cameras, and custom animations for every noble are outside the initial budget.

The first chapter proves a roaming warband and local consequences; the M7 frontier slice proves the requested war/siege experience. Both are required steps toward the intended game. Twenty-two nobles remain the story framework while only the current region's actors need active simulation.

### Story foundation — family tragedy, permanent choice, and two endings

The [story canon](story-canon.md) is authoritative; the full chronology and 22-house draft register live there.

1. The archduke's son and eldest imperial daughter are already in love and welcome their fathers' marriage promise. The second prince is their close childhood friend. The first prince died before the coup; the eldest daughter is the lawful heir.
2. The emperor secretly murders the second prince's mother and plans to kill the innocent prince out of paranoia. The archduke is kept in the dark. The prince strikes first and publicly justifies the coup as necessary.
3. The prince imprisons his sister out of fear while remaining unable to kill her. He wrongly believes the archduke and protagonist helped persecute him; he wants the protagonist captured and executed.
4. An imperial commander kills the archduke during the escape. The protagonist reaches Oathkeeper and escapes alone and penniless. A treacherous relative takes the duchy as one of the twelve loyalist seats; ten other houses become independent competing factions.
5. A required investigation reveals the old emperor's crimes before the midpoint fork. It cannot depend on optional companions.
6. As the player approaches the capital, three loyalist houses offer four veteran formations, an unassigned advanced frame, and gold in exchange for abandoning the princess. Accepting is an explicit permanent commitment to self-crowning. Refusing causes their elite force to attack, followed by a midpoint prison raid that frees her without conquering the capital.
7. On restoration, the princess leads politically and can pilot a mech. On the dark route she organizes her own escape with another ally and survives in exile. In both routes the player must resolve the imperial war through diplomacy, submission, or conquest.
8. The prince embraces the throne's magic-amplifying, addictive mechanism, refuses surrender, and dies fighting. Restoration ends with empress/prince-consort marriage and destruction of the mechanism; self-crowning retains the mechanism in the draft dark ending. Its possible influence on the old emperor remains uncertain.

**Delivery and production boundary:** Retain the four-memory illustrated opening and Greyford's temporary local defenders. Runtime narration still reflects revision 1 in places; this document update does not implement revised dialogue, a playable castle escape, imperial hunting AI, the rescue, or the endings. Greyford's roadwardens remain local defenders. Preserve free essential recovery, old-save resources, and the small opening slice.

**World and characters:** Medieval magitech supports rare mechs while early scarce guns coexist with traditional arms. The princess is compassionate and politically sharp. All five optional full-campaign companions are mech pilots; the chapter stages only two. Noble support comes through houses, resources, and armies rather than 1–3 recruitable noble pilots in the player's tactical roster. Draft names and ages remain distinct from direct user decisions.

### Noble interactions and consequences

The following are implementation recommendations for the full campaign. The player must have access to all four approaches as the campaign develops; individual nobles may reject an invitation or require particular conditions.

| Player approach | Conditions and outcome | Recommended consequences |
| --- | --- | --- |
| Conquer a domain | Defeat its forces and resolve territorial control; the ruler may be captured or remain at large | Gain territory and its obligations; local resistance and other nobles' reactions depend on how the conquest is handled |
| Imprison a noble | Capture a living ruler; retain them in custody without automatically gaining their allegiance | Remove their direct command while creating a negotiation opportunity and a custody obligation |
| Execute a noble | Requires custody of the living noble; permanently ends that character's participation | Possible fear, retaliation, lost recruitment opportunities, and a succession dispute; the noble's house and domain do not disappear automatically |
| Invite a noble to the cause | Offer terms before war, after surrender, or during imprisonment; acceptance depends on authored motives and conditions | Gain agreed support, troops, access, or allegiance; do not automatically transfer every allied domain into direct player ownership |

Keep **ruler fate, house allegiance, faction membership, and territory ownership separate**. A ruler can be alive and imprisoned while their house resists; an invited ally can retain their own lands; an executed ruler can leave an heir or replacement. Use a small set of authored successor outcomes initially rather than a complete family simulation. Show known terms and likely political consequences before the player commits, with an explicit confirmation for execution.

**Production boundary:** The opening chapter establishes this history and demonstrates one invitation/recruitment arc. Conquest, noble imprisonment, execution, territorial transfer, and succession become playable in the political expansion after M6. The recoverable-casualty rules for early tactical battles do not remove these later authored ruler-fate choices.

## 2. Working production assumptions

- **Engine baseline:** Continue with the existing Godot scaffold unless a prototype exposes a specific blocker. Verify and pin the exact editor version and matching export templates during M0; the `4.7` project feature tag is not an exact version pin.
- **Presentation:** Painted 2D illustrated terrain over hidden hexes, compact formation battles at a fixed elevated three-quarter angle, illustrated portraits, dialogue windows, and menu-driven management. Use sprites, layered artwork, and 2D effects throughout; the apparent depth comes from composition, shading, and overlap. Both gameplay layers remain turn-based.
- **Target:** Single-player desktop. Develop on the available macOS workspace; choose the first supported release operating system, architecture, minimum resolution, and reference test machine during M0. Development host and release target need not be the same.
- **Implementation:** Use the selected engine's native scripting and data tools; for Godot, GDScript and Resources are a proposed default.
- **Content:** Define faction rosters, formation/single-entity units, weapons, missions, recruits, upgrades, goods, trade agreements, routes, and events as reusable data.
- **Art:** Adopt the painted storybook-medieval and industrial-mech direction below. Prototype with readable placeholders in that palette and scale; prove one polished battle vignette before commissioning the full chapter's assets.
- **Production capacity:** Assume one primary developer until a different team size is recorded. Record available hours and an asset/tools budget before making date commitments.
- **Schedule:** Work by milestone exit criteria. Estimate M2–M4 after measuring M1; estimate M5 after the MVP playtest. Keep a proposed 25% of each estimate available for integration, fixes, and iteration; revise this allowance from actual effort.
- **Language and controls:** English text and keyboard/mouse initially. Controller support, localization, and other desktop targets require separate scope decisions.

### Selected art direction — a painted chronicle of steel and banners

**Look:** A richly illustrated medieval storybook with believable, slightly stylized soldiers and weathered industrial mechs. Use soft painted textures, clean silhouettes, selective ink edges, and warm sunlight. Large shapes should read at gameplay zoom; fine engraving, embroidery, and brushwork reward a closer look. Keep the world inviting and colorful while battles retain weight. This is high-resolution 2D illustration rather than pixel art.

| Layer | Selected treatment | Readability rule |
| --- | --- | --- |
| World map | Hand-painted emerald/olive countryside, winding ochre roads, deep blue water, pale stone towns, wooded ridges, and soft atmospheric fog | Blend terrain artwork across hidden hexes; emphasize roads and settlement silhouettes rather than tile borders |
| Battlefields | Fixed elevated three-quarter camera; painted grass, earth, masonry, and trees; restrained contact shadows under 2D units | Limit perspective distortion so six-way movement remains clear; faded foreground foliage cannot hide targets |
| Infantry and cavalry | Stylized proportions, readable weapons, cloth tabards, bold faction banners; small ranked formations | Draw about 4–6 representative soldiers/riders per formation at normal zoom, independent of actual troop count; troop strength remains an explicit number |
| Mechs and cannon | Riveted steel, worn brass fittings, pistons, leather/fabric details, and large heraldic plates | Give each role a distinct outline; keep weapons and shields legible without relying on team color |
| Portraits | Painterly character illustrations with expressive faces and costume details matching their house's battlefield identity | Large waist-up speaker portrait; expressive eyes and clear facial lighting; shared style across all characters |
| Interface | Warm ivory/parchment panels, dark navy text/header accents, restrained brass trim, serif headings and a highly readable body font | Keep decoration at panel edges; stable contrast, clear buttons, and icons/text in addition to color |

**Palette and lighting:** Warm cream `#E9DFC8`, ink navy `#243448`, forest green `#52684C`, muted gold `#B99A5C`, and weathered steel `#73828A` are starting swatches, not fixed text/background pairings. Use restrained crimson for danger and distinct house accent colors. Keep scenery less contrasty than units, with the selected unit and objective clearest. Paint a consistent upper-left light direction and ground contact shadows; use small 2D glows only for impacts, lamps, and selected machinery. Check final UI contrast at actual display size.

**Composition:** Work from a 1600 × 900 reference canvas with scalable interface layout; M0 still verifies supported display sizes and export performance. The battle camera pans and zooms within a fixed angle; no rotation or cinematic camera cuts during ordinary attacks. The world map uses a higher, flatter illustrated viewpoint for navigation. Paint original reference sheets for one village, one battlefield corner, one infantry formation, the starter mech, and one portrait so they look like parts of the same world.

### Animation direction and required states

Motion should feel deliberate and tactile: infantry marches in short coordinated steps, horses trot, cloth follows movement, cannon recoil pushes against the ground, and a mech plants its weight before striking. Add anticipation, impact, and recovery to attacks. Use short shared loops with slight timing offsets between decorative soldiers; keep formation motion cohesive rather than treating the sprites as independent agents.

Thin the visible formation through a few strength bands as casualties mount, without simulating each drawn soldier. The numeric troop count remains authoritative; do not draw more surviving figures than the remaining soldiers. Reuse one falling pose and a brief stagger rather than author a unique casualty sequence for every soldier.

| Actor/layer | Required animation or feedback | Scope and first delivery |
| --- | --- | --- |
| Infantry formations | Idle/breathing, march, change facing, weapon-ready, melee swing/thrust or ranged aim/fire, return to ready, hit reaction, guard/block, rout/retreat, defeat | M1 starter sword/gunner set; add lance-specific thrust/brace when that unit enters the roster |
| Starter and later mechs | Idle piston/exhaust motion, heavy walk, turn/plant feet, weapon wind-up and attack, recoil/recovery, hit stagger, guard pose, disabled/wreck transition | M1 starter frame; reuse common locomotion and add role-specific weapon motion only when each mech is introduced |
| Mounted formations | Idle weight shift, trot, turn, sword strike, pistol aim/fire, hit reaction, rout/defeat | Post-M6 horsemen; rider and horse animate as one commandable entity; lance charge only with the later charge rules |
| Mobile cannon | Wheels roll, stop/setup, aim pose, muzzle flash and recoil, smoke dissipation, hit/disabled state | When the cannon enters the roster; crew animation is decorative and simple |
| Projectiles and impacts | Bullet trace, cannon shot, muzzle flash, sword arc, sparks, dust, small smoke puffs, damage/status feedback | M1 shared melee/gun effects; cannon/lance variants later. Projectiles illustrate a resolved action rather than simulate ballistics |
| World parties | Travel along the legal hex path, face travel direction, small march/trot/wheel loop, stop at encounters, arrive/depart | M2 player/patrol/bandit; M4 caravan; M5 noble. Use a compact leader/banner icon rather than draw the entire army |
| World scenery | Gentle water motion, flag flutter, chimney smoke, occasional foliage sway; visible raid smoke where an incident exists | Small reused loops from M2–M5; decoration does not advance the campaign clock or reveal hidden activity |
| Dialogue portraits | Soft entrance/exit, subtle breathing/blink, expression changes, highlighted active speaker | Static prototype first; M5 finishes a small layered idle and up to three expressions for the initial noble, with a static fallback |
| Interface and results | Selection/range transitions, turn banner, concise objective update, agreement confirmation, reward reveal | M1 onward; short, skippable presentation that never selects an action for the player |
| Siege | Gate damage/opening, brief dust/debris, banner transfer, retreat or surrender cue | M7; one authored gate sequence, not a general destruction system |

Ranged recovery may include a reload gesture, but it does not create an ammunition system, extra activation, or hidden reload cooldown. A hit reaction must preserve the unit's actual hex and facing. Corpses/wrecks are non-blocking decoration unless a future explicit terrain rule says otherwise; remove or fade excess remains to avoid obscuring the board. Rout and death/disable must look different because their campaign meanings differ.

**Suggested normal-speed timing:** About 0.15–0.25 seconds per hex step; about 0.45–0.8 seconds for a standard attack including recovery, and 0.7–1.1 seconds for a heavy mech/cannon strike. These are targets for iteration, not frame-count requirements. Travel playback may group NPC movements so End Turn does not require watching every march individually. Keep a brief attack anticipation and visible impact even at faster speeds.

**Playback controls:** Provide Normal, Fast (approximately 2×), and Quick Resolve for presentation. Quick Resolve finishes the current visual sequence and shows the same resolved positions, damage, and result; it is not strategic auto-battle and cannot choose targets or change outcomes. Reduced Motion disables screen shake, large damage flashes, excessive particles, and decorative bobbing while preserving path/attack/impact cues. Pause freezes action playback. Decorative idle motion while considering orders is cosmetic; NPC travel, deadlines, and payments still advance only through committed campaign actions.

**Animation and game rules:** Validate the command and resolve its movement/damage once, then play a presentation record with action ID, source/destination, facing, attack/impact cue, and final state. Time the visible health/strength update to the impact cue. Animation callbacks never roll damage, grant rewards, consume another action, or advance a campaign turn. Missing clips, skipped playback, speed changes, or repeated clicks must settle to the same final state and release input locks safely. Do not save a half-played animation; use the existing campaign/battle checkpoint policy. Cancelled or hidden NPC movement must not leave sprites, footsteps, effects, or camera focus outside permitted visibility.

### Art and animation production budget

Use a hybrid of **layered 2D rigs for reusable bodies/portraits** and short sprite strips for weapon accents, impacts, smoke, and special poses. Hand-author strong poses and easing to avoid a stiff cutout appearance. Build one humanoid base set supporting sword/gun equipment, one starter mech set, shared effects, and a small terrain kit first. Different faction clothing, shield shapes, helmets, and banners provide distinct identities while reusing compatible motion. Do not mirror asymmetrical heraldry, weapon hands, or equipment incorrectly.

Represent all six tactical facing directions consistently in the 2D artwork. Reuse body parts, mirrored neutral components, and animation poses where valid, with directional weapon/crest corrections; author extra views only where reuse fails. Locomotion and visual turning never change the six-way facing rule. The number of drawn figures and idle phase offsets are presentation details, not saved soldiers or extra units.

**Production order:** M0 style sheet, scale/palette sample, and a motion test → M1 complete starter action loops using rough art → M2 world travel and minimal ambience → M3–M4 reusable equipment/caravan/incident effects → M5 one polished battle vignette plus the chapter's coherent map/portrait/UI pass → M7 gate/siege additions. Finish only the currently used unit types. In M5, review the polished vignette before spreading that treatment across the chapter; do not replace all assets based on an untested still image.

**Beauty/readability gate:** Capture a normal-zoom battlefield, a world-map scene with moving parties, and a diplomacy scene from the exported build, plus a short move/attack/guard/defeat recording. Check consistent lighting, palette and scale; clean terrain blending with hex outlines off; readable silhouettes and text; feet anchored to the ground; unobstructed targets; convincing attack timing; and correct playback in Normal/Fast/Quick Resolve/Reduced Motion. Meet the existing reference-machine performance budget before approving more effects. Quality comes from cohesive painting, silhouettes, posing, and restrained motion rather than more unit types or effects.

## 3. Scope boundaries

### Combat prototype

- One compact battlefield; an 8 × 8 offset hex layout is a proposed starting size, with the grid hidden by default.
- One player mech, two allied infantry formations, and three enemy units. Six commandable entities total; troop sprites inside formations do not increase the activation count.
- Movement, attack, guard/brace, formation strength, mech health, side turns, facing/flanks, simple morale, terrain obstacles, and enemy behavior. Build movement/attack first, then add formation rules before the M1 review.
- Victory, defeat, and restart.
- Rough but complete movement/attack/reaction animations for the starter force, with normal/fast/quick playback and safe fallbacks; final painting comes after combat validation.
- No campaign content required to evaluate combat.

### Core MVP

- First prove a smaller integration slice: one village, one job, one encounter, one reward, one repair, and save/load. Expand to the following content only after this works.
- One region of approximately 20–30 hexes.
- One starting village, one small market settlement, one bandit camp, and one tournament location.
- Turn-based travel, terrain costs, End Turn/wait, and unexplored/explored/currently visible world-map states.
- One patrolling guard party and one roaming bandit party with persistent positions and readable jobs; add the trade caravan in M4 and visiting noble in M5.
- Buy/sell a small set of goods; one agreed trade route and a visible caravan traveling between the two settlements.
- One player starter mech seized during the castle escape, with a small selection of equipment upgrades.
- Three basic enemy types and two recruitable infantry types.
- Three NPC missions: defend the village, rescue a caravan, and clear the bandit camp. The rescue demonstrates the trade-route system in play; keep its authored event within this mission budget.
- One tournament format: a one-on-one mech duel.
- Gold, experience, equipment, basic repair costs, and local trust.
- One campaign save slot with manual saving, automatic battle-boundary and End Turn checkpoints, a last-good backup, and a complete loadable gameplay loop; no mid-battle saving.
- An early story arc ending in permission to establish a headquarters and command a formal soldier group; the headquarters menu follows in M5.

### First playable chapter additions

- Two named companion mech pilots with simple abilities and short optional questlines; deployment requires an assigned available frame. The full campaign permits up to five companions.
- One recruitable noble ally with a short questline and one tangible benefit, such as access to trained soldiers.
- One limited alliance agreement with that ally: explicit parties, non-aggression, access/support terms, and a visible status. Allied territory remains independently owned.
- A reusable portrait dialogue screen for greetings, proposals, replies, and agreement review, using a few expressions and shared location backgrounds.
- A simple headquarters menu supporting the existing party loop, warband naming, and a two-color/one-centered-emblem crest creator.
- An introductory escape sequence using dialogue and the existing combat systems where practical.

The core MVP and these additions together form the first playable chapter. Companions and noble recruitment remain explicit milestone work so they do not block initial combat validation.

### Banner, garage, and inventory refinement

Follow [campaign-refinement.md](campaign-refinement.md) for the complete adopted behavior. M3 proves owned frame/equipment instances, shared workshop inventory, pilot assignment, repairs, compatible weapon/shield fitting, a small module/refit selection, cargo, and validated transactions. Default fittings are two weapon mounts and two module slots; two-handed equipment uses both mounts. Physical body-part assembly remains deferred.

M5 introduces the personal warband banner at headquarters. Use two colors and one centered preset emblem, with cosmetic edits later. It appears on campaign markers, standards, owned sites, diplomacy, and designated mech panels without changing house identity or approved body appearance.

Reserve machines and armory equipment are accessible at any friendly workshop, off-map, without cargo or deployment cost. Trade goods remain carried cargo with capacity. Quest items are protected. No individual human armor/boot/helmet inventory is added. Frame swapping and upgrades must not bypass approved art/loadout support.

### Deferred until the first chapter is proven

- Settlement ownership, construction, production, taxes, and garrisons.
- Food and ammunition upkeep, complex logistics, and multiple player-controlled armies. NPC war parties are part of the M7 frontier slice.
- Full mech body-part customization, heat or energy systems, and extensive crafting.
- Large political networks, house rivalries, betrayal systems, and the Council of Lords; the story's 22-noble/10-breakaway structure is established early without simulating every domain.
- Domain conquest, noble capture/imprisonment, execution, expanded negotiated faction allegiance, and authored succession outcomes; implement these after M6. The opening chapter already demonstrates one limited alliance.
- One fort, simple war/peace, and a constrained siege enter the defined M7 frontier slice after the chapter review. Additional fortress types, expanded regions, and the return to Berania follow later.
- Multiple endings and the full restoration campaign.
- General destructible terrain, elevation modifiers, multi-hex mechs, reaction attacks, and procedural mission generation. M7's scripted gate-opening objective is a limited exception to terrain destruction. World-map fog and the two authored rescue event types are core scope.
- Global dynamic pricing, a production-chain economy, naval trade, automated multi-route management, coalition wars, and a general-purpose political simulation. Prove one local route and one authored alliance first.
- Mod support, cloud saves, achievements, controller support, and localization beyond English.

**Production constraints:** No multiplayer, real-time combat, open-world 3D environments, runtime fully animated 3D mechs, fully voiced dialogue, or individual villager simulation. Offline Blender source models/animations rendered into 2D sprites are now authorized by the user's latest art decision.

### Unit roster — formations and single entities

The ten planned core archetypes, including the newly requested mage circle, are enough for an initial combined-arms roster. More tactical depth should first come from strengths, counters, terrain, formation condition, and faction doctrine. Do not implement every archetype for every faction at once. **Multiple-unit** means several visible soldiers/horses in one commandable formation; **single-unit** means one commandable cannon or mech. Neither requires controlling each crew member or soldier separately.

| Requested archetype | Battlefield representation | Proposed role and limitation |
| --- | --- | --- |
| Sword infantry | Multi-soldier formation | Flexible close combat and village fighting; vulnerable to concentrated fire and heavy frontal armor |
| Gunner infantry | Multi-soldier formation | Ranged volleys supporting the line; vulnerable when caught in melee; line of sight matters |
| Mage circle | Multi-mage formation, typically five mages | Magical support or ranged effects; exact abilities and counters require a small prototype before expansion |
| Mobile cannon | Single cannon with decorative crew | Slow redeploying fire support and a possible anti-mech weapon; exposed to flanking; move-or-fire proposed when introduced |
| Shield-and-lance infantry | Multi-soldier formation | Defensive line and braced anti-charge role; slow, vulnerable to rear attacks; treat as spear/lance foot troops rather than mounted lancers |
| Sword-and-gun horsemen | Multi-rider formation | Mobile flank attacks and short-range shooting; choose sword or gun attack for the activation; weak into prepared lance formations |
| Shield mech | Single mech | Hold a choke point and protect a line; lower damage and vulnerable rear |
| Sword mech | Single mech | Assault and breach infantry lines; must close through enemy fire |
| Lance mech | Single mech | Reach/armor-piercing specialist; depends on approach and positioning; extra reach rules deferred until this role is prototyped |
| Gunner mech | Single mech | Heavy ranged support; needs an infantry screen and clear firing lanes |

**Recommended additions, in priority order:**

| Optional archetype | Representation | New decision it adds | Earliest scope |
| --- | --- | --- | --- |
| Scout/skirmisher | Small formation | Better campaign vision and fast harassment; weak staying power | First roster expansion after M6 |
| Pike/halberd infantry | Formation | Dedicated armor-piercing/anti-mech line with limited mobility; add only if shield-lance troops cannot cover this role | After counter-role testing |
| Shock lancer cavalry | Formation | Strong frontal charge with setup distance; distinct from gun horsemen's mobile shooting | After charge rules exist |
| Engineer/sapper team | Small formation | Fieldworks, obstacle removal, and later siege interaction; avoid free in-combat full repairs | Military expansion |
| Banner/command support | Small formation or attached leader | Morale support with an opportunity cost in deployment; use an attached upgrade first if a full unit lacks a meaningful role | After morale playtests |

Use roughly **10 core + up to 5 optional archetypes** as a long-term role catalogue, not a chapter-one content target. The first chapter uses sword and gunner formations, Oathkeeper, staged companion frames, and three enemy roles. Add shield-lance troops, horsemen, and a cannon in the first post-M6 roster expansion; test the remaining mech roles one at a time. Oathkeeper's starting identity is fixed; its current prototype statistics do not make its approved appearance provisional.

### Faction roster identity

For each playable faction, author a roster entry linking its own unit definitions, recruitment source, visual language, preferred roles, and one weakness. Not every faction receives all ten core archetypes. Distinguish related noble houses with heraldry and selected variants while sharing a regional military tradition; 22 nobles do not require 22 completely separate sets of mechanics.

The following are **unnamed doctrine examples**, not established faction lore:

| Proposed doctrine | Distinct roster direction | Tradeoff |
| --- | --- | --- |
| Defensive court army | Heavy shield-lance formations and shield mechs | Slower travel/redeployment, limited pursuit |
| Industrial march | Disciplined gunners, mobile cannons, and gunner mechs | Expensive forces needing a protected firing line |
| Frontier houses | Sword-and-gun horsemen, scouts, and lighter lance mechs | Less staying power in a prolonged frontal fight |
| Assault principality | Elite sword formations and sword mechs | Short-range focus; vulnerable during the approach |

In M1–M3 prove two small faction rosters, not four complete armies. Each faction variant should change a relevant rule, equipment option, recruitment constraint, or cost tradeoff; avoid stacking blanket bonuses. Allied recruitment may grant access to that ally's troops while retaining their faction identity. Final faction names and roster assignments belong in the political/content register.

### Campaign turns, fog, trade routes, and events

**Proposed turn contract:** A campaign turn gives the player party 3 movement points initially; an adjacent plain/road hex costs 1 and rough terrain costs 2. Impassable hexes block travel. These values are tunable. Selecting a destination previews the route and required turns; movement stops at the current budget or a new encounter, and the player explicitly ends the turn to continue. Waiting is End Turn without moving. Ensure the maximum legal terrain-entry cost fits the party's budget. No real-time simulation runs while the player considers orders.

On End Turn, resolve NPC/caravan movement, arrivals, raid deadlines, and agreed payments once in the fixed order under “A living map with a small cast,” then refresh the player's budget and visibility. Newly created threats allow a response on the next player turn. Encounters freeze the campaign clock; tactical rounds do not consume campaign turns. Commit event/battle outcomes before resuming travel. The displayed calendar scale remains a design decision; use numbered campaign turns initially.

**Fog of war:** Unexplored hexes hide terrain and locations; explored hexes retain terrain and discovered settlements; only currently visible hexes show current hostile parties and caravans. Start with a proposed 2-hex party vision radius. Allied sight sharing, terrain-based vision blockers, and tactical fog are later additions. Mission reports may mark an approximate incident or last-known position, explicitly labeled as a report rather than live tracking. Known trade-route lines may remain visible through explored fog, but current caravan icons require sight. Clip route overlays in unexplored terrain so agreements do not reveal hidden geography.

**Two kinds of trading:** Settlement trading buys/sells cargo at posted prices. A trade agreement is a separate accepted contract that creates an active route between discovered settlements, with named parties, allowed goods, dispatch timing, cargo funding, delivery payout, and suspension terms. Local merchant contracts in M4 need no political alliance. Faction-level agreements later check diplomatic access. Start with fixed authored prices and one active caravan; expand demand and competition only after the loop works.

**Route lifecycle:** Offer → accepted agreement → valid hex path → funded dispatch → traveling caravan → delivered or lost → next scheduled dispatch. If no legal path exists, show the agreement as pending/blocked and do not charge or spawn. Validate cargo capacity and deduct dispatch costs once; only successful arrival pays delivery income. Defeat causes the stated cargo loss. A rescued caravan resumes from its saved hex if still viable; rescue reward and delivery payout are separate, uniquely identified transactions. On later war/access changes, suspend new departures and explicitly hold or reroute existing traffic; never teleport caravans through closed territory. Initially the caravan is AI-controlled; the player intervenes by reaching the threatened caravan or accepting its rescue encounter.

| Event | Trigger and choice | Battle objective | Campaign consequence |
| --- | --- | --- | --- |
| Village under bandit attack | Authored raid after arrival; visible alert with response turns; help or ignore | Route/defeat attackers while protecting a village objective | Success grants local trust and reward; optional later raids may temporarily disrupt trade/services after failure |
| Caravan ambushed | The active route's caravan reaches an authored ambush hex; rescue within the shown window or leave it | Protect the caravan while routing bandits, or reach a marked extraction point | Success preserves surviving cargo and pays the agreed rescue reward; failure destroys or damages cargo and may interrupt deliveries |

The opening village-defense mission remains retryable and its essential services cannot be permanently lost. Its tutorial raid waits for acceptance before its response clock starts. The caravan rescue is optional; failure cannot remove the required route to headquarters. Later free-roaming incidents can expire with bounded, visible consequences and a cooldown. Start with authored locations/timing, not procedural event generation. Avoid simultaneous tutorial alerts or an attack every caravan trip.

**Alliance scope:** M5 demonstrates one negotiated non-aggression/access/support pact with the recruitable noble's house or faction. Record who agrees, the granted benefit, and whether it is active or ended; refusal leaves the required story path available. Full campaign diplomacy adds mutual defense obligations, war/peace, breach penalties, and renegotiation after M6. Alliance, trade agreement, personal friendship, joining the player's faction, and territory ownership remain distinct states.

### Compact battles — current tactical reference and combined arms

Use a small hex battlefield viewed from a fixed elevated angle, rendered with 2D sprites and depth sorting. Girls' Frontline 2: Exilium now guides cover, terrain, targeting, and distinct abilities, adapted to hexes; the earlier formation/readability references remain useful. Target up to 10 units per side ordinarily and 15 in major battles, while retaining smaller staged encounters. Several infantry sprites form one readable block; a cannon or mech is one larger silhouette. At normal zoom, identify weapon, faction, facing, condition, and selection without opening a panel. Keep banners above overlapping artwork and movement overlays below units. Foreground scenery should fade or become selectable through when it obscures a valid destination.

Each encounter should ask one clear question: hold the village, keep the caravan alive, break a bandit line, or capture the fort courtyard. Proposed duration is 5–10 minutes for ordinary encounters and 10–15 minutes for the first siege, subject to playtests. Use a short deployment preview, a clear objective header, and a quick results screen. Automatic camera motion and hit effects must not hide whose turn it is.

For post-M1 specials, first try a shield formation's **Brace**, a gunner formation's **Focused Volley**, and the starter mech's **Heavy Strike**, all using the same target/preview flow and replacing the attack. These are alternatives to validate, not three required new subsystems. Keep full-strength attack previews deterministic; weakened formations use the shared strength table. No randomized hit chance, separate per-soldier rolls, reaction chains, or complex morale modifiers in the initial rules.

### A living map with a small cast

Every moving party has an ID, faction/owner, position, strength, destination, and **one current job**. Advance it by legal hex steps on End Turn; show a short intent label when visible. A party continues its job until completion, a relevant threat, or a short reconsideration interval rather than switching destinations constantly.

| Party | Simple job loop | Interaction that makes it matter | First needed |
| --- | --- | --- | --- |
| Caravan | Load → follow agreed route → deliver → return/next dispatch | Cargo reaches a market; protection keeps trade open | M4 |
| Guard patrol | Visit two road waypoints → respond to a nearby raid → return to post | Deters bandits and can help protect a route | M2 |
| Bandit party | Roam near camp → threaten a vulnerable target → raid or retreat → recover | Threat creates a village/caravan incident; a patrol or player can disrupt it | M2 movement; M4 raids |
| Visiting noble | Travel between a settlement and a meeting point → remain for an audience → return | The player can meet the ruler and propose an agreement | M5 |
| War party | March toward one frontier objective → besiege/defend → withdraw to recover | Fort control and road access can change | M7 |

**Contact rules:** During player travel, entering contact with a hostile party stops the path and opens an encounter choice. During End Turn, NPC contacts produce a reserved pending encounter or incident for the next player decision; they cannot silently launch a tactical battle. Adjacent friendly parties may contribute only if registered in the encounter's starting participant list. No remote or mid-battle reinforcements in the initial model. Offer Fight, Talk where appropriate, and Withdraw when a legal retreat exists; preview any withdrawal cost. Lock participants until the incident resolves.

**NPC-versus-NPC action:** Use one small deterministic strength comparison with bounded losses and a retreat result for off-player skirmishes. Important village/caravan/fort threats first enter an announced incident state with a response window; unresolved incidents then auto-resolve. Do not calculate each NPC battle tactically. Replenishment uses a capped cooldown at its home/camp, not free new parties every turn; clearing the camp suppresses its bandits for the chapter. Named rulers retreat or become captured according to authored rules instead of disappearing in an unseen roll.

Keep the optional authored caravan rescue available after the camp is cleared: it may use a final group of stragglers inside that encounter without restarting recurring bandit spawns. Completed/failed tutorial incidents remain resolved rather than retriggering every trip.

**End Turn order:** Freeze all orders → move eligible NPC parties in stable ID order → register contacts/threats → resolve unopposed arrivals and already-expired incidents → update siege progress, scheduled trade transactions, and bounded replenishment → update visibility and known reports → commit one snapshot → present pending decisions and refresh the player budget. Reserve contacts immediately so one party cannot fight twice or deliver while ambushed. Newly announced incidents never expire in the same tick. A failed save leaves the previous committed turn available; the resolver must not partially advance live state.

NPC diplomatic evaluations run with the end-of-turn updates and announce any declaration for the following campaign turn; newly hostile parties cannot attack in the declaration tick. Accepted player peace/alliance terms take effect on commitment and cancel incompatible pending incidents before further travel. This keeps the fixed movement order from deciding diplomacy invisibly.

**Liveliness with consequences:** A patrol driving off bandits makes that road safer; a delivered caravan generates a named arrival report; a failed rescue briefly closes that route; a war party marching past a town explains a fort warning. Add brief unit barks, smoke at a reported raid, and settlement flags where visible. Reuse these cues with a small recent-news log showing who, what, where, and when. Only log events the player sees or has received as reports; never expose unseen live coordinates.

**Event pressure:** Keep at most one urgent optional incident in the opening region, with a proposed three-turn quiet period after it resolves. Tutorials pause their deadline until accepted. Give war warnings priority in the news feed and defer new optional incidents while an urgent one is active; never erase an existing caravan threat to make room. Direct hostile contact can still require a battle choice. Show remaining campaign turns and offer an explicit ignore/leave option. The world advances when the player ends a turn; dialogue reading and tactical animation never consume response time.

### Simple war, peace, and siege

M7 introduces two neighboring NPC factions and a single disputed fort, alongside the player's warband. Other imperial factions remain background reports. Give each pilot ruler one motive, such as defending a border or securing a road. Evaluate a war proposal only at a short fixed interval, with a proposed five-turn minimum between stance changes. One war and one siege may be active in the pilot. Authored rivalries plus visible strength/opinion conditions select an objective; there is no global grand-strategy planner.

Here “one war” means one regional conflict with two sides and one fort objective. The player may join either side, creating the appropriate pairwise hostilities within that conflict, without opening a second front or another independent war simulation.

| Diplomatic state/action | Compact rule | Visible result |
| --- | --- | --- |
| Neutral | No faction attacks or fort assaults; bandits are separate hostile actors | Travel and individual trade depend on posted access terms |
| Allied | Neutral protections plus the agreed recruitment/access/support benefit | Shared support is stated; a defensive pact does not secretly trigger offensive wars |
| At war | Explicit declaration or confirmed hostile act required | Enemy parties can engage; affected trade dispatches suspend; one frontier objective becomes available |
| Peace/truce | Both sides accept authored terms; clear active siege/hostility and set a truce expiry | War stops, queued incompatible attacks cancel, and route access is revalidated before dispatch resumes |
| Join the player's cause | A separate allegiance agreement, possibly after surrender | House support/faction membership changes as stated; personal opinion and land title are not overwritten implicitly |

The player may seek trade, alliance, military access/support, peace, surrender, or allegiance through the same dialogue screen as those actions become available. NPC factions may declare war, offer peace, or ask for aid using authored messages and the same conditions. Announce new wars before their first hostile action. Refusing aid has a stated, bounded opinion consequence; no obligation can silently force the player into war. Breaking a pact or attacking a neutral prompts a clear consequences review.

Peace cancels only incidents whose hostility came from that war. Independent bandit ambushes remain valid; show which pending threats ended and which still need a response. Ending an alliance also removes its stated access/support benefits and revalidates affected recruitment/travel rather than leaving stale privileges active.

**Siege loop:** Approach a fort during war → choose Besiege → commit the army to that hex → advance a single readiness meter on End Turn → demand surrender, assault, or withdraw. A proposed two preparation turns unlock assault; this is preparation, not automatic victory by waiting. A defending party can approach and trigger one relief battle using the existing field map. The player can also join a defense or attack the besiegers to relieve a fort. Siege progress pauses while participants are reserved for another encounter; withdrawing or losing the besieging army clears its progress.

**Assault:** Reuse one authored map with an exterior approach, a scripted gate objective, and a courtyard capture point. Gate damage uses the existing attack system; opening it changes a small authored set of blocked hexes. Capture requires occupying the courtyard while no defending formation remains adjacent, checked at the end of the attacker's side turn. Defenders win by routing/defeating attackers; no ladder physics, climb animations, or multiple wall sections. Size the forces to the tactical cap and show reserves as strategic strength, not endless reinforcement waves. Siege cannon variants can wait until the basic gate/infantry/mech encounter is fun.

**Resolution:** Commit the siege result, surviving/captured ruler state, fort owner, garrison strength, and trade-access changes together. Use a small authored surrender rule for badly outmatched defenders. A ruler who was not a participant cannot be captured merely because their fort fell. Reuse village recovery and the NPC retreat/replenishment rules; the pilot fort cannot remove the opening village's essential services or required story route. The full campaign later connects these systems to the existing noble-fate choices and authored successors.

### Diplomacy dialogue — portrait scene with concrete choices

Use the attached screenshot's **composition**: a large waist-up portrait in front of a relevant background, with a nameplate and a readable dialogue box along the bottom. Add Berania's heraldry, speaker title, and a small current-relationship indicator. Use original art. Portrait expression changes (neutral, approving, displeased) and short written reactions are sufficient; a static portrait is a valid prototype.

Place **two to four reply choices** above or beside the dialogue box. A compact terms panel shows the proposed costs, access, support, duration, and known consequence; keep hidden rules out of the player's decision. The first screen offers topics; the next screen presents one proposal and its reply, rather than a sprawling conversation tree. Start with shared templates and a few motive-specific lines for each ruler. No generated dialogue service or voice acting is required.

**Minimal negotiation:** Greeting → topic → one offer → accept, one authored counteroffer, refuse, or leave → review terms → commit. Acceptance is deterministic from displayed requirements: a quest flag, house opinion, affordable payment, or military situation. Use a five-step opinion scale (hostile, wary, neutral, friendly, trusted) plus a separate diplomatic stance; do not add a second persuasion skill tree. A repeated offer with unchanged conditions gives the same answer and cannot farm opinion. The final agreement screen rechecks authority, current stance, affordability, and prerequisites before applying once.

**Illustrative alliance exchange — placeholder character and terms:**

> **Border noble:** “You saved our caravan. I can open our barracks to your recruits, but I will not promise soldiers for an invasion.”
>
> **Player choices:** “Let us agree to mutual non-aggression and recruitment access.” / “What would earn your military support?” / “I need time to consider.”
>
> **Reply:** “Protect the road, and we have an agreement.”
>
> **Terms panel:** Parties named; non-aggression; access to this house's troop roster; no offensive-war obligation; caravan-rescue requirement shown as met or unmet. **Accept terms / Back.**

These example conditions do not make the optional caravan quest necessary for the chapter ending. The ally's final authored terms may use a different short objective. Meeting a ruler on the map or requesting an audience at a known settlement opens the same scene; remote diplomacy starts as a simple authored message, not a separate courier simulation.

**Usability and persistence:** Click/keyboard advance, instant-text option, recent dialogue log, readable contrast, and a clear leave/back action. Freeze the campaign while talking. Save committed costs, agreement state, opinion change, and one-time flags together; prototype saves may reopen at the conversation's start rather than store a typing animation or every dialogue node. Never auto-accept terms through Skip/Auto; players must select the agreement action.

## 4. Milestones and completion criteria

### M0 — Project foundation and design decisions

**Purpose:** Establish a runnable project and resolve decisions that affect the prototype.

**0.1 status:** Most foundation tasks are implemented; exact adopted choices are in the QA review. The main scene and data PCK run, but the standalone export and measured performance exit criteria are still pending. M0 is not marked complete.

- [x] Inspect and retain the existing scaffold; verify the installed Godot version, rendering backend, export templates, release target, architecture, and scripting language.
- [x] Resolve repository boundaries without changing the parent repository or unrelated projects as part of setup; document the chosen arrangement before committing.
- [x] Establish a small project structure, appropriate ignore rules, and a short setup README with editor version, launch/export steps, and save location.
- [x] Define input actions, camera behavior, UI scaling, and basic screen navigation.
- [x] Record the initial combat, deployment, casualty, and recovery rules below in a decision register.
- [x] Define prototype unit and weapon data, using stable identifiers.
- [x] Record the hidden-grid presentation, formation/single-entity distinction, two prototype faction identities, and proposed tactical hex adaptation in the decision register.
- [x] Adopt/revise the simplification limits, battle reference blend, and proposed single-special-action ceiling; keep advanced campaign systems outside M1.
- [x] Create a small style sheet using the selected painted 2D direction, fixed battle angle, palette, scale, and six-facing convention. Test one infantry march/attack and one mech pose before expanding art production.
- [ ] Configure a main scene and create a runnable empty battle scene and exported development build. Godot exports require presets and export templates; see the [official export guide](https://docs.godotengine.org/en/stable/tutorials/export/exporting_projects.html).
- [ ] Record the reference test machine, a provisional 60 FPS target for the small battlefield, and the supported window sizes; verify these in the export.

**Recommended starting rules to adopt or revise before M1:**

| Decision | Proposed prototype default |
| --- | --- |
| Grid and footprint | 8 × 8 offset hex layout, stored with axial coordinates; six neighbors; each formation, mech, or cannon occupies one hex; sprites may fill the hex without changing occupancy; outlines hidden by default |
| Movement | One move up to a unit's movement allowance; blocked and occupied cells are impassable; no move after attacking or guarding |
| Activation | Player side first, then enemy side; player chooses friendly activation order; a unit finishes its activation before another is selected; unspent actions can be skipped; explicit End Turn |
| Attacks | One equipped attack per unit; melee range 1; ranged distance uses hex distance with an explicitly defined line-of-sight check against blocked terrain; no friendly fire |
| Damage and armor | Deterministic integer damage, `max(1, weapon_damage - armor)`; no accuracy or critical rolls; preview exactly matches applied damage |
| Guard | End activation and reduce incoming damage by a fixed, previewed amount until the start of that unit's next side turn; final damage remains at least 1 |
| Terrain | Passable or blocked initially; blocked cells also block line of sight; cover bonuses deferred unless positioning needs them |
| Facing and formations | Six facing directions; final movement direction sets facing, with one optional facing adjustment before attack/guard; finish facing before resolving the action. Front two, side two, and rear two adjacent directions are relative to facing; use a fixed, previewed side/rear bonus without free retaliation in M1 |
| Strength and morale | Formations track current/max soldiers and cohesion (steady, shaken, routed); one aggregate attack and shared activation. Author a small strength-to-damage table. A damaging flank/rear hit or strength falling below half causes one cohesion drop per activation; routed formations leave combat. Mechs/cannons track hull health and disable at zero; no formation morale for these in M1 |
| Deployment | Fixed starting cells and the fixed six-unit roster for M1; validate legal spawn cells and party capacity before campaign encounters |
| Completion | Victory when enemies are defeated; protagonist defeat takes precedence if both outcomes occur together; every activation has an explicit finish/skip path |
| Casualties | M1 casualties last only for the encounter; recommended first-chapter policy is recoverable injuries, persistent mech damage, and no permanent character deaths |
| Recovery | In campaign play, protagonist defeat returns the party to the village through the recovery rules in section 5; retry/restart remains available in the standalone prototype |

Define hex line-of-sight edge/tie behavior, facing-sector mapping, strength/damage conversion, flank bonuses, weapon ranges, movement values, guard reduction, and initial statistics in a small rules/content sheet. A routed formation counts as removed for victory but is distinguished from destroyed casualties in the battle result. Ensure melee units can reach opponents. These proposed rules provide a small formation-battle baseline; morale recovery, pursuit, charges, reload cycles, and more advanced counters follow only after M1's review.

**Done when:** A clean project copy opens and runs with documented setup steps, an exported build launches on the chosen target, repository boundaries are recorded, and the battle rules are concrete enough to implement without unresolved structural decisions.

### M1 — Tactical combat prototype

**Depends on:** M0.

**0.1 status:** The following implementation tasks are present in the playable demo. The two unfamiliar-player reviews, standalone exported-build verification, and art/performance review gates remain open; checkbox completion alone does not close M1. Six-way rules use chevrons and simplified figure poses pending finished directional art.

- [x] Implement grid coordinates, occupancy, movement costs, and pathfinding.
- [x] Add unit selection and readable movement and attack previews.
- [x] Implement side turns, action limits, attack resolution, armor, damage, and defeat.
- [x] Implement guard, terrain blocking, and line of sight; add cover only if the review gate requires it.
- [x] Add the player mech, two allied infantry, and three enemies.
- [x] Render infantry as multi-sprite formations controlled as single entities; show surviving strength separately from hull health.
- [x] Add six-way facing, flank/rear previews, simple cohesion/routing, and a readable banner/status for each formation.
- [x] Keep terrain visible with grid outlines disabled; show temporary movement/target overlays only when useful.
- [x] Use the compact Tacticus-inspired selection/feedback direction with Field of Glory-style formations; verify original 2D sprites, facing, and banners remain readable at normal zoom. Special actions are not an M1 prerequisite.
- [x] Add the starter idle/move/turn/attack/hit/guard/rout/defeat animation set and shared muzzle/impact effects using rough 2D art. Show strength/health changes at the impact cue and settle actions safely if a clip is absent or skipped.
- [x] Add Normal/Fast/Quick Resolve playback and Reduced Motion; verify that presentation speed never changes actions, damage, occupancy, or turn completion.
- [x] Add simple enemy decisions: approach, select a valid target, attack, and end turn.
- [x] Add battle objectives, victory, defeat, and restart.
- [x] Show health, available actions, active side, and feedback explaining invalid actions.
- [x] Lock gameplay input during action resolution and scene transitions; repeated clicks cannot queue extra attacks or turn changes.
- [x] Add a short control explanation, enemy intent/attack-range inspection, and quick restart for playtesting.

**Done when:** A player can finish the encounter without developer intervention; units cannot overlap or act after defeat/routing; turns cannot stall; and positioning creates at least two useful tactical choices. Players can distinguish a troop formation from a single mech and read facing, strength, and reachable hexes with the permanent grid hidden. Starter actions visibly move/attack/react, and all playback modes produce identical final game state without stuck input locks.

**Review gate:** Have at least two people unfamiliar with the controls attempt the exported encounter without live coaching. Proposed targets: understand how to move and attack within five minutes, finish a battle in roughly 5–10 minutes after learning, and identify a useful role for both the mech and infantry. Record observed problems and whether terrain, guard, and unit roles create meaningful decisions. This is formative feedback from a small sample, not proof of broad appeal. If it fails, revise M1 before adding campaign systems.

### M2 — Overworld and encounter transitions

**Depends on:** M1.

**0.1 status:** Only the bounded village/defense/save integration slice is demonstrated. Terrain is uniform-cost, party loadouts are fixed, and NPC contacts outside Greyford do not yet start encounters. Market/camp/tournament locations, general jobs and persistent formation casualties remain future work. The 30-hex backdrop is not full M2 completion.

- [ ] Create a 20–30-hex region with a village, market settlement, camp, tournament grounds, and traversable terrain; hide permanent hex boundaries.
- [ ] Implement turn-based party movement, a movement budget, terrain costs, path/cost previews, and explicit End Turn/wait. Do not advance time while browsing menus.
- [ ] Implement unexplored, explored-but-not-visible, and currently visible world-map states; reveal nearby terrain as the party travels and hide unseen mobile actors.
- [ ] Establish one deterministic campaign-turn resolution for movement of NPC parties/caravans and event deadlines; freeze it during tactical battles.
- [ ] Add one patrol following two waypoints and one bandit party roaming near camp; persist their jobs/positions and stop player travel on hostile contact. M4 adds raid/escort consequences to this movement foundation.
- [ ] Animate party markers along their resolved paths, stopping at encounters and fog boundaries; add a small shared water/flag/smoke ambience set without advancing simulation time.
- [ ] Add location interaction and encounter entry.
- [ ] Pass the selected party and equipment into battle.
- [ ] Return battle outcomes, rewards, and casualties to campaign state.
- [ ] Implement minimal free village recovery and placeholder rewards so an unsuccessful battle does not leave the campaign in an unusable state; priced repairs and full progression follow in M3.
- [ ] Add a minimal campaign snapshot save/load for location, campaign turn and movement budget, exploration memory, party health/strength/cohesion recovery, encounter completion, and committed rewards before expanding progression.

**Integration checkpoint:** Connect a village and one encounter first. Accept a placeholder job, travel, fight, apply one reward, return for basic recovery, close the application, and load the same campaign. Verify a loss and a restart during the return transition. Only then expand the overworld to its 20–30-hex target. A temporary job flag, fixed loadout, and small resource balance are sufficient until M3 adds preparation and M4 introduces the general quest model.

**Done when:** The player can leave the village, travel to an encounter, complete it, and return with the correct persistent results. A patrol and bandit visibly pursue distinct jobs on End Turn and resume them after load. Hidden enemies cannot leak through markers or tooltips, and exploration survives reloading.

### M3 — Progression, preparation, and persistence

**Depends on:** M2.

- [ ] Expand M2's placeholder resource/reward handling into gold, experience, inventory, and validated transactions.
- [ ] Add owned frame/equipment instances, shared friendly-workshop storage, one-pilot/one-frame assignment, repairs, and a small compatible fitting/refit selection. Preserve Oathkeeper when another frame is assigned.
- [ ] Give at least one upgrade a tactical effect rather than only a stat increase.
- [ ] Optionally prototype one attack-replacing special for a starter unit; retain it only if players understand its use without extra resource/status systems.
- [ ] Add two infantry recruitment options, a party limit, and a roster screen.
- [ ] Recruit infantry as small formation instances with troop counts; retain one activation per formation. Give the two initial faction rosters distinct names, silhouettes, and at least one tactical difference while sharing role logic.
- [ ] Add settlement buy/sell menus with a small goods list, posted prices, cargo capacity, protected quest items, and validated transfers; keep workshop reserves separate from carried trade goods.
- [ ] Add take/leave battle loot, explicit cargo overflow, last-usable-frame sale protection, and single-claim frame/equipment rewards. Use only art-supported loadouts.
- [ ] Set deployment capacity separately from roster capacity, validate mission restrictions, and ensure mandatory battles remain possible with the starter force.
- [ ] Add basic unit experience progression; defer the full five-rank promotion tree.
- [ ] Extend M2 persistence into one campaign slot with manual saving, automatic battle-boundary and End Turn checkpoints, schema/build versions, a last-good backup, and validated safe replacement.
- [ ] Save at stable campaign points; suspend saving during unresolved battle transitions.
- [ ] Handle missing or invalid save data with a clear recovery message.
- [ ] Harden the zero-gold recovery route and add a balance sheet covering starting resources, mission rewards, repairs, recruitment, upgrades, trade/cargo costs, and tournament fees/prizes.
- [ ] Add New Game, Continue, pause, return to menu, and quit flows; make unsaved progress and battle restart behavior clear.

**Done when:** Recruiting and upgrading change the next battle, rewards cannot be claimed twice, and loading restores party, equipment, resources, location, trust, and progression correctly.

### M4 — Core MVP story, trade route, and rescue events

**Depends on:** M3.

- [ ] Build the starting village menu and short NPC dialogue flows.
- [ ] Add quest states, objectives, prerequisites, and one-time rewards.
- [ ] Implement three NPC missions: village defense, caravan rescue, and bandit camp. Reuse combat rules with explicit defend/protect objectives.
- [ ] Add one local merchant trade agreement with named endpoints, goods, dispatch interval, and payout terms. Agreement activation creates the route; dispatch creates a caravan that advances on campaign turns.
- [ ] Draw the agreed trade route and caravan icon on the world map according to discovery/visibility rules; handle arrival, reward settlement, interruption, and blocked travel.
- [ ] Add authored village-raid and caravan-attack alerts with a visible response window, help/ignore choices, battle objectives, and success/failure consequences. Count these as the first two NPC missions, not extra quests.
- [ ] Connect the patrol/bandit job loops to these incidents, enforce the active-party/urgent-incident caps, and add a small visibility-filtered recent-news log. Validate that suppressing bandit spawns preserves the optional authored rescue.
- [ ] Add caravan wheel/travel feedback, visible raid smoke, and arrival/rescue/reward cues using shared effects; hidden actors and expired incidents cannot keep emitting effects.
- [ ] Persist route, cargo, caravan, event, deadline, and payout state; returning from battle cannot dispatch or pay twice.
- [ ] Add the bandit camp encounter and three distinct enemy roles.
- [ ] Add a one-on-one tournament using existing combat rules and clear entry restrictions.
- [ ] Track local trust; add separate fame only when the tournament or a stated unlock actually uses it. Defer political influence until a concrete recruitment rule needs it.
- [ ] Add the arrival, mech repair, and village-trust story beats.
- [ ] Unlock headquarters permission and the first formal soldier group as the MVP conclusion, claimed once through village dialogue.
- [ ] Author the dependency and reward table in section 6; make required objectives visible, optional work recognizable, and reward collection one-time.
- [ ] Add contextual guidance for the first mission, preparation, combat, return, repair, and recruitment using the actual game UI.
- [ ] Run a fresh-player exported-build playtest now, before adding M5's extra characters and content.

**Done when:** A new player can complete the core loop from arrival to headquarters permission, with understandable objectives, sufficient resources to progress, and a clear ending milestone. A separate trade/rescue run demonstrates an agreed route, visible caravan travel, intervention, and exactly one resolved payout or loss across save/load.

### M5 — First playable chapter

**Depends on:** M4.

- [ ] Expand the implemented memory intro into the chapter's authored story delivery: shared childhood/betrothal, second son's murder and usurpation, princess's imprisonment, father's sacrifice, mech escape, ten secessionists/twelve loyalists and imperial hunt. Culpability and starting allegiance are fixed; optional playable escape work must reuse combat and remain separately scoped.
- [ ] Add two companion mech pilots, each with one distinctive benefit, a short optional questline, and an available-frame deployment requirement. Stage extra approved frames only after visual and ownership checks.
- [ ] Add a minor noble or authorized house representative as the introduction to political recruitment; establish whose pact they can negotiate and what support they control.
- [ ] Use that character as the single recruitable noble ally, with an explicit recruitment condition and a lasting benefit; do not add a second introduction character by accident.
- [ ] Keep companion membership separate from noble-house allegiance in data and UI.
- [ ] Make the noble arc offer one explicit limited alliance with non-aggression and agreed access/support. Show its parties, terms, current state, and refusal outcome; joining the cause and annexing territory remain separate actions.
- [ ] Build the shared portrait/background/nameplate/dialogue/choice screen, deterministic offer/counteroffer flow, terms review, and dialogue log. Use a static portrait first, adding up to three expressions only if budget allows.
- [ ] Finish the initial noble's subtle layered idle/blink and expression transitions with a static fallback; ensure text advance cannot accept an agreement or advance campaign time.
- [ ] Let that noble travel on a short visible schedule and offer the same conversation through an audience at their known settlement, so movement cannot permanently hide a quest contact.
- [ ] Let the one noble recruitment arc introduce the player's cause and a concrete reason to support it within the imperial succession crisis; do not require the entire 22-noble roster to be implemented.
- [ ] Let noble support improve the headquarters reward or services; keep headquarters permission obtainable through the required village-trust path unless a different dependency is explicitly adopted.
- [ ] Add a small headquarters menu for recruitment, roster review, repairs, preparation, warband naming, and the two-color/one-centered-emblem crest creator. Propagate heraldry consistently and keep it cosmetic.
- [ ] Review one polished battle vignette, then apply the selected painted 2D style consistently across the chapter's units, map, UI, portraits, animation, and first-pass audio. Record the beauty/readability gate evidence before expanding final assets.

**Done when:** The player can finish the escape-to-headquarters arc, recruit both companions and secure the noble alliance on a completionist route, understand their different roles, and save/load the resulting state. The agreement grants its stated benefit without transferring territory. A separate run that skips optional ally quests must still reach the chapter ending.

### M6 — Validation and project review

**Depends on:** M5.

- [ ] Play the entire chapter from a new save and from a loaded save.
- [ ] Have a fresh player attempt the chapter without coaching.
- [ ] Review objective clarity, tactical choices, pacing, reward balance, and mech progression.
- [ ] Check text readability, UI scaling, controls, feedback, and basic volume settings.
- [ ] Verify the minimum resolution and reference-machine performance budget, pause/focus behavior, settings persistence, and non-color-only indicators for side, range, and objectives.
- [ ] Review exported screenshots and a short animation recording at normal zoom; verify six-direction art, ground contact, formation readability, impacts, playback modes, reduced-motion settings persistence, and effect performance.
- [ ] Verify the build launches and completes the chapter on the chosen target operating system.
- [ ] Fix progression blockers, crashes, save corruption, and repeatable resource exploits.
- [ ] Include engine/third-party credits, verify asset provenance, and package concise controls, known limitations, version, and feedback instructions for external testers.
- [ ] Record feedback and decide whether to refine the chapter or approve strategy expansion.

**Done when:** The chapter is playable from start to finish in an exported build, has no known progression blockers, and playtesting supports investing in the next layer of the game. Proposed pacing target: 30–60 minutes for the required path, measured separately from optional companion content. The review must record evidence for objective clarity, useful mech/infantry roles, recovery after failure, and whether players want another mission; revise scope or pacing if the evidence is weak.

### M7 — Small living frontier: war, diplomacy, and one siege

**Depends on:** M6 approval and a fresh scope estimate. This is the next playable slice, not part of the opening chapter's completion count.

- [ ] Use two NPC factions, 2–3 authored rulers/representatives, and one disputed fort. Keep the player to one army and the region to the active-party caps.
- [ ] Add neutral/allied/war stance transitions, explicit declarations, truce expiry, one ruler motive, simple opinion conditions, and a cooldown on war/peace decisions.
- [ ] Extend portrait dialogue to peace, surrender, access, and aid proposals; show cost/obligation/breach consequences and preserve refusal/leave routes.
- [ ] Give the two factions one war-party job each using existing party slots; implement one deterministic off-player skirmish outcome and bounded home recovery.
- [ ] Make war suspend affected dispatches and revalidate cargo/access after peace, with visibility-filtered notices.
- [ ] Implement besiege/readiness/surrender/assault/withdraw, one relief encounter, the gate interaction, courtyard capture, and atomic fort-control results.
- [ ] Add gate-opening/debris, surrender/retreat, and banner-transfer animation within the established 2D style; replay/skip cannot open the gate or transfer ownership twice.
- [ ] Record which nobles actually participated and support the minimal capture/custody outcome needed for surrender; expanded execution/succession quest branches follow the regional-power roadmap.
- [ ] Keep first-chapter locations/progression protected; test conflict outcomes from checkpoints so defeat, refusal, and peace do not strand the player.
- [ ] Export and playtest the full chain: observe a march → receive war/fort news → negotiate or join a side → assault or relieve the fort → observe changed ownership/trade → save/load.

**Done when:** The region changes through NPC action without player orders; the player can influence that change through diplomacy or a siege; peace ends the conflict cleanly; and no tactical fight exceeds the cap. At least one player should be able to explain who is fighting, why, what changed, and how to respond from the map/dialogue UI. Record whether this adds interest without making turn management or negotiation confusing before expanding the simulation.

## 5. Architecture and data plan

Build these systems as their milestone needs them. The list describes responsibilities, not a requirement to create a global manager for every feature.

| Responsibility | First needed | Owns |
| --- | --- | --- |
| Battle state and turn rules | M1 | Units, grid occupancy, actions, objectives, combat results |
| Animation and presentation | M1 onward | Reusable 2D clips/rigs, visual action records, impact cues, speed/reduced-motion options, final-state cleanup; no authority over gameplay outcomes |
| Content definitions | M1 | Unit, weapon, terrain, and later quest and character definitions |
| World map | M2 | Hidden hex terrain, locations, movement budgets, exploration/visibility, travel, encounter triggers |
| NPC party jobs | M2 movement; M4 consequences; M7 war | Party IDs, owners, destinations, jobs, strength, contact reservations, retreat and bounded recovery |
| Campaign state | M2 | Turn number/resolution state, party, world progress, resources, known news, and persistent outcomes |
| Inventory, garage, and equipment | M3 | Owned frame/equipment instances, shared workshop reserves, pilot assignment, mount/module compatibility, repairs/refits, and validated transactions |
| Personal banner | M5 | Warband name, two colors, centered preset emblem, shared heraldry presentation, and cosmetic edits |
| Recruitment and progression | M3 | Roster, party limits, experience, and unit advancement |
| Markets and cargo | M3 | Goods, posted prices, cargo capacity, validated buy/sell transfers |
| Trade routes and world events | M4 | Agreements, route paths, caravan instances, dispatch/delivery transactions, raid/ambush states and deadlines |
| Save/load | M2 minimal; M3 hardened | Campaign snapshots, schema version, validation, backup, and file writes |
| Quests and dialogue | M4; portrait negotiation M5 | Conditions, objectives, dialogue branches/history, speaker presentation, proposal templates, and claimed rewards |
| Relationships and allegiance | M4–M5 | Settlement trust, fame, companions, noble support, and one limited alliance agreement |
| Frontier conflict | M7 | Stances/truces, one fort/garrison, war objectives, siege readiness, surrender, control transfer, and trade suspension |
| Expanded settlement and political systems | After M7 | More domains, faction membership, expanded noble custody/fate/succession, construction, and council decisions |

**Implementation rules:**

- Keep static content definitions separate from mutable campaign and battle state.
- Treat definition Resources as read-only templates; Godot reuses loaded Resources, so runtime health, injuries, and equipment ownership need independent per-instance state. See [Godot Resources](https://docs.godotengine.org/en/stable/tutorials/scripting/resources.html).
- Reference content through stable IDs so saves survive routine content edits.
- Give individual recruited units, mech frames, and owned equipment their own instance IDs, separate from their shared definition IDs. Keep hull condition, permanent refits, removable modules, weapon/shield fittings, and pilot assignment distinct. Battle setup validates a deployment snapshot; stored frames do not count as deployed units.
- Persist the warband's name and crest, shared garage/armory, cargo, quest items, claimed asset rewards, and eventual permanent story-route choice. Introduce a versioned migration from the current schema 1 only when implementing these systems; preserve existing gold/progress and map the old mech-health value onto one Oathkeeper instance.
- A formation instance owns faction/unit definition IDs, current/max troop count, experience, injury state, and equipment; a single entity owns hull health. Battle state adds facing, actions, and cohesion. Decorative troop sprites never become separate campaign units. Record routed/surviving troops and recover morale at a documented campaign boundary.
- Give trade agreements, routes, caravans, events, and payments stable IDs. Caravan state includes route/progress hex, cargo manifest, health, and any active ambush. Event state includes its target, status, deadline, objective, and outcome. Persist these together with the turn and any resolved transactions.
- NPC parties reuse a small job state record, not a manager per party type. Persist destinations, strength, home, recovery cooldown, and pending contact reservations. Store the last committed campaign turn so jobs cannot advance twice after interruption.
- Dialogue nodes refer to speaker/proposal IDs and conditions; use the same agreement validation as campaign transactions. Store a committed agreement/offer ID and history entry rather than tying political state to portrait animations.
- M7 stores pairwise diplomatic stance, truce expiry, known declarations, fort owner/garrison, siege participants/readiness, and resolved battle IDs. Capture, peace, and trade-access changes must invalidate incompatible queued actions within the same transaction.
- Have battles return an explicit result before applying campaign rewards and losses once.
- Keep animation playback outside authoritative rule changes. Key a visual sequence to its resolved action ID; missing clips, fast playback, pause/resume, and skipped effects must finish safely without duplicating damage or leaving an entity visually between hexes. World movement playback consumes only committed, visibility-filtered records.
- Route purchases, upgrades, recruitment, and rewards through shared transaction logic.
- Keep relationship meanings distinct: fame is recognition, trust is local confidence, influence is political power, and noble loyalty belongs to a house relationship.
- When political expansion begins, give nobles, houses, factions, and domains separate stable IDs. Track a noble's life/custody status separately from allegiance and territorial control; preserve these choices and authored successor outcomes in campaign saves.
- Avoid implementing late-game abstractions until a concrete playable feature requires them.

### Battle and campaign boundary

Keep rule resolution separate from animation and interface code so the same action validation powers previews, execution, and focused automated checks. Hex coordinate/distance helpers can be shared, but battlefield occupancy, facing, and attack rules remain separate from campaign travel, sight, and trade-path costs. Hiding outlines is a rendering choice; it does not alter legal moves or hit testing.

Use a small explicit application flow: **menu → campaign → preparation → battle → results → campaign**. Reject unrelated inputs while resolving actions or changing scenes. Battle code must not directly grant campaign money or quest rewards.

| Data crossing the boundary | Minimum contents |
| --- | --- |
| Encounter request | Unique encounter-run ID, mission/event ID, map ID, protected village/caravan target if any, objective, deployment restrictions, formation/entity instance IDs, equipment, strength, and starting health |
| Battle result | Same encounter-run ID, outcome, surviving/defeated/routed unit IDs, remaining troop counts, mech health/injuries, protected-target condition, and objective completion |
| Campaign commit | Updated roster, health/strength, resources/cargo, quest/event flags, caravan/route state, encounter completion, and applied transaction/encounter IDs in one validated snapshot |

Campaign logic calculates rewards from authored definitions. Retrying the same result must not grant rewards twice. Keep an encounter-run ID distinct from a mission ID so intentionally repeatable activities can later have separate runs. For the first chapter, story missions and tournament victory prizes are one-time unless explicitly marked otherwise.

### Persistence and interruption policy

- Save campaign data under `user://`; store settings separately. Godot's [saving guide](https://docs.godotengine.org/en/stable/tutorials/io/saving_games.html) explains the basic serialization and file APIs; the transaction and backup rules here are additional project requirements.
- Before entering battle, persist the prepared campaign and pending encounter-run ID. After resolving victory or defeat, apply the result once and save the entire resulting campaign before returning control. A failure to write must leave the last valid snapshot available and offer retry; do not show a successful save message.
- On interruption during combat or before the result snapshot is committed, load the pre-battle checkpoint and allow the encounter to restart. After a successful result commit, load the resolved campaign. Mid-battle resumption is outside scope. Explain that battle-boundary checkpoints update the single campaign slot.
- Serialize data, not live nodes or scene paths. Record schema version, build/content version, stable content references, instance IDs, resources, location, health/injuries, equipment, progression, relationships, quest states, reward claims, and pending/applied encounter IDs.
- Also record troop strength, faction variants, campaign turn/budget, explored hexes and known locations, NPC party jobs/positions/strength, contact reservations, known news, market/cargo state, agreements/alliances, route/caravan progress, event deadlines, and paid transaction IDs. M5 adds opinion and committed dialogue choices; M7 adds war/truce, fort and siege state. Recompute current visibility from saved party positions and vision rules. Commit each End Turn as one stable snapshot; interruption must not move actors or charge cargo twice.
- Write a temporary file in the save directory, validate it, preserve the last known-good snapshot, then replace the current save. Check write/replacement errors. Validate both current and backup on load; never overwrite the backup with a corrupt current file.
- Check field types, resource bounds, unique instance IDs, and referenced content before replacing live state. For incompatible schemas or removed required content, preserve the file and explain recovery or starting a new campaign. Automatic migration is deferred until a released save format needs it; prototype builds may explicitly declare incompatibility.
- New Game requires confirmation before replacing an existing campaign. Manual saving is available only at stable campaign points. Loading during battle abandons current battle progress and returns to the last checkpoint after confirmation.

### Casualties, repairs, and a viable economy

**Recommended first-chapter default:** Protagonist defeat ends the encounter, followed by village recovery rather than campaign deletion. Infantry formations and companions return with recoverable losses/injuries and can replenish at the village without permanent roster loss. Routing ends their participation in that battle, not their existence in the roster. Persist mech damage and surviving troop strength between victories; recovery restores cohesion to steady. Keep injury effects simple and visible. Adopt final casualty rules in M0 so battle results and saves agree.

Provide free basic recovery at the village that restores the starter mech and required starter force to a documented, battle-capable condition. Higher repairs and optional upgrades may cost gold. Emergency recovery grants no money, experience, items, or trust. A mandatory job must remain available or retryable after failure; the player cannot be required to pay a tournament fee, recruit an optional unit, or buy an upgrade to resume the required path.

The balance sheet must demonstrate three routes: ordinary required-path success, one defeat followed by recovery, and zero gold with a damaged mech. For each route, show current gold, next required costs, available income/recovery, and remaining missions. Required first repairs are free or funded by guaranteed starting resources; optional spending must not remove the emergency route. Keep travel free of time-based upkeep and hunger in this chapter.

## 6. Content preparation

Prepare only the content required by the next milestone.

| Content | Initial target | Notes |
| --- | --- | --- |
| Starting mech | 1 frame | Damaged Oathkeeper seized during the castle escape; retain its approved identity, owned instance, and repair/progression arc |
| Weapons and upgrades | 2 weapon options; up to 3 upgrades | Reuse basic attacks; at least one option changes range, movement, or another tactical choice |
| Recruitable infantry | 2 roles | Sword and gunner formations; small faction variants using shared logic |
| Basic enemy roles | 3 | Include the tournament opponent in this budget; reuse the militia frame for an enemy mech |
| Battle layout | 1 initially | Reuse it before authoring additional maps |
| Starter art/animation kit | 1 humanoid base set, 1 mech set, shared effects | Sword/gun equipment variants, six-way facing, complete action/reaction states; polished vignette before chapter-wide final art |
| World ambience/travel kit | Small shared loop set | Water, flag, smoke, and party travel; caravan wheel variant in M4; no weather simulation |
| Initial faction rosters | 2 small rosters | Different identity and one tactical distinction; full nine-role rosters deferred |
| Overworld region | 20–30 hexes | Village, market settlement, camp, and tournament location; hidden boundaries and world fog |
| Trade goods | 3 initially | Proposed grain, ore, and machine parts; fixed prices and cargo capacity |
| Trade route/caravan | 1 agreement, 1 active caravan | Discovered endpoints, funded dispatch, visible turn-driven travel, ambush and arrival outcomes |
| Other moving NPC parties | 1 patrol, 1 bandit, 1 visiting noble | Movement in M2; incident jobs in M4; noble in M5; reuse party slots for M7 war jobs |
| NPC missions/events | 3 | Village defense, caravan rescue, bandit camp; two event templates within this budget |
| Tournament | 1 format | One-on-one mech duel |
| Companions | 2 | One objective per questline; reuse infantry deployment/ability rules rather than adding a separate combat system |
| Noble ally/alliance | 1 | Explicit pact and benefit, independently owned territory; no separate commanded army |
| Headquarters | 1 menu-based location | No full construction simulation in the first chapter |
| Diplomacy presentation | 1 reusable screen; 1 noble portrait initially | Shared painted background, nameplate/crest, 2–4 choices, terms panel; small blink/breathing loop and up to three expressions with static fallback |
| Frontier pilot after chapter | 2 NPC factions; 1 fort; 1 assault layout | M7; one active war/siege and short authored peace/surrender branches |

**Full-campaign political register:** Use the 22-house draft table in [story-canon.md](story-canon.md): ten independent breakaway factions and twelve initial loyalists. Valcrest's seat is held by the protagonist's treacherous uncle; Rothmar, Vaust, and Merrow are the three bargain-makers within the twelve. House names/motives are authored drafts; full ruler biographies, domains, and succession details remain content work. Keep ruler fate, house allegiance, faction membership, and territorial ownership distinct.

**Full-campaign companion target:** Up to five mech pilots, with draft concepts for Mira Vale, Tomas Flint, Ilyan Reed, Sera Vey, and Dorian Ash. Their optional quests cannot gate the investigation, headquarters, permanent branch, or final recognition. The first chapter still stages two companions.



### Required progression and optional content

The following is a proposed dependency structure, not replacement story canon. Use it to avoid hidden requirements while names and dialogue are still placeholders. Start with a local-trust threshold of 3 and tune it through playtesting.

| Beat or activity | Prerequisite | Required? | Completion/unlock |
| --- | --- | --- | --- |
| Memories, arrival and basic repair | New campaign; four canon memories are implemented | Yes | Alone, zero gold, seized mech; village offers free repairs and paid work; its formations are temporary allies |
| NPC mission 1: village defense | Arrival | Yes | First combat/protect tutorial; 1 trust; reward/repair loop taught; retryable raid |
| Local merchant agreement | Village defense and market discovered | No | Agreed goods/terms create the single trade route and allow funded dispatch |
| NPC mission 2: caravan rescue | Active trade route and dispatched caravan at ambush hex | No | Protect caravan; 1 trust and an optional reward; delivery payout waits for arrival |
| NPC mission 3: bandit camp | Village defense | Yes | Camp cleared; 2 trust; required route reaches 3 without optional trade/rescue work |
| Tournament duel | Village reached; legal mech loadout | No | One-time prize and, only if used, fame; no headquarters prerequisite |
| Companion introductions/quests | Authored village or mission flags | No | Two recruitable named companions in M5; each adds one small questline |
| Noble recruitment/alliance | Bandit camp cleared | No by default | One short M5 questline; accepted pact adds a headquarters service or trained-soldier option |
| Headquarters permission | Camp cleared and trust ≥ 3; claim through village dialogue | Yes; chapter endpoint | Formal soldier group unlocked in M4; headquarters menu available in M5 |

Keep story dependencies acyclic and failure behavior explicit. Required missions remain retryable after defeat and cannot permanently fail in this chapter. Optional quests must neither consume required quest items nor remove access to headquarters. The three NPC missions exclude the two companion questlines and noble questline; count all six in the M5 content budget. Limit each ally questline to one objective and short dialogue, reusing existing locations and encounters wherever possible. Village protection and caravan rescue objectives are included in version 1.3; further objective mechanics require a recorded scope decision.

Headquarters permission is an explicit claim rather than an immediate campaign shutdown after the bandit battle. After the ending message, allow continued play in the same region so optional ally quests and headquarters services remain accessible. The first formal soldier group must fit the established roster/deployment rules and reuse the two infantry types.

Prototype infantry are temporary test formations. M3 introduces small hired detachments for preparation; M4's formal soldier group represents recognition as a commander and a stable recruitment source. Both use the same formation rules. Introduce these distinctions in dialogue and roster labels.

## 7. Verification priorities

Use lightweight automated checks where rules are easy to break, and playtests for feel and presentation.

- **Combat:** Six-neighbor hex paths, blocked tiles, legal targets, action limits, facing/flank sectors, strength-scaled attacks, cohesion/routing, defeated-unit removal, and battle termination.
- **Combat edge cases:** Hex line-of-sight ties, minimum damage against armor/guard, unreachable targets, no legal enemy action, repeated input, routed formations, and protagonist defeat. AI must skip/end safely when no valid move or attack exists.
- **Animation:** Equal final game state at Normal/Fast/Quick Resolve, missing-clip fallback, repeated clicks, pause/resume, interrupted transitions, one impact application, visual occupancy/facing matching logical state, and no stale hidden-unit effects. Verify Reduced Motion retains tactical information and settings survive load.
- **Art quality:** Exported normal-zoom screenshots/recording of battle, world, and diplomacy; consistent painted palette/light/scale, correct directional weapons/heraldry, hidden terrain seams, unobstructed targets, readable formations/text, and acceptable reference-machine performance with effects enabled.
- **World turns and fog:** Budget exhaustion, wait, terrain entry costs, one NPC advance per End Turn, job completion/reconsideration, contacts reserved once, bounded spawning/replenishment, hidden actors/tooltips, exploration memory, route clipping, and frozen campaign time during battle/menus/dialogue.
- **Trade and rescue lifecycle:** Agreement before dispatch, valid path and funded cargo, capacity/price validation, delivery versus rescue rewards, blocked routes, visible warnings, response-window reachability, deadline expiry, failed protection, and no duplicate caravan movement/payment after interruption or load.
- **Faction identity and alliances:** Correct roster/recruitment source, useful faction tradeoffs, agreed benefits applied once, refusal without story blockage, and alliance state restored without transferring territory.
- **Portrait negotiation:** Speaker/portrait/name match, choice and text readability, clear terms, deterministic requirements, rejected stale offers, unaffordable costs, repeated offers without opinion farming, and no acceptance through text advance/skip. Closing or loading an unfinished conversation cannot apply its proposal.
- **M7 war and siege:** Declaration warning before attacks, stance cooldown/truce, one objective per war party, cancelled actions after peace, suspended/reopened routes, relief/withdrawal, gate path changes, courtyard capture timing, participating-ruler capture only, and no double fort transfer after reload.
- **Campaign transitions:** Correct deployment, casualty handling, defeat recovery, and rewards applied once.
- **Economy and quests:** Affordable transactions, no duplicate rewards, and valid prerequisite transitions.
- **Content validation:** Duplicate/missing definition IDs, invalid spawn cells, impossible deployment restrictions, quest dependency cycles, and missing reward references. Start with checks for the definitions actually in use.
- **Persistence:** Save/load round trip, missing/malformed/incompatible saves, interrupted writes, a valid backup with corrupt current data, replayed result commits, companion membership, noble allegiance, and unlocked headquarters state.
- **Player experience:** Clear objectives, readable action previews, useful upgrades, and distinct ally roles.

**Required campaign playthroughs by M6:** New game to headquarters using only required missions; a route with both companions and the noble alliance; one buy/sell → trade agreement → dispatch → caravan rescue → delivery loop; a missed/failed optional rescue; defeat and recovery at zero gold; quit/reload before and after a battle result, campaign End Turn, caravan arrival, and alliance acceptance; and reload immediately before and after the headquarters unlock. Use saved checkpoints to repeat edge cases without replaying the entire chapter every time.

**Additional M7 playthroughs:** NPC march and off-player skirmish without player intervention; declare war and assault the fort; defend/relieve it; demand surrender with a valid and invalid strength condition; withdraw/lose and recover; accept peace while a siege or ambush is pending; refuse an aid request; reload before/after stance changes, gate opening via the pre-battle checkpoint, and fort transfer. Verify that the opening required path remains available in every outcome. Mid-battle reload restarts the assault rather than preserving an open gate from an uncommitted battle.

**Evidence per milestone:** Record build/version, test machine, checks performed, playtest observations, known issues, and the exit decision. Add a repeatable import/rule-check/export command when scripts exist; introduce CI if collaboration or repeated release work makes it useful. Do not make CI infrastructure a prerequisite for the first encounter.

**Scope review at M4:** If the measured workload exceeds capacity, first reduce bespoke dialogue/art and ally quest length, then propose fewer companions or deferring the tournament. Record any changed content counts and milestone criteria before proceeding. Preserve the complete mission loop, dependable saves, readable combat, and failure recovery in every reduced scope.

Milestone completion requires both its stated acceptance criteria and a runnable build. Do not treat a list of implemented systems as evidence that the chapter is enjoyable.

### Plan coverage and consistency audit — version 1.8

This is a **planning audit**, not evidence of implemented or playtested gameplay. Every requested feature below has a design description, a production stage, and a verification path. Later-stage features remain part of the intended game; they are not silently removed to keep the opening chapter small.

| Request retained | Plan coverage | Delivery/verification stage |
| --- | --- | --- |
| Hex world movement and turns | Hidden hex map, movement budget, End Turn, fixed NPC resolution | M2 travel and interruption checks |
| Map visible without permanent hex lines | Continuous terrain; temporary paths/reach shading; grid off by default | M1/M2 normal-zoom readability |
| Mount & Blade-like roaming campaign | Persistent warband, settlement visits, recruiting, jobs, trade, rulers | M2–M6 required/optional route playtests |
| Field of Glory II: Medieval battle appearance in 2D | Ranked troop sprites, banners, facing, morale, individual mechs | M1 combined-arms/readability gate |
| Additional Tacticus battle reference | Compact encounters, distinct silhouettes, selection/target clarity, limited abilities | M1/M3 feedback and tactical-choice review |
| All nine requested archetypes | Unit roster table preserves formations, horsemen, single cannon, and four single-mech roles | Starter subset M1–M3; staged post-M6 roster growth |
| More unit recommendations | Five optional roles with distinct purpose and prerequisites | Later roster review; no new chapter requirement |
| Faction-specific units | Two initial small rosters, unique identity and tactical tradeoffs | M3 recruitment/data checks |
| Trading | Posted-price goods, cargo capacity, validated buy/sell | M3 market/save checks |
| Agreements create routes and traveling caravans | Route lifecycle, funded dispatch, visible legal hex movement, arrival/loss | M4 trade/rescue playthrough |
| World-map fog | Unexplored/explored/current states; hidden actors; reports separate from sight | M2 visibility/save checks |
| Save an attacked village | Retryable first defense plus bounded later raids | M4 required mission and defeat recovery |
| Save a caravan | Optional timed ambush/protect encounter with cargo consequences | M4 rescue success, expiry, and failure |
| Alliances | Named pact terms, support/access, no automatic annexation | M5 negotiation/benefit save checks |
| Moving NPCs and a more alive world | Patrol, bandit, caravan, noble jobs; consequences, flags, barks, known-news log | M2 movement; M4–M5 integrated activity |
| War | Two pilot factions, declarations, motives, objective, truce, bounded losses | M7 NPC/player conflict routes |
| Siege | Besiege/readiness, surrender, assault, defense/relief, withdrawal, fort transfer | M7 one-fort pilot |
| Diplomacy like the supplied dialogue image | Large portrait/background, nameplate, lower text box, replies and terms review | M5 screen/choice review; M7 political topics |
| Simple and understandable gameplay | One army, party/entity/incident caps, limited actions, three stances, one siege meter | Every review gate; M7 explain-the-conflict playtest |
| Movement, attack, and other animation | State matrix for units, mechs, horsemen, cannon, travel, scenery, portraits, UI, and siege; outcome-independent playback | M1 foundation; M2–M5 chapter polish; M7 siege; later roster clips only as introduced |
| Beautiful art chosen by the assistant, still 2D | Selected painted medieval/industrial style, fixed elevated camera, palette/material/portrait/UI rules, shared rigs, beauty gate | M0 style sample; M5 polished vignette/chapter pass; M6 exported visual review |
| Corrected backstory and restoration goal | Archduke's son/princess bond and betrothal; second son's murder/coup; dungeon; father's sacrifice; seized mech; solo zero-gold start; 10 secessionists/12 loyalists; imperial hunt | Four-memory demo intro and zero-gold flow verified; full pursuit, rescue and restoration remain later campaign content |
| Prior conquest, custody, execution, invitation choices | Noble consequence table; M7 minimal custody; later authored ruler-fate branches | Post-M6 political implementation and save/progression checks |
| Dependable saves and recovery | Atomic turn/encounter/agreement commits, backups, free essential recovery | M2–M7 persistence and zero-gold checks |
| Refined family tragedy and two routes | Required evidence, permanent bargain, midpoint rescue, independent escape/exile, final refusal to surrender | Story canon; full-campaign branch/recognition checks |
| Personal banner | Two colors, one centered preset emblem, warband name, shared crest rendering | M5 headquarters and heraldry propagation |
| Owned mechs and workshop fitting | Shared reserves, purchased/gifted frames, pilot assignment, weapons/shields, modules/refits | M3 transactions, compatibility, art support, and save migration |
| Party inventory | Shared armory, carried cargo, protected quest items, take/leave loot | M3 capacity/ownership/reward/recovery checks |
| Final tactical scale and hero roles | 10 ordinary/15 major; each mech counts; nobles support the campaign; companions pilot | Staged deployment and roster expansion |

**Cross-system conflicts resolved in this revision:** NPCs move only on End Turn, not during dialogue or battles; declarations warn before attacks; peace cancels incompatible queued actions; trade routes can be known while unseen caravans remain hidden; a reserved ambush blocks delivery; rescue and delivery pay through separate one-time transactions; a traveling noble also offers a settlement audience; clearing the bandit camp does not delete the optional authored rescue; a captured fort cannot delete the chapter's required services; and mid-battle loading restarts from the checkpoint rather than partially committing gate/fort changes.

**Animation consistency:** Cosmetic idles and scenery may play while the player considers orders, but only committed actions move parties or advance simulation. Playback speed/skip cannot alter damage or rewards, corpses do not invent blocking rules, reload gestures do not invent ammunition rules, hidden movement emits no revealing effects, and the fixed 2D art direction replaces the earlier unresolved projection choice.

**Remaining decisions, not missed requests:** Godot 4.7.2/GDScript/macOS-arm64 and starter combat values are now selected for prototype 0.1. Measured development capacity, release targets beyond this host, final roster assignments, richer world timing, negotiation thresholds, authored ruler motives, and art production estimates remain open. Art style and the fixed elevated battle view were selected in version 1.5 under the user's delegation. The short demo now runs; standalone export, fresh-player reviews, and measured performance are still pending. The source design document remains absent, so fidelity to it cannot be checked. See the QA report for tested behavior versus deferred roadmap requirements.

## 8. Main risks and responses

| Risk | Response |
| --- | --- |
| Kingdom management overwhelms the tactical game | Gate expansion behind the first-chapter review |
| Combat lacks meaningful decisions | Test the six-unit encounter early and revise positioning, terrain, or equipment before adding content |
| Too many bespoke assets | Reuse silhouettes, tiles, portraits, and encounter layouts; add polish after rules stabilize |
| Directional animations multiply the asset budget | Share layered rigs and common actions, correct asymmetric equipment, animate only current-roster units, and validate the polished starter vignette before expanding |
| Effects slow turns, obscure tactics, or trigger rules twice | Restrained timings/effects, speed and reduced-motion options, visibility-filtered playback, and outcomes resolved once independently of animation |
| Faction uniqueness multiplies every unit into a new system | Share role logic, prove two small rosters, and vary doctrine/equipment before creating new mechanics |
| Hidden hexes make legal moves hard to read | Use path/cost previews, temporary reach shading, facing markers, and clear hover selection; playtest at normal zoom |
| Caravans, fog, and raids create inconsistent world state | Use one campaign-turn resolver and atomic event/trade commits; test interruption and visibility before increasing route counts |
| Formation sprites or morale obscure outcomes | One activation per formation, aggregate strength, short state labels, and a clear difference between rout and destruction |
| Living-world ambition overwhelms simple play | Enforce active-party, incident, unit-action, stance, and siege caps; deepen outcomes before adding more systems |
| Wars flip too quickly or erase essential services | Declare before attacking, use cooldowns/truces, restrict the pilot to one disputed fort, and protect first-chapter recovery/progression |
| Diplomacy becomes a large visual-novel writing project | Reuse one portrait screen and shared proposal templates; give rulers a motive and a few responsive lines |
| Army wages or repair costs create a progression dead end | Delay complex upkeep and verify a viable recovery path after defeat |
| Noble politics becomes a simulation project | Start with one authored recruitment arc and one concrete contribution |
| Twenty-two nobles multiply quests and assets before the loop is proven | Establish the counts in lore; implement one early ally, then test political choices with 2–3 rulers before expanding the campaign roster |
| Executing or imprisoning a ruler breaks required story progression | Provide authored succession and alternate quest routes; never require a permanently removed character to continue the campaign |
| Save data breaks as systems evolve | Use stable IDs, a schema version, and round-trip checks from the first save implementation |
| Story production delays gameplay | Use concise dialogue and existing encounters; keep names and lore placeholders replaceable |
| Solo workload exceeds available time | Estimate from completed work, limit active milestone work, and cut optional content before weakening the core loop |
| Optional allies or tournament gates block the story | Test the required-only route and keep mandatory trust rewards sufficient |
| Export behaves differently from the editor | Export in M0 and at milestone exits; verify dynamically referenced content is packaged |
| Starting the campaign requires systems that are still deferred | Keep first-chapter services menu-based and test the full dependency table before expanding |

## 9. Decisions to resolve

### Before or during the combat prototype

- [ ] Record available development hours, team size, asset/tools budget, and repository boundary.
- [ ] Engine/version and initial PC operating system.
- [ ] Side-based turns versus initiative; use the proposed side-based model unless testing gives a reason to change.
- [ ] Adopt/revise the proposed tactical hex grid; world-map hex movement and turn-based play are already established requirements.
- [ ] Movement and action limits, footprint, line of sight, facing sectors, damage/armor/guard, troop-strength conversion, cohesion/routing, terrain effects, and deployment.
- [ ] Validate the selected fixed elevated 2D view, representative formation sprite count/scale, and temporary overlays with hex outlines hidden; do not reopen the art direction as an undecided feature.
- [ ] Measure starter rig/clip production cost, six-facing reuse, animation timing, impact cues, speed/skip cleanup, and reduced-motion behavior.
- [ ] Validate staged chapter roster/deployment limits and the one-passive/one-special-action approach; retain the adopted final 10-per-side ordinary and 15-per-side major battle caps.
- [ ] Casualty/recovery policy for soldiers, companions, and protagonist, needed before battle-result integration.
- [ ] Input method, UI scale, minimum supported resolution, reference machine, and performance target.

### Before the chapter is content-complete

- [x] Player-named male protagonist with fixed history/romance and customizable appearance; draft house Valcrest.
- [x] Compassionate, politically sharp princess; restoration leader and deployable mech pilot.
- [x] Prince initially strikes to survive unjust persecution; fear and addiction to authority keep him ruling.
- [x] Princess kept alive because he cannot kill his sister; father innocent of the persecution.
- [x] Rare military mechs and early scarce guns within medieval magitech.
- [ ] Finalize draft names/ages, exact assassination methods, scene dialogue, and neighboring geography without reopening settled plot decisions.
- [ ] Party/roster capacities, mission restrictions, starting economy, and exact free-recovery health/injury rules.
- [ ] Noble ally identity, motivation, recruitment terms, and contribution.
- [ ] How companion and noble quests fit alongside the village-trust milestone.
- [ ] Required-path pacing, optional-content budget, and whether fame has a concrete first-chapter purpose.
- [ ] Campaign movement budget, vision radius, turn label/calendar scale, NPC resolution order, and event response windows.
- [ ] Goods/prices, cargo capacity, agreement funding/payout, caravan speed/health, and ambush rescue versus delivery rewards.
- [ ] Two initial faction rosters and their tactical/visual differences; exact terms and parties of the single M5 alliance.
- [ ] Patrol/bandit/noble waypoints, contact/withdrawal rules, deterministic off-player strength comparison, replenishment cooldown, and one-urgent-incident pacing.
- [ ] Portrait scene layout at minimum resolution, choice/terms controls, shared proposal templates, and the noble's authored motive/opinion requirements.

Maintain a decision register in this plan or a linked file: **ID, decision, adopted/proposed status, reason, affected milestone, and date**. Technical defaults may be adopted to unblock a prototype without treating unresolved creative choices as settled canon. Use the latest user-authored canon for story content now; compare the missing design document if it becomes available and record conflicts without overriding the correction.

### Gameplay decision register — November 1, 2026

| ID | Decision | Status | Reason | Affected milestone |
| --- | --- | --- | --- | --- |
| G01 | Turn-based campaign with hex movement | Established by user | Requested campaign model | M2 onward |
| G02 | Hide permanent world hex outlines; illustrated terrain and temporary travel previews | Established presentation goal; overlay design proposed | User wants an unobstructed map | M2 onward |
| G03 | 2D formation-battle presentation referencing Field of Glory II: Medieval and Warhammer 40,000: Tacticus | Established supporting references; latest tactical direction recorded in G15 | Requested formation appearance and readability | M1 onward |
| G04 | Hex tactics, side turns, facing, and compact cohesion rules | Adopted for prototype 0.1; values recorded in QA review | Consistent movement and a small combined-arms prototype | M0–M1 |
| G05 | Faction-specific formations and single cannon/mech entities; ten core archetypes including mages | Established direction; exact statistics/content staging proposed | User's roster and faction requirements | M1–M3, expansion |
| G06 | Settlement trade, agreed routes, visible traveling caravans, and world fog | Established by user; lifecycle/turn values proposed | Connect travel, economy, and discovery | M2–M4 |
| G07 | Village and caravan rescue events | Established by user; authored first missions proposed | Make intervention part of the campaign loop | M4 |
| G08 | Alliances distinct from conquest and faction membership | Established feature; limited first pact proposed | Demonstrate diplomacy without requiring the full political simulation | M5, expansion |
| G09 | Scouts, pikes, shock cavalry, engineers, and command support | Recommended additions, not adopted roster commitments | Fill specific tactical gaps after testing the core roles | After M6 |
| G10 | Moving NPC parties, wars, sieges, and expanded diplomacy | Established by user; small party/job model and one-fort pilot proposed | A more alive campaign | M2–M5 movement; M7 conflict |
| G11 | Portrait/background/nameplate/dialogue-box diplomacy based on the supplied screenshot | Established presentation preference where feasible; choice/terms flow proposed | Make ruler interactions personal and readable | M5 onward |
| G12 | Keep the game simplified | Established by user; numerical limits proposed | Constrain controls, party count, politics, economy, and siege complexity | All milestones |
| G13 | Animate movement, attacks, reactions, travel, and supporting scenes | Established by user; clip matrix, timings, and shared-rig budget proposed | Make the 2D game feel responsive and alive | M1–M5, M7 and roster expansion |
| G14 | Painted storybook-medieval/industrial art, fixed elevated 2D battles, painterly portraits and parchment/navy/brass UI | Selected by assistant under the user's delegated art choice | Cohesive, beautiful, readable 2D presentation | M0 style sample; M5–M6 art/animation gate |
| G15 | Hex tactics referencing Girls' Frontline 2: Exilium; 10 ordinary/15 major units per side | Established by user | Latest tactical direction; smaller prototypes remain staged | Combat expansion |
| G16 | Allied nobles provide campaign support; protagonist/princess/up to five companions are personal mech pilots | Established by user | Separate house politics from personal pilot recruitment | M5 and campaign expansion |
| G17 | Two-color/one-centered-emblem personal banner | User-selected scope; headquarters timing is adopted plan default | Establish a readable warband identity | M5 |
| G18 | Persistent frames with fitted equipment/modules, shared friendly-workshop garage | Established by user; two mounts/two module slots are plan defaults | Buy, receive, retain, swap, and upgrade machines | M3 and frame expansion |
| G19 | Shared party gear and trade goods; no personal human equipment slots | User-selected scope | Meaningful equipment and commerce without individual soldier outfitting | M3 |
| G20 | Permanent midpoint rescue/crown bargain and two endings | Established by user; authored names and scene details remain draft | Give the restoration a consequential personal choice | Full campaign |

### Before the full campaign

- [ ] Finalize ruler names/titles, biographies, and domains for the draft 22-house register; preserve its established ten/twelve opening split.
- [x] The deceased archduke's seat passes to a treacherous relative among the twelve loyalists; the three bargain-makers also belong to the twelve.
- [ ] Choose the first chapter's recruitable noble from the 22-seat register and author their pact terms.
- [ ] Initial faction groupings, regional boundaries, and major story battles; do not assume each noble always equals one faction.
- [ ] Faction-specific roster assignments, upgrade paths, and which optional archetypes earn a place through tactical testing.
- [ ] Mutual-defense obligations, alliance breaches, diplomatic access, trade disruption during war, and the extent of shared intelligence.
- [ ] Capture/surrender rules, imprisonment limits, invitation terms, execution consequences, and authored succession for each ruler used in the political prototype.
- [ ] Tune NPC war-party caps; retain one player army by default and require a measured reason before reconsidering multiple player armies.
- [ ] M7 pilot factions/rulers, fort layout, siege readiness/capture timing, strength-based surrender conditions, and bounded off-player losses/recovery.
- [ ] Settlement acquisition rules and strategic economy depth.
- [ ] Council decisions, loyalty consequences, and foreshadowed betrayal.
- [x] Two main routes: midpoint rescue/restoration and permanent abandonment/self-crowning; the princess independently escapes into exile on the latter.
- [ ] Author route scenes, the independent escape, the final throne confrontation, and recognition/succession outcomes while preserving those two endings.

## 10. Expansion roadmap after validation

Proceed in this order, re-estimating scope at each step:

1. **M7 living frontier:** Deliver the defined two-faction, one-fort war/peace/siege slice using the existing party jobs, portrait diplomacy, and tactical rules. This is the first proof of strategic conflict; do not require a construction economy or all ten core unit roles before attempting it.
2. **Local command and roster growth:** Expand the captured fort or one settlement with a few menu upgrades, training, and promotions. Add shield-lance formations, sword-and-gun horsemen, and a mobile cannon, then specialized mechs individually. Extend the proven route to a small regional network and bounded repeatable raids. Add upkeep only if playtests identify a useful decision it supplies. Every added role needs a counter.
3. **Regional power:** Expand the pilot rulers' motives, invitations before war/after capture, domain conquest, imprisonment, execution, and authored successors. Extend the proven alliance/peace dialogue with mutual defense and breach terms. Persist ruler fate, faction allegiance, territory control, and relationship changes. Verify diplomacy and conquest both support progress and removing a ruler cannot block the campaign. Expand toward the 22-noble register only after this works; establish the Council of Lords when meaningful choices exist.
4. **Military campaign:** Add more authored fortress layouts and garrisons using the existing siege loop. Connect conquered domains and allied support to political outcomes; retain tactical entity caps and one player army unless testing supports a deliberate revision.
5. **Midpoint bargain and rescue:** Build the required investigation, three-house offer, permanent route commitment, elite-force opposition on refusal, and capital-prison raid. Rescuing the princess does not capture the capital. On acceptance she later escapes independently into exile.
6. **Imperial settlement:** Continue the civil war on either route, obtain recognition from every surviving major house, and stage the prince's final refusal to surrender and death in battle. Restoration ends in empress/prince-consort marriage and destruction of the throne mechanism; self-crowning leaves the princess in exile and retains the mechanism in the draft ending.

The five-act narrative is **The broken promise → A banner without a country → The price of a crown → Restoration or dominion → The throne's last prisoner**. Earlier chapter labels are superseded pacing proposals; production milestones need not match act boundaries.

## 11. Project handoff and first work session

Keep this roadmap at `plan/initial-plan.md`, read `plan/campaign-refinement.md` for the new systems, and use story canon revision 2 for plot. Add the source design document to `plan/` using its cited filename and verify its version before story production. Reconcile it with the user's later story and gameplay updates: the assassinated sovereign is the emperor, the political split is 10 secessionists plus 12 usurper loyalists, the archduke's son starts alone/penniless in the seized mech and is hunted, the princess is the imprisoned true heir, and the second son/father's sacrifice are fixed, and the campaign is turn-based with hidden hex movement, compact 2D formation battles, faction units, moving NPCs, fog, trade routes, rescue events, portrait diplomacy, war, and sieges. Preserve the simplification contract and the M7 conflict boundary. Keep the plan updated as decisions are made, with a brief record of scope changes and milestone completion.

Use the selected painted 2D art direction and animation-state matrix as the presentation brief. Prototype starter movement/attack/reaction loops in M1; validate one polished vignette before expanding final assets. Keep outcome resolution independent of playback and retain the visual/readability gate alongside gameplay checks.

**Next work session after prototype 0.1:**

1. Read applicable instructions and `qa/qa-review.md`; run the existing main scene and both QA suites before changing the prototype.
2. Finish the outstanding export-template/standalone launch and measured performance checks; preserve the existing parent repository arrangement unless separately asked to change it.
3. Have two unfamiliar players try the encounter without coaching and record clarity, role balance, timing, and enjoyment evidence.
4. Revise combat/usability from those observations; develop directional unit art and animation within the selected 2D style without expanding the roster prematurely.
5. Close the relevant M0/M1 gates before expanding the bounded village slice toward full M2; keep trade, politics and siege work at their stated stages.

**Suggested project kickoff prompt:**

> Continue the existing Dawn at Greyford prototype using `plan/initial-plan.md` and `qa/qa-review.md`. Inspect applicable instructions, run the main scene and existing QA suites, and preserve current user changes. Do not recreate the scaffold or treat later roadmap features as already implemented. Finish outstanding M0/M1 standalone export, performance and unfamiliar-player review gates, then use observed feedback to guide the smallest next campaign slice. Keep the selected painted 2D art/animation direction and simplification limits. Use the original design document if it becomes available; otherwise follow `plan/story-canon.md` and keep only its listed open details unresolved. Preserve the parent Git repository and avoid unrelated changes unless separately instructed.

## 12. Revision record

| Version | Date | Changes |
| --- | --- | --- |
| 1.0 | November 1, 2026 | Initial milestone plan |
| 1.1 | November 1, 2026 | Validated workspace assumptions; identified missing design source; clarified combat/recruitment rules, required versus optional progression, early integration and persistence, defeat recovery, production capacity, export/playtest evidence, and actual handoff paths |
| 1.2 | November 1, 2026 | Added the emperor's assassination, the working 22-noble/10-secessionist split, independent domains, conquest/imprisonment/execution/invitation choices, political consequences and succession, and staged implementation after the opening chapter |
| 1.3 | November 1, 2026 | Added the user's turn-based hidden-hex campaign direction, proposed hex formation tactics and faction rosters, nine requested unit archetypes plus optional role recommendations, world fog, settlement trading, agreed routes and moving caravans, village/caravan rescue events, one early alliance, and matching milestone/persistence/validation requirements |
| 1.4 | November 1, 2026 | Added Tacticus as a compact-battle reference, explicit simplification limits, capped moving NPC/job loops and known-news feedback, portrait/choice/terms diplomacy, a concrete M7 war/peace/one-fort siege slice, consistent campaign transactions, and a full request-coverage/contradiction audit |
| 1.5 | November 1, 2026 | Selected a painted 2D medieval/industrial art direction and fixed elevated battle view under delegated art authority; added animation states, timing/playback/accessibility rules, shared-rig and asset budgets, staged production, exported visual quality gates, and updated coverage/consistency checks |
| 1.6 | November 1, 2026 | Reviewed the complete plan as QA; adopted concrete prototype rules; implemented and played the short Greyford intro/travel/battle/save demo; recorded 252 passing checks, native victory/recovery evidence, PCK initialization, fixed defects, and open export/human/performance gates without claiming later milestones complete |
| 1.7 | November 1, 2026 | Adopted the user's full backstory correction; fixed the assassin, princess/heir and marriage promise, archduke's sacrifice, seized mech escape, ten secessionists/twelve loyalists, imperial hunt and restoration goal; updated four-memory intro, temporary local allies and zero-gold start while preserving old saves |
| 1.8 | November 1, 2026 | Recorded the detailed story interview, tragic royal-family motive, false accusation and inherited-domain betrayal, required evidence, permanent three-house bargain, midpoint rescue, independent escape/exile, corrupting throne and two endings; adopted 10/15 battle caps, companion pilots and campaign-support nobles, simple banner creation, persistent owned frames, shared workshop storage, modules/refits, party inventory, and save/acceptance requirements. Documentation only; runtime and prior QA evidence unchanged. |
