extends RefCounted
## Authoritative combat. No scene, animation, timer, or reward code belongs here.
const Hex = preload("res://scripts/hex_grid.gd")
const DEFINITIONS = {
	"militia_mech": {"name": "Oathkeeper", "role": "Militia walker", "kind": "mech", "hp": 30, "attack": 9, "armor": 2, "move": 3, "range": 1},
	"greyford_blades": {"name": "Greyford Blades", "role": "Sword formation", "kind": "sword", "hp": 12, "attack": 6, "armor": 1, "move": 3, "range": 1},
	"roadwardens": {"name": "Roadwardens", "role": "Gunner formation", "kind": "gunner", "hp": 12, "attack": 6, "armor": 0, "move": 2, "range": 4},
	"raiders": {"name": "Ashen Raiders", "role": "Fast sword formation", "kind": "sword", "hp": 12, "attack": 4, "armor": 0, "move": 3, "range": 1},
	"deserters": {"name": "Blackpowder Deserters", "role": "Short-range gunners", "kind": "gunner", "hp": 10, "attack": 4, "armor": 0, "move": 2, "range": 3},
	"scrap_walker": {"name": "Cinderjack", "role": "Scavenged walker", "kind": "mech", "hp": 20, "attack": 6, "armor": 1, "move": 2, "range": 1}
}
const COMBINED = {
	"pikemen": {"name": "March Pikes", "role": "Pike formation", "kind": "pike", "hp": 16, "attack": 6, "armor": 1, "move": 2, "range": 1},
	"cavalry": {"name": "Road Lancers", "role": "Cavalry formation", "kind": "cavalry", "hp": 16, "attack": 7, "armor": 1, "move": 4, "range": 1},
	"cannon": {"name": "Guild Cannon", "role": "Field artillery", "kind": "cannon", "hp": 12, "attack": 8, "armor": 0, "move": 2, "range": 5},
	"mages": {"name": "Lantern Circle", "role": "Five-mage circle", "kind": "mage", "hp": 10, "attack": 5, "armor": 0, "move": 3, "range": 3}
}
var units = []
var width = 8
var height = 8
var combined = false
var cover = {}
var terrain = {}
var objective = Vector2i.ZERO
var objective_progress = 0
var objective_name = "Route every enemy. Oathkeeper must survive."
var deployment = {}
var cap = 10
var board = Hex.cells(8, 8)
var blocked = [Hex.cell(3, 3), Hex.cell(4, 3), Hex.cell(3, 4)]
var side = 0
var round_number = 1
var active_id = ""
var outcome = ""
var sequence = 0

func _init(encounter: Dictionary = {}):
	if not encounter.is_empty():
		_setup_combined(encounter)
		return
	var setup = [["hero", "militia_mech", 0, 1, 5], ["blades", "greyford_blades", 0, 0, 4], ["gunners", "roadwardens", 0, 1, 6], ["raiders", "raiders", 1, 5, 3], ["deserters", "deserters", 1, 6, 2], ["walker", "scrap_walker", 1, 6, 5]]
	for item in setup:
		var u = DEFINITIONS[item[1]].duplicate(true)
		u.merge({"id": item[0], "definition": item[1], "side": item[2], "pos": Hex.cell(item[3], item[4]), "max_hp": u.hp, "facing": 0 if item[2] == 0 else 3, "moved": false, "acted": false, "guard": false, "rotated": false, "cohesion": 0})
		units.append(u)

func unit(id: String) -> Dictionary:
	for u in units:
		if u.id == id:
			return u
	return {}

func alive(u: Dictionary) -> bool:
	return not u.is_empty() and u.hp > 0 and u.cohesion < 2

func occupant(pos: Vector2i) -> Dictionary:
	for u in units:
		if alive(u) and u.pos == pos:
			return u
	return {}

func can_activate(id: String) -> bool:
	var u = unit(id)
	return outcome.is_empty() and alive(u) and u.side == side and not u.acted and (active_id.is_empty() or active_id == id)

