extends RefCounted
## Pure ownership/transaction model. Rendering and file writes belong to callers.
const COLORS = ["243448", "c5a46b", "eee5d1", "52684c", "8d4040", "587b91"]
const EMBLEMS = ["sun", "sword", "tower"]
const ITEMS = {
	"sword": {"name": "Knight's sword", "kind": "weapon", "price": 12, "attack": 0, "armor": 0, "move": 0},
	"shield": {"name": "Kite shield", "kind": "shield", "price": 12, "attack": 0, "armor": 0, "move": 0},
	"armor": {"name": "Reinforced plating", "kind": "module", "price": 12, "attack": 0, "armor": 1, "move": -1},
	"actuator": {"name": "Tuned actuators", "kind": "module", "price": 16, "attack": 0, "armor": -1, "move": 1}
}
const GOODS = {"grain": {"name": "Grain", "buy": 3, "sell": 2}, "ore": {"name": "Iron ore", "buy": 6, "sell": 4}}
const CARGO_CAPACITY = 20

static func defaults(hp: int = 18) -> Dictionary:
	return {
		"frames": [{"id": "frame_1", "chassis": "knight", "name": "Oathkeeper", "hp": hp, "refit": 0, "right": "item_2", "left": "item_3", "module_a": "", "module_b": ""}],
		"items": [{"id": "item_2", "definition": "sword"}, {"id": "item_3", "definition": "shield"}],
		"pilot_frame": "frame_1", "next_id": 4, "cargo": {}, "headquarters": false,
		"banner": {"created": false, "name": "A Banner Reborn", "primary": "243448", "secondary": "c5a46b", "emblem": "sun"}
	}

static func integer(value, low: int, high: int) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and value == floor(value) and value >= low and value <= high

static func frame(state: Dictionary, id: String = "") -> Dictionary:
	for f in state.get("frames", []):
		if f.id == (state.get("pilot_frame", "") if id.is_empty() else id):
			return f
	return {}

static func item(state: Dictionary, id: String) -> Dictionary:
	for owned in state.get("items", []):
		if owned.id == id:
			return owned
	return {}

static func stats(state: Dictionary, f: Dictionary = {}) -> Dictionary:
	if f.is_empty():
		f = frame(state)
	var result = {"hp": 30 + int(f.get("refit", 0)) * 4, "attack": 9, "armor": 2, "move": 3, "range": 1}
	for slot in ["module_a", "module_b"]:
		var owned = item(state, f.get(slot, ""))
		if not owned.is_empty() and ITEMS.has(owned.definition):
			for key in ["attack", "armor", "move"]:
				result[key] += ITEMS[owned.definition][key]
	result.armor = maxi(0, result.armor)
	result.move = maxi(1, result.move)
	return result

static func cargo_used(state: Dictionary) -> int:
	var used = 0
	for quantity in state.get("cargo", {}).values():
		used += int(quantity)
	return used

static func normalized(state: Dictionary) -> Dictionary:
	var result = state.duplicate(true)
	result.next_id = int(result.next_id)
	for f in result.frames:
		f.hp = int(f.hp)
		f.refit = int(f.refit)
	for good in result.cargo:
		result.cargo[good] = int(result.cargo[good])
	return result

