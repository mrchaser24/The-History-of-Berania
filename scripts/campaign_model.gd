extends RefCounted
const Hex = preload("res://scripts/hex_grid.gd")
const Region = preload("res://scripts/region_model.gd")
const Workshop = preload("res://scripts/workshop_model.gd")
var region = Region.defaults()
var board = Hex.cells(6, 5)
var player = Hex.cell(2, 2)
var village = Hex.cell(4, 2)
var patrol = Hex.cell(2, 1)
var bandit = Hex.cell(5, 3)
var turn = 1
var budget = 3
var gold = 0
var trust = 0
var explored = []
var visible = []
var quest = "travel"
var rewarded = false
var workshop = Workshop.defaults(18)
var mech_hp: int:
	get:
		return int(Workshop.frame(workshop).hp)
	set(value):
		Workshop.frame(workshop).hp = value
var pending_battle = false
var news = "Smoke rises beyond the eastern road. Greyford needs help."

func _init():
	update_visibility()

func max_hull() -> int:
	return int(Workshop.stats(workshop).hp)

func update_visibility():
	board = Hex.cells(10, 7) if rewarded else Hex.cells(6, 5)
	visible.clear()
	for p in board:
		if Hex.distance(player, p) <= 2:
			visible.append(p)
			if p not in explored:
				explored.append(p)

func path_to(goal: Vector2i) -> Array:
	if goal not in explored:
		return []
	var path = Hex.path(player, goal, board, [])
	if path.size() <= 1 or path.size() - 1 > budget:
		return []
	return path

func travel(goal: Vector2i) -> Array:
	if pending_battle: return []
	var path = path_to(goal)
	if path.is_empty():
		return []
	budget -= path.size() - 1
	player = goal
	update_visibility()
	return path

func end_turn() -> Dictionary:
	if pending_battle: return {}
	var before = {"patrol": patrol, "bandit": bandit}
	if rewarded:
		for party in region.parties: before[party.id] = Region.pos(party.cell)
	turn += 1
	budget = 3
	patrol = Hex.cell(3 if turn % 2 == 0 else 2, 1)
	if not rewarded:
		bandit = Hex.cell(4 if turn % 2 == 0 else 5, 3)
	if rewarded:
		var reports = Region.tick(region, board)
		for report in reports:
			if Region.pos(report.cell) in explored: news = report.text
	update_visibility()
	news = "Roadwardens patrol the northern road."
	if bandit in visible and not rewarded:
		news = "A raider banner has been sighted east of Greyford."
	if rewarded:
		news = "Regional turn %d. Caravans and armies have moved." % region.ticks
		for incident in region.incidents:
			if Region.pos(incident.cell) in visible: news = "%s · %d turns to help." % [incident.name, incident.expires - region.ticks + 1]
	return before

func finish_battle(outcome: String, remaining_hp: int) -> bool:
	if outcome not in ["victory", "defeat"] or not pending_battle: return false
	if rewarded:
		return false
	pending_battle = false
	if outcome == "victory":
		mech_hp = maxi(1, remaining_hp)
		if not rewarded:
			gold += 40
			trust += 1
			rewarded = true
			quest = "complete"
			news = "Greyford is safe. Regional roads, guild work and recruitment are now open."
			update_visibility()
			return true
	else:
		player = village
		mech_hp = max_hull()
		quest = "retry"
		news = "The villagers recovered your walker. Repairs are free; the defense can be retried."
	return false

func snapshot() -> Dictionary:
	var memory = []
	for p in explored:
		memory.append([p.x, p.y])
	return {"schema": 3, "build": "greyford-demo-0.3", "region": region.duplicate(true), "player": [player.x, player.y], "patrol": [patrol.x, patrol.y], "bandit": [bandit.x, bandit.y], "turn": turn, "budget": budget, "gold": gold, "trust": trust, "quest": quest, "rewarded": rewarded, "mech_hp": mech_hp, "pending_battle": pending_battle, "explored": memory, "news": news, "workshop": workshop.duplicate(true)}

