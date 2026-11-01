extends RefCounted
## Presentation only. No animation callback mutates combat or campaign state.
const REGISTRY = {"militia_mech": {"rig": "ivory_knight", "bounds": Rect2(-55, -145, 110, 158)}}
const STATES = ["idle", "walk", "attack", "hit", "guard", "guard_hit"]
const DIRECTIONS = ["E", "SE", "SW", "W", "NW", "NE"]
const FORWARD = [Vector2(1, 0), Vector2(0.67, 0.74), Vector2(-0.67, 0.74), Vector2(-1, 0), Vector2(-0.67, -0.74), Vector2(0.67, -0.74)]
const ATLAS = preload("res://assets/art/mechs/oathkeeper/parts-v2.png")
# One jointly authored atlas: six views per main part, one shared limb inventory.
# Explicit registration reflects the painted gutters; no separately generated views.
const COLUMN_EDGES = [0, 205, 400, 595, 780, 970, 1160]
const ROW_EDGES = [0, 172, 350, 502, 657, 788, 1058, 1355]
const DIRECTIONAL_ROWS = {"head": 0, "torso": 1, "pelvis": 2, "shoulder": 3, "foot": 4, "shield": 5}
const SHARED_COLUMNS = {"upper_arm": 0, "forearm": 1, "thigh": 2, "shin": 3, "hand": 4, "sword": 5}
static var _parts: Dictionary = {}

static func has_art(u: Dictionary) -> bool:
	return REGISTRY.has(u.get("definition", ""))

static func bounds(u: Dictionary) -> Rect2:
	if has_art(u):
		return REGISTRY[u.definition].bounds
	return Rect2(-42, -98 if u.get("kind") == "mech" else -72, 84, 147 if u.get("kind") == "mech" else 121)

static func context(u: Dictionary, event: Dictionary, progress: float) -> Dictionary:
	var result = {"state": "guard" if u.get("guard", false) else "idle", "progress": 1.0}
	var type = event.get("type", "")
	if type == "attack" and event.get("target") == u.get("id"):
		if progress >= 0.48:
			result.state = "guard_hit" if event.get("guarded", false) else "hit"
			result.progress = clampf((progress - 0.48) / 0.52, 0, 1)
	elif event.get("id") == u.get("id"):
		if type == "attack":
			result.state = "attack"
			result.progress = progress
		elif type == "move":
			result.state = "walk"
			result.progress = progress
		elif type == "guard":
			result.state = "guard"
			result.progress = progress
	return result

static func _smooth(p: float) -> float:
	p = clampf(p, 0, 1)
	return p * p * (3.0 - 2.0 * p)

