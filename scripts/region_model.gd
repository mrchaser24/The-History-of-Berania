extends RefCounted
## Bounded regional state. JSON-native data; ticks occur only on committed travel turns.
const Hex = preload("res://scripts/hex_grid.gd")
const Battle = preload("res://scripts/battle_model.gd")
const SETTLEMENTS = [
	{"id": "greyford", "name": "Greyford", "cell": [3, 2], "kind": "Village · friendly workshop", "friendly": true},
	{"id": "stonebridge", "name": "Stonebridge", "cell": [6, 2], "kind": "Market · independent house envoy", "friendly": true},
	{"id": "millhaven", "name": "Millhaven", "cell": [1, 5], "kind": "Village · grain guild", "friendly": true},
	{"id": "emberwatch", "name": "Emberwatch", "cell": [6, 5], "kind": "Imperial fort · hostile", "friendly": false}
]
const PRICES = {"greyford_blades": 8, "roadwardens": 10, "pikemen": 10, "cavalry": 16, "cannon": 20, "mages": 18}

static func pos(point: Array) -> Vector2i:
	return Vector2i(int(point[0]), int(point[1]))

static func point(p: Vector2i) -> Array:
	return [p.x, p.y]

static func defaults() -> Dictionary:
	return normalized({"ticks": 0, "next_id": 1, "formations": [], "selected": [], "parties": [
		{"id": "caravan", "kind": "Caravan", "cell": [3, 2], "goal": [6, 2]},
		{"id": "patrol", "kind": "Patrol", "cell": [2, 1], "goal": [5, 1]},
		{"id": "bandits", "kind": "Bandits", "cell": [6, 4], "goal": [1, 5]},
		{"id": "envoy", "kind": "Noble retinue", "cell": [6, 2], "goal": [1, 5]},
		{"id": "army", "kind": "Imperial army", "cell": [6, 5], "goal": [7, 1]}
	], "incidents": [], "resolved": [], "allied": false, "relation": 0, "job": "", "job_ready": 0, "battle_ready": 0, "deliveries": 0, "pending": {}, "last_result": "", "last_reward": 0})

static func settlement(p: Vector2i) -> Dictionary:
	for place in SETTLEMENTS:
		if pos(place.cell) == p: return place
	return {}

static func tick(state: Dictionary, board: Array, camp_cleared: bool = false) -> Array:
	state.ticks += 1
	var reports = []
	for party in state.parties:
		if camp_cleared and party.id == "bandits": continue
		var pinned = false
		for incident in state.incidents:
			if incident.kind == "caravan" and party.id == "caravan": pinned = true
		if pinned: continue
		if party.id == "patrol" and not state.incidents.is_empty(): party.goal = state.incidents[0].cell.duplicate()
		if party.id == "bandits" and party.get("strength", 3) < 2:
			party.goal = [5, 3]
		var start = pos(party.cell)
		var path = Hex.path(start, pos(party.goal), board, [])
		if path.size() > 1: party.cell = point(path[1])
		if party.cell == party.goal:
			if party.id == "caravan": reports.append({"cell": party.cell, "text": "The merchant caravan completed a delivery; its next route has begun."})
			if party.id == "envoy": reports.append({"cell": party.cell, "text": "The independent envoy reached a scheduled meeting. Speak to the retinue for local terms."})
			if party.id == "bandits" and party.get("strength", 3) < 3: party.strength += 1
			if party.id == "patrol":
				for incident in state.incidents.duplicate():
					if incident.cell == party.cell and state.ticks > incident.expires - 2:
						state.incidents.erase(incident)
						reports.append({"cell": party.cell, "text": "Greyford's patrol relieved an attack after its announced response window. No player battle or reward was applied."})
			var destination = [3, 2] if party.id == "caravan" else ([6, 5] if party.id == "army" else [2, 1])
			if destination == party.goal:
				destination = [6, 2] if party.id == "caravan" else ([7, 1] if party.id == "army" else [1, 5])
			party.goal = destination
	for incident in state.incidents.duplicate():
		if state.ticks > incident.expires:
			state.incidents.erase(incident)
			reports.append({"cell": incident.cell, "text": incident.name + " was lost. The attackers withdrew."})
	if state.ticks % 4 == 1 and not (camp_cleared and state.ticks % 8 == 1):
		var village = state.ticks % 8 == 1
		var cell = [1, 5] if village else state.parties[0].cell.duplicate()
		state.incidents.append({"id": "incident_" + str(state.ticks), "name": "Millhaven under attack" if village else "Caravan ambushed", "cell": cell, "expires": state.ticks + 4, "kind": "village" if village else "caravan"})
	return reports

