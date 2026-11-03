# Battle gameplay — phases and counterattacks

**Status: implemented in source; targeted Godot exercises passed on November 4.** Battle rules and controller confirmation were exercised with isolated data; this is not a complete campaign or device playthrough. The design supersedes older battle activation and Guard rules across Greyford, tournaments, ordinary encounters and major battles. Existing detailed 2D artwork, campaign progress and fixed weapons are preserved.

## Turn sequence

Each side completes **Command → Movement → Ranged → Charge and Melee → End**, then the opposing side takes its turn. A unit may take at most one action in each phase. The player advances without a phase confirmation; unused actions in the completed phase are lost. Automatically skip phases with no eligible actions while displaying the active phase. The End phase resolves automatically. The enemy follows the same rules and commits its choices automatically.

- **Command:** Each unit may choose at most one eligible order: Guard, Rally or mage Mend. Rally removes one cohesion loss and does not restrict later movement or attacks. Mend keeps its existing effect and cooldown. Guard permits movement and counterattacks, but prevents shooting, charging and initiating melee during that turn. Guard lasts until the start of that unit's next friendly Command phase.
- **Movement:** Each unit may move once along an unobstructed path, paying terrain costs. Its final facing is selected as part of the movement confirmation. Once during the phase it may also make a separately confirmed facing change in place without consuming its move. A unit may withdraw from an adjacent enemy without a free attack if a legal path exists; friendly units, enemies and obstacles block that path.
- **Ranged:** Each eligible unit may fire once. A unit adjacent to an enemy cannot shoot. A unit that withdrew may shoot if its final position is no longer adjacent to an enemy and its weapon permits firing after movement. Retain and display existing role-specific movement restrictions. A unit with usable ranged and melee weapons may shoot and later charge or attack in melee.
- **Charge and Melee:** Each eligible unit may initiate one melee attack. A unit already adjacent to an enemy cannot charge to reposition; it may attack from its current position or have withdrawn during Movement. Otherwise, a charge grants separate movement up to half the unit's movement stat, rounded up. It must follow a clear path, pay terrain costs and end within its selected weapon's authored melee reach of its target. A unit may also attack without charging when a target is already within reach. All melee attacks require line of sight and turn the attacker toward its target. Cavalry and lance movement-dependent special bonuses count only the distance moved during the charge itself.
- **End:** Resolve end-of-turn effects automatically and award eligible capture points after a completed opposing turn, as specified below. Check defeat immediately after damage, including counterattack damage. Retain encounter-specific victory conditions, round limits and ability cooldown lengths, adapted to the phase sequence. Eligible abilities apply in Greyford as well as later battles.

For shooting and charge-repositioning restrictions, **engaged means an enemy is adjacent**. Longer melee reach alone does not make a distant unit engaged.

## Counterattacks and role data

- A surviving, unrouted defender automatically counters a melee attack if the attacker is within the defender's authored melee reach and line of sight. Each unit counters at most once per opposing turn; refresh its reaction at the start of each opposing turn.
- Resolve the attack and any counter in order before another action. A counter uses the defender's normal melee attack and the existing facing, armor and Guard calculations; it turns the defender toward the attacker. A counter cannot trigger another counter and does not consume the defender's next-turn actions. If the attacker is defeated or routed, check the battle outcome immediately.
- Give ranged roles distinct authored basic melee attack stats: gunners **3**, deserters **2**, mages **2**, cannon **2**, gunner mechs **5**. Each listed ranged role has one-hex basic melee reach. Retain longer authored melee reach, such as that of a lance mech. These are starting gameplay values, separate from ranged attack stats and fixed weapon visuals. Existing formation-rank and pilot-experience attack bonuses apply to both melee and ranged attacks. Mage basic melee is physical and does not bypass armor; ranged magic retains its existing bypass.
- Place existing special abilities in their matching phase. An ability replaces that phase's normal action and retains its existing cooldown; do not create weapon customization.

## Capture objectives

- For capture-enabled encounters, author an objective point target from **1–10**, defaulting to **3**. This is an encounter setting, not an in-battle player setting. Both sides score independently; the first to reach the target wins immediately, even when opposing units remain.
- A specific unit begins a hold as soon as it occupies the objective. It earns one point after surviving the next complete opposing turn while remaining on the objective. A unit that begins the encounter on the objective can first score after the opponent's first full turn. The same holder earns another point after each subsequent complete opposing turn it survives there.
- Leaving the objective, defeat or routing breaks that unit's current hold. Previously earned points remain. A replacement unit starts its own hold as soon as it occupies the objective and must survive the next complete opposing turn to score.
- If neither side reaches the target by the existing round limit, the player loses. Encounters authored to require routing all enemies retain that condition; objective scoring must not bypass the final confrontation or other route-all encounters.

## Confirmation and presentation

- Preview each player unit action and require confirmation before committing it. Cancelling a preview leaves the action available. A confirmed action cannot be undone.
- Before confirming an attack or charge, show the target, predicted damage, whether a counter will occur, and the destination and path when applicable. Confirm a charge destination and target together before either takes effect; a charge automatically faces its target. Counterattacks are automatic reactions and do not ask for confirmation.
- Provide phase-specific actions and clear phase/side indicators in the existing landscape interface. Keep movement/target overlays, existing camera controls and accessibility settings. Animation speed and reduced motion must not alter battle results.

## Implementation and persistence

- Update the authoritative battle model, enemy decisions, battle presentation and controls together. Represent phase and per-unit command, movement, ranged, melee and reaction availability separately. Ensure previews and commits share eligibility and damage rules; apply attack, facing, counter and outcome deterministically.
- Keep deployment locked, ordinary/major caps at ten/fifteen per side, encounter-specific victory conditions, progression and one-time rewards. Adapt capture-enabled objectives to the contested scoring rules above, and adapt the opening's existing encounter and combined encounters to the same phase rules.
- Retain battle-boundary checkpoints: interrupted battles restart from their committed deployment. Migrate saved campaigns conservatively and do not rewrite real player save files during implementation.
- Use the user's November 4 authorization for targeted Godot exercises of the current changes. Battle/controller exercises covered phase transitions, previews and confirmation, movement, charges, counters and objective scoring; separate isolated campaign exercises covered schema-1/2/3 migration, deployment checkpoints and first-chapter one-time rewards. Runtime validation and transaction guards remain required. Further campaign and device coverage remains incomplete.
