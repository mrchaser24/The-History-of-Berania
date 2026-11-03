extends RefCounted
const Hex = preload("res://scripts/hex_grid.gd")
const Region = preload("res://scripts/region_model.gd")
const Workshop = preload("res://scripts/workshop_model.gd")
const Quests = preload("res://scripts/quest_model.gd")
const Economy = preload("res://scripts/economy_model.gd")
const Pilots = preload("res://scripts/pilot_model.gd")
const Politics = preload("res://scripts/politics_model.gd")
const Chronicle = preload("res://scripts/chronicle_model.gd")
const BattleData = preload("res://scripts/battle_model.gd")
# Capture-enabled encounters may set an authored point target between 1 and 10.
const OBJECTIVE_TARGETS = {"guild": 3, "village": 3, "caravan": 3, "house_support": 3, "contact": 3, "raid": 3, "merchant_rescue": 3, "funded_rescue": 3, "companion": 3, "prison": 3, "siege": 3, "obligation": 3}
var journal = Quests.defaults()
var inventory = Economy.defaults()
var pilots = Pilots.defaults()
var politics = Politics.defaults()
var chronicle = Chronicle.defaults()
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
	var costs = terrain_costs()
	var route = Hex.path(player, goal, explored, [], costs)
	var path = [player]
	var spent = 0
	for cell in route.slice(1):
		var cost = int(costs.get(cell, 1))
		if spent + cost > budget: break
		path.append(cell); spent += cost
		if not contacts_at(cell).is_empty(): break
	return path if path.size() > 1 else []

func travel(goal: Vector2i) -> Array:
	if pending_battle: return []
	var path = path_to(goal)
	if path.is_empty():
		return []
	for cell in path.slice(1): budget -= int(terrain_costs().get(cell, 1))
	player = path.back()
	update_visibility()
	return path

func end_turn() -> Dictionary:
	if pending_battle or not chronicle.ending.is_empty(): return {}
	var before = {"patrol": patrol, "bandit": bandit}
	if rewarded:
		for party in region.parties: before[party.id] = Region.pos(party.cell)
	turn += 1
	budget = 3
	patrol = Hex.cell(3 if turn % 2 == 0 else 2, 1)
	if not rewarded:
		bandit = Hex.cell(4 if turn % 2 == 0 else 5, 3)
	if rewarded:
		var reports = Region.tick(region, board, Quests.claimed(journal, "camp"))
		for report in reports:
			if Region.pos(report.cell) in explored:
				news = report.text
				Economy.report(inventory, report.text)
	if rewarded:
		gold = mini(1000000000, gold + Economy.tick(inventory, turn, board) + Politics.tick(politics, turn, player))
		for pilot in pilots.pilots: pilot.injury = maxi(0, pilot.injury - 1)
		var story_report = Chronicle.tick(chronicle, turn)
		if not story_report.is_empty(): Economy.report(inventory, story_report)
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
	pilots.pilots[0].xp += 4 if outcome == "victory" else 1
	if outcome == "victory":
		mech_hp = maxi(1, remaining_hp)
		if not rewarded:
			gold += 40
			trust += 1
			rewarded = true
			quest = "complete"
			Quests.record(journal, "defense", "Greyford defended. 40 gold and 1 trust paid once; camp mission opened.")
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
	return {"schema": 4, "build": "berania-campaign-0.4", "journal": journal.duplicate(true), "inventory": inventory.duplicate(true), "pilots": pilots.duplicate(true), "politics": politics.duplicate(true), "chronicle": chronicle.duplicate(true), "region": region.duplicate(true), "player": [player.x, player.y], "patrol": [patrol.x, patrol.y], "bandit": [bandit.x, bandit.y], "turn": turn, "budget": budget, "gold": gold, "trust": trust, "quest": quest, "rewarded": rewarded, "mech_hp": mech_hp, "pending_battle": pending_battle, "explored": memory, "news": news, "workshop": workshop.duplicate(true)}