static func valid_snapshot(data) -> bool:
	if not data is Dictionary or not Workshop.integer(data.get("schema"), 1, 3):
		return false
	if (data.schema == 1 and data.get("build") != "greyford-demo-0.1") or (data.schema == 2 and data.get("build") != "greyford-demo-0.2") or (data.schema == 3 and data.get("build") != "greyford-demo-0.3"):
		return false
	var max_saved_hull = 30
	if data.schema >= 2:
		if not Workshop.valid(data.get("workshop")):
			return false
		max_saved_hull = Workshop.stats(data.workshop).hp
		if data.get("mech_hp") != Workshop.frame(data.workshop).hp:
			return false
	if data.schema == 3:
		if not Region.valid(data.get("region")): return false
		if data.get("pending_battle") != (not data.region.pending.is_empty()) and data.get("rewarded") == true: return false
		if not data.region.pending.is_empty():
			if data.get("rewarded") != true: return false
			var p = data.region.pending
			if p.frame_id != Workshop.frame(data.workshop).id or Region.normalized(p.friendly[0].stats) != Workshop.stats(data.workshop) or p.friendly[0].get("hp") != data.mech_hp: return false
			for entry in p.friendly.slice(1):
				if entry.get("owned", false):
					var found = false
					for f in data.region.formations:
						if f == entry: found = true
					if not found: return false
	var legal_board = Hex.cells(10, 7) if data.schema == 3 and data.get("rewarded") == true else Hex.cells(6, 5)
	for key in ["player", "patrol", "bandit"]:
		if not data.get(key) is Array or data[key].size() != 2:
			return false
		for value in data[key]:
			if not (value is int or value is float) or value != int(value):
				return false
		if legal_board.find(Vector2i(int(data[key][0]), int(data[key][1]))) < 0:
			return false
	for key in ["turn", "budget", "gold", "trust", "mech_hp"]:
		if not (data.get(key) is int or data.get(key) is float) or data[key] != int(data[key]):
			return false
	if data.turn < 1 or data.budget < 0 or data.budget > 3 or data.gold < 0 or data.gold > 1000000000 or data.trust < 0 or data.mech_hp < 1 or data.mech_hp > max_saved_hull:
		return false
	if data.get("quest") not in ["travel", "retry", "complete"] or not data.get("rewarded") is bool or not data.get("pending_battle") is bool:
		return false
	if data.rewarded != (data.quest == "complete") or (data.rewarded and data.pending_battle and data.schema < 3):
		return false
	if not data.get("explored") is Array or not data.get("news") is String:
		return false
	var seen = []
	for point in data.explored:
		if not point is Array or point.size() != 2:
			return false
		for value in point:
			if not (value is int or value is float) or value != int(value):
				return false
		var p = Vector2i(int(point[0]), int(point[1]))
		if p not in legal_board or p in seen:
			return false
		seen.append(p)
	return true

func restore(data: Dictionary) -> bool:
	if not valid_snapshot(data):
		return false
	workshop = Workshop.normalized(data.workshop) if data.schema >= 2 else Workshop.defaults(int(data.mech_hp))
	region = Region.normalized(data.region) if data.schema == 3 else Region.defaults()
	player = Vector2i(int(data.player[0]), int(data.player[1]))
	patrol = Vector2i(int(data.patrol[0]), int(data.patrol[1]))
	bandit = Vector2i(int(data.bandit[0]), int(data.bandit[1]))
	turn = int(data.turn)
	budget = int(data.budget)
	gold = int(data.gold)
	trust = int(data.trust)
	quest = data.quest
	rewarded = data.rewarded
	mech_hp = int(data.mech_hp)
	pending_battle = data.pending_battle
	news = data.news
	explored.clear()
	for point in data.explored:
		explored.append(Vector2i(int(point[0]), int(point[1])))
	update_visibility()
	return true


func settlement() -> Dictionary:
	return Region.settlement(player) if rewarded else {}

func recruit(definition: String) -> String:
	if not rewarded or pending_battle or settlement().is_empty() or not settlement().friendly: return "Recruit at a friendly settlement."
	if definition not in Region.PRICES: return "Unknown formation."
	var cost = Region.PRICES[definition]
	if gold < cost or region.formations.size() >= 20: return "Insufficient gold or roster full (20 formations)."
	var data = load("res://scripts/battle_model.gd")
	var definition_data = data.DEFINITIONS.get(definition, data.COMBINED.get(definition))
	var id = "formation_" + str(region.next_id)
	region.next_id += 1
	region.formations.append({"id": id, "definition": definition, "hp": definition_data.hp, "owned": true})
	if region.selected.size() < 9: region.selected.append(id)
	gold -= cost
	return "Recruited %s for %d gold." % [definition_data.name, cost]

