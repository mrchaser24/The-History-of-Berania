extends RefCounted
## The canon register has exactly 22 persistent seats; rulers are not pilot slots.
const Shop = preload("res://scripts/workshop_model.gd")
const Hex = preload("res://scripts/hex_grid.gd")
const NAMES = ["Asterfell", "Thornwall", "Bellacourt", "Maroven", "Veyrmont", "Calder", "Ravenholt", "Dunmere", "Caerwyn", "Windmere", "Valcrest", "Rothmar", "Vaust", "Merrow", "Voss", "Elmsford", "Karswell", "Halbrecht", "Solmere", "Orrick", "Draxen", "Evendale"]
const PACTS = {
	"access": {"name": "Workshop access", "trust": 3, "cost": 8, "effect": "Friendly workshop and reserve access in this domain."},
	"recruitment": {"name": "Recruitment charter", "trust": 3, "cost": 12, "effect": "Recruit this house's formations at its domain."},
	"trade": {"name": "Trade charter", "trust": 3, "cost": 10, "effect": "Trade goods in this domain."},
	"funding": {"name": "Campaign funding", "trust": 5, "cost": 0, "effect": "Receive 30 gold once; promise military aid within 12 turns."},
	"nonaggression": {"name": "Non-aggression", "trust": 3, "cost": 10, "effect": "Mutual non-aggression; declaring war is a public breach."},
	"alliance": {"name": "Military support", "trust": 5, "cost": 20, "effect": "Two allied pikes fill spare command slots. Defend this house within 12 turns."},
	"peace": {"name": "Peace and three-turn truce", "trust": 3, "cost": 15, "effect": "End this war; neither side may attack during the truce."}
}

static func defaults() -> Dictionary:
	var houses = []
	for i in NAMES.size():
		var name = NAMES[i]
		houses.append({"id": name.to_lower(), "name": name, "origin": "breakaway" if i < 10 else "loyalist", "faction": name.to_lower() if i < 10 else "imperial", "ruler": "Garrick Valcrest" if name == "Valcrest" else ("Marshal Cassian Voss" if name == "Voss" else "Lord " + name), "fate": "free", "opinion": 0, "stance": "neutral", "owner": name.to_lower(), "recognition": "", "agreements": [], "contracts": {}, "lineage": [], "truce": 0, "war_turn": 0, "garrison": 5 + i % 4, "administrator": "", "obligation": 0, "paid": false, "successor": 0})
	return {"version": 1, "houses": houses, "siege": {}, "reports": [], "npc_clock": 0, "front": {}}

static func house(state: Dictionary, id: String) -> Dictionary:
	for h in state.houses:
		if h.id == id: return h
	return {}

static func cell(index: int) -> Vector2i:
	# Reusable bounded regional atlas, one distinct authored domain per seat.
	var coordinates = [[0,0],[2,0],[4,0],[6,0],[8,0],[9,1],[0,2],[8,2],[9,3],[0,4],[2,4],[4,4],[6,4],[8,4],[8,5],[0,6],[1,6],[2,6],[3,6],[4,6],[7,6],[8,6]]
	return Hex.cell(coordinates[index][0], coordinates[index][1])

static func report(state: Dictionary, text: String):
	state.reports.append(text)
	while state.reports.size() > 16: state.reports.pop_front()

static func terms(h: Dictionary, kind: String, trust: int, gold: int, turn: int, counteroffer: bool = false) -> Dictionary:
	if kind not in PACTS: return {}
	var pact = PACTS[kind]
	var cost = maxi(0, pact.cost - (4 if counteroffer and h.opinion >= 5 else 0))
	var allowed = h.fate in ["free", "displaced"] and kind not in h.agreements and trust >= pact.trust and gold >= cost and (not counteroffer or h.opinion >= 5)
	if kind == "peace": allowed = allowed and h.stance == "war"
	else: allowed = allowed and h.stance != "war"
	if kind == "funding" and h.paid: allowed = false
	return {"kind": kind, "house": h.id, "name": pact.name, "cost": cost, "counteroffer": counteroffer, "trust": pact.trust, "effect": pact.effect, "eligible": allowed, "turn": turn}