static func valid_snapshot(data) -> bool:
	if not data is Dictionary or not Workshop.integer(data.get("schema"), 1, 4):
		return false
	if (data.schema == 1 and data.get("build") != "greyford-demo-0.1") or (data.schema == 2 and data.get("build") != "greyford-demo-0.2") or (data.schema == 3 and data.get("build") != "greyford-demo-0.3") or (data.schema == 4 and data.get("build") != "berania-campaign-0.4"):
		return false
	var max_saved_hull = 30
	if data.schema >= 2:
		if not Workshop.valid(data.get("workshop")):
			return false
		max_saved_hull = Workshop.stats(data.workshop).hp
		if data.get("mech_hp") != Workshop.frame(data.workshop).hp:
			return false
	if data.schema >= 3:
		if not Region.valid(data.get("region")): return false
		if data.get("pending_battle") != (not data.region.pending.is_empty()) and data.get("rewarded") == true: return false
		if not data.region.pending.is_empty():
			if data.get("rewarded") != true: return false
			var p = data.region.pending
			if p.frame_id != Workshop.frame(data.workshop).id: return false
			var hero_stats = Workshop.stats(data.workshop)
			if data.schema >= 4 and p.friendly[0].has("pilot_id"):
				if not Pilots.valid(data.get("pilots"), data.workshop): return false
				if p.friendly[0].pilot_id != "protagonist" or p.friendly[0].get("frame_id") != p.frame_id or p.friendly[0].definition != Workshop.CHASSIS[Workshop.frame(data.workshop).chassis].definition: return false
				hero_stats = Pilots.stats(data.workshop, data.pilots.pilots[0])
			if Region.normalized(p.friendly[0].stats) != hero_stats or p.friendly[0].get("hp") != data.mech_hp: return false
			for entry in p.friendly.slice(1):
				if entry.get("owned", false):
					var found = false
					if data.schema >= 4 and entry.has("pilot_id"):
						if not Pilots.valid(data.get("pilots"), data.workshop): return false
						var pilot = Pilots.pilot(data.pilots, entry.pilot_id)
						var f = Workshop.frame(data.workshop, entry.get("frame_id", ""))
						found = not pilot.is_empty() and not f.is_empty() and entry.id == "pilot_" + pilot.id and pilot.deploy and pilot.injury == 0 and pilot.frame == f.id and entry.definition == Workshop.CHASSIS[f.chassis].definition and entry.get("hp") == f.hp and Region.normalized(entry.get("stats", {})) == Pilots.stats(data.workshop, pilot)
					else:
						for f in data.region.formations:
							if f.id == entry.id and f.definition == entry.definition and f.hp == entry.get("hp"):
								found = true
								if entry.has("stats"):
									var definition = BattleData.DEFINITIONS.get(f.definition, BattleData.COMBINED.get(f.definition))
									found = Region.normalized(entry.stats) == Pilots.formation_stats(definition, f)
								elif p.has("target"): found = false
					if not found: return false
	if data.schema >= 4:
		if not Quests.valid(data.get("journal")) or not Economy.valid(data.get("inventory")) or not Pilots.valid(data.get("pilots"), data.workshop) or not Politics.valid(data.get("politics")) or not Chronicle.valid(data.get("chronicle")): return false
		if Quests.claimed(data.journal, "defense") != data.get("rewarded") or data.journal.identity.name != data.pilots.pilots[0].name: return false
		if Quests.claimed(data.journal, "headquarters"):
			if not data.workshop.headquarters or not data.workshop.banner.created: return false
			var formal_found = false
			for f in data.region.formations:
				if f.id == data.journal.formal_id: formal_found = true
			if not formal_found: return false
		if Quests.claimed(data.journal, "investigation") != (data.chronicle.evidence.size() == 3): return false
		if Quests.claimed(data.journal, "bargain") != (not data.chronicle.route.is_empty()): return false
		if Quests.claimed(data.journal, "rescue") != data.inventory.rescue_done or Quests.claimed(data.journal, "tournament") != data.inventory.tournament_won: return false
		if data.inventory.quest_items != data.chronicle.evidence: return false
		if Pilots.pilot(data.pilots, "princess").is_empty() != (data.chronicle.princess != "restored"): return false
		if not data.region.pending.is_empty():
			var kind = data.region.pending.kind
			if kind == "camp" and Quests.claimed(data.journal, "camp"): return false
			if kind == "merchant_rescue" and data.inventory.rescue_done: return false
			if kind == "tournament" and data.inventory.tournament_won: return false
			if kind == "elite" and (data.chronicle.route != "restoration" or data.chronicle.elite_defeated): return false
			if kind == "prison" and (data.chronicle.route != "restoration" or data.chronicle.princess != "imprisoned"): return false
			if kind == "funded_rescue" and (data.inventory.caravan.is_empty() or data.inventory.caravan.phase != "ambushed" or data.inventory.caravan.id != data.region.pending.get("target")): return false
			if not data.chronicle.ending.is_empty(): return false
		if not data.chronicle.ending.is_empty() and Politics.recognized(data.politics, data.chronicle.route) != 22: return false
	var legal_board = Hex.cells(10, 7) if data.schema >= 3 and data.get("rewarded") == true else Hex.cells(6, 5)
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
	region = Region.normalized(data.region) if data.schema >= 3 else Region.defaults()
	journal = Region.normalized(data.journal) if data.schema >= 4 else Quests.defaults(data.rewarded)
	inventory = Region.normalized(data.inventory) if data.schema >= 4 else Economy.defaults()
	pilots = Region.normalized(data.pilots) if data.schema >= 4 else Pilots.defaults()
	politics = Region.normalized(data.politics) if data.schema >= 4 else Politics.defaults()
	chronicle = Region.normalized(data.chronicle) if data.schema >= 4 else Chronicle.defaults()
	if data.schema < 4:
		pilots.pilots[0].frame = workshop.pilot_frame
		if region.deliveries > 0: Quests.record(journal, "delivery", "Prior guild deliveries retained; no reward replayed.")
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
	if not rewarded: return {}
	for place in locations():
		if Region.pos(place.cell) == player: return place
	return {}

