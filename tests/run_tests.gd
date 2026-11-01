extends SceneTree
const Hex = preload("res://scripts/hex_grid.gd")
const Battle = preload("res://scripts/battle_model.gd")
const Campaign = preload("res://scripts/campaign_model.gd")
const Saves = preload("res://scripts/save_store.gd")
const Demo = preload("res://scripts/demo.gd")
var checks = 0
var failures = []

func _initialize():
	call_deferred("_run")

func check(condition: bool, label: String):
	checks += 1
	if not condition:
		failures.append(label)
		printerr("FAIL: " + label)

func _run():
	_hex_tests()
	_battle_tests()
	_campaign_tests()
	_save_tests()
	_animation_tests()
	var result = {"checks": checks, "failures": failures, "engine": Engine.get_version_info().string, "suite": "greyford-demo-0.1"}
	var file = FileAccess.open("res://qa/test-results.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(result, "\t"))
		file.close()
	print("QA: %d checks; %d failures." % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)

func _hex_tests():
	var origin = Vector2i.ZERO
	check(Hex.cells(8, 8).size() == 64, "battle has 64 unique cells")
	for d in Hex.DIRECTIONS:
		check(Hex.distance(origin, d) == 1, "each axial neighbor is distance one")
		check(Hex.distance(origin, d * 3) == 3, "axial distance scales along a ray")
	for r in 8:
		for c in 8:
			check(Hex.column(Hex.cell(c, r)) == c, "offset/axial column round trip")
	var board = Hex.cells(4, 4)
	var path = Hex.path(Hex.cell(0, 0), Hex.cell(3, 3), board, [])
	check(not path.is_empty(), "connected board has path")
	for i in range(1, path.size()):
		check(Hex.distance(path[i - 1], path[i]) == 1, "path follows six-neighbor steps")
	check(Hex.path(Vector2i.ZERO, Hex.cell(3, 3), board, [Hex.cell(3, 3)]).is_empty(), "blocked destination rejected")
	check(Hex.path(Vector2i.ZERO, Vector2i(100, 100), board, []).is_empty(), "off-board destination rejected")
	var a = Vector2i.ZERO
	var b = Vector2i(3, 3)
	var line = Hex.line(a, b)
	var reverse = Hex.line(b, a)
	reverse.reverse()
	check(line == reverse, "hex LOS tie handling is symmetric")
	var weighted = Hex.path(Vector2i.ZERO, Vector2i(2, 0), Hex.cells(4, 4), [], {Vector2i(1, 0): 9})
	check(Vector2i(1, 0) not in weighted, "weighted path avoids costly tile when cheaper route exists")

func _battle_tests():
	var b = Battle.new()
	check(b.units.size() == 6, "six commandable entities")
	var ids = []
	var positions = []
	for u in b.units:
		check(u.id not in ids, "unit instance IDs unique")
		check(u.pos not in positions and u.pos not in b.blocked, "legal non-overlapping deployment")
		ids.append(u.id)
		positions.append(u.pos)
	check(b.move_unit("hero", b.unit("blades").pos).is_empty(), "occupied movement rejected")
	check(b.move_unit("hero", Hex.cell(7, 0)).is_empty(), "over-budget movement rejected")
	var destination = Hex.cell(2, 5)
	check(not b.move_unit("hero", destination).is_empty(), "legal move succeeds")
	check(b.unit("hero").pos == destination, "logical position committed once")
	check(b.move_unit("hero", Hex.cell(3, 5)).is_empty(), "second move rejected")
	check(not b.can_activate("blades"), "moving locks the active unit until attack/guard")
	check(not b.guard_unit("hero").is_empty(), "guard finishes activation")
	check(b.can_activate("blades"), "guard releases activation lock")
	check(b.guard_unit("hero").is_empty(), "second action rejected")
	check(not b.has_los(Hex.cell(2, 3), Hex.cell(5, 3)), "blocked rocks stop line of sight")
	b.end_side()
	check(b.side == 1 and b.unit("hero").guard, "guard persists through opposing side")
	b.end_side()
	check(b.side == 0 and not b.unit("hero").guard and b.round_number == 2, "guard expires on own next turn")
	b = Battle.new()
	var hero = b.unit("hero")
	var target = b.unit("raiders")
	hero.pos = Vector2i(0, 0)
	target.pos = Vector2i(1, 0)
	target.facing = 3
	var preview = b.attack_preview("hero", "raiders")
	var old_hp = target.hp
	var action = b.attack("hero", "raiders")
	check(old_hp - target.hp == mini(old_hp, preview.damage), "damage preview equals applied damage")
	var after_hp = target.hp
	check(b.attack("hero", "raiders").is_empty() and target.hp == after_hp, "duplicate attack cannot damage twice")
	check(not b.rotate_unit("hero"), "acted units cannot rotate")
	b = Battle.new()
	hero = b.unit("hero")
	target = b.unit("raiders")
	hero.pos = Vector2i.ZERO
	target.pos = Vector2i(1, 0)
	target.facing = 3
	var frontal = b.attack_preview("hero", "raiders").damage
	target.facing = 0
	var rear = b.attack_preview("hero", "raiders").damage
	check(rear == frontal + 3, "rear damage bonus is fixed and previewed")
	target.guard = true
	check(b.attack_preview("hero", "raiders").damage == rear - 2, "guard mitigation matches preview")
	hero.attack = 1
	target.armor = 100
	check(b.attack_preview("hero", "raiders").damage == 1, "minimum damage remains one")
	check(b.rotate_unit("hero") and not b.rotate_unit("hero"), "one facing adjustment per activation")
	b.attack("hero", "raiders")
	check(target.cohesion == 1, "rear hit shakes formation")
	hero.acted = false
	b.attack("hero", "raiders")
	check(target.cohesion == 2 and not b.alive(target), "second cohesion drop routes formation")
	check(b.move_unit("hero", target.pos).is_empty(), "unit that attacked cannot then move")
	b = Battle.new()
	b.unit("hero").hp = 0
	for u in b.units:
		if u.side == 1:
			u.hp = 0
	b._check_outcome()
	check(b.outcome == "defeat", "protagonist defeat takes precedence over enemy removal")
	b = Battle.new()
	for u in b.units:
		if u.side == 1:
			u.cohesion = 2
	b._check_outcome()
	check(b.outcome == "victory", "routed enemies count toward victory")
	# A trapped AI must guard/end instead of stalling.
	b = Battle.new()
	b.end_side()
	var raider = b.unit("raiders")
	b.blocked.clear()
	for direction in Hex.DIRECTIONS:
		b.blocked.append(raider.pos + direction)
	check(b.ai_action("raiders").type == "guard", "trapped AI has a finite finish path")
	# The same rules can play an entire encounter without UI intervention.
	b = Battle.new()
	var operations = 0
	var walkthrough = []
	while b.outcome.is_empty() and b.round_number <= 35 and operations < 1000:
		var current_side = b.side
		for u in b.units:
			if u.side != current_side:
				continue
			var per_unit = 0
			while b.can_activate(u.id) and per_unit < 3:
				var record = b.ai_action(u.id)
				var entry = {"side": current_side, "round": b.round_number, "id": u.id, "type": record.get("type", "")}
				if record.get("type") == "move":
					entry.destination = [Hex.column(record.path[-1]), record.path[-1].y]
				elif record.get("type") == "attack":
					entry.target = record.target
				walkthrough.append(entry)
				operations += 1
				per_unit += 1
				check(not record.is_empty(), "AI action is valid and terminates")
		if b.outcome.is_empty():
			b.end_side()
	check(not b.outcome.is_empty() and operations < 1000, "whole battle terminates within safety bound")
	check(b.outcome == "victory", "starter force can win with legal shared-rule tactics")
	print("Autoplay battle: %s in round %d (%d actions)." % [b.outcome, b.round_number, operations])
	var walkthrough_file = FileAccess.open("res://qa/autoplay-walkthrough.json", FileAccess.WRITE)
	walkthrough_file.store_string(JSON.stringify(walkthrough, "\t"))
	walkthrough_file.close()

func _campaign_tests():
	var c = Campaign.new()
	check(c.board.size() == 30, "demo world has 30 hexes")
	check(c.gold == 0 and c.trust == 0 and not c.pending_battle, "fugitive begins penniless with no earned support")
	var older_save = c.snapshot()
	older_save.gold = 60
	var existing_campaign = Campaign.new()
	check(existing_campaign.restore(older_save) and existing_campaign.gold == 60, "story correction preserves older saved resources")
	check(c.player in c.visible, "party sees its own hex")
	var before = c.snapshot()
	check(c.travel(Vector2i(100, 100)).is_empty() and c.snapshot() == before, "invalid travel does not mutate campaign")
	var path = c.travel(c.village)
	check(path.size() == 3 and c.player == c.village and c.budget == 1, "village reachable with one budgeted path")
	var old_exploration = c.explored.duplicate()
	c.end_turn()
	check(c.turn == 2 and c.budget == 3 and c.patrol != Vector2i(before.patrol[0], before.patrol[1]), "End Turn advances NPC and refreshes budget once")
	for p in old_exploration:
		check(p in c.explored, "exploration memory retained")
	var snapshot = JSON.parse_string(JSON.stringify(c.snapshot()))
	check(Campaign.valid_snapshot(snapshot), "JSON round-trip snapshot valid")
	var copy = Campaign.new()
	check(copy.restore(snapshot) and copy.snapshot() == c.snapshot(), "campaign round trip preserves state")
	c.pending_battle = true
	check(c.finish_battle("victory", 17), "first victory applies reward")
	check(c.gold == 40 and c.trust == 1 and c.mech_hp == 17 and not c.pending_battle, "victory amount and flags exact")
	var rewarded = c.snapshot()
	check(not c.finish_battle("victory", 1) and c.snapshot() == rewarded, "replayed victory result is idempotent")
	check(not c.finish_battle("defeat", 0) and c.snapshot() == rewarded, "stale defeat cannot undo completed result")
	c = Campaign.new()
	c.gold = 0
	c.pending_battle = true
	c.finish_battle("defeat", 0)
	check(c.gold == 0 and c.mech_hp == 30 and c.quest == "retry" and c.player == c.village, "zero-gold defeat recovers at village without reward")
	check(Campaign.valid_snapshot(c.snapshot()), "recovered campaign remains saveable")
	for key in ["turn", "budget", "gold", "trust", "mech_hp"]:
		var bad = c.snapshot()
		bad[key] = -1
		check(not Campaign.valid_snapshot(bad), "negative field rejected: " + key)
	var bad = c.snapshot()
	bad.player = [0.5, 1]
	check(not Campaign.valid_snapshot(bad), "fractional coordinates rejected")
	bad = c.snapshot()
	bad.explored.append(bad.explored[0])
	check(not Campaign.valid_snapshot(bad), "duplicate exploration cells rejected")
	bad = c.snapshot()
	bad.schema = 999
	check(not Campaign.valid_snapshot(bad), "incompatible schema rejected")
	bad = c.snapshot()
	bad.rewarded = true
	check(not Campaign.valid_snapshot(bad), "contradictory progress flags rejected")
	check(not Campaign.valid_snapshot(null), "null save rejected")

func _save_tests():
	var store = Saves.new("/tmp/berania_model_qa.json")
	var c = Campaign.new()
	check(store.write(c.snapshot()), "safe initial save succeeds")
	c.end_turn()
	check(store.write(c.snapshot()), "validated safe replacement succeeds")
	var loaded = Campaign.new()
	check(loaded.restore(store.load_data()) and loaded.snapshot() == c.snapshot(), "current save loads exact snapshot")
	var file = FileAccess.open(store.path, FileAccess.WRITE)
	file.store_string("{broken-current")
	file.close()
	var backup = store.load_data()
	check(not backup.is_empty() and int(backup.turn) == c.turn - 1, "corrupt current falls back to last-good backup")
	check(not store.last_error.is_empty(), "backup recovery is explained")
	check(store.write(c.snapshot()), "new valid write can recover corrupt current")
	var preserved = store._read(store.path + ".bak")
	check(preserved == backup, "corrupt current never poisons backup")
	var rejected = c.snapshot()
	rejected.gold = -9
	check(not store.write(rejected), "invalid data cannot replace a good save")
	check(loaded.restore(store.load_data()) and loaded.snapshot() == c.snapshot(), "invalid write leaves current intact")
	var inaccessible = Saves.new("/tmp/berania_qa_no_such_directory_1741/save.json")
	check(not inaccessible.write(c.snapshot()) and not inaccessible.last_error.is_empty(), "write failure is surfaced, not reported as success")

func _animation_tests():
	var final_states = []
	for mode in 3:
		var demo = Demo.new()
		demo.phase = "battle"
		demo.battle = Battle.new()
		demo.speed_mode = mode
		demo.battle.unit("hero").pos = Vector2i.ZERO
		demo.battle.unit("raiders").pos = Vector2i(1, 0)
		var record = demo.battle.attack("hero", "raiders")
		demo._play_action(record)
		var hp = demo.battle.unit("raiders").hp
		demo._battle_click(Vector2i(1, 0))
		check(demo.battle.unit("raiders").hp == hp, "input during playback cannot repeat damage")
		demo.modal = "pause"
		demo._process(1.0)
		check(demo.animation_time == 0, "pause freezes playback")
		demo.modal = ""
		for i in 120:
			demo._process(1.0 / 60.0)
		check(demo.animation.is_empty(), "animation finishes at each speed")
		check(demo.battle.unit("raiders").hp == hp, "playback completion does not repeat damage")
		final_states.append(demo.battle.units.duplicate(true))
		demo.free()
	check(final_states[0] == final_states[1] and final_states[1] == final_states[2], "normal/fast/quick playback have identical authoritative final states")
