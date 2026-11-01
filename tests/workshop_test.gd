extends SceneTree
const Shop = preload("res://scripts/workshop_model.gd")
const Campaign = preload("res://scripts/campaign_model.gd")
const Saves = preload("res://scripts/save_store.gd")
const Demo = preload("res://scripts/demo.gd")
var checks = 0
var failures = []

func check(condition: bool, message: String):
	checks += 1
	if not condition:
		failures.append(message)
		printerr("FAIL: " + message)

func _initialize():
	call_deferred("_run")

func _run():
	var c = Campaign.new()
	check(Shop.valid(c.workshop) and c.workshop.frames.size() == 1 and c.workshop.items.size() == 2 and c.gold == 0, "new fugitive owns only equipped Oathkeeper")
	check(c.mech_hp == 18 and not c.workshop.headquarters and not c.workshop.banner.created, "fresh game grants neither free repairs nor headquarters")
	var original = c.workshop.duplicate(true)
	var order = Shop.transact(c.workshop, 0, "buy_frame")
	check(not order.ok and c.workshop == original, "unaffordable purchase is atomic")
	order = Shop.transact(c.workshop, 180, "buy_frame")
	check(order.ok and order.gold == 90 and order.state.frames.size() == 2 and original == c.workshop, "buy creates a separate equipped reserve without mutating input")
	var state = order.state
	var reserve = state.frames[1].id
	check(state.items.size() == 4 and Shop.frame(state).name == "Oathkeeper", "new frame creates real equipment and does not steal pilot")
	check(not Shop.transact(state, 90, "sell_frame", {"frame": state.pilot_frame}).ok, "active required frame cannot be sold")
	order = Shop.transact(state, 90, "assign", {"frame": reserve})
	state = order.state
	check(Shop.frame(state).id == reserve and state.frames.size() == 2, "assign retains old frame in storage")
	order = Shop.transact(state, 90, "sell_frame", {"frame": "frame_1"})
	check(order.ok and order.gold == 135 and order.state.items.size() == 4, "selling reserve retains its owned fittings")
	order = Shop.transact(state, 90, "buy_item", {"definition": "armor"})
	state = order.state
	var armor_id = state.items[-1].id
	order = Shop.transact(state, order.gold, "equip", {"frame": reserve, "slot": "module_a", "item": armor_id})
	state = order.state
	check(order.ok and Shop.stats(state).armor == 3 and Shop.stats(state).move == 2, "plating changes the tactical build")
	check(not Shop.transact(state, order.gold, "equip", {"frame": "frame_1", "slot": "module_b", "item": armor_id}).ok, "physical module cannot be fitted twice")
	order = Shop.transact(state, order.gold, "equip", {"frame": reserve, "slot": "module_a", "item": ""})
	state = order.state
	check(order.ok and Shop.fitted_to(state, armor_id).is_empty() and Shop.stats(state).move == 3, "removing module restores stored ownership and base stats")
	order = Shop.transact(state, 90, "refit", {"frame": reserve})
	state = order.state
	check(order.ok and Shop.stats(state).hp == 34 and Shop.frame(state).hp == 30, "hull refit preserves damage rather than healing")
	order = Shop.transact(state, order.gold, "repair", {"frame": reserve})
	check(order.ok and Shop.frame(order.state).hp == 34, "paid repair respects upgraded hull")
	order = Shop.transact(state, 90, "buy_good", {"good": "grain", "quantity": 20})
	state = order.state
	check(order.ok and order.gold == 30 and Shop.cargo_used(state) == 20, "trade charges once and fills cargo")
	var full = state.duplicate(true)
	check(not Shop.transact(state, 30, "buy_good", {"good": "ore"}).ok and state == full, "full cargo rejects purchase unchanged")
	check(not Shop.transact(state, 30, "sell_good", {"good": "ore"}).ok, "unowned goods cannot be sold")
	check(not Shop.transact(state, 30, "buy_good", {"good": "grain", "quantity": -1}).ok, "negative trade quantity rejected")
	check(not Shop.transact(state, 30, "banner", {"banner": state.banner}).ok, "banner founding locked until headquarters")
	state.headquarters = true
	var banner = state.banner.duplicate(true)
	banner.name = "The Dawnward"
	banner.emblem = "tower"
	order = Shop.transact(state, 30, "banner", {"banner": banner})
	check(order.ok and order.state.banner.created and order.state.banner.name == "The Dawnward", "two-color crest saves at headquarters")
	check(not Shop.transact(state, 30, "banner", {"banner": []}).ok, "malformed banner order fails safely")
	banner.secondary = banner.primary
	check(not Shop.transact(state, 30, "banner", {"banner": banner}).ok, "invisible same-color crest rejected")
	var broken = state.duplicate(true)
	broken.items.append(broken.items[0].duplicate(true))
	check(not Shop.valid(broken), "duplicate inventory IDs rejected")
	broken = state.duplicate(true)
	broken.frames[0].right = "missing"
	check(not Shop.valid(broken), "dangling fitting rejected")
	broken = state.duplicate(true)
	broken.next_id = 1
	check(not Shop.valid(broken), "ID counter cannot reuse existing assets")
	var saved = c.snapshot()
	saved.schema = 1
	saved.build = "greyford-demo-0.1"
	saved.erase("workshop")
	saved.gold = 63
	saved.mech_hp = 17
	var migrated = Campaign.new()
	check(migrated.restore(JSON.parse_string(JSON.stringify(saved))), "schema-1 campaign migrates")
	check(migrated.snapshot().schema == 3 and migrated.gold == 63 and migrated.mech_hp == 17 and migrated.workshop.frames.size() == 1, "migration preserves resources and condition without granting extra assets")
	c.workshop = state
	c.gold = 30
	var copy = Campaign.new()
	check(copy.restore(JSON.parse_string(JSON.stringify(c.snapshot()))) and copy.snapshot() == c.snapshot(), "nested owned inventory survives exact JSON round trip")
	broken = c.snapshot()
	broken.mech_hp -= 1
	check(not Campaign.valid_snapshot(broken), "contradictory active hull mirror rejected")
	var d = Demo.new()
	root.add_child(d)
	var main_before = d.campaign.snapshot()
	d._open_workshop(true)
	await process_frame
	await process_frame
	var body = d.workshop_panel.find_child("WorkshopBody", true, false)
	check(body != null and body.size.y >= 400 and d.workshop_panel.container.size == Vector2(1600, 900), "workshop fills the logical game canvas with a usable body")
	check(d.phase == "workshop" and d.workshop_owner != d.campaign and d.campaign.snapshot() == main_before, "review sandbox isolated from campaign")
	var review_before = d.workshop_owner.snapshot()
	d.workshop_store = Saves.new("/tmp/berania_workshop_missing_directory_8842/save.json")
	d._workshop_order("buy_item", {"definition": "armor"})
	check(d.workshop_owner.snapshot() == review_before and "rolled back" in d.workshop_panel.status_text, "filesystem failure rolls back gold and inventory together")
	d.workshop_store = Saves.new("/tmp/berania_workshop_review_test.json")
	d.workshop_owner = Campaign.new()
	d.workshop_owner.gold = 180
	d.workshop_owner.workshop.headquarters = true
	d.workshop_panel.owner_campaign = d.workshop_owner
	d._workshop_order("buy_item", {"definition": "actuator"})
	var module_id = d.workshop_owner.workshop.items[-1].id
	d._workshop_order("equip", {"slot": "module_a", "item": module_id})
	var trial_before = d.workshop_owner.snapshot()
	d._workshop_order("trial", {})
	check(d.phase == "battle" and d.battle.unit("hero").move == 4 and d.battle.unit("hero").armor == 1, "training battle uses workshop loadout stats")
	d.battle.unit("hero").hp = 0
	d.battle._check_outcome()
	d._finish_battle()
	d._leave_results()
	check(d.phase == "workshop" and d.workshop_panel.visible and d.workshop_owner.snapshot() == trial_before and d.campaign.snapshot() == main_before, "training defeat returns without damaging review or real campaign")
	d._workshop_order("trial", {})
	d.modal = "pause"
	d._refresh_ui()
	var leave_button
	for node in d.ui.get_children():
		if node is Button and node.text == "Return to workshop":
			leave_button = node
	check(leave_button != null, "practice pause offers a direct exit")
	if leave_button != null:
		leave_button.pressed.emit()
	check(d.phase == "workshop" and d.modal.is_empty() and d.workshop_owner.snapshot() == trial_before, "leaving practice from pause preserves workshop state")
	for page in ["Equipment", "Market", "Banner", "Art review"]:
		d.workshop_panel._choose_tab(page)
		await process_frame
		await process_frame
		body = d.workshop_panel.find_child("WorkshopBody", true, false)
		check(body.size.y >= 400 and body.size.x <= 1536, page + " fits inside the workshop viewport")
	d._workshop_order("reset_review", {})
	check(d.workshop_owner.gold == 180 and d.workshop_owner.workshop.frames.size() == 1 and d.campaign.snapshot() == main_before, "review reset preserves real campaign and restores review budget")
	d._close_workshop()
	check(d.phase == "title", "review exits to title")
	d.phase = "world"
	d.campaign.player = d.campaign.village
	d._open_workshop(false)
	check(d.phase == "world", "campaign workshop requires village defense")
	d.campaign.rewarded = true
	d.campaign.quest = "complete"
	d.campaign.gold = 40
	d._open_workshop(false)
	check(d.phase == "workshop" and d.workshop_owner == d.campaign, "earned village workshop uses campaign ownership")
	d._workshop_order("refit", {})
	check(d.campaign.gold == 22 and d.campaign.max_hull() == 34, "campaign purchase persists real cost and hull refit")
	d._close_workshop()
	check(d.phase == "world", "campaign workshop exits to world")
	d.queue_free()
	await process_frame
	await process_frame
	var file = FileAccess.open("res://qa/workshop-results.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"suite": "workshop-prototype-0.2", "checks": checks, "failures": failures}, "\t"))
	file.close()
	print("WORKSHOP QA: %d checks; %d failures." % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