static func sign(state: Dictionary, id: String, kind: String, trust: int, gold: int, turn: int, counteroffer: bool = false) -> Dictionary:
	var h = house(state, id)
	if h.is_empty(): return {"ok": false, "message": "No such house."}
	var offer = terms(h, kind, trust, gold, turn, counteroffer)
	if offer.is_empty() or not offer.eligible: return {"ok": false, "message": "The displayed terms are not currently available. No payment made."}
	h.agreements.append(kind)
	h.contracts[kind] = {"signed": turn, "cost": offer.cost, "advance": 30 if kind == "funding" else 0, "counteroffer": counteroffer}
	h.opinion = mini(100, h.opinion + 1)
	if kind == "peace": h.stance = "neutral"; h.truce = turn + 3
	if kind == "alliance": h.stance = "allied"; h.obligation = turn + 12
	if kind == "funding": h.paid = true; h.obligation = turn + 12
	var balance = gold - offer.cost + (30 if kind == "funding" else 0)
	report(state, "%s signed %s. %s" % [h.name, offer.name, offer.effect])
	return {"ok": true, "gold": balance, "message": state.reports.back()}

static func declare_war(state: Dictionary, id: String, turn: int) -> String:
	var h = house(state, id)
	if h.is_empty() or h.stance == "war": return "This war is already announced."
	if turn <= h.truce: return "The announced truce still protects this house."
	var breach = h.stance == "allied" or "nonaggression" in h.agreements
	h.stance = "war"; h.war_turn = turn; h.recognition = ""; h.obligation = 0
	if breach:
		h.opinion = maxi(-100, h.opinion - 20)
		for other in state.houses: other.opinion = maxi(-100, other.opinion - 3)
	h.agreements.clear()
	report(state, "War announced against %s. Attacks may begin next travel turn.%s" % [h.name, " Broken obligations cost opinion across Berania." if breach else ""])
	return state.reports.back()

static func begin_siege(state: Dictionary, id: String, turn: int) -> String:
	var h = house(state, id)
	if h.is_empty() or h.owner == "player": return "This domain is already under your control."
	if h.stance != "war" or turn <= h.war_turn or turn <= h.truce: return "Announce war, then allow one travel turn for the warning before approaching."
	if not state.siege.is_empty(): return "Finish or withdraw from the existing siege first."
	state.siege = {"house": id, "readiness": 0, "started": turn}
	return "Siege warning issued. Remain at this domain and End Turn to build readiness. At 2 readiness, assault or demand surrender."

static func capture(state: Dictionary, id: String):
	var h = house(state, id)
	h.owner = "player"; h.garrison = 2; h.administrator = "quartermaster"; h.fate = "captured"
	h.stance = "occupied"; h.agreements.clear(); h.obligation = 0
	state.siege = {}
	report(state, h.name + " domain captured. Choose custody terms, administrator and explicit recognition separately.")

static func custody(state: Dictionary, id: String, action: String, route: String) -> Dictionary:
	var h = house(state, id)
	if h.is_empty() or h.fate != "captured": return {"ok": false, "message": "This ruler is not in your custody."}
	var gold = 0
	match action:
		"release": h.fate = "displaced"; h.opinion = mini(100, h.opinion + 5)
		"ransom": h.fate = "displaced"; h.opinion = maxi(-100, h.opinion - 3); gold = 20
		"submission":
			if route.is_empty(): return {"ok": false, "message": "Settle your sovereign claim before requesting submission."}
			h.fate = "displaced"; h.recognition = route; h.stance = "submitted"
		"execute":
			h.lineage.append("Executed: " + h.ruler)
			h.successor += 1; h.ruler = "Heir %d of House %s" % [h.successor, h.name]; h.fate = "displaced"; h.opinion = -30
			for other in state.houses: other.opinion = maxi(-100, other.opinion - 5)
		_ : return {"ok": false, "message": "No custody terms selected."}
	report(state, "%s custody resolved: %s.%s" % [h.name, action, " Every house loses 5 opinion; the successor preserves the seat and required envoys." if action == "execute" else ""])
	return {"ok": true, "gold": gold, "message": state.reports.back()}

