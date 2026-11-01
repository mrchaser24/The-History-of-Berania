# The Living March — prototype 0.3 rules

Implementation defaults, November 2, 2026. These are tunable prototype rules, not additional user decisions. This sheet governs **regional** encounters. The original 3-v-3 opening and workshop loadout trial retain their earlier rules.

## Regional turns and economy

After the first Greyford defense, the board expands from 6×5 to 10×7. Travel has 3 points per turn and sight radius 2. Moving spends points; only **End travel turn** advances regional time, moves NPCs, refreshes points and ages incidents. Dialogue, shopping, preparation, battle rounds and playback never tick the world.

The region has Greyford, Stonebridge, Millhaven and hostile Emberwatch. Five persistent parties represent a caravan, patrol, bandits, noble retinue and imperial army. They follow bounded routes, one hex per committed turn. Their positions render only in current sight; known settlements remain visible as geography. NPC route motion is deterministic, not an empire-wide strategy AI.

Every fourth regional turn alternates an authored village attack with a caravan ambush. An attack lasts its creation turn plus four subsequent turns; it disappears on the next tick. An ambushed caravan waits at its attack site. Reach the site's hex and use **Help nearby incident** (or click your party) to prepare an intervention. No battle or menu time consumes its deadline. Ignoring it removes the incident; this version has no settlement destruction or story consequences. No off-screen event changes required story outcomes.

Friendly settlements offer shared workshops, cargo trade, recruiting, replenishment and free emergency mech repair. Grain costs 3 / sells for 2; ore costs 6 / sells for 4, matching the existing market. Cargo capacity remains 20. A guild contract consumes 2 carried grain at Millhaven for 16 gold and 1 trust, once per accepted delivery. The next contract opens four regional turns later.

Road-clearance jobs pay 18 gold, incidents 24, and a supply raid at Emberwatch 28; victories also give 1 trust. Road and raid work reopen two committed turns after a victory. Defeat is retryable immediately. A supply raid reduces the regional relation counter; it does not capture the fort. Stonebridge's envoy offers a road pact for 20 gold at 2 trust. It provides two pike formations in spare deployment slots, with no noble added as a pilot. No recognition or imperial political settlement is implemented.

Recruiting buys one formation: swords 8g, gunners/pikes 10g, cavalry 16g, cannon 20g, mage circle 18g. The owned roster holds 20 formations. Replenishment costs 1 gold per missing strength. These prices emphasize trying mixed forces, not a balanced campaign economy.

## Deployment and maps

One mech, troop formation, mage circle or cannon takes one command slot and activation. Ordinary encounters share **10 slots per side** across owned, allied and local participants. Owned selections take priority, then allied pikes, then up to two local volunteers. Excess support stays outside; it grants no hidden bonuses or reinforcements. The personal pilot is the only mech pilot in this regional slice. Stored/unassigned frames never spawn.

Preparation selects at most 9 owned formations alongside the player's fitted frame. Deployment locks exact frame ID, fittings-derived stats, hull, formation IDs/strength, support, enemies and reward before battle entry. Save/load or confirmed restart replays that deployment; there is no mid-battle saving. Workshop changes cannot alter a live encounter.

Ordinary fields use 14×10 hexes. Major capacity practice uses 18×12 and **15 slots per side**. Both have clear starting columns, passages through a central rock line, directional stone cover, rough patches and a supply crossing. Major battles are a capacity practice, not an implemented siege chapter. Up to 15 formations share a side; this does not manufacture extra hero pilots.

## Combat sheet

Move once, then attack, use an ability, or guard. Attacking/guarding/healing consumes the activation; after moving, finish that unit before selecting another. One optional 60° facing change is allowed. Existing front/flank/rear bonuses (0/+2/+3), strength scaling and two-step cohesion routing remain. Rocks block movement and sight, units block movement, rough ground costs 2 movement. The path label reports weighted movement cost.