func reachable_paths(id: String) -> Dictionary:
	var u = unit(id)
	if not can_activate(id) or u.moved:
		return {}
	var occupied = blocked.duplicate()
	for other in units:
		if alive(other) and other.id != id:
			occupied.append(other.pos)
	var paths = {u.pos: [u.pos]}
	var costs = {u.pos: 0}
	var frontier = [u.pos]
	while not frontier.is_empty():
		var current = frontier.pop_front()
		for delta in Hex.DIRECTIONS:
			var next = current + delta
			if next not in board or next in occupied:
				continue
			var cost = costs[current] + int(terrain.get(next, 1))
			if cost <= u.move and (not costs.has(next) or cost < costs[next]):
				costs[next] = cost
				paths[next] = paths[current] + [next]
				frontier.append(next)
	paths.erase(u.pos)
	return paths

func movement_path(id: String, goal: Vector2i) -> Array:
	return reachable_paths(id).get(goal, [])

func path_cost(path: Array) -> int:
	var cost = 0
	for p in path.slice(1):
		cost += int(terrain.get(p, 1))
	return cost

func move_unit(id: String, goal: Vector2i) -> Dictionary:
	var path = movement_path(id, goal)
	if path.is_empty():
		return {}
	var u = unit(id)
	u.facing = Hex.direction(path[-2], path[-1])
	u.pos = goal
	u.moved = true
	u["travelled"] = path.size() - 1
	active_id = id
	sequence += 1
	return {"type": "move", "id": id, "path": path, "sequence": sequence}

func has_los(a: Vector2i, b: Vector2i) -> bool:
	var samples = Hex.line(a, b)
	for i in range(1, samples.size() - 1):
		if samples[i] in blocked:
			return false
	return true

func can_attack(id: String, target_id: String, special: bool = false) -> bool:
	var a = unit(id)
	var b = unit(target_id)
	if not can_activate(id) or not alive(b) or a.side == b.side:
		return false
	if special and (not combined or a.get("cooldown", 0) > 0 or (a.kind in ["gunner", "cannon"] and a.moved)):
		return false
	var reach = a.range + (1 if special and a.kind == "gunner" else 0)
	return Hex.distance(a.pos, b.pos) <= reach and has_los(a.pos, b.pos)

func attack_preview(id: String, target_id: String, special: bool = false) -> Dictionary:
	if not can_attack(id, target_id, special):
		return {}
	var a = unit(id)
	var b = unit(target_id)
	# Facing index 0 points east: front sectors 0/5, side 1/4, rear 2/3.
	var sector = posmod(Hex.direction(b.pos, a.pos) - b.facing, 6)
	var flank = 3 if sector in [2, 3] else (2 if sector in [1, 4] else 0)
	var ratio = float(a.hp) / a.max_hp
	var scale = 1.0 if a.kind == "mech" or ratio >= 0.75 else (0.8 if ratio >= 0.5 else 0.6)
	var cover_value = cover_reduction(a, b)
	var armor = b.armor
	var bonus = 0
	if combined and a.kind == "mage":
		armor = 0
		cover_value = mini(1, cover_value)
	if special:
		bonus = 2
		if a.kind == "mech": armor = maxi(0, armor - 2)
		if a.kind == "cannon": cover_value = 0
		if a.kind == "cavalry": bonus = 4 if a.get("travelled", 0) >= 2 else 0
	var guard_value = guard_reduction(b, a)
	var damage = maxi(1, roundi(a.attack * scale) + flank + bonus - armor - guard_value - cover_value)
	var label = "REAR +3" if flank == 3 else ("FLANK +2" if flank == 2 else "FRONT")
	return {"damage": damage, "flank": flank, "label": label + (" · " + ability_name(a) if special else "") + (" · COVER −%d" % cover_value if cover_value > 0 else ""), "guarded": b.guard, "cover": cover_value, "armor": armor, "guard": guard_value, "special": special}