func recruit(definition: String) -> String:
	if not rewarded or pending_battle or settlement().is_empty() or not settlement().friendly: return "Recruit at a friendly settlement."
	if not recruitment_access(): return "A recruitment charter or headquarters is required here."
	if definition not in recruitable_roles(): return "This house does not supply that formation under its doctrine."
	var cost = Region.PRICES[definition]
	if gold < cost or region.formations.size() >= 56: return "Insufficient gold or roster full (56 formations)."
	var data = load("res://scripts/battle_model.gd")
	var definition_data = data.DEFINITIONS.get(definition, data.COMBINED.get(definition))
	var id = "formation_" + str(region.next_id)
	region.next_id += 1
	region.formations.append({"id": id, "definition": definition, "hp": definition_data.hp, "owned": true, "xp": 0, "rank": 0})
	if region.selected.size() < 9: region.selected.append(id)
	gold -= cost
	return "Recruited %s for %d gold." % [definition_data.name, cost]

func regional_order(action: String) -> String:
	if not rewarded or pending_battle: return "Finish the village defense first."
	var place = settlement()
	if place.is_empty() or not place.friendly: return "Enter a friendly settlement for this service."
	if action == "permission":
		if place.id != "greyford": return "Greyford's council must authorize this claim."
		if Quests.claimed(journal, "permission"): return "Permission is already recorded. Enter the watchhouse north of Greyford."
		if not Quests.claimed(journal, "camp") or trust < 3: return "Permission requires the bandit camp cleared and 3 trust. Defense and camp supply all three; no optional work is required."
		Quests.record(journal, "permission", "Greyford's council granted the abandoned watchhouse without a fee.")
		return "Permission granted. Travel to the watchhouse north of Greyford and found your warband."
	if action == "rescue":
		if place.id != "stonebridge": return "The stranded merchant's partner waits at Stonebridge."
		if inventory.rescue_done: return "The merchant has already been rescued. You can sign his route agreement."
		inventory.rescue_started = true
		return "Rescue accepted. A stranded merchant waits on the eastern road (column 9, row 4). This optional job has no expiry and survives camp clearance."
	if action == "merchant":
		if place.id != "stonebridge" or not inventory.rescue_done: return "Rescue the merchant, then return to Stonebridge to agree on route terms."
		inventory.merchant = true
		return "Merchant agreement signed: dispatch at Stonebridge for 18 gold; six grain to Millhaven pays 36, then the empty caravan returns. Ambushes must be resolved before delivery."
	if action == "dispatch":
		if place.id != "stonebridge": return "Dispatch from Stonebridge."
		var result = Economy.dispatch(inventory, gold)
		if result.ok: gold = result.gold
		return result.message
	if action == "support":
		if place.id != "stonebridge": return "The Asterfell envoy offers this optional work at Stonebridge."
		if Quests.claimed(journal, "support"): return "The envoy is already safe; the support quest cannot be rewarded again."
		region["support_started"] = true
		return "Protection contract accepted. Prepare the envoy defense at Stonebridge. Victory pays 20 gold, 1 trust and 5 Asterfell opinion; the noble remains strategic support."
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
		Quests.record(journal, "delivery", "Grain delivered to Millhaven; payment committed with the cargo transfer.")
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
		if not _friendly_service(): return "Emergency aid requires a friendly workshop or founded headquarters."
		mech_hp = max_hull()
		for pilot in pilots.pilots:
			pilot.injury = 0
			if not pilot.frame.is_empty():
				var f = Workshop.frame(workshop, pilot.frame)
				f.hp = maxi(1, int(f.hp))
		return "Essential frame repair and pilot recovery complete, free of charge."
	return "No service selected."

func terrain_costs() -> Dictionary:
	if not rewarded: return {}
	var costs = {}
	for cell in [Hex.cell(3, 3), Hex.cell(4, 3), Hex.cell(7, 3), Hex.cell(3, 5), Hex.cell(8, 5)]: costs[cell] = 2
	return costs

func contacts_at(cell: Vector2i) -> Array:
	var contacts = []
	if rewarded:
		for party in region.parties:
			if Region.pos(party.cell) == cell and not (party.id == "bandits" and Quests.claimed(journal, "camp")): contacts.append(party)
	return contacts

func locations() -> Array:
	var result = Region.SETTLEMENTS.duplicate(true)
	var voss = Politics.house(politics, "voss")
	result[3].house = "voss"
	result[3].friendly = voss.owner == "player" or "access" in voss.agreements or "recruitment" in voss.agreements or "trade" in voss.agreements
	if not rewarded: return result
	result.append({"id": "camp", "name": "Cleared camp" if Quests.claimed(journal, "camp") else "Bandit camp", "cell": Quests.CAMP, "kind": "Required raider stronghold", "friendly": false})
	result.append({"id": "headquarters", "name": "Headquarters" if Quests.claimed(journal, "headquarters") else "Abandoned watchhouse", "cell": Quests.HQ, "kind": "Warband headquarters", "friendly": true})
	if inventory.rescue_started and not inventory.rescue_done:
		result.append({"id": "merchant_rescue", "name": "Stranded merchant", "cell": [7, 3], "kind": "Optional rescue · retryable", "friendly": false})
	if Quests.claimed(journal, "headquarters"):
		# Emberwatch already represents Voss's domain.
		for i in politics.houses.size():
			var h = politics.houses[i]
			if h.id == "voss": continue
			result.append({"id": "domain_" + h.id, "house": h.id, "name": h.name, "cell": Region.point(Politics.cell(i)), "kind": "House domain · " + h.stance, "friendly": h.owner == "player" or "access" in h.agreements or "recruitment" in h.agreements or "trade" in h.agreements})
		result.append({"id": "capital", "name": "Imperial capital", "cell": Chronicle.CAPITAL, "kind": "Prison and imperial throne", "friendly": false})
	return result