static func pose(u: Dictionary, time: float, animation: Dictionary, reduced: bool = false) -> Dictionary:
	var state: String = animation.get("state", "guard" if u.get("guard", false) else "idle")
	var p = clampf(float(animation.get("progress", 1.0)), 0, 1)
	var facing = posmod(int(u.get("facing", 0)), 6)
	var forward: Vector2 = FORWARD[facing]
	var right = Vector2(-forward.y, forward.x * 0.22)
	var side = 1.0 if forward.x >= 0 else -1.0
	# Retain a small three-quarter spread in profile; do not stack both legs/arms.
	if facing in [0, 3]:
		right.x = -side * 0.24
	var defending = state == "guard" or state == "guard_hit"
	var brace = _smooth(p) if state == "guard" else (1.0 if defending else 0.0)
	var recoil = sin(p * PI) if state in ["hit", "guard_hit"] else 0.0
	var motion = 0.18 if reduced else 1.0
	var breathe = sin(time * TAU / 2.8) * 0.45 if state in ["idle", "guard"] and not reduced else 0.0
	var root = Vector2(-forward.x * recoil * (1.1 if defending else 3.5) * motion, brace * 2.0 + recoil * (1.4 if defending else 4.0) * motion + breathe)
	var pelvis = Vector2(0, -65) + root
	var chest = Vector2(0, -98) + root
	var attack_lift = 0.0
	var rest_rotation = -signf(right.x) * 0.42
	var sword_rotation = rest_rotation
	if state == "attack":
		if p < 0.30:
			attack_lift = _smooth(p / 0.30)
			sword_rotation = lerpf(rest_rotation, side * 2.7, attack_lift)
		elif p < 0.48:
			var strike = _smooth((p - 0.30) / 0.18)
			attack_lift = lerpf(1.0, 0.35, strike)
			sword_rotation = side * lerpf(2.7, -1.3, strike)
		else:
			var recovery = _smooth((p - 0.48) / 0.52)
			attack_lift = lerpf(0.35, 0.0, recovery)
			sword_rotation = lerpf(-side * 1.3, rest_rotation, recovery)
	var feet = []
	var knees = []
	var hips = []
	for sign_value in [-1.0, 1.0]:
		var hip = pelvis + right * sign_value * 12.0
		var foot = right * sign_value * (20.0 + brace * 2.0)
		if facing in [0, 3]:
			foot -= forward * sign_value * 4.0
		if state == "walk":
			# During the stance half-cycle, local foot displacement cancels root travel.
			var cycle = fposmod(float(animation.get("travel_px", time * 96.0)) / 32.0 + (0.5 if sign_value > 0 else 0.0), 1.0)
			var step = 8.0 - cycle * 32.0 if cycle < 0.5 else -8.0 + (cycle - 0.5) * 32.0
			foot += forward * step
			if cycle >= 0.5:
				foot.y -= sin((cycle - 0.5) * TAU) * (2.0 if reduced else 6.0)
		# Human-like forward knees with almost straight weight-bearing legs.
		# The previous inverse bend and short chain produced a hock-like silhouette.
		var knee = hip.lerp(foot + Vector2(0, -4), 0.44) + Vector2(forward.x * (2.0 + recoil * motion), 0)
		hips.append(hip)
		feet.append(foot)
		knees.append(knee)
	var shoulders = [chest - right * 29.0 + Vector2(0, -8), chest + right * 29.0 + Vector2(0, -8)]
	# Index 0 is anatomical left (shield); index 1 is anatomical right (sword).
	var hands = [shoulders[0] + Vector2(-side * 1.0, 44), shoulders[1] + Vector2(side * 2.0, 44)]
	hands[0] += forward * brace * 13.0 + Vector2(side * recoil * motion * 1.5, -brace * 17.0)
	hands[1] += Vector2(side * attack_lift * 15.0 * motion, -attack_lift * 29.0 * motion)
	if state == "walk" and not reduced:
		var counter = sin(float(animation.get("travel_px", time * 96.0)) / 32.0 * TAU) * 3.0
		hands[0] += forward * counter
		hands[1] -= forward * counter
	return {"state": state, "progress": p, "facing": facing, "forward": forward, "right": right,
		"root": root, "chest": chest, "pelvis": pelvis, "hips": hips, "knees": knees, "feet": feet,
		"shoulders": shoulders, "hands": hands, "sword_rotation": sword_rotation,
		"shield_rotation": -side * brace * 0.22, "near_arm": 1 if right.y >= 0 else 0,
		"guarded": defending, "recoil": recoil * motion}

static func _joint(a: Vector2, b: Vector2, upper: float, lower: float, bend: float) -> Vector2:
	var delta = b - a
	var distance = clampf(delta.length(), 0.001, upper + lower - 0.01)
	var axis = delta.normalized()
	var along = (upper * upper - lower * lower + distance * distance) / (2.0 * distance)
	var height = sqrt(maxf(0.0, upper * upper - along * along))
	return a + axis * along + axis.orthogonal() * height * bend

static func _prepare(facing: int):
	if _parts.has(facing):
		return
	var image = ATLAS.get_image()
	var regions = {}
	var factor = Vector2(image.get_size()) / Vector2(1160, 1355)
	var names = DIRECTIONAL_ROWS.keys() + SHARED_COLUMNS.keys()
	for part in names:
		var column: int = facing if DIRECTIONAL_ROWS.has(part) else SHARED_COLUMNS[part]
		var row: int = DIRECTIONAL_ROWS[part] if DIRECTIONAL_ROWS.has(part) else 6
		var start = Vector2(COLUMN_EDGES[column], ROW_EDGES[row])
		var end = Vector2(COLUMN_EDGES[column + 1], ROW_EDGES[row + 1])
		var region = Rect2i(start * factor, (end - start) * factor)
		var used = _solid_bounds(image, region)
		# The shared studies include material beyond their final joint. Register
		# only the requested segment, excluding the duplicate wrist/ankle/limb stub.
		if part == "upper_arm":
			used.size.y = roundi(used.size.y * 0.76)
		elif part == "forearm":
			used.size.y = roundi(used.size.y * 0.82)
		elif part == "thigh":
			used.size.y = roundi(used.size.y * 0.84)
		elif part == "shin":
			used.size.y = roundi(used.size.y * 0.82)
		regions[part] = Rect2(Vector2(region.position + used.position), Vector2(used.size))
	_parts[facing] = regions

