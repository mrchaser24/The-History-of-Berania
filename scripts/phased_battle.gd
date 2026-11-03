extends "res://scripts/battle_model.gd"
## Phase rules remain authoritative; presentation never applies damage.
const PHASES = ["Command", "Movement", "Ranged", "Charge and Melee"]
var battle_phase = 0
var scores = [0, 0]
var score_target = 3
var holder_id = ""
var holder_turn = -1
var turn_serial = 0
var capture_enabled = false

func _init(encounter: Dictionary = {}):
	super(encounter)
	var threshold = encounter.get("objective_target", 3)
	if (threshold is int or threshold is float) and threshold == int(threshold): score_target = clampi(int(threshold), 1, 10)
	capture_enabled = combined and encounter.get("kind", "") not in ["tournament", "elite", "final", "camp", "investigation"]
	if capture_enabled:
		objective_name = "Hold the objective through opposing turns: first to %d points wins, or route the enemy." % score_target
	for u in units:
		u["command_used"] = false; u["movement_used"] = false; u["ranged_used"] = false; u["melee_used"] = false
		u["counter_used"] = false; u["guard_order"] = false; u["rotated"] = false
		u["cooldown"] = int(u.get("cooldown", 0)); u["travelled"] = 0
	_track_holder()
	if not holder_id.is_empty(): holder_turn = -1

func phase_name() -> String:
	return PHASES[battle_phase]

func can_activate(id: String) -> bool:
	var u = unit(id)
	if not outcome.is_empty() or not alive(u) or u.side != side: return false
	match battle_phase:
		0: return not u.command_used
		1: return not u.movement_used or not u.rotated
		2: return not u.ranged_used and not u.guard_order and has_ranged(u)
		3: return not u.melee_used and not u.guard_order
	return false

func has_ranged(u: Dictionary) -> bool:
	return u.kind in ["gunner", "cannon", "mage"] or u.get("doctrine", "") == "gunner"

func melee_reach(u: Dictionary) -> int:
	return 2 if u.get("doctrine", "") == "lance" else 1

func melee_attack(u: Dictionary) -> int:
	var base = {"roadwardens": 3, "deserters": 2, "mages": 2, "cannon": 2, "gunner_mech": 5}
	if not base.has(u.definition): return u.attack
	var d = DEFINITIONS.get(u.definition, COMBINED.get(u.definition))
	return base[u.definition] + maxi(0, int(u.attack) - int(d.attack))

func engaged(u: Dictionary) -> bool:
	for other in units:
		if alive(other) and other.side != u.side and Hex.distance(u.pos, other.pos) == 1: return true
	return false

func paths_for(id: String, limit: int) -> Dictionary:
	var u = unit(id)
	var occupied = blocked.duplicate()
	for other in units:
		if alive(other) and other.id != id: occupied.append(other.pos)
	var paths = {u.pos: [u.pos]}; var costs = {u.pos: 0}; var frontier = [u.pos]
	while not frontier.is_empty():
		var current = frontier.pop_front()
		for delta in Hex.DIRECTIONS:
			var next = current + delta
			if next not in board or next in occupied: continue
			var cost = costs[current] + int(terrain.get(next, 1))
			if cost <= limit and (not costs.has(next) or cost < costs[next]):
				costs[next] = cost; paths[next] = paths[current] + [next]; frontier.append(next)
	paths.erase(u.pos)
	return paths

func reachable_paths(id: String) -> Dictionary:
	var u = unit(id)
	if battle_phase != 1 or not can_activate(id) or u.movement_used: return {}
	return paths_for(id, u.move)

func charge_paths(id: String) -> Dictionary:
	var u = unit(id)
	if battle_phase != 3 or not can_activate(id) or engaged(u): return {}
	return paths_for(id, ceili(u.move / 2.0))