func recruitment_access() -> bool:
	var place = settlement()
	if place.is_empty(): return false
	if not place.has("house"): return place.id != "headquarters" or Quests.claimed(journal, "headquarters")
	var h = Politics.house(politics, place.house)
	return h.owner == "player" or "recruitment" in h.agreements

func trade_access() -> bool:
	var place = settlement()
	if place.is_empty() or not place.friendly: return false
	if not place.has("house"): return place.id != "headquarters" or Quests.claimed(journal, "headquarters")
	var h = Politics.house(politics, place.house)
	return h.owner == "player" or "trade" in h.agreements

func identity(name: String, appearance: int) -> String:
	if pending_battle: return "Finish the committed encounter first."
	name = name.strip_edges()
	if name.is_empty() or name.length() > 28 or "\n" in name or "\r" in name or appearance < 0 or appearance >= Quests.APPEARANCES.size(): return "Use a name of 1–28 characters and an available heraldic portrait."
	journal.identity = {"name": name, "appearance": appearance}
	pilots.pilots[0].name = name
	return "Identity saved. Your Valcrest history and love for Aurelia remain unchanged."

func found_headquarters(banner: Dictionary) -> String:
	if pending_battle or player != Region.pos(Quests.HQ): return "Enter the watchhouse to found the warband."
	if not Quests.claimed(journal, "permission"): return "Ask Greyford's council for explicit permission first."
	if Quests.claimed(journal, "headquarters"): return "Headquarters is already established. Edit your banner in the workshop."
	var next = workshop.duplicate(true)
	next.headquarters = true
	var result = Workshop.transact(next, gold, "banner", {"banner": banner})
	if not result.ok: return result.message
	workshop = result.state
	var id = "formation_" + str(region.next_id); region.next_id += 1
	region.formations.append({"id": id, "definition": "greyford_blades", "hp": 12, "owned": true, "xp": 0, "rank": 0})
	if region.selected.size() < 9: region.selected.append(id)
	journal.formal_id = id
	trust += 1
	Quests.record(journal, "headquarters", "Warband founded. One formal sword formation awarded once; earlier hires and temporary militia remain distinct.")
	return "Headquarters founded. Your first formal formation joins once. Naming, banner, party, reserves and formal recruitment are now open; regional work continues."

func deployment_roster(major: bool = false) -> Array:
	var result = Pilots.roster(pilots, workshop)
	var limit = 15 if major else 10
	for id in region.selected:
		for f in region.formations:
			if f.id == id and result.size() < limit:
				var entry = f.duplicate(true)
				entry.stats = Pilots.formation_stats(BattleData.DEFINITIONS.get(f.definition, BattleData.COMBINED.get(f.definition)), f)
				result.append(entry)
	var support = region.allied
	for h in politics.houses:
		if "alliance" in h.agreements and h.stance == "allied": support = true
	for i in (2 if support else 0):
		if result.size() < limit: result.append({"id": "support_" + str(i), "definition": "pikemen", "name": "Allied house guard", "owned": false})
	return result.slice(0, limit)