static func roster(state: Dictionary, workshop: Dictionary, selected: Array, allied: bool = true, major: bool = false) -> Array:
	var Shop = load("res://scripts/workshop_model.gd")
	var hero = {"id": "hero", "definition": "militia_mech", "name": Shop.frame(workshop).name, "hp": Shop.frame(workshop).hp, "stats": Shop.stats(workshop), "owned": true}
	var result = [hero]
	var limit = 15 if major else 10
	for id in selected:
		for f in state.formations:
			if f.id == id and result.size() < limit: result.append(f.duplicate(true))
	if allied:
		for i in (2 if state.allied else 0):
			if result.size() < limit: result.append({"id": "support_" + str(i), "definition": "pikemen", "name": "House road guard", "owned": false})
	return result

static func enemies(count: int) -> Array:
	var roles = ["raiders", "deserters", "pikemen", "cavalry", "mages", "cannon", "raiders", "deserters", "pikemen", "cavalry", "mages", "cannon", "raiders", "deserters", "pikemen"]
	var result = []
	for i in mini(count, 15): result.append({"id": "foe_" + str(i), "definition": roles[i]})
	return result

static func valid(state) -> bool:
	if not state is Dictionary: return false
	for key in ["ticks", "next_id", "battle_ready", "job_ready", "deliveries", "last_reward"]:
		if not _integer(state.get(key), 0, 1000000000): return false
	if state.has("support_started") and not state.support_started is bool: return false
	if state.has("last_trust") and not _integer(state.last_trust, 0, 2): return false
	if state.next_id < 1 or not _integer(state.get("relation"), -100, 100) or not state.get("allied") is bool: return false
	if state.get("job") not in ["", "grain"] or not state.get("last_result") is String: return false
	for key in ["formations", "selected", "parties", "incidents", "resolved"]:
		if not state.get(key) is Array: return false
	if state.formations.size() > 64 or state.selected.size() > 14 or state.parties.size() != 5 or state.incidents.size() > 3 or state.resolved.size() > 10000: return false
	var ids = []
	for f in state.formations:
		if not f is Dictionary or not f.get("id") is String or f.id in ids or f.get("definition") not in PRICES or f.get("owned") != true: return false
		var definition = Battle.DEFINITIONS.get(f.definition, Battle.COMBINED.get(f.definition))
		if not _integer(f.get("xp", 0), 0, 1000000) or not _integer(f.get("rank", 0), 0, 2): return false
		if not _integer(f.get("hp"), 1, definition.hp): return false
		if not f.id.begins_with("formation_") or not f.id.trim_prefix("formation_").is_valid_int() or int(f.id.trim_prefix("formation_")) < 1 or int(f.id.trim_prefix("formation_")) >= state.next_id: return false
		ids.append(f.id)
	var selected = []
	for id in state.selected:
		if id not in ids or id in selected: return false
		selected.append(id)
	ids = []
	for party in state.parties:
		if not party is Dictionary or party.get("id") not in ["caravan", "patrol", "bandits", "envoy", "army"] or party.id in ids or not party.get("kind") is String or not _cell(party.get("cell")) or not _cell(party.get("goal")): return false
		if party.has("strength") and not _integer(party.strength, 1, 10): return false
		if party.has("ready") and not _integer(party.ready, 0, 1000000000): return false
		if party.has("owner") and not party.owner is String: return false
		if party.has("job") and not party.job is String: return false
		ids.append(party.id)
	ids = []
	for incident in state.incidents:
		if not incident is Dictionary or not incident.get("id") is String or incident.id in ids or not incident.get("name") is String or incident.get("kind") not in ["village", "caravan"] or not _cell(incident.get("cell")) or not _integer(incident.get("expires"), state.ticks, state.ticks + 4): return false
		ids.append(incident.id)
	ids = []
	for id in state.resolved:
		if not id is String or id in ids: return false
		ids.append(id)
	if not state.get("pending") is Dictionary: return false
	if not state.pending.is_empty():
		var p = state.pending
		if not p.get("id") is String or p.id in state.resolved or not p.get("name") is String or p.get("kind") not in ["guild", "village", "caravan", "raid", "camp", "merchant_rescue", "funded_rescue", "tournament", "companion", "investigation", "elite", "prison", "siege", "final", "obligation", "contact", "house_support"] or not p.get("frame_id") is String or not p.get("major") is bool or not _integer(p.get("reward"), 0, 100): return false
		if p.has("target") and (not p.target is String or not _integer(p.get("fee"), 0, 5)): return false
		var cap = 15 if p.major else 10
		var all_ids = []
		for key in ["friendly", "enemy"]:
			if not p.get(key) is Array or p[key].is_empty() or p[key].size() > cap: return false
			ids = []
			var positions = 0
			for u in p[key]:
				if not u is Dictionary or not u.get("id") is String or u.id in all_ids or u.get("definition") not in Battle.DEFINITIONS and u.get("definition") not in Battle.COMBINED: return false
				ids.append(u.id)
				all_ids.append(u.id)
				if u.has("name") and (not u.name is String or u.name.length() > 80): return false
				if u.has("owned") and not u.owned is bool: return false
				if u.has("stats"):
					if not u.stats is Dictionary: return false
					for stat in ["hp", "attack", "armor", "move", "range"]:
						if not _integer(u.stats.get(stat), 0 if stat == "armor" else 1, 100): return false
				if u.has("hp") and not _integer(u.hp, 1, 100): return false
		if p.friendly[0].id != "hero" or Battle.DEFINITIONS.get(p.friendly[0].definition, Battle.COMBINED.get(p.friendly[0].definition, {})).get("kind") != "mech" or p.friendly[0].get("stats", {}).is_empty(): return false
	return true