static func valid(state) -> bool:
	if not state is Dictionary:
		return false
	for key in ["frames", "items"]:
		if not state.get(key) is Array:
			return false
	if state.frames.is_empty() or state.frames.size() > 128 or state.items.size() > 512:
		return false
	if not state.get("pilot_frame") is String or not integer(state.get("next_id"), 1, 1000000000):
		return false
	if not state.get("headquarters") is bool or not state.get("cargo") is Dictionary or not state.get("banner") is Dictionary:
		return false
	var ids = {}
	var largest_id = 0
	for owned in state.items:
		if not owned is Dictionary or not owned.get("id") is String or not ITEMS.has(owned.get("definition")):
			return false
		if not owned.id.begins_with("item_") or not owned.id.trim_prefix("item_").is_valid_int() or ids.has(owned.id):
			return false
		var number = int(owned.id.trim_prefix("item_"))
		if number < 1:
			return false
		largest_id = maxi(largest_id, number)
		ids[owned.id] = true
	var fitted = {}
	var active_found = false
	for f in state.frames:
		if not f is Dictionary or not f.get("id") is String or f.get("chassis") != "knight":
			return false
		if not f.id.begins_with("frame_") or not f.id.trim_prefix("frame_").is_valid_int() or ids.has(f.id):
			return false
		var number = int(f.id.trim_prefix("frame_"))
		if number < 1:
			return false
		largest_id = maxi(largest_id, number)
		ids[f.id] = true
		if not f.get("name") is String or f.name.strip_edges().is_empty() or f.name.length() > 40 or "\n" in f.name or "\r" in f.name:
			return false
		if not integer(f.get("refit"), 0, 2) or not integer(f.get("hp"), 0, 30 + int(f.refit) * 4):
			return false
		for slot in ["right", "left", "module_a", "module_b"]:
			if not f.get(slot) is String:
				return false
			var id = f[slot]
			if id.is_empty():
				if slot in ["right", "left"]:
					return false
				continue
			var owned = item(state, id)
			if owned.is_empty() or fitted.has(id):
				return false
			var kind = ITEMS[owned.definition].kind
			if (slot == "right" and kind != "weapon") or (slot == "left" and kind != "shield") or (slot.begins_with("module_") and kind != "module"):
				return false
			fitted[id] = true
		var a = item(state, f.module_a)
		var b = item(state, f.module_b)
		if not a.is_empty() and not b.is_empty() and a.definition == b.definition:
			return false
		if f.id == state.pilot_frame:
			active_found = f.hp > 0
	if not active_found or state.next_id <= largest_id:
		return false
	for good in state.cargo:
		if not GOODS.has(good) or not integer(state.cargo[good], 1, CARGO_CAPACITY):
			return false
	if cargo_used(state) > CARGO_CAPACITY:
		return false
	var banner = state.banner
	if not banner.get("created") is bool or not banner.get("name") is String:
		return false
	if banner.name.strip_edges().is_empty() or banner.name.length() > 28 or "\n" in banner.name or "\r" in banner.name:
		return false
	if banner.get("primary") not in COLORS or banner.get("secondary") not in COLORS or banner.primary == banner.secondary or banner.get("emblem") not in EMBLEMS:
		return false
	if banner.created and not state.headquarters:
		return false
	return true

static func _id(state: Dictionary, prefix: String) -> String:
	var result = prefix + "_" + str(int(state.next_id))
	state.next_id += 1
	return result

static func _add_item(state: Dictionary, definition: String) -> String:
	var id = _id(state, "item")
	state.items.append({"id": id, "definition": definition})
	return id

static func fitted_to(state: Dictionary, item_id: String) -> String:
	for f in state.frames:
		for slot in ["right", "left", "module_a", "module_b"]:
			if f[slot] == item_id:
				return f.name
	return ""