func prepare_region(kind: String, target: String = "") -> Dictionary:
	if not rewarded or pending_battle or not chronicle.ending.is_empty(): return {}
	var name = "Guild road clearance"; var reward = 18; var count = 3; var major = false
	var place = settlement()
	var enemy = []
	match kind:
		"camp":
			if player != Region.pos(Quests.CAMP) or Quests.claimed(journal, "camp"): return {}
			name = "Break the bandit camp"; reward = 30; count = 4
		"village", "caravan":
			var found = false
			for incident in region.incidents:
				if incident.id == target and Region.pos(incident.cell) == player: found = true; name = incident.name
			if not found: return {}
			reward = 24; count = 4
		"house_support":
			if place.get("id") != "stonebridge" or not region.get("support_started", false) or Quests.claimed(journal, "support"): return {}
			name = "Protect Asterfell's envoy"; reward = 20; count = 4
		"contact":
			var found = false
			for party in contacts_at(player):
				if party.id == target and party.id in ["bandits", "army"] and party.ready <= region.ticks:
					found = true; name = "Intervene against " + party.kind; count = party.strength
			if not found: return {}
			reward = 12
		"raid":
			if place.get("id") != "emberwatch" or region.ticks < region.battle_ready: return {}
			name = "Raid imperial supply line"; reward = 28; count = 5
		"guild":
			if place.is_empty() or not place.friendly or region.ticks < region.battle_ready: return {}
		"merchant_rescue":
			if place.get("id") != "merchant_rescue" or inventory.rescue_done: return {}
			name = "Rescue the stranded merchant"; reward = 24; count = 4
		"funded_rescue":
			var c = inventory.caravan
			if c.is_empty() or c.phase != "ambushed" or Region.pos(c.cell) != player: return {}
			target = c.id; name = "Recover your funded caravan"; reward = 0; count = 4
		"tournament":
			if place.get("id") != "stonebridge" or inventory.tournament_won or gold < 5: return {}
			name = "Stonebridge solo mech duel"; reward = 25
			enemy = [{"id": "duelist", "definition": "shield_mech", "name": "Guild champion"}]
		"companion":
			if target not in Pilots.COMPANIONS: return {}
			var info = Pilots.COMPANIONS[target]
			if place.get("id") != info.place or not Quests.claimed(journal, info.requires) or not Pilots.pilot(pilots, target).is_empty(): return {}
			name = info.title; reward = 12; count = 5
		"investigation":
			if place.get("id") != "emberwatch" or not Quests.claimed(journal, "headquarters") or "orders" not in chronicle.evidence or "testimony" not in chronicle.evidence or "courier" in chronicle.evidence: return {}
			name = "Intercept Voss's courier"; reward = 20; count = 5
		"elite":
			if place.get("id") != "headquarters" or chronicle.route != "restoration" or chronicle.elite_defeated: return {}
			name = "The three houses' elite force"; reward = 40; major = true
			for role in ["greyford_blades", "pikemen", "roadwardens", "cavalry"]:
				var d = BattleData.DEFINITIONS.get(role, BattleData.COMBINED.get(role))
				var stats = Pilots.formation_stats(d, {"rank": 2})
				enemy.append({"id": "elite_" + role, "definition": role, "stats": stats, "name": "Sponsor veteran · " + d.name})
			enemy.append({"id": "merrow_pilot", "definition": "shield_mech", "name": "Merrow's advanced frame", "stats": {"hp": 42, "attack": 11, "armor": 3, "move": 3, "range": 1}})
		"prison":
			if place.get("id") != "capital" or chronicle.route != "restoration" or not chronicle.elite_defeated or chronicle.princess != "imprisoned": return {}
			name = "Raid the capital prison"; reward = 35; count = 8; major = true
		"siege":
			if politics.siege.is_empty() or politics.siege.house != target or politics.siege.readiness < 2 or player != Politics.cell(Politics.NAMES.find(Politics.house(politics, target).name)): return {}
			name = "Assault " + Politics.house(politics, target).name; reward = 30; count = Politics.house(politics, target).garrison; major = true
		"obligation":
			var h = Politics.house(politics, target)
			if h.is_empty() or h.obligation <= 0 or player != Politics.cell(Politics.NAMES.find(h.name)): return {}
			name = "Honor the defense of " + h.name; reward = 10; count = 5
		"final":
			if place.get("id") != "capital" or chronicle.route.is_empty() or Politics.recognized(politics, chronicle.route) != 22: return {}
			if chronicle.route == "restoration" and chronicle.princess != "restored": return {}
			if chronicle.route == "dominion" and chronicle.princess != "exiled": return {}
			name = "The throne's last prisoner"; reward = 0; count = 11; major = true
			enemy = Region.enemies(count)
			enemy.append({"id": "lucien", "definition": "shield_mech", "name": "Lucien · throne-amplified imperial frame", "stats": {"hp": 48, "attack": 12, "armor": 3, "move": 3, "range": 2}})
		_: return {}
	var friendly = deployment_roster(major)
	if friendly.is_empty() or friendly[0].id != "hero": return {}
	if kind == "tournament": friendly = [friendly[0]]
	elif kind not in ["final", "elite", "siege"]:
		# Essential recovery is playable even when optional spending emptied the treasury.
		for i in 2:
			if friendly.size() < (15 if major else 10): friendly.append({"id": "loan_" + str(i), "definition": "greyford_blades" if i == 0 else "roadwardens", "name": "Local volunteer", "owned": false})
	return {"id": kind + "_" + str(region.next_id), "target": target, "kind": kind, "name": name, "major": major, "reward": reward, "fee": 5 if kind == "tournament" else 0, "objective_target": OBJECTIVE_TARGETS.get(kind, 3), "frame_id": Workshop.frame(workshop).id, "friendly": friendly, "enemy": enemy if not enemy.is_empty() else Region.enemies(count)}

func commit_region(preparation: Dictionary) -> bool:
	if not rewarded or pending_battle or preparation.is_empty(): return false
	if preparation != prepare_region(preparation.get("kind", ""), preparation.get("target", "")): return false
	var before = region.duplicate(true)
	region.pending = preparation.duplicate(true)
	if not Region.valid(region): region = before; return false
	gold -= int(preparation.get("fee", 0))
	region.next_id += 1
	pending_battle = true
	return true