func attack(id: String, target_id: String, special: bool = false) -> Dictionary:
	var preview = attack_preview(id, target_id, special)
	if preview.is_empty():
		return {}
	var a = unit(id)
	var b = unit(target_id)
	var old_hp = b.hp
	b.hp = maxi(0, b.hp - preview.damage)
	if b.kind != "mech" and b.hp > 0:
		var threshold_crossed = old_hp * 2 >= b.max_hp and b.hp * 2 < b.max_hp
		if preview.flank > 0 or threshold_crossed:
			b.cohesion = mini(2, b.cohesion + 1)
	if special:
		a.cooldown = 3
	if combined and special and a.kind == "sword" and b.kind != "mech" and alive(b):
		b.cohesion = mini(2, b.cohesion + 1)
	a.acted = true
	active_id = ""
	sequence += 1
	_check_outcome()
	return {"type": "attack", "id": id, "target": target_id, "from": a.pos, "to": b.pos, "old_hp": old_hp, "damage": preview.damage, "label": preview.label, "guarded": preview.guarded, "ranged": a.range > 1, "removed": not alive(b), "routed": b.cohesion == 2, "sequence": sequence}

func guard_unit(id: String) -> Dictionary:
	if not can_activate(id):
		return {}
	var u = unit(id)
	u.guard = true
	u.acted = true
	active_id = ""
	sequence += 1
	return {"type": "guard", "id": id, "sequence": sequence}

func rotate_unit(id: String) -> bool:
	if not can_activate(id) or unit(id).rotated:
		return false
	var u = unit(id)
	u.facing = (u.facing + 1) % 6
	u.rotated = true
	return true

func end_side():
	if not outcome.is_empty():
		return
	active_id = ""
	side = 1 - side
	if side == 0:
		round_number += 1
	for u in units:
		if u.side == side:
			u.moved = false
			u.acted = false
			u.rotated = false
			u.guard = false
			if combined:
				u.cooldown = maxi(0, u.cooldown - 1)
	_check_objective()

func _check_outcome():
	if not alive(unit("hero")):
		outcome = "defeat"
		return
	var enemies = 0
	for u in units:
		if u.side == 1 and alive(u):
			enemies += 1
	if enemies == 0:
		outcome = "victory"

func ai_action(id: String) -> Dictionary:
	if not can_activate(id):
		return {}
	var u = unit(id)
	if combined and u.kind == "mage" and u.cooldown == 0:
		for ally in units:
			if can_mend(id, ally.id) and ally.max_hp - ally.hp >= 4:
				return mend(id, ally.id)
	var candidates = []
	for target in units:
		if target.side != side and alive(target): candidates.append(target)
	candidates.sort_custom(func(a, b): return a.hp < b.hp)
	var best_target = ""
	var best_value = -1
	var use_special = false
	for target in candidates:
		for special in [false, true] if combined else [false]:
			var preview = attack_preview(id, target.id, special)
			if not preview.is_empty():
				var value = mini(target.hp, preview.damage) + (10 if preview.damage >= target.hp else 0)
				if value > best_value:
					best_value = value
					best_target = target.id
					use_special = special
	if not best_target.is_empty(): return attack(id, best_target, use_special)
	if not u.moved:
		var paths = reachable_paths(id)
		var best_path = []
		var best_score = 99999
		for cell_pos in paths:
			for target in candidates:
				var distance = Hex.distance(cell_pos, target.pos)
				var score = distance * 10 + path_cost(paths[cell_pos])
				if combined:
					score -= int(cover.get(cell_pos, {}).get("value", 0)) * 2
					if distance <= u.range and has_los(cell_pos, target.pos): score -= 20
					if objective_progress > 0: score += Hex.distance(cell_pos, objective) * 2
				if score < best_score:
					best_score = score
					best_path = paths[cell_pos]
		if not best_path.is_empty(): return move_unit(id, best_path[-1])
	return guard_unit(id)

static func ability_name(u: Dictionary) -> String:
	return {"mech": "Breach", "sword": "Shield bash", "pike": "Thrust", "gunner": "Aimed shot", "cavalry": "Charge", "cannon": "Bombard", "mage": "Arc surge"}.get(u.get("kind", ""), "Strike")

static func ability_description(u: Dictionary) -> String:
	return {"mech": "+2 damage; ignore 2 armor.", "sword": "+2 damage; extra cohesion loss on surviving formations.", "pike": "+2 damage. Guard blocks 6 damage from cavalry.", "gunner": "+2 damage, +1 range. Cannot use after moving.", "cavalry": "+4 damage after moving at least 2 hexes; otherwise no bonus.", "cannon": "+2 damage; ignores cover. Cannot use after moving.", "mage": "+2 damage. All magic ignores armor and all but 1 cover. E: heal 4 within 2 hexes."}.get(u.get("kind", ""), "Select a ready unit.")