Directional cover belongs to the destination hex, independently of the occupant's facing. The marked wall faces one of six directions and protects its front and neighboring sectors. It subtracts 2 ranged damage from those three sectors. Melee bypasses it; attacking around it bypasses it. No accuracy rolls or hidden hit chances are used. Minimum damage remains 1. Hover shows exact damage, facing, cover, armor and guard reductions; Q toggles a special attack preview.

| Role | Default strength / attack / armor / move / range | Special action |
| --- | --- | --- |
| Player mech | Workshop-derived; base 30 / 9 / 2 / 3 / 1 | Breach: +2 damage, ignore 2 armor |
| Swords | 12 / 6 / 1 / 3 / 1 | Shield bash: +2 damage and one extra cohesion loss to a surviving formation |
| Pikes | 16 / 6 / 1 / 2 / 1 | Thrust: +2 damage; their guard reduces cavalry damage by 6 |
| Gunners | 12 / 6 / 0 / 2 / 4 | Aimed shot: +2 damage, +1 range; unavailable after moving |
| Cavalry | 16 / 7 / 1 / 4 / 1 | Charge: +4 damage after moving at least 2 hexes in this activation; otherwise no bonus |
| Cannon | 12 / 8 / 0 / 2 / 5 | Bombard: +2 damage, ignore cover; unavailable after moving |
| Mage circle | 10 / 5 / 0 / 3 / 3 | Arc surge: +2 damage; E selects Mend instead, restoring 4 strength/hull to a living ally within 2 hexes and sight |

All mage attacks ignore armor and reduce cover to at most 1; guard still applies. Mages are vulnerable low-strength, unarmored formations. Mend cannot revive a defeated/routed unit or erase cohesion. Mend and Arc surge share the same cooldown. Abilities are ready initially; using one sets cooldown 3, reduced at the beginning of each subsequent own turn. They become ready on the third subsequent own turn. Normal attacks and guard remain available during cooldown.

Guard lasts until the unit's next own turn. Mechs, swords and pikes reduce incoming damage by 3; others by 2. Pikes reduce incoming cavalry attacks by 6 instead. Guard, armor and cover stack; magic bypasses armor as described. Exact previews use these same resolution functions. The original opening retains its uniform 2-point guard.

Win by routing/defeating every enemy, or holding the gold supply hex at the end of **three consecutive player sides**. An empty/enemy-held crossing resets the counter. Hero removal loses immediately. A battle unresolved after 16 rounds loses, bounding stalemates. AI uses the same movement, preview, ability, healing and guard legality as the player. It is deterministic and basic, not an optimized tactical opponent.

## Results, recovery and presentation

Winning records the same owned frame's remaining hull and each deployed owned formation's remaining strength. Routed or defeated formations retain 1 strength; reserve formations remain unchanged. Losing returns the party to Greyford and freely recovers/repairs the required mech; wounded formations can be replenished later. Local volunteers and allied troops never become owned. Results clear the pending encounter and pay once; repeat result callbacks cannot duplicate rewards. Failed recruitment, trade or battle-entry saves roll back their mutations. Result save failures keep the computed result in memory for **Retry save** and preserve the previous disk checkpoint.

New regional battles use temporary original 2D tactical symbols with distinct role silhouettes, facing dots, health bars, targeting lines and deterministic feedback. Wheel zoom, arrow pan and Home fit affect only presentation. The original cutout renderer remains in the old opening/trial and its labeled legacy gallery. No still, rig or motion approval is implied; no runtime 3D or new generated body parts were introduced.

Regional review uses `user://region_review.json`, separate from both campaign and workshop-review saves. It starts with the village defended, 130 gold before recruiting six example formations (48 gold left), 1 trust, full Oathkeeper hull and discovered settlement locations. It grants no headquarters. Its capacity practices never change its saved state. QA launch flags use `/tmp` slots, including `--qa --region-review` and optional `--capacity-15`.