func finish_region(battle) -> bool:
	if region.pending.is_empty() or not pending_battle or battle.outcome not in ["victory", "defeat"] or battle.deployment != region.pending: return false
	var encounter = region.pending.duplicate(true)
	var victory = battle.outcome == "victory"
	Pilots.award(pilots, workshop, region.formations, battle, victory)
	# Old interrupted deployments contain no pilot metadata; retain their original result contract.
	if not encounter.friendly[0].has("pilot_id"): mech_hp = maxi(1, int(battle.unit("hero").hp))
	region.last_reward = 0
	var trust_reward = 2 if encounter.kind == "camp" else (0 if encounter.kind in ["tournament", "funded_rescue", "final"] else 1)
	if victory:
		gold = mini(1000000000, gold + encounter.reward); trust += trust_reward; region.last_reward = encounter.reward
		news = "%s won. +%d gold, +%d trust. Strength, hull condition and earned experience retained." % [encounter.name, encounter.reward, trust_reward]
		match encounter.kind:
			"camp":
				Quests.record(journal, "camp", "Bandit camp cleared. 30 gold and 2 trust paid once; recurring camp raids suppressed.")
				for incident in region.incidents.duplicate():
					if incident.kind == "village": region.incidents.erase(incident)
				Economy.offer(inventory, "camp_cache", {"medicine": 2, "ore": 2}, ["armor"])
				news += " Ask Greyford's council for headquarters permission."
			"house_support":
				Quests.record(journal, "support", "Envoy protected; 20 gold, 1 trust and 5 Asterfell opinion committed once.")
				Politics.house(politics, "asterfell").opinion = mini(100, Politics.house(politics, "asterfell").opinion + 5)
			"merchant_rescue":
				inventory.rescue_done = true
				Quests.record(journal, "rescue", "Merchant rescued. His route agreement is available at Stonebridge.")
			"funded_rescue":
				inventory.caravan.phase = "outbound"
				Economy.report(inventory, "The six reserved grain were recovered. The caravan resumes its route next End Turn; no delivery occurred during the ambush.")
			"tournament":
				inventory.tournament_won = true
				Quests.record(journal, "tournament", "Solo duel won. The 25-gold first-victory purse was paid once.")
			"companion":
				if Pilots.recruit(pilots, workshop, encounter.target): news += " Pilot and the explicitly offered usable frame join in reserve. Enable deployment in Party."
			"investigation":
				news += " " + Chronicle.evidence(chronicle, inventory, "courier")
				Quests.record(journal, "investigation", "Orders, testimony and courier documents establish Aldren's crimes and Roland's innocence.")
			"elite": chronicle.elite_defeated = true; news += " The prison road is open. Aurelia remains in the capital dungeon."
			"prison":
				chronicle.princess = "restored"
				pilots.pilots.append({"id": "princess", "name": "Princess Aurelia", "frame": "", "xp": 0, "injury": 0, "deploy": false})
				news += " Aurelia is rescued and leads politically. Assign an available frame to deploy her. The capital remains under Lucien's control."
			"siege": Politics.capture(politics, encounter.target)
			"obligation":
				var h = Politics.house(politics, encounter.target)
				h.obligation = 0; h.opinion = mini(100, h.opinion + 8)
			"contact":
				for party in region.parties:
					if party.id == encounter.target: party.strength = maxi(1, party.strength - 1); party.ready = region.ticks + 4
			"raid": region.relation = maxi(-100, region.relation - 1)
			"final":
				Chronicle.ending(chronicle, journal, politics, journal.identity.name, pilots.pilots)
				news = chronicle.epilogue
		if encounter.kind in ["guild", "raid"]: region.battle_ready = region.ticks + 2
		if encounter.kind not in ["camp", "tournament", "final", "funded_rescue"]: Economy.offer(inventory, encounter.id, {"grain": 1, "medicine": 1})
	else:
		player = village; mech_hp = max_hull()
		news = "Greyford recovered your frame for free. Formations retain at least 1 strength. Required missions remain retryable; pilots recover in two End Turns or by free emergency aid."
		if encounter.kind == "funded_rescue": inventory.caravan.phase = "lost"; inventory.caravan.cargo = 0; Economy.report(inventory, "The rescue failed and the funded caravan was lost. Another dispatch may be funded.")
		if encounter.kind == "siege": politics.siege = {}
	region.last_result = news
	region["last_trust"] = trust_reward if victory else 0
	region.resolved.append(encounter.id)
	for incident in region.incidents.duplicate():
		if incident.id == encounter.get("target", encounter.id): region.incidents.erase(incident)
	region.pending = {}; pending_battle = false
	update_visibility()
	return true

func order(action: String, args: Dictionary = {}) -> String:
	if pending_battle: return "The encounter is locked. Finish it before changing campaign assets."
	if not chronicle.ending.is_empty(): return "The civil war is settled. Your chronicle is complete."
	var before = snapshot()
	var result = _order(action, args)
	if not valid_snapshot(snapshot()):
		restore(before)
		return "That order could not be committed. Your prior resources and progress were retained."
	return result