func move_confirmed(id: String, goal: Vector2i, facing: int) -> Dictionary:
	if facing < 0 or facing > 5: return {}
	var path = movement_path(id, goal)
	if path.is_empty(): return {}
	var u = unit(id); u.pos = goal; u.facing = facing; u.movement_used = true; u.moved = true
	_track_holder()
	sequence += 1
	return {"type": "move", "id": id, "path": path, "sequence": sequence}

func rotate_confirmed(id: String, facing: int) -> Dictionary:
	var u = unit(id)
	if battle_phase != 1 or not can_activate(id) or u.rotated or facing < 0 or facing > 5: return {}
	u.facing = facing; u.rotated = true; sequence += 1
	return {"type": "turn", "id": id, "sequence": sequence}

func guard_unit(id: String) -> Dictionary:
	var u = unit(id)
	if battle_phase != 0 or not can_activate(id): return {}
	u.guard = true; u.guard_order = true; u.command_used = true; sequence += 1
	return {"type": "guard", "id": id, "sequence": sequence}

func rally(id: String) -> Dictionary:
	var u = unit(id)
	if battle_phase != 0 or not can_activate(id) or u.kind == "mech" or u.cohesion != 1: return {}
	u.cohesion = 0; u.command_used = true; sequence += 1
	return {"type": "rally", "id": id, "sequence": sequence}

func can_mend(id: String, target_id: String) -> bool:
	var a = unit(id); var b = unit(target_id)
	return battle_phase == 0 and can_activate(id) and a.kind == "mage" and a.cooldown == 0 and alive(b) and a.side == b.side and b.hp < b.max_hp and Hex.distance(a.pos, b.pos) <= 2 and has_los(a.pos, b.pos)

func mend(id: String, target_id: String) -> Dictionary:
	if not can_mend(id, target_id): return {}
	var a = unit(id); var b = unit(target_id); var restored = mini(4, b.max_hp - b.hp)
	b.hp += restored; a.cooldown = 3; a.command_used = true; sequence += 1
	return {"type": "mend", "id": id, "target": target_id, "restored": restored, "sequence": sequence}

func can_attack(id: String, target_id: String, special: bool = false) -> bool:
	var a = unit(id); var b = unit(target_id)
	if battle_phase not in [2, 3] or not can_activate(id) or not alive(b) or a.side == b.side: return false
	if special and (a.cooldown > 0 or (battle_phase == 2 and a.moved and (a.kind in ["gunner", "cannon"] or a.get("doctrine", "") == "gunner"))): return false
	if special and ((battle_phase == 2) != has_ranged(a)): return false
	if battle_phase == 2:
		if not has_ranged(a) or engaged(a): return false
		return Hex.distance(a.pos, b.pos) <= a.range + (1 if special and a.kind == "gunner" else 0) and has_los(a.pos, b.pos)
	return Hex.distance(a.pos, b.pos) <= melee_reach(a) and has_los(a.pos, b.pos)

func strike_preview(a: Dictionary, b: Dictionary, is_melee: bool, special: bool = false, charge_distance: int = 0) -> Dictionary:
	var sector = posmod(Hex.direction(b.pos, a.pos) - b.facing, 6)
	var flank = 3 if sector in [2, 3] else (2 if sector in [1, 4] else 0)
	var ratio = float(a.hp) / a.max_hp
	var scale = 1.0 if a.kind == "mech" or ratio >= .75 else (.8 if ratio >= .5 else .6)
	var armor = b.armor; var cover_value = 0 if is_melee else cover_reduction(a, b); var bonus = 0
	if not is_melee and a.kind == "mage": armor = 0; cover_value = mini(1, cover_value)
	if special:
		bonus = 2
		if a.kind == "mech":
			armor = maxi(0, armor - 2)
			if a.get("doctrine") == "lance": bonus = 4 if charge_distance >= 2 else 1
			if a.get("doctrine") == "sword": bonus = 3
			if a.get("doctrine") == "gunner": cover_value = 0
		if a.kind == "cannon": cover_value = 0
		if a.kind == "cavalry": bonus = 4 if charge_distance >= 2 else 0
	var guard_value = guard_reduction(b, a)
	var power = melee_attack(a) if is_melee else a.attack
	var damage = maxi(1, roundi(power * scale) + flank + bonus - armor - guard_value - cover_value)
	return {"damage": damage, "flank": flank, "label": "REAR +3" if flank == 3 else ("FLANK +2" if flank == 2 else "FRONT"), "guarded": b.guard, "cover": cover_value, "armor": armor, "guard": guard_value, "special": special}

