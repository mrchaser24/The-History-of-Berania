extends SceneTree
const Hex = preload("res://scripts/hex_grid.gd")
const Battle = preload("res://scripts/battle_model.gd")
const Campaign = preload("res://scripts/campaign_model.gd")
const Region = preload("res://scripts/region_model.gd")
const Shop = preload("res://scripts/workshop_model.gd")
const Demo = preload("res://scripts/demo.gd")
const Saves = preload("res://scripts/save_store.gd")
var checks = 0
var failures = []
var timings = []

func _initialize(): call_deferred("_run")
func check(value: bool, label: String):
	checks += 1
	if not value:
		failures.append(label)
		printerr("FAIL: " + label)

func regional() -> RefCounted:
	var c = Campaign.new()
	c.pending_battle = true
	c.finish_battle("victory", 23)
	c.player = c.village
	c.update_visibility()
	return c

func _run():
	_campaign()
	_combat()
	await _flow()
	var file = FileAccess.open("res://qa/region-results.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"suite": "living-march-0.3", "checks": checks, "failures": failures, "autoplay": timings, "engine": Engine.get_version_info().string}, "\t"))
	file.close()
	print("REGIONAL QA: %d checks; %d failures." % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)

func _campaign():
	var c = regional()
	check(c.board.size() == 70 and c.gold == 40 and c.region.formations.is_empty(), "village victory opens region without gifting an army")
	check(Region.valid(c.region), "new region validates")
	var old = c.snapshot()
	old.schema = 2; old.build = "greyford-demo-0.2"; old.erase("region")
	old.explored = old.explored.filter(func(p): return Region.pos(p) in Hex.cells(6, 5))
	var migrated = Campaign.new()
	check(migrated.restore(old) and migrated.gold == c.gold and migrated.mech_hp == c.mech_hp and migrated.region.formations.is_empty(), "schema2 migration preserves earned resources and grants no formations")
	var failed = c.snapshot()
	c.gold = 0
	check(c.recruit("cannon").begins_with("Insufficient") and c.region.formations.is_empty(), "unaffordable recruitment is atomic")
	c.restore(failed)
	c.recruit("pikemen")
	check(c.gold == 30 and c.region.formations.size() == 1 and c.region.selected.size() == 1, "recruitment spends actual campaign gold")
	var exact = c.snapshot()
	check(Campaign.valid_snapshot(exact), "recruited state validates")
	var restored = Campaign.new()
	check(restored.restore(JSON.parse_string(JSON.stringify(exact))) and restored.snapshot() == exact, "regional nested save round trip exact")
	var party_before = c.region.parties.duplicate(true)
	var turn = c.turn
	c.travel(Hex.cell(5, 2))
	check(c.turn == turn and c.region.parties == party_before, "travel animation path commits no NPC turn")
	c.end_turn()
	check(c.turn == turn + 1 and c.region.parties != party_before and c.region.incidents.size() == 1, "one end turn moves five party kinds and creates attack")
	var incident = c.region.incidents[0].duplicate(true)
	check(Region.pos(incident.cell) not in c.visible, "remote attack stays behind fog")
	c.player = Region.pos(incident.cell); c.update_visibility()
	check(Region.pos(incident.cell) in c.visible and not c.prepare_region(incident.kind, incident.id).is_empty(), "visible attack at player position supports intervention")
	for i in 5: c.end_turn()
	var found = false
	for item in c.region.incidents:
		if item.id == incident.id: found = true
	check(not found, "ignored attack expires after committed turns")
	c.player = c.village
	c.regional_order("guild")
	check(c.region.job == "grain", "guild contract accepted without advancing time")
	var order = Shop.transact(c.workshop, c.gold, "buy_good", {"good": "grain", "quantity": 2})
	c.workshop = order.state; c.gold = order.gold
	c.player = Region.pos(Region.SETTLEMENTS[2].cell); c.update_visibility()
	var gold = c.gold
	c.regional_order("deliver")
	check(c.gold == gold + 16 and not c.workshop.cargo.has("grain") and c.region.deliveries == 1, "carried grain delivery consumes exact cargo and grants once")
	gold = c.gold; c.regional_order("deliver")
	check(c.gold == gold and Campaign.valid_snapshot(c.snapshot()), "duplicate delivery cannot pay and zero cargo remains valid")
	c.player = Region.pos(Region.SETTLEMENTS[1].cell); c.update_visibility()
	c.gold = 100; c.trust = 2
	c.regional_order("diplomacy")
	check(c.region.allied and c.gold == 80, "independent envoy signs concrete paid support terms")
	c.regional_order("diplomacy")
	check(c.gold == 80, "existing pact never charges again")
	var prepared = c.prepare_region("guild")
	check(prepared.friendly.size() == 6 and prepared.friendly[2].id == "support_0", "owned, allied and local formations share encounter roster")
	check(c.commit_region(prepared) and c.pending_battle and Campaign.valid_snapshot(c.snapshot()), "preparation locks valid snapshot before combat")
	var locked = c.region.pending.duplicate(true)
	var blocked_turn = c.snapshot()
	check(c.end_turn().is_empty() and c.travel(c.village).is_empty() and c.snapshot() == blocked_turn, "locked encounter prevents campaign time and travel mutations")
	var saved_pending = c.snapshot()
	var pending_copy = Campaign.new()
	check(pending_copy.restore(JSON.parse_string(JSON.stringify(saved_pending))) and pending_copy.snapshot() == saved_pending, "locked frame and pending battle survive JSON numeric normalization")
	var corrupt_pending = c.snapshot()
	corrupt_pending.region.pending.friendly[0].stats.attack += 1
	check(not Campaign.valid_snapshot(corrupt_pending), "pending frame statistics must match actual owned fittings")
	corrupt_pending = c.snapshot()
	corrupt_pending.region.pending.enemy[0].id = "hero"
	check(not Campaign.valid_snapshot(corrupt_pending), "unit IDs cannot collide between opposing sides")
	c.region.selected.clear()
	check(c.region.pending == locked, "deployment independent of later selection array edits")
	var battle = Battle.new(locked)
	battle.unit(c.region.formations[0].id).hp = 3
	battle.unit("hero").hp = 7
	battle.outcome = "victory"
	gold = c.gold
	check(c.finish_region(battle) and c.gold == gold + prepared.reward and c.mech_hp == 7 and c.region.formations[0].hp == 3, "battle results persist gold and owned hull / formation strength")
	var finished = c.snapshot()
	check(not c.finish_region(battle) and c.snapshot() == finished, "stale regional result idempotent")
	check(c.prepare_region("guild").is_empty(), "won road job needs two travel turns to reopen")
	c.regional_order("replenish")
	check(c.region.formations[0].hp == Battle.COMBINED.pikemen.hp, "replenishment restores actual saved formation strength")
	for i in 2: c.end_turn()
	check(not c.prepare_region("guild").is_empty(), "repeatable work reopens after committed turns")
	c.region.selected = [c.region.formations[0].id]
	c.commit_region(c.prepare_region("guild")); battle = Battle.new(c.region.pending)
	battle.unit("hero").hp = 0; battle.unit(c.region.formations[0].id).cohesion = 2; battle.outcome = "defeat"
	c.gold = 0
	check(c.finish_region(battle) and c.gold == 0 and c.player == c.village and c.mech_hp == c.max_hull() and c.region.formations[0].hp == 1, "regional defeat recovers disabled frame at zero gold and wounds routed formation")
	check(not c.prepare_region("guild").is_empty(), "essential work remains retryable after defeat")
	var invalid = c.snapshot()
	invalid.region.formations.append(invalid.region.formations[0].duplicate(true))
	check(not Campaign.valid_snapshot(invalid), "duplicate owned formation rejected")
	invalid = c.snapshot(); invalid.region.parties[0].cell = [999, 0]
	check(not Campaign.valid_snapshot(invalid), "off-region NPC state rejected")
	invalid = c.snapshot(); invalid.region.selected = ["missing"]
	check(not Campaign.valid_snapshot(invalid), "dangling deployment selection rejected")
	invalid = c.snapshot(); invalid.region.ticks = 1.5
	check(not Campaign.valid_snapshot(invalid), "fractional regional time rejected")
	c.gold = 1000
	while c.region.formations.size() < 14: c.recruit("roadwardens")
	c.region.selected.clear()
	for f in c.region.formations: c.region.selected.append(f.id)
	var big = Region.roster(c.region, c.workshop, c.region.selected, true, true)
	check(big.size() == 15 and big[-1].get("owned", false), "15 slots include protagonist and owned troops before allied overflow")
	var small = Region.roster(c.region, c.workshop, c.region.selected)
	check(small.size() == 10, "ordinary shared cap excludes excess allies without stat bonuses")

func encounter(major: bool = false) -> Dictionary:
	var cap = 15 if major else 10
	var friend = [{"id": "hero", "definition": "militia_mech"}]
	var roles = ["pikemen", "roadwardens", "cavalry", "cannon", "mages", "greyford_blades"]
	for i in cap - 1: friend.append({"id": "ally_" + str(i), "definition": roles[i % roles.size()]})
	return {"major": major, "friendly": friend, "enemy": Region.enemies(cap)}

func _combat():
	for major in [false, true]:
		var b = Battle.new(encounter(major))
		check(b.units.size() == (30 if major else 20) and b.board.size() == (216 if major else 140), "force scale has dedicated legal map")
		var positions = []
		for u in b.units:
			check(u.pos in b.board and u.pos not in b.blocked and u.pos not in positions, "large-force spawn is unique, on-board and unobstructed")
			positions.append(u.pos)
		for u in b.units:
			if u.side == 0: check(not b.reachable_paths(u.id).is_empty(), "every deployed friendly has maneuvering room")
		var start = Time.get_ticks_msec()
		var operations = 0
		while b.outcome.is_empty() and operations < 2000:
			for u in b.units:
				if u.side != b.side: continue
				for action in 3:
					if b.can_activate(u.id):
						check(not b.ai_action(u.id).is_empty(), "mixed-role AI always makes a finite legal action")
						operations += 1
			if b.outcome.is_empty(): b.end_side()
		check(not b.outcome.is_empty() and operations < 2000, "full capacity battle reaches result without stalls")
		timings.append({"units": b.units.size(), "ms": Time.get_ticks_msec() - start, "operations": operations, "round": b.round_number, "outcome": b.outcome})
	var b = Battle.new(encounter())
	var gun = b.unit("ally_1"); var target = b.unit("foe_0")
	gun.pos = Hex.cell(1, 0); target.pos = Hex.cell(4, 0); target.facing = 3
	b.cover[target.pos] = {"value": 2, "facing": 3}
	var preview = b.attack_preview(gun.id, target.id)
	check(preview.cover == 2, "cover protects the marked incoming arc")
	b.cover[target.pos].facing = 0
	check(b.attack_preview(gun.id, target.id).damage == preview.damage + 2, "flanking bypasses directional cover")
	b.cover[target.pos].facing = 3
	var aimed = b.attack_preview(gun.id, target.id, true)
	var hp = target.hp
	var record = b.attack(gun.id, target.id, true)
	check(hp - target.hp == mini(hp, aimed.damage) and gun.cooldown == 3, "special preview exact and cooldown spent once")
	check(b.attack(gun.id, target.id, true).is_empty(), "special cannot repeat activation")
	b = Battle.new(encounter())
	gun = b.unit("ally_1"); target = b.unit("foe_0")
	gun.pos = Hex.cell(1, 0); target.pos = Hex.cell(5, 0)
	gun.moved = true
	check(not b.can_attack(gun.id, target.id, true), "aimed shot unavailable after movement")
	var mage = b.unit("ally_4")
	mage.pos = Hex.cell(1, 0); target.pos = Hex.cell(3, 0); target.armor = 8; target.facing = 3
	b.cover[target.pos] = {"value": 2, "facing": 3}
	preview = b.attack_preview(mage.id, target.id)
	check(preview.armor == 0 and preview.cover == 1, "mage counters armor but retains one cover mitigation")
	var hero = b.unit("hero")
	hero.pos = Hex.cell(0, 0); hero.hp = 20
	check(b.can_mend(mage.id, "hero"), "mage can target nearby wounded ally")
	var healed = b.mend(mage.id, "hero")
	check(healed.restored == 4 and hero.hp == 24 and mage.acted and mage.cooldown == 3, "mend heals four and consumes activation / cooldown")
	check(b.guard_reduction({"guard": true, "kind": "pike"}, {"kind": "cavalry"}) == 6, "braced pikes counter cavalry")
	b = Battle.new(encounter()); hero = b.unit("hero")
	hero.pos = Hex.cell(0, 0); b.terrain[Hex.cell(1, 0)] = 2
	check(b.path_cost([hero.pos, Hex.cell(1, 0)]) == 2, "rough terrain cost is explicit")
	check(not b.movement_path("hero", Hex.cell(2, 0)).is_empty(), "weighted movement can find affordable path")
	hero.pos = b.objective
	for i in 3:
		b.end_side()
		if i < 2: b.end_side()
	check(b.outcome == "victory" and b.objective_progress == 3, "objective wins after three consecutive completed player turns")
	b = Battle.new(encounter()); hero = b.unit("hero")
	hero.pos = b.objective; b.end_side(); b.end_side()
	hero.pos = Hex.cell(1, 1); b.end_side()
	check(b.objective_progress == 0, "vacating the crossing resets consecutive hold progress")
	b = Battle.new(encounter()); gun = b.unit("ally_1"); target = b.unit("foe_0")
	gun.pos = Hex.cell(1, 0); target.pos = Hex.cell(3, 0)
	b.attack(gun.id, target.id, true)
	for i in 3:
		b.end_side(); b.end_side()
		check(gun.cooldown == 2 - i, "ability cooldown counts subsequent own turns exactly")
	b = Battle.new(encounter()); var cavalry = b.unit("ally_2")
	target = b.unit("foe_0"); cavalry.pos = Hex.cell(1, 0); target.pos = Hex.cell(2, 0)
	cavalry.travelled = 2; cavalry.moved = true
	var normal = b.attack_preview(cavalry.id, target.id).damage
	check(b.attack_preview(cavalry.id, target.id, true).damage == normal + 4, "charge bonus requires a qualifying movement")
	cavalry.travelled = 1
	check(b.attack_preview(cavalry.id, target.id, true).damage == normal, "short reposition grants no charge bonus")
	b = Battle.new(encounter()); var cannon = b.unit("ally_3")
	target = b.unit("foe_0"); cannon.pos = Hex.cell(1, 0); target.pos = Hex.cell(4, 0)
	b.cover[target.pos] = {"value": 2, "facing": 3}
	check(b.attack_preview(cannon.id, target.id, true).cover == 0, "bombard ignores cover")
	cannon.moved = true
	check(not b.can_attack(cannon.id, target.id, true), "moving locks out bombard but permits normal fire")

func _flow():
	var d = Demo.new(); root.add_child(d)
	d.campaign = regional(); d.phase = "world"; d.saves = Saves.new("/tmp/berania_regional_flow_qa.json")
	d._refresh_ui(); d._world_click(d.campaign.player)
	check(d.phase == "settlement", "defended village enters settlement services")
	d._service("guild"); d._trade_cargo("buy_good", "grain")
	check(d.campaign.region.job == "grain" and d.campaign.workshop.cargo.get("grain", 0) == 1, "settlement service buttons operate on campaign inventory")
	d._hire("roadwardens")
	d._open_workshop(false)
	d._workshop_order("buy_item", {"definition": "armor"})
	var fitted = d.campaign.workshop.items[-1].id
	d._workshop_order("equip", {"slot": "module_a", "item": fitted})
	d._close_workshop()
	check(d.phase == "settlement" and Shop.stats(d.campaign.workshop).armor == 3, "regional settlement workshop fits actual shared equipment and returns to services")
	d._open_preparation("guild")
	check(d.phase == "preparation" and d._preview_preparation().friendly.size() == 4, "regional battle opens owned + local preparation")
	var snapshot = d.campaign.snapshot()
	d._commit_preparation()
	check(d.phase == "battle" and d.battle.combined and d.campaign.pending_battle, "prepared encounter launches integrated tactical model")
	check(d.battle.unit("hero").armor == 3 and d.battle.unit("hero").move == 2, "regional deployment consumes fitted plating armor / mobility tradeoff")
	var locked = d.campaign.snapshot(); d.battle.unit("hero").hp = 1
	d._continue_demo()
	check(d.phase == "battle" and d.battle.unit("hero").hp == 23 and d.campaign.snapshot() == locked, "Continue restores locked regional deployment")
	d.battle.outcome = "victory"; d._finish_battle(); var result = d.campaign.snapshot(); d._finish_battle()
	check(d.phase == "results" and result == d.campaign.snapshot(), "regional UI result callback cannot double-pay")
	d._leave_results()
	check(d.phase == "world" and not d.campaign.pending_battle, "regional result returns to continuing map")
	d.campaign = regional(); d.phase = "world"; d.saves = Saves.new("/tmp/berania_region_missing_8939/save.json")
	d._interact_region(); var before = d.campaign.snapshot(); d._hire("pikemen")
	check(d.campaign.snapshot() == before and d.modal == "save_error", "failed recruitment checkpoint rolls back roster and gold")
	d.modal = ""; d._open_preparation("guild"); d._commit_preparation()
	check(d.campaign.snapshot() == before and d.phase == "preparation", "failed battle entry save rolls back pending deployment")
	d.saves = Saves.new("/tmp/berania_ui_qa.json"); d.phase = "title"; d.modal = ""
	var real_path = d.saves.path
	d._open_region_review(true)
	check(d.region_review and d.saves.path != real_path, "regional review uses independent save path")
	var review = d.campaign.snapshot()
	d._capacity_review(true)
	check(d.practice and d.battle.units.size() == 30, "15v15 practice available from regional review")
	for zoom in [0.8, 1.0, 1.5]:
		d.battle_zoom = zoom; d.battle_pan = Vector2(-100, -30)
		for u in d.battle.units:
			var point = d._pos(u.pos)
			check(d._cell_at(point, false) == (u.pos if d.BATTLE_FIELD.has_point(point) else Vector2i(-999, -999)), "battle camera transforms target visible cells and reject offscreen cells")
	d.modal = "restart"; d._confirm_modal()
	check(d.battle.units.size() == 30 and d.battle.combined and d.campaign.snapshot() == review, "capacity restart preserves scale and isolated state")
	d.modal = "pause"; d._refresh_ui()
	var leave_button
	for child in d.ui.get_children():
		if child is Button and child.text == "Return to region": leave_button = child
	check(leave_button != null, "capacity pause has a direct region exit")
	if leave_button != null: leave_button.pressed.emit()
	check(d.phase == "world" and d.campaign.snapshot() == review and d.modal.is_empty(), "capacity pause exit leaves regional state unchanged")
	d._capacity_review(true)
	d.battle.outcome = "defeat"; d._finish_battle(); d._leave_results()
	check(d.phase == "world" and d.campaign.snapshot() == review, "capacity results cannot alter review or campaign state")
	d.modal = "home"; d._confirm_modal()
	check(d.phase == "title" and not d.region_review and d.saves.path == real_path, "leaving regional review restores real save store")
	d.queue_free(); await process_frame; await process_frame