static func _solid_bounds(image: Image, region: Rect2i) -> Rect2i:
	# Imagegen's near-transparent fringe is not a registration mark. Godot's
	# get_used_rect() includes that noise and was halving the visible limb widths.
	var mask = BitMap.new()
	mask.create_from_image_alpha(image.get_region(region), 0.5)
	var outlines = mask.opaque_to_polygons(Rect2i(Vector2i.ZERO, region.size), 0.25)
	var best_area = 0.0
	var best = Rect2()
	for outline in outlines:
		var area = 0.0
		var rect = Rect2(outline[0], Vector2.ZERO)
		for i in outline.size():
			area += outline[i].cross(outline[(i + 1) % outline.size()])
			rect = rect.expand(outline[i])
		area = absf(area)
		if area > best_area:
			best_area = area
			best = rect
	if best_area == 0.0:
		return Rect2i(Vector2i.ZERO, region.size)
	var start = (Vector2i(best.position.floor()) - Vector2i(1, 1)).max(Vector2i.ZERO)
	var end = (Vector2i(best.end.ceil()) + Vector2i(1, 1)).min(region.size)
	return Rect2i(start, end - start)

static func _part(c: CanvasItem, facing: int, name: String, center: Vector2, size: Vector2, rotation: float = 0.0, tint: Color = Color.WHITE):
	c.draw_set_transform(center, rotation)
	c.draw_texture_rect_region(ATLAS, Rect2(-size * 0.5, size), _parts[facing][name], tint)

static func _segment(c: CanvasItem, f: int, name: String, a: Vector2, b: Vector2, width: float, tint: Color):
	var delta = b - a
	# Slight overlap at both ends covers joint surfaces during bends.
	_part(c, f, name, (a + b) * 0.5, Vector2(width, delta.length() + 5), delta.angle() - PI / 2.0, tint)

static func _arm(c: CanvasItem, p: Dictionary, index: int, origin: Vector2):
	var f: int = p.facing
	var a: Vector2 = origin + p.shoulders[index]
	var b: Vector2 = origin + p.hands[index]
	var elbow = a.lerp(b, 0.48) + Vector2(-p.forward.x * 2.0, 0)
	var tint = Color("d4d9dd") if index != p.near_arm else Color.WHITE
	_segment(c, f, "upper_arm", a, elbow, 16, tint)
	_segment(c, f, "forearm", elbow, b, 17, tint)
	_part(c, f, "shoulder", a + Vector2(0, 1), Vector2(26, 27), 0, tint)
	_part(c, f, "hand", b, Vector2(10, 12), 0, tint)
	if index == 1:
		var rotation: float = p.sword_rotation
		var grip = Vector2(0, 32.5).rotated(rotation)
		_part(c, f, "sword", b + grip, Vector2(12, 78), rotation, tint)
	else:
		_part(c, f, "shield", b + Vector2(0, -2), Vector2(32, 72), p.shield_rotation, tint)

static func draw(c: CanvasItem, u: Dictionary, origin: Vector2, time: float, animation: Dictionary, reduced: bool):
	var p = pose(u, time, animation, reduced)
	var f: int = p.facing
	_prepare(f)
	var far_arm: int = 1 - p.near_arm
	_arm(c, p, far_arm, origin)
	for i in [far_arm, p.near_arm]:
		var tint = Color("d4d9dd") if i == far_arm else Color.WHITE
		_segment(c, f, "thigh", origin + p.hips[i], origin + p.knees[i], 21, tint)
		_segment(c, f, "shin", origin + p.knees[i], origin + p.feet[i] + Vector2(0, -4), 20, tint)
		_part(c, f, "foot", origin + p.feet[i] + Vector2(p.forward.x * 3, -3), Vector2(23, 14), 0, tint)
	# Continuous mechanical abdomen behind the separate breastplate and hip shell.
	c.draw_set_transform(origin)
	c.draw_line(p.pelvis, p.chest + Vector2(0, 11), Color("252c30"), 12, true)
	for offset in [-5.0, 5.0]:
		var a: Vector2 = p.pelvis + Vector2(offset, -2)
		var b: Vector2 = p.chest + Vector2(offset * 1.4, 13)
		c.draw_line(a, b, Color("5b6261"), 3, true)
	_part(c, f, "pelvis", origin + p.pelvis, Vector2(32, 25))
	_part(c, f, "torso", origin + p.chest, Vector2(43 if f not in [0, 3] else 32, 39))
	_part(c, f, "head", origin + p.chest + Vector2(p.forward.x * 3, -27), Vector2(15, 23))
	_arm(c, p, p.near_arm, origin)
	c.draw_set_transform(Vector2.ZERO)