func _order(action: String, args: Dictionary) -> String:
	var id = str(args.get("id", ""))
	var place = settlement()
	match action:
		"shop": return shop_order(str(args.get("action", "")), args)
		"identity": return identity(str(args.get("name", "")), int(args.get("appearance", 0)))
		"found": return found_headquarters(args.get("banner", {}))
		"service": return regional_order(id)
		"hire": return recruit(id)
		"loot": return Economy.take(inventory, workshop, id, str(args.get("kind", "")), str(args.get("key", "")), int(args.get("quantity", 1)))
		"leave_loot": return Economy.leave(inventory, id)
		"discard":
			if id not in Workshop.GOODS or workshop.cargo.get(id, 0) < 1: return "No such carried good. Protected quest items cannot be discarded or sold."
			workshop.cargo[id] -= 1
			if workshop.cargo[id] == 0: workshop.cargo.erase(id)
			return "One carried good discarded. Pending loot remains available."
		"medicine":
			if workshop.cargo.get("medicine", 0) < 1: return "No field medicine carried. Free emergency aid is available at friendly workshops."
			var p = Pilots.pilot(pilots, id)
			if p.is_empty() or p.injury == 0: return "Choose an injured pilot."
			workshop.cargo.medicine -= 1
			if workshop.cargo.medicine == 0: workshop.cargo.erase("medicine")
			p.injury = 0
			return "Field medicine used. Pilot recovered without advancing time."
		"assign":
			if not _friendly_service(): return "Assign frames at headquarters or a friendly workshop."
			return Pilots.assign(pilots, workshop, id, str(args.get("frame", "")))
		"deploy_pilot":
			var p = Pilots.pilot(pilots, id)
			if p.is_empty() or id == "protagonist": return "The protagonist always deploys."
			if p.frame.is_empty() or p.injury > 0: return "Assign a usable frame and recover the pilot first."
			p.deploy = not p.deploy
			return "Pilot deployment preference updated. Every personal mech uses one command slot."
		"select_formation":
			for f in region.formations:
				if f.id == id:
					if id in region.selected: region.selected.erase(id)
					elif region.selected.size() < 14: region.selected.append(id)
					return "Formation preference saved. Preparation displays the actual capped participants."
			return "Unknown formation."
		"upgrade":
			if not _friendly_service(): return "Train at headquarters or a friendly settlement."
			for f in region.formations:
				if f.id != id: continue
				var rank = int(f.get("rank", 0)); var xp = int(f.get("xp", 0))
				if rank >= 2 or xp < (rank + 1) * 12 or gold < 8: return "Training needs 8 gold and 12/24 earned formation XP. Maximum rank 2."
				gold -= 8; f["rank"] = rank + 1
				return "Formation rank increased: +1 attack. Pilot XP and frame refits remain separate."
			return "Unknown formation."
		"evidence":
			if not Quests.claimed(journal, "headquarters"): return "Found the headquarters before beginning the required investigation."
			if id == "orders" and place.get("id") == "millhaven": return Chronicle.evidence(chronicle, inventory, id)
			if id == "testimony" and place.get("id") == "stonebridge" and "orders" in chronicle.evidence: return Chronicle.evidence(chronicle, inventory, id)
			return "The journal lists the next evidence source. Courier documents require the Emberwatch encounter."
		"branch":
			if place.get("id") != "headquarters": return "The three-house envoys await you at headquarters."
			if not Chronicle.choose(chronicle, journal, pilots, workshop, region, id, turn): return "Complete the required investigation first. An existing route can never be changed."
			if id == "dominion":
				gold = mini(1000000000, gold + Chronicle.GRANT_GOLD)
				for sponsor in ["rothmar", "vaust", "merrow"]:
					var h = Politics.house(politics, sponsor)
					h.faction = "player"; h.stance = "allied"
				return "Dominion committed permanently. Four veteran formations, an unassigned Merrow Crownward and 120 gold delivered once. Aurelia's independent escape will be reported."
			return "Restoration committed permanently. Prepare at headquarters to face the sponsors' elite force, then raid the capital prison."
		"princess_loan":
			if place.get("id") != "headquarters" or chronicle.princess != "restored": return "Aurelia must be restored and present at headquarters."
			var p = Pilots.pilot(pilots, "princess")
			if not p.frame.is_empty(): return "Aurelia already has a frame."
			# Explicit one-time loan, tracked by a stable named record rather than every assignment.
			if "princess_loan" in inventory.claims: return "The restoration loan was already issued; assign an owned reserve frame."
			p.frame = Workshop.add_frame(workshop, "knight", "Restoration Oathguard")
			inventory.claims.append("princess_loan")
			return "Aurelia accepts the explicitly offered restoration frame, placed in reserve. Enable her deployment in Party."
		"pact", "war", "recognize", "custody", "administrator", "siege", "surrender", "withdraw_siege":
			return _political_order(action, args)
		_: return "No campaign order selected."

func _friendly_service() -> bool:
	var place = settlement()
	if not rewarded or place.is_empty() or not place.friendly or (place.id == "headquarters" and not Quests.claimed(journal, "headquarters")): return false
	if place.has("house"):
		var h = Politics.house(politics, place.house)
		return h.owner == "player" or "access" in h.agreements
	return true

