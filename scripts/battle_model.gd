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
var units = []
var board = Hex.cells(8, 8)
var blocked = [Hex.cell(3, 3), Hex.cell(4, 3), Hex.cell(3, 4)]
var side = 0
var round_number = 1
var active_id = ""
var outcome = ""
var sequence = 0

func _init():
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

func movement_path(id: String, goal: Vector2i) -> Array:
	var u = unit(id)
	if not can_activate(id) or u.moved:
		return []
	var obstacles = blocked.duplicate()
	for other in units:
		if alive(other) and other.id != id:
			obstacles.append(other.pos)
	var result = Hex.path(u.pos, goal, board, obstacles)
	if result.size() <= 1 or result.size() - 1 > u.move:
		return []
	return result

func move_unit(id: String, goal: Vector2i) -> Dictionary:
	var path = movement_path(id, goal)
	if path.is_empty():
		return {}
	var u = unit(id)
	u.facing = Hex.direction(path[-2], path[-1])
	u.pos = goal
	u.moved = true
	active_id = id
	sequence += 1
	return {"type": "move", "id": id, "path": path, "sequence": sequence}

func has_los(a: Vector2i, b: Vector2i) -> bool:
	var samples = Hex.line(a, b)
	for i in range(1, samples.size() - 1):
		if samples[i] in blocked:
			return false
	return true

func can_attack(id: String, target_id: String) -> bool:
	var a = unit(id)
	var b = unit(target_id)
	return can_activate(id) and alive(b) and a.side != b.side and Hex.distance(a.pos, b.pos) <= a.range and has_los(a.pos, b.pos)

func attack_preview(id: String, target_id: String) -> Dictionary:
	if not can_attack(id, target_id):
		return {}
	var a = unit(id)
	var b = unit(target_id)
	# Facing index 0 points east: front sectors 0/5, side 1/4, rear 2/3.
	var sector = posmod(Hex.direction(b.pos, a.pos) - b.facing, 6)
	var flank = 3 if sector in [2, 3] else (2 if sector in [1, 4] else 0)
	var ratio = float(a.hp) / a.max_hp
	var scale = 1.0 if a.kind == "mech" or ratio >= 0.75 else (0.8 if ratio >= 0.5 else 0.6)
	var damage = maxi(1, roundi(a.attack * scale) + flank - b.armor - (2 if b.guard else 0))
	var label = "REAR +3" if flank == 3 else ("FLANK +2" if flank == 2 else "FRONT")
	return {"damage": damage, "flank": flank, "label": label, "guarded": b.guard}

func attack(id: String, target_id: String) -> Dictionary:
	var preview = attack_preview(id, target_id)
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
	a.acted = true
	active_id = ""
	sequence += 1
	_check_outcome()
	return {"type": "attack", "id": id, "target": target_id, "from": a.pos, "to": b.pos, "old_hp": old_hp, "damage": preview.damage, "label": preview.label, "ranged": a.range > 1, "removed": not alive(b), "routed": b.cohesion == 2, "sequence": sequence}

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
	var candidates = []
	for target in units:
		if target.side != side and alive(target):
			candidates.append(target)
	candidates.sort_custom(func(a, b): return a.hp < b.hp)
	for target in candidates:
		if can_attack(id, target.id):
			return attack(id, target.id)
	var u = unit(id)
	if not u.moved:
		var best_path = []
		var best_score = 99999
		for cell_pos in board:
			var path = movement_path(id, cell_pos)
			if path.is_empty():
				continue
			for target in candidates:
				var score = Hex.distance(cell_pos, target.pos) * 10 + path.size()
				if score < best_score:
					best_score = score
					best_path = path
		if not best_path.is_empty():
			return move_unit(id, best_path[-1])
	return guard_unit(id)
