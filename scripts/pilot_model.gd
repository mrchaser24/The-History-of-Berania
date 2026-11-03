extends RefCounted
## Personal pilots, formation experience and owned-frame assignments are independent.
const Shop = preload("res://scripts/workshop_model.gd")
const COMPANIONS = {
	"mira": {"name": "Captain Mira Vale", "place": "greyford", "title": "Protect the outlying farms", "frame": "bulwark", "frame_name": "Greyford Bastion", "requires": "headquarters"},
	"tomas": {"name": "Tomas Flint", "place": "stonebridge", "title": "Recover the foundry convoy", "frame": "gunner", "frame_name": "Foundry Cinderjack", "requires": "headquarters"},
	"ilyan": {"name": "Ilyan Reed", "place": "millhaven", "title": "Break the frontier blockade", "frame": "scout", "frame_name": "Frontier Kestrel", "requires": "investigation"},
	"sera": {"name": "Sera Vey", "place": "stonebridge", "title": "Recover the imperial research folio", "frame": "lancer", "frame_name": "Lantern Lance", "requires": "investigation"},
	"dorian": {"name": "Dorian Ash", "place": "emberwatch", "title": "Extract the hunted deserters", "frame": "gunner", "frame_name": "Ashwatch Gunner", "requires": "bargain"}
}

static func defaults() -> Dictionary:
	return {"version": 1, "pilots": [{"id": "protagonist", "name": "Alaric", "frame": "frame_1", "xp": 0, "injury": 0, "deploy": true}], "completed": []}

static func pilot(state: Dictionary, id: String) -> Dictionary:
	for p in state.pilots:
		if p.id == id: return p
	return {}

static func assigned(state: Dictionary, frame_id: String) -> String:
	for p in state.pilots:
		if p.frame == frame_id: return p.id
	return ""

static func level(xp: int) -> int:
	return mini(3, xp / 12)

static func stats(workshop: Dictionary, p: Dictionary) -> Dictionary:
	var result = Shop.stats(workshop, Shop.frame(workshop, p.frame))
	result.attack += level(p.xp)
	return result

static func assign(state: Dictionary, workshop: Dictionary, id: String, frame_id: String) -> String:
	var p = pilot(state, id)
	if p.is_empty(): return "Unknown pilot."
	if frame_id.is_empty() and id != "protagonist": p.frame = ""; p.deploy = false; return "Pilot moved to reserve."
	var f = Shop.frame(workshop, frame_id)
	if f.is_empty() or f.hp < 1: return "Choose a usable owned frame."
	var other = assigned(state, frame_id)
	if not other.is_empty() and other != id: return "That frame already has a pilot. Unassign that pilot first."
	p.frame = frame_id
	if id == "protagonist": workshop.pilot_frame = frame_id
	return "Pilot assigned. Each personal mech counts toward the deployment cap."

static func roster(state: Dictionary, workshop: Dictionary) -> Array:
	var result = []
	for p in state.pilots:
		if not p.deploy or p.injury > 0 or p.frame.is_empty(): continue
		var f = Shop.frame(workshop, p.frame)
		if f.is_empty() or f.hp <= 0: continue
		result.append({"id": "hero" if p.id == "protagonist" else "pilot_" + p.id, "pilot_id": p.id, "frame_id": f.id, "definition": Shop.CHASSIS[f.chassis].definition, "name": p.name + " · " + f.name, "hp": f.hp, "stats": stats(workshop, p), "owned": true})
	return result

static func recruit(state: Dictionary, workshop: Dictionary, id: String) -> bool:
	if id not in COMPANIONS or not pilot(state, id).is_empty() or state.pilots.size() >= 7 or workshop.frames.size() >= 256 or workshop.items.size() > 1022: return false
	var info = COMPANIONS[id]
	var frame_id = Shop.add_frame(workshop, info.frame, info.frame_name)
	state.pilots.append({"id": id, "name": info.name, "frame": frame_id, "xp": 0, "injury": 0, "deploy": false})
	state.completed.append(id)
	return true

static func award(state: Dictionary, workshop: Dictionary, formations: Array, battle, victory: bool):
	for entry in battle.deployment.friendly:
		var u = battle.unit(entry.id)
		if u.is_empty(): continue
		if entry.has("pilot_id"):
			var p = pilot(state, entry.pilot_id)
			var f = Shop.frame(workshop, entry.frame_id)
			if p.is_empty() or f.is_empty(): continue
			f.hp = maxi(1, int(u.hp))
			p.xp = mini(1000000, p.xp + (4 if victory else 1))
			if not battle.alive(u) and p.id != "protagonist": p.injury = 2
		else:
			for formation in formations:
				if formation.id != entry.id: continue
				formation.hp = maxi(1, int(u.hp)) if battle.alive(u) else 1
				formation["xp"] = mini(1000000, int(formation.get("xp", 0)) + (4 if victory else 1))

static func formation_stats(definition: Dictionary, formation: Dictionary) -> Dictionary:
	return {"hp": definition.hp, "attack": definition.attack + int(formation.get("rank", 0)), "armor": definition.armor, "move": definition.move, "range": definition.range}

static func valid(state, workshop: Dictionary) -> bool:
	if not state is Dictionary or state.get("version") != 1 or not state.get("pilots") is Array or state.pilots.is_empty() or state.pilots.size() > 7 or not state.get("completed") is Array: return false
	var ids = []; var frames = []
	for p in state.pilots:
		if not p is Dictionary or p.get("id") not in ["protagonist", "princess", "mira", "tomas", "ilyan", "sera", "dorian"] or p.id in ids: return false
		if not p.get("name") is String or p.name.is_empty() or p.name.length() > 50 or not p.get("frame") is String or not p.get("deploy") is bool: return false
		if not Shop.integer(p.get("xp"), 0, 1000000) or not Shop.integer(p.get("injury"), 0, 2): return false
		if not p.frame.is_empty():
			if p.frame in frames or Shop.frame(workshop, p.frame).is_empty(): return false
			frames.append(p.frame)
		elif p.deploy: return false
		ids.append(p.id)
	for id in ids:
		if id in COMPANIONS and id not in state.completed: return false
	if state.pilots[0].id != "protagonist" or not state.pilots[0].deploy or state.pilots[0].injury != 0 or state.pilots[0].frame != workshop.pilot_frame: return false
	var seen = []
	for id in state.completed:
		if id not in COMPANIONS or id not in ids or id in seen: return false
		seen.append(id)
	return true