func regional_order(action: String) -> String:
	if not rewarded or pending_battle: return "Finish the village defense first."
	var place = settlement()
	if place.is_empty() or not place.friendly: return "Enter a friendly settlement for this service."
	if action == "guild":
		if region.job == "grain": return "Deliver 2 grain to Millhaven. Buy grain in the workshop market."
		if region.ticks < region.job_ready: return "The guild has no new delivery yet."
		region.job = "grain"
		return "Guild contract: deliver 2 grain to Millhaven for 16 gold and 1 trust. No time limit."
	if action == "deliver":
		if place.id != "millhaven" or region.job != "grain" or workshop.cargo.get("grain", 0) < 2: return "Millhaven needs an accepted contract and 2 carried grain."
		workshop.cargo.grain -= 2
		if workshop.cargo.grain == 0: workshop.cargo.erase("grain")
		region.job = ""
		region.deliveries += 1
		region.job_ready = region.ticks + 4
		gold += 16
		trust += 1
		return "Grain delivered. +16 gold, +1 trust. A new contract will open in 4 travel turns."
	if action == "diplomacy":
		if place.id != "stonebridge": return "The independent house envoy resides at Stonebridge."
		if region.allied: return "The road pact is active: two allied pikes may fill spare deployment slots."
		if trust < 2 or gold < 20: return "Road pact terms: 2 local trust and 20 gold. Gain two allied pike formations in regional encounters."
		gold -= 20
		region.allied = true
		region.relation = mini(100, region.relation + 1)
		return "Road pact signed. Two house formations support battles when slots remain. The noble stays with the regional army."
	if action == "replenish":
		var cost = 0
		var data = load("res://scripts/battle_model.gd")
		for f in region.formations:
			cost += data.DEFINITIONS.get(f.definition, data.COMBINED.get(f.definition)).hp - f.hp
		if gold < cost: return "Replenishment costs %d gold (1 per missing strength)." % cost
		gold -= cost
		for f in region.formations: f.hp = data.DEFINITIONS.get(f.definition, data.COMBINED.get(f.definition)).hp
		return "Formations replenished for %d gold." % cost
	if action == "repair":
		mech_hp = max_hull()
		return "Emergency workshop repairs complete, free of charge."
	return "No service selected."

func prepare_region(kind: String, id: String = "") -> Dictionary:
	if not rewarded or pending_battle: return {}
	var name = "Guild road clearance"
	var reward = 18
	var count = 3
	if kind in ["village", "caravan"]:
		var found = false
		for incident in region.incidents:
			if incident.id == id and Region.pos(incident.cell) == player:
				found = true
				name = incident.name
		if not found: return {}
		reward = 24
		count = 4
	elif kind == "raid":
		if settlement().get("id") != "emberwatch" or region.ticks < region.battle_ready: return {}
		name = "Raid imperial supply line"
		reward = 28
		count = 5
	elif kind == "guild":
		if settlement().is_empty() or not settlement().friendly or region.ticks < region.battle_ready: return {}
	else: return {}
	if id.is_empty(): id = kind + "_" + str(region.next_id)
	var friendly = Region.roster(region, workshop, region.selected)
	# Local loan formations keep zero-gold work playable; they are not owned troops.
	for i in 2:
		if friendly.size() < 10: friendly.append({"id": "loan_" + str(i), "definition": "greyford_blades" if i == 0 else "roadwardens", "name": "Local volunteer", "owned": false})
	return {"id": id, "kind": kind, "name": name, "major": false, "reward": reward, "frame_id": Workshop.frame(workshop).id, "friendly": friendly, "enemy": Region.enemies(count)}

func commit_region(preparation: Dictionary) -> bool:
	if not rewarded or pending_battle or preparation.is_empty(): return false
	if preparation != prepare_region(preparation.get("kind", ""), preparation.get("id", "")): return false
	var before = region.duplicate(true)
	region.pending = preparation.duplicate(true)
	if not Region.valid(region):
		region = before
		return false
	region.next_id += 1
	pending_battle = true
	return true

func finish_region(battle) -> bool:
	if region.pending.is_empty() or not pending_battle or battle.outcome not in ["victory", "defeat"]: return false
	if battle.deployment != region.pending: return false
	var encounter = region.pending.duplicate(true)
	mech_hp = maxi(1, int(battle.unit("hero").hp))
	for f in region.formations:
		var u = battle.unit(f.id)
		if not u.is_empty(): f.hp = maxi(1, int(u.hp)) if battle.alive(u) else 1
	region.last_reward = 0
	if battle.outcome == "victory":
		gold += encounter.reward
		trust += 1
		region.last_reward = encounter.reward
		if encounter.kind == "raid": region.relation = maxi(-100, region.relation - 1)
		if encounter.kind in ["guild", "raid"]: region.battle_ready = region.ticks + 2
		news = "%s won. +%d gold, +1 trust. Formation strength and hull damage retained." % [encounter.name, encounter.reward]
	else:
		player = village
		mech_hp = max_hull()
		news = "Greyford recovered your disabled frame for free. Wounded formations retain 1 strength; replenish at a settlement."
	region.last_result = news
	region.resolved.append(encounter.id)
	for incident in region.incidents.duplicate():
		if incident.id == encounter.id: region.incidents.erase(incident)
	region.pending = {}
	pending_battle = false
	update_visibility()
	return true