func _political_order(action: String, args: Dictionary) -> String:
	if not Quests.claimed(journal, "headquarters"): return "Found headquarters before negotiating as a warband."
	var id = str(args.get("id", "")); var kind = str(args.get("kind", ""))
	var h = Politics.house(politics, id)
	if action == "withdraw_siege": politics.siege = {}; return "Siege withdrawn; no capture or reward."
	if h.is_empty(): return "Unknown house seat."
	var place = settlement()
	var index = Politics.NAMES.find(h.name)
	var present = player == Politics.cell(index)
	var audience = present or place.get("id") in ["headquarters", "stonebridge"]
	if not audience: return "Seek this house at its domain, Stonebridge's envoy court or headquarters."
	match action:
		"pact":
			var result = Politics.sign(politics, id, kind, trust, gold, turn, bool(args.get("counteroffer", false)))
			if result.ok: gold = result.gold
			return result.message
		"war": return Politics.declare_war(politics, id, turn)
		"siege":
			if not present: return "Approach this house's marked domain on the regional map."
			return Politics.begin_siege(politics, id, turn)
		"surrender":
			if not present or politics.siege.is_empty() or politics.siege.house != id or politics.siege.readiness < 2: return "Build siege readiness to 2 at this domain first."
			if deployment_roster(true).size() < h.garrison or h.garrison > 6: return "The garrison refuses. Bring at least its number of commandable units and face a garrison no stronger than 6, or assault."
			Politics.capture(politics, id)
			return "The fort surrenders under the displayed terms. Resolve custody and recognition separately."
		"custody":
			var result = Politics.custody(politics, id, kind, chronicle.route)
			if result.ok: gold = mini(1000000000, gold + result.gold)
			return result.message
		"administrator":
			if h.owner != "player" or kind not in ["quartermaster", "steward", "captain"]: return "Choose an administrator for an owned domain."
			h.administrator = kind
			return "Administrator appointed. Steward yields 3 gold per four turns; other offices yield 2. Captain strengthens surrendered garrisons."
		"recognize":
			if chronicle.route.is_empty() or (chronicle.route == "restoration" and chronicle.princess != "restored") or (chronicle.route == "dominion" and chronicle.princess != "exiled"): return "Resolve the rescue or independent escape before seeking a sovereign settlement."
			if kind in ["breakaway", "loyalist"]:
				var supporters = 0
				for member in politics.houses:
					if member.origin == kind and member.recognition == chronicle.route: supporters += 1
				if supporters < 2 or trust < 5: return "Coalition terms require two seats of this opening bloc already recognizing your sovereign and 5 trust. No fee."
				for member in politics.houses:
					if member.origin == kind:
						member.recognition = chronicle.route
						if member.stance == "war": member.stance = "submitted"
						if member.fate == "captured": member.fate = "displaced"
				Politics.report(politics, "The " + kind + " coalition explicitly recognizes " + ("Empress Aurelia." if chronicle.route == "restoration" else journal.identity.name + " as emperor."))
				return politics.reports.back()
			if h.recognition == chronicle.route: return "This seat already recognizes your sovereign. No opinion or payment can be farmed."
			if h.fate == "captured": return "Resolve this ruler's custody, including a negotiated submission, first."
			if h.owner != "player" and (trust < 5 or h.opinion < 0 or h.stance == "war"): return "Recognition terms: 5 trust, non-negative opinion and no active war, or a controlled domain with settled custody."
			h.recognition = chronicle.route
			Politics.report(politics, h.name + " explicitly recognizes " + ("Empress Aurelia." if chronicle.route == "restoration" else journal.identity.name + " as emperor."))
			return politics.reports.back()
	return "No political terms selected."

func shop_order(action: String, args: Dictionary) -> String:
	if action in ["buy_good", "sell_good"]:
		if not trade_access(): return "Trade at a friendly market with access."
	elif not _friendly_service(): return "Visit headquarters or a friendly workshop for that order."
	if action == "buy_frame" and args.get("chassis") == "advanced":
		var merrow = Politics.house(politics, "merrow")
		if "recruitment" not in merrow.agreements and merrow.owner != "player" and not chronicle.bargain_claimed: return "Advanced Merrow purchases require its recruitment charter, control of its domain or the accepted bargain."
	if action in ["buy_good", "sell_good"] and not trade_access(): return "This domain requires a trade charter."
	var frame_id = str(args.get("frame", workshop.pilot_frame))
	var assigned = Pilots.assigned(pilots, frame_id)
	if action == "sell_frame" and not assigned.is_empty(): return "Unassign this frame's pilot before selling it. The protagonist needs a usable replacement."
	if action == "assign" and assigned not in ["", "protagonist"]: return "That machine is assigned to another personal pilot. Unassign it in Party first."
	var terms = args.duplicate(true); terms.place = settlement().get("id", "")
	var result = Workshop.transact(workshop, gold, action, terms)
	if not result.ok: return result.message
	workshop = result.state; gold = result.gold
	if action == "assign": pilots.pilots[0].frame = workshop.pilot_frame
	return result.message

func recruitable_roles() -> Array:
	var place = settlement()
	if not place.has("house"): return Region.PRICES.keys()
	var doctrine = {"veyrmont": ["mages", "pikemen"], "calder": ["roadwardens", "cannon"], "draxen": ["roadwardens", "cannon"], "ravenholt": ["cavalry", "greyford_blades"], "thornwall": ["pikemen", "cannon"], "merrow": ["cannon", "roadwardens"], "windmere": ["roadwardens", "cavalry"], "vaust": ["pikemen", "greyford_blades"]}
	return doctrine.get(place.house, ["greyford_blades", "pikemen"])