static func normalized(state: Dictionary) -> Dictionary:
	# JSON parses numbers as floats; normalize recursively to keep snapshot equality.
	var result = state.duplicate(true)
	for key in result:
		result[key] = _normalize(result[key])
	if result.has("parties"):
		var owners = {"caravan": "merchant", "patrol": "greyford", "bandits": "camp", "envoy": "asterfell", "army": "imperial"}
		var jobs = {"caravan": "deliver goods", "patrol": "respond to raids", "bandits": "raid and recover", "envoy": "attend meetings", "army": "guard imperial roads"}
		for party in result.parties:
			if not party.has("owner"): party.owner = owners[party.id]
			if not party.has("job"): party.job = jobs[party.id]
			if not party.has("strength"): party.strength = 6 if party.id == "army" else 3
			if not party.has("ready"): party.ready = 0
	return result

static func _normalize(value):
	if value is float: return int(value)
	if value is Array:
		var result = []
		for item in value: result.append(_normalize(item))
		return result
	if value is Dictionary:
		var result = {}
		for key in value: result[key] = _normalize(value[key])
		return result
	return value

static func _integer(value, low: int, high: int) -> bool:
	return (value is float or value is int) and value == int(value) and value >= low and value <= high

static func _cell(value) -> bool:
	return value is Array and value.size() == 2 and _integer(value[0], -3, 9) and _integer(value[1], 0, 6) and pos(value) in Hex.cells(10, 7)