static func transact(source: Dictionary, gold: int, action: String, args: Dictionary = {}) -> Dictionary:
	var failure = {"ok": false, "message": "That workshop order is unavailable."}
	if not valid(source) or not integer(gold, 0, 1000000000):
		return failure
	var state = normalized(source)
	var selected = frame(state, str(args.get("frame", state.pilot_frame)))
	var cost = 0
	var message = ""
	match action:
		"buy_frame":
			if state.frames.size() >= 128:
				return failure
			cost = 90
			var id = _id(state, "frame")
			state.frames.append({"id": id, "chassis": "knight", "name": "Reserve Knight " + id.trim_prefix("frame_"), "hp": 30, "refit": 0, "right": _add_item(state, "sword"), "left": _add_item(state, "shield"), "module_a": "", "module_b": ""})
			message = "A refurbished knight frame joins the garage, with a sword and shield."
		"assign":
			if selected.is_empty() or selected.hp <= 0:
				return {"ok": false, "message": "Repair that frame before assigning your pilot."}
			state.pilot_frame = selected.id
			message = "You will pilot " + selected.name + ". The previous frame stays in reserve."
		"sell_frame":
			if selected.is_empty() or selected.id == state.pilot_frame:
				return {"ok": false, "message": "Assign another usable frame before selling this machine."}
			state.frames.erase(selected)
			cost = -45
			message = "Frame sold for 45 gold. Its equipment remains in the armory."
		"refit":
			if selected.is_empty() or selected.refit >= 2:
				return {"ok": false, "message": "This frame already has its maximum hull refit."}
			cost = 18
			selected.refit += 1
			message = "Hull capacity increased by 4. Current damage is preserved."
		"repair":
			if selected.is_empty():
				return failure
			var missing = stats(state, selected).hp - selected.hp
			if missing <= 0:
				return {"ok": false, "message": "This frame is already fully repaired."}
			cost = maxi(1, ceili(missing / 5.0))
			selected.hp = stats(state, selected).hp
			message = "Workshop repair complete."
		"rename":
			var new_name = str(args.get("name", "")).strip_edges()
			if selected.is_empty() or new_name.is_empty() or new_name.length() > 40 or "\n" in new_name or "\r" in new_name:
				return failure
			selected.name = new_name
			message = "Machine name updated."
		"buy_item":
			var definition = str(args.get("definition", ""))
			if not ITEMS.has(definition) or state.items.size() >= 512:
				return failure
			cost = ITEMS[definition].price
			_add_item(state, definition)
			message = ITEMS[definition].name + " stored in the shared armory."
		"equip":
			var slot = str(args.get("slot", ""))
			var id = str(args.get("item", ""))
			if selected.is_empty() or slot not in ["module_a", "module_b"]:
				return failure
			if not id.is_empty():
				var owned = item(state, id)
				if owned.is_empty() or ITEMS[owned.definition].kind != "module" or not fitted_to(state, id).is_empty():
					return {"ok": false, "message": "Choose an unfitted module from the armory."}
			selected[slot] = id
			message = "Module fitting updated. Removed equipment returns to the armory."
		"buy_good", "sell_good":
			var good = str(args.get("good", ""))
			var quantity = args.get("quantity", 1)
			if not GOODS.has(good) or not integer(quantity, 1, CARGO_CAPACITY):
				return failure
			if action == "buy_good":
				if cargo_used(state) + quantity > CARGO_CAPACITY:
					return {"ok": false, "message": "Your cargo hold is full. Capacity: 20 goods."}
				cost = int(quantity) * GOODS[good].buy
				state.cargo[good] = int(state.cargo.get(good, 0)) + int(quantity)
			else:
				if state.cargo.get(good, 0) < quantity:
					return {"ok": false, "message": "You do not carry that quantity."}
				cost = -int(quantity) * GOODS[good].sell
				state.cargo[good] -= int(quantity)
				if state.cargo[good] == 0:
					state.cargo.erase(good)
			message = "Trade completed. Workshop reserves do not occupy cargo space."
		"banner":
			if not state.headquarters:
				return {"ok": false, "message": "Found your headquarters before declaring a personal banner. Try it in Workshop review."}
			if not args.get("banner") is Dictionary:
				return failure
			state.banner = args.get("banner", {}).duplicate(true)
			state.banner.created = true
			message = "Your warband's banner is saved."
		_:
			return failure
	if cost > gold:
		return {"ok": false, "message": "You need %d gold; you have %d. Nothing was changed." % [cost, gold]}
	if not valid(state):
		return {"ok": false, "message": "That combination is invalid. Nothing was changed."}
	return {"ok": true, "state": state, "gold": gold - cost, "message": message}
