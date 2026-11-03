extends RefCounted
## Inventory claims and a single funded caravan; strategic time is supplied by Campaign.
const Shop = preload("res://scripts/workshop_model.gd")
const Hex = preload("res://scripts/hex_grid.gd")
const Region = preload("res://scripts/region_model.gd")
const EVIDENCE = {"orders": "Aldren's sealed assassination order", "testimony": "The court physician's signed testimony", "courier": "Voss's persecution orders"}
const ROUTE = {"origin": [6, 2], "destination": [1, 5], "good": "grain", "quantity": 6, "funding": 18, "payment": 36}

static func defaults() -> Dictionary:
	return {"version": 1, "loot": [], "claims": [], "quest_items": [], "merchant": false, "rescue_started": false, "rescue_done": false, "tournament_won": false, "caravan": {}, "next_route": 1, "reports": []}

static func offer(state: Dictionary, id: String, goods: Dictionary, modules: Array = []) -> bool:
	if id in state.claims: return false
	for entry in state.loot:
		if entry.id == id: return false
	state.loot.append({"id": id, "goods": goods.duplicate(true), "modules": modules.duplicate(), "left": false})
	return true

static func take(state: Dictionary, workshop: Dictionary, id: String, kind: String, key: String, quantity: int = 1) -> String:
	for entry in state.loot:
		if entry.id != id or entry.left: continue
		if kind == "good":
			if not Shop.GOODS.has(key) or quantity < 1 or entry.goods.get(key, 0) < quantity: return "That loot is unavailable."
			if Shop.cargo_used(workshop) + quantity > Shop.CARGO_CAPACITY: return "Cargo full. Leave this loot pending, sell or discard carried goods, then take it."
			workshop.cargo[key] = workshop.cargo.get(key, 0) + quantity
			entry.goods[key] -= quantity
			if entry.goods[key] == 0: entry.goods.erase(key)
		elif kind == "module":
			if key not in entry.modules or workshop.items.size() >= 512: return "No room in shared module reserves."
			Shop._add_item(workshop, key)
			entry.modules.erase(key)
		else: return "Unknown loot category."
		if entry.goods.is_empty() and entry.modules.is_empty():
			state.claims.append(id)
			state.loot.erase(entry)
		return "Loot transferred to its inventory category."
	return "That reward has already been collected or left."

static func leave(state: Dictionary, id: String) -> String:
	for entry in state.loot:
		if entry.id == id:
			state.claims.append(id)
			state.loot.erase(entry)
			return "Remaining loot left behind permanently."
	return "No loot remains."

static func report(state: Dictionary, text: String):
	state.reports.append(text)
	while state.reports.size() > 12: state.reports.pop_front()

static func dispatch(state: Dictionary, gold: int) -> Dictionary:
	if not state.merchant: return {"ok": false, "message": "Rescue the merchant and sign his agreement at Stonebridge first."}
	if not state.caravan.is_empty() and state.caravan.phase not in ["returned", "lost"]: return {"ok": false, "message": "Your funded caravan is still on the road."}
	if gold < ROUTE.funding: return {"ok": false, "message": "Dispatch needs 18 gold to buy six grain. No carried cargo is taken."}
	var id = "player_caravan_" + str(state.next_route)
	state.next_route += 1
	state.caravan = {"id": id, "phase": "outbound", "cell": ROUTE.origin.duplicate(), "cargo": ROUTE.quantity, "age": 0, "ambushed": false, "paid": false, "expires": 0}
	report(state, "Caravan dispatched: Stonebridge → Millhaven → Stonebridge. Six grain purchased for 18 gold; delivery pays 36 gold once.")
	return {"ok": true, "gold": gold - ROUTE.funding, "message": state.reports.back()}

static func tick(state: Dictionary, turn: int, board: Array) -> int:
	var c = state.caravan
	if c.is_empty() or c.phase in ["lost", "returned"]: return 0
	if c.phase == "ambushed":
		if turn > c.expires:
			c.phase = "lost"; c.cargo = 0
			report(state, "The funded caravan was lost after its rescue deadline. A new route may be funded.")
		return 0
	c.age += 1
	var destination = ROUTE.destination if c.phase == "outbound" else ROUTE.origin
	var path = Hex.path(Region.pos(c.cell), Region.pos(destination), board, [])
	if path.size() > 1: c.cell = Region.point(path[1])
	if c.phase == "outbound" and c.age == 3 and not c.ambushed:
		c.ambushed = true; c.phase = "ambushed"; c.expires = turn + 5
		report(state, "Your caravan is ambushed. Its six grain are reserved and cannot deliver. Reach its marked position within five turns.")
		return 0
	if c.cell == destination:
		if c.phase == "outbound" and not c.paid and c.cargo == ROUTE.quantity:
			c.paid = true; c.cargo = 0; c.phase = "returning"
			report(state, "Millhaven received six grain. +36 gold. The empty caravan is returning to Stonebridge.")
			return ROUTE.payment
		if c.phase == "returning":
			c.phase = "returned"
			report(state, "Your caravan returned to Stonebridge. The ledger is closed; another dispatch is available.")
	return 0

static func valid(state) -> bool:
	if not state is Dictionary or state.get("version") != 1: return false
	for key in ["merchant", "rescue_started", "rescue_done", "tournament_won"]:
		if not state.get(key) is bool: return false
	if state.merchant and not state.rescue_done or state.rescue_done and not state.rescue_started: return false
	if not Shop.integer(state.get("next_route"), 1, 1000000000) or not state.get("caravan") is Dictionary: return false
	for key in ["loot", "claims", "quest_items", "reports"]:
		if not state.get(key) is Array: return false
	if state.loot.size() > 1000 or state.claims.size() > 10000 or state.reports.size() > 12: return false
	var seen = []
	for id in state.claims:
		if not id is String or id in seen: return false
		seen.append(id)
	for entry in state.loot:
		if not entry is Dictionary or not entry.get("id") is String or entry.id in seen or not entry.get("goods") is Dictionary or not entry.get("modules") is Array or entry.get("left") != false: return false
		seen.append(entry.id)
		for good in entry.goods:
			if good not in Shop.GOODS or not Shop.integer(entry.goods[good], 1, 20): return false
		for module in entry.modules:
			if module not in ["armor", "actuator"]: return false
	seen = []
	for item in state.quest_items:
		if item not in EVIDENCE or item in seen: return false
		seen.append(item)
	for line in state.reports:
		if not line is String or line.length() > 600: return false
	var c = state.caravan
	if not c.is_empty():
		if not c.get("id") is String or not c.id.begins_with("player_caravan_") or c.get("phase") not in ["outbound", "ambushed", "returning", "returned", "lost"] or not Region._cell(c.get("cell")): return false
		for key in ["age", "expires"]:
			if not Shop.integer(c.get(key), 0, 1000000000): return false
		if not Shop.integer(c.get("cargo"), 0, 6) or not c.get("ambushed") is bool or not c.get("paid") is bool: return false
		if c.phase in ["outbound", "ambushed"] and (c.paid or c.cargo != 6): return false
		if c.phase in ["returning", "returned"] and (not c.paid or c.cargo != 0): return false
		if c.phase == "lost" and c.cargo != 0: return false
	return true