func attack_preview(id: String, target_id: String, special: bool = false) -> Dictionary:
	if not can_attack(id, target_id, special): return {}
	var a = unit(id); var b = unit(target_id); var melee = battle_phase == 3
	var result = strike_preview(a, b, melee, special, int(a.get("charge_distance", 0)))
	var routed = b.kind != "mech" and b.cohesion + (1 if result.flank > 0 or (b.hp * 2 >= b.max_hp and (b.hp - result.damage) * 2 < b.max_hp) else 0) + (1 if special and a.kind == "sword" else 0) >= 2
	result["counter"] = melee and b.hp > result.damage and not routed and not b.counter_used and Hex.distance(a.pos, b.pos) <= melee_reach(b) and has_los(b.pos, a.pos)
	return result

func charge_preview(id: String, target_id: String, goal: Vector2i, special: bool = false) -> Dictionary:
	var a = unit(id); var b = unit(target_id); var paths = charge_paths(id)
	if not alive(b) or b.side == side or not paths.has(goal) or Hex.distance(goal, b.pos) > melee_reach(a) or not has_los(goal, b.pos): return {}
	if special and (a.cooldown > 0 or has_ranged(a)): return {}
	var old = a.pos; a.pos = goal
	var result = strike_preview(a, b, true, special, paths[goal].size() - 1)
	var routed = b.kind != "mech" and b.cohesion + (1 if result.flank > 0 or (b.hp * 2 >= b.max_hp and (b.hp - result.damage) * 2 < b.max_hp) else 0) + (1 if special and a.kind == "sword" else 0) >= 2
	result["counter"] = b.hp > result.damage and not routed and not b.counter_used and Hex.distance(goal, b.pos) <= melee_reach(b) and has_los(goal, b.pos)
	a.pos = old
	result["path"] = paths[goal]
	return result

func _strike(a: Dictionary, b: Dictionary, special: bool, melee: bool, charge_distance: int) -> Dictionary:
	if melee: a.facing = Hex.direction(a.pos, b.pos)
	var preview = strike_preview(a, b, melee, special, charge_distance); var old_hp = b.hp
	b.hp = maxi(0, b.hp - preview.damage)
	if b.kind != "mech" and b.hp > 0 and (preview.flank > 0 or (old_hp * 2 >= b.max_hp and b.hp * 2 < b.max_hp)): b.cohesion = mini(2, b.cohesion + 1)
	if special and a.kind == "sword" and b.kind != "mech" and alive(b): b.cohesion = mini(2, b.cohesion + 1)
	_track_holder(); sequence += 1
	return {"type": "attack", "id": a.id, "target": b.id, "from": a.pos, "to": b.pos, "old_hp": old_hp, "damage": preview.damage, "label": preview.label, "guarded": preview.guarded, "ranged": not melee, "removed": not alive(b), "routed": b.cohesion == 2, "sequence": sequence}

func attack(id: String, target_id: String, special: bool = false) -> Dictionary:
	if not can_attack(id, target_id, special): return {}
	var a = unit(id); var b = unit(target_id); var melee = battle_phase == 3
	if melee: a.melee_used = true
	else: a.ranged_used = true
	if special: a.cooldown = 3
	var action = _strike(a, b, special, melee, int(a.get("charge_distance", 0)))
	_check_outcome()
	if outcome.is_empty() and melee and alive(b) and not b.counter_used and Hex.distance(a.pos, b.pos) <= melee_reach(b) and has_los(b.pos, a.pos):
		b.counter_used = true
		action["counter"] = _strike(b, a, false, true, 0)
		_check_outcome()
	return action