func guard_reduction(target: Dictionary, attacker: Dictionary) -> int:
	if not target.guard: return 0
	if not combined: return 2
	if target.kind == "pike" and attacker.kind == "cavalry": return 6
	return 3 if target.kind in ["mech", "sword", "pike"] else 2

func cover_reduction(attacker: Dictionary, target: Dictionary) -> int:
	if attacker.range <= 1 or not cover.has(target.pos): return 0
	var barrier = cover[target.pos]
	var sector = posmod(Hex.direction(target.pos, attacker.pos) - barrier.facing, 6)
	return barrier.value if sector in [0, 1, 5] else 0

func can_mend(id: String, target_id: String) -> bool:
	var a = unit(id)
	var b = unit(target_id)
	return combined and can_activate(id) and a.kind == "mage" and a.cooldown == 0 and alive(b) and a.side == b.side and b.hp < b.max_hp and Hex.distance(a.pos, b.pos) <= 2 and has_los(a.pos, b.pos)

func mend(id: String, target_id: String) -> Dictionary:
	if not can_mend(id, target_id): return {}
	var a = unit(id)
	var b = unit(target_id)
	var restored = mini(4, b.max_hp - b.hp)
	b.hp += restored
	a.cooldown = 3
	a.acted = true
	active_id = ""
	sequence += 1
	return {"type": "mend", "id": id, "target": target_id, "restored": restored, "sequence": sequence}

func _check_objective():
	if not combined or not outcome.is_empty(): return
	# One check per completed player side, after all player activations.
	if side == 1:
		var holder = occupant(objective)
		objective_progress = objective_progress + 1 if not holder.is_empty() and holder.side == 0 else 0
		if objective_progress >= 3: outcome = "victory"
	if round_number > 16: outcome = "defeat"

func _setup_combined(encounter: Dictionary):
	combined = true
	deployment = encounter.duplicate(true)
	cap = 15 if encounter.get("major", false) else 10
	width = 18 if cap == 15 else 14
	height = 12 if cap == 15 else 10
	board = Hex.cells(width, height)
	blocked = []
	for row in range(2, height - 2):
		if row not in [height / 2, height / 2 - 1]: blocked.append(Hex.cell(width / 2, row))
	for row in range(1, height - 1):
		for col in [width / 2 - 2, width / 2 + 2]:
			var p = Hex.cell(col, row)
			if row % 3 == 1: cover[p] = {"value": 2, "facing": 0 if col < width / 2 else 3}
			elif row % 3 == 2: terrain[p] = 2
	objective = Hex.cell(width / 2, height / 2)
	objective_name = "Hold the supply crossing for 3 turns, or route every enemy. Hero must survive."
	for team in 2:
		var roster = encounter.get("friendly" if team == 0 else "enemy", [])
		for i in mini(roster.size(), cap):
			var entry = roster[i]
			var definition = entry.get("definition", "greyford_blades")
			var u = DEFINITIONS.get(definition, COMBINED.get(definition, COMBINED.pikemen)).duplicate(true)
			u.merge({"id": entry.get("id", ("ally_" if team == 0 else "foe_") + str(i)), "definition": definition, "side": team, "pos": Hex.cell(1 + i / (height - 2) if team == 0 else width - 2 - i / (height - 2), 1 + i % (height - 2)), "max_hp": u.hp, "facing": 0 if team == 0 else 3, "moved": false, "acted": false, "guard": false, "rotated": false, "cohesion": 0, "cooldown": 0, "travelled": 0})
			if entry.has("stats"):
				for key in ["attack", "armor", "move", "range"]: u[key] = int(entry.stats[key])
				u.max_hp = int(entry.stats.hp)
			u.hp = clampi(int(entry.get("hp", u.max_hp)), 1, u.max_hp)
			u.name = entry.get("name", u.name)
			u["owned"] = entry.get("owned", false)
			units.append(u)