static func tick(state: Dictionary, turn: int, position: Vector2i) -> int:
	var taxes = 0
	for i in state.houses.size():
		var h = state.houses[i]
		if h.owner == "player" and turn % 4 == 0: taxes += 3 if h.administrator == "steward" else 2
		if h.obligation > 0 and turn > h.obligation:
			h.obligation = 0; h.opinion = maxi(-100, h.opinion - 8); h.stance = "neutral"
			h.agreements.erase("alliance")
			report(state, h.name + ": the announced military obligation expired. Support withdrawn; opinion −8.")
		if turn % 4 == 0:
			if h.owner != "player" and state.siege.get("house", "") != h.id: h.garrison = mini(9, h.garrison + 1)
			elif h.administrator == "captain": h.garrison = mini(9, h.garrison + 1)
	if not state.siege.is_empty():
		var index = NAMES.find(house(state, state.siege.house).name)
		if position == cell(index):
			state.siege.readiness = mini(3, state.siege.readiness + 1)
			var defender = house(state, state.siege.house)
			if state.siege.readiness >= 3 and turn % 2 == 0 and defender.garrison > 3:
				defender.garrison -= 1
				report(state, defender.name + ": the maintained blockade reduced its garrison by one. Minimum 3; no reinforcements recover during this siege.")
		else: state.siege = {}; report(state, "Siege withdrawn after leaving the domain.")
	# Announce a bounded NPC front, then resolve it on a later End Turn.
	if not state.front.is_empty() and turn > state.front.announced:
		var a = house(state, state.front.a); var b = house(state, state.front.b)
		if a.owner != "player" and b.owner != "player":
			a.garrison = maxi(3, a.garrison - 1); b.garrison = maxi(3, b.garrison - 1)
			report(state, "%s and %s fought on the announced border front. Both withdrew with reduced garrisons; rulers and required envoys remain protected." % [a.name, b.name])
		state.front = {}
	if turn % 6 == 0:
		state.npc_clock += 1
		var a = state.houses[state.npc_clock % 10]; var b = state.houses[(state.npc_clock + 1) % 10]
		if a.owner != "player" and b.owner != "player" and a.recognition.is_empty() and b.recognition.is_empty():
			state.front = {"a": a.id, "b": b.id, "announced": turn}
			report(state, "%s announced a border war with %s. Clashes may begin on the next travel turn." % [a.name, b.name])
	return taxes

static func recognized(state: Dictionary, route: String) -> int:
	var total = 0
	for h in state.houses:
		if h.recognition == route and not route.is_empty(): total += 1
	return total

static func valid(state) -> bool:
	if not state is Dictionary or state.get("version") != 1 or not state.get("houses") is Array or state.houses.size() != 22 or not state.get("siege") is Dictionary or not state.get("front") is Dictionary or not state.get("reports") is Array or state.reports.size() > 16 or not Shop.integer(state.get("npc_clock"), 0, 1000000000): return false
	for i in NAMES.size():
		var h = state.houses[i]
		if not h is Dictionary or h.get("name") != NAMES[i] or h.get("id") != NAMES[i].to_lower() or h.get("origin") != ("breakaway" if i < 10 else "loyalist"): return false
		for key in ["faction", "ruler", "owner", "administrator"]:
			if not h.get(key) is String: return false
		if h.owner not in [h.id, "player"] or h.administrator not in ["", "quartermaster", "steward", "captain"]: return false
		if h.get("fate") not in ["free", "captured", "displaced"] or h.get("stance") not in ["neutral", "war", "allied", "occupied", "submitted"] or h.get("recognition") not in ["", "restoration", "dominion"]: return false
		if not Shop.integer(h.get("opinion"), -100, 100) or not Shop.integer(h.get("garrison"), 0, 9) or not h.get("paid") is bool or not h.get("agreements") is Array: return false
		if not h.get("contracts") is Dictionary or not h.get("lineage") is Array or h.lineage.size() > 1000: return false
		for line in h.lineage:
			if not line is String: return false
		for kind in h.contracts:
			var contract = h.contracts[kind]
			if kind not in PACTS or not contract is Dictionary or not Shop.integer(contract.get("signed"), 1, 1000000000) or not Shop.integer(contract.get("cost"), 0, 100) or not Shop.integer(contract.get("advance"), 0, 30) or not contract.get("counteroffer") is bool: return false
		var seen = []
		for kind in h.agreements:
			if kind not in PACTS or kind in seen: return false
			seen.append(kind)
		for key in ["truce", "war_turn", "obligation", "successor"]:
			if not Shop.integer(h.get(key), 0, 1000000000): return false
	if not state.siege.is_empty():
		if house(state, state.siege.get("house", "")).is_empty() or not Shop.integer(state.siege.get("readiness"), 0, 3) or not Shop.integer(state.siege.get("started"), 1, 1000000000): return false
	if not state.front.is_empty():
		if house(state, state.front.get("a", "")).is_empty() or house(state, state.front.get("b", "")).is_empty() or not Shop.integer(state.front.get("announced"), 1, 1000000000): return false
	for line in state.reports:
		if not line is String: return false
	return true