func charge(id: String, target_id: String, goal: Vector2i, special: bool = false) -> Dictionary:
	var preview = charge_preview(id, target_id, goal, special)
	if preview.is_empty(): return {}
	var a = unit(id); a.pos = goal; a["charge_distance"] = preview.path.size() - 1
	_track_holder()
	var action = attack(id, target_id, special)
	if not action.is_empty(): action["charge_path"] = preview.path
	return action

func _track_holder():
	if not capture_enabled: return
	var current = occupant(objective)
	var id = "" if current.is_empty() else current.id
	if id != holder_id:
		holder_id = id; holder_turn = turn_serial

func advance_phase():
	if not outcome.is_empty(): return
	battle_phase += 1
	if battle_phase < PHASES.size(): return
	_track_holder()
	if capture_enabled and not holder_id.is_empty():
		var holder = unit(holder_id)
		if alive(holder) and holder.side != side and holder_turn < turn_serial:
			scores[holder.side] += 1
			objective_progress = scores[0]
			if scores[holder.side] >= score_target: outcome = "victory" if holder.side == 0 else "defeat"
	if not outcome.is_empty(): return
	side = 1 - side; turn_serial += 1; battle_phase = 0
	if side == 0: round_number += 1
	if combined and round_number > 16: outcome = "defeat"; return
	for u in units:
		if u.side == side:
			u.command_used = false; u.movement_used = false; u.ranged_used = false; u.melee_used = false
			u.rotated = false; u.guard = false; u.guard_order = false; u.moved = false; u.charge_distance = 0
			u.cooldown = maxi(0, u.cooldown - 1)
		else: u.counter_used = false

func has_phase_actions() -> bool:
	for u in units:
		if not can_activate(u.id): continue
		if battle_phase == 0: return true
		if battle_phase == 1:
			if not u.rotated or (not u.movement_used and not reachable_paths(u.id).is_empty()): return true
			continue
		for enemy in units:
			if not alive(enemy) or enemy.side == side: continue
			if can_attack(u.id, enemy.id): return true
			if can_attack(u.id, enemy.id, true): return true
			if battle_phase == 3:
				for cell in charge_paths(u.id):
					if Hex.distance(cell, enemy.pos) <= melee_reach(u) and has_los(cell, enemy.pos): return true
	return false

func ai_action(id: String) -> Dictionary:
	var u = unit(id)
	if not can_activate(id): return {}
	if battle_phase == 0:
		if u.kind == "mage":
			for ally in units:
				if can_mend(id, ally.id): return mend(id, ally.id)
		if u.cohesion == 1: return rally(id)
		u.command_used = true; return {}
	if battle_phase == 1:
		if capture_enabled and u.pos == objective:
			u.movement_used = true; u.rotated = true; return {}
		var best = []; var distance = 9999
		var objective_holder = occupant(objective)
		var contest_objective = capture_enabled and (objective_holder.is_empty() or objective_holder.side != side)
		for cell in reachable_paths(id):
			for enemy in units:
				if not alive(enemy) or enemy.side == side: continue
				var score = Hex.distance(cell, enemy.pos) + (3 * Hex.distance(cell, objective) if contest_objective else 0)
				if score < distance: distance = score; best = reachable_paths(id)[cell]
		if not best.is_empty(): return move_confirmed(id, best.back(), Hex.direction(best[-2], best[-1]))
		u.movement_used = true; u.rotated = true; return {}
	for enemy in units:
		if not alive(enemy) or enemy.side == side: continue
		if can_attack(id, enemy.id, true): return attack(id, enemy.id, true)
		if can_attack(id, enemy.id): return attack(id, enemy.id)
		if battle_phase == 3:
			for cell in charge_paths(id):
				if not charge_preview(id, enemy.id, cell, true).is_empty(): return charge(id, enemy.id, cell, true)
				if not charge_preview(id, enemy.id, cell).is_empty(): return charge(id, enemy.id, cell)
	if battle_phase == 2: u.ranged_used = true
	else: u.melee_used = true
	return {}
