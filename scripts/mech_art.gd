extends RefCounted
## Complete illustrated 2D characters with fixed equipment and two facings.
const STATES = ["idle", "walk", "attack", "guard", "guard_hit", "hit"]
const DIRECTIONS = ["Right", "Left"]
const ROOT = "res://assets/art/mechs/oathkeeper/fullbody/v004/"
const MANIFEST = preload(ROOT + "manifest.json")
const ATLAS = preload(ROOT + "oathkeeper-illustrated-actions.png")
const REGISTRY = {"militia_mech": "oathkeeper"}

static func has_art(u: Dictionary) -> bool:
	return REGISTRY.has(u.get("definition", ""))

static func bounds(u: Dictionary) -> Rect2:
	if has_art(u):
		var r: Array = MANIFEST.data.bounds
		return Rect2(r[0] if faces_left(int(u.get("facing", 0))) else -r[0] - r[2], r[1], r[2], r[3])
	return Rect2(-42, -98, 84, 147)

static func faces_left(facing: int) -> bool:
	return posmod(facing, 6) in [2, 3, 4]

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

static func pose(u: Dictionary, time: float, animation: Dictionary, reduced: bool = false) -> Dictionary:
	var state: String = animation.get("state", "guard" if u.get("guard", false) else "idle")
	if not MANIFEST.data.states.has(state):
		state = "idle"
	var p = clampf(float(animation.get("progress", 1.0)), 0.0, 1.0)
	var guarded = state in ["guard", "guard_hit", "guard_hold", "guard_exit"]
	var canonical = false
	if reduced:
		state = "guard_hold" if guarded else "idle"
		canonical = true
	elif state == "guard" and p >= 1.0:
		state = "guard_hold"
	elif state == "guard_hit" and (p <= 0.0 or p >= 1.0):
		state = "guard_hold"
		canonical = true
	elif state == "guard_exit" and (p <= 0.0 or p >= 1.0):
		state = "idle" if p >= 1.0 else "guard_hold"
		canonical = true
	elif state in ["attack", "hit"] and (p <= 0.0 or p >= 1.0):
		state = "idle"
		canonical = true
	var spec: Dictionary = MANIFEST.data.states[state]
	var index = 0
	if not canonical:
		if spec.loop:
			var phase = fposmod(time, float(spec.duration)) / float(spec.duration)
			if state == "walk":
				var distance: float = animation.get("travel_px", time * float(MANIFEST.data.stride_px) / float(spec.duration))
				phase = fposmod(distance / float(MANIFEST.data.stride_px), 1.0)
			index = mini(spec.frames.size() - 1, floori(phase * spec.frames.size()))
		else:
			for i in spec.frames.size():
				if p + .0000001 >= float(spec.frames[i].progress):
					index = i
				else:
					break
	var frame: Dictionary = spec.frames[index]
	var r: Array = frame.region
	var a: Array = frame.anchor
	var left = faces_left(int(u.get("facing", 0)))
	var side = 1.0 if left else -1.0
	return {"state": state, "frame_index": index, "texture": ATLAS, "sample_time": frame.time,
		"region": Rect2(r[0], r[1], r[2], r[3]), "anchor": Vector2(a[0], a[1]),
		"flip_h": not left, "guarded": guarded, "chest": Vector2(0, -94),
		"hands": [Vector2(side * (12 if guarded else 35), -91 if guarded else -67)]}

static func preview_texture() -> AtlasTexture:
	var texture = AtlasTexture.new()
	texture.atlas = ATLAS
	var r: Array = MANIFEST.data.states.idle.frames[0].solid_bounds
	texture.region = Rect2(r[0], r[1], r[2], r[3])
	return texture

static func draw(c: CanvasItem, u: Dictionary, origin: Vector2, time: float, animation: Dictionary, reduced: bool):
	var p = pose(u, time, animation, reduced)
	var factor = float(MANIFEST.data.scale) * float(u.get("sprite_scale", 1.0))
	c.draw_set_transform(origin, 0, Vector2(-1 if p.flip_h else 1, 1) * factor)
	c.draw_texture_rect_region(ATLAS, Rect2(p.region.position - p.anchor, p.region.size), p.region)
	c.draw_set_transform(Vector2.ZERO)
