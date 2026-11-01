extends SceneTree
const Demo = preload("res://scripts/demo.gd")
const Campaign = preload("res://scripts/campaign_model.gd")
const Saves = preload("res://scripts/save_store.gd")
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
	var d = Demo.new()
	root.add_child(d)
	d._begin_new()
	check(d.phase == "intro" and d.campaign.mech_hp == 18 and d.campaign.gold == 0, "new prologue begins penniless with damaged walker")
	var opening_checkpoint = d.campaign.snapshot()
	for page in d.Story.MEMORIES.size():
		var next_button: Button
		for child in d.ui.get_children():
			if child is Button and child.text == "Continue the story   →":
				next_button = child
		check(d.phase == "intro" and d.intro_page == page and next_button != null, "memory %d has a working advance control" % page)
		if next_button != null:
			next_button.pressed.emit()
	check(d.phase == "intro" and d.intro_page == d.Story.MEMORIES.size(), "all memories reach Mira without skipping to world")
	d._intro_question()
	check(d.phase == "intro" and d.intro_page == d.Story.MEMORIES.size() + 1 and d.campaign.snapshot() == opening_checkpoint, "pursuit dialogue changes no time, gold or campaign progress")
	d._intro_question()
	check(d.phase == "world", "intro reaches world scene")
	d._world_click(d.campaign.village)
	check(not d.animation.is_empty() and d.campaign.budget == 1, "world click starts budgeted travel playback")
	d._process(1)
	check(d.animation.is_empty(), "travel finishes and unlocks input")
	d._village()
	check(d.phase == "battle" and d.campaign.pending_battle and d.campaign.mech_hp == 30, "village repairs for free and creates battle checkpoint")
	var turn = d.campaign.turn
	check(d._battle_cell_at(d._pos(d.battle.unit("hero").pos) + Vector2(0, -70)) == d.battle.unit("hero").pos, "mech body hit test targets its occupied hex")
	check(d._battle_cell_at(d._pos(d.battle.unit("hero").pos) + Vector2(0, -123)) == d.battle.unit("hero").pos, "ivory knight helmet uses the new art bounds")
	var bent_path = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1)]
	check(d._mech_travel(bent_path, 0.25).facing == 0 and d._mech_travel(bent_path, 0.75).facing == 1, "walking faces the current path segment rather than its final destination")
	check(d._mech_travel(bent_path, 1.0).distance > d._mech_travel(bent_path, 0.5).distance, "walking phase follows cumulative screen travel")
	check(d._battle_cell_at(d._pos(d.battle.unit("raiders").pos) + Vector2(0, -40)) == d.battle.unit("raiders").pos, "formation body hit test targets its occupied hex")
	var safety = 0
	while d.phase == "battle" and safety < 1000:
		safety += 1
		if not d.animation.is_empty():
			d._process(2.0)
		elif d.battle.side == 0:
			var acted = false
			for u in d.battle.units:
				if u.side == 0 and d.battle.can_activate(u.id):
					d.selected = u.id
					d._play_action(d.battle.ai_action(u.id))
					acted = true
					break
			if not acted:
				d._end_turn()
		else:
			d._enemy_step()
	check(safety < 1000 and d.phase == "results" and d.battle.outcome == "victory", "whole demo battle reaches victory results without stalls")
	check(d.campaign.turn == turn, "tactical turns and animation do not advance campaign time")
	check(d.campaign.gold == 40 and d.campaign.trust == 1 and not d.campaign.pending_battle, "results commit exactly one campaign reward")
	var committed = d.campaign.snapshot()
	d._finish_battle()
	check(d.campaign.snapshot() == committed, "duplicate result callback cannot grant another reward")
	d._leave_results()
	check(d.phase == "world", "results returns to same world")
	d._village()
	check(d.campaign.mech_hp == 30 and d.campaign.gold == 40, "completed village repairs remain free")
	d._continue_demo()
	check(d.phase == "world" and d.campaign.rewarded and d.campaign.gold == 40, "Continue restores committed completed campaign")
	check(d.message.begins_with("Greyford is safe."), "completed Continue shows completion guidance")
	d.modal = "home"
	d._confirm_modal()
	check(d.phase == "title" and d.message.is_empty(), "return to title clears gameplay hints")
	# Separate zero-gold loss/retry run through the same application flow.
	d._begin_new()
	d._enter_world()
	d.campaign.gold = 0
	d._world_click(d.campaign.village)
	d._process(1)
	d._village()
	d.battle.unit("hero").hp = 0
	d.battle._check_outcome()
	d._finish_battle()
	check(d.phase == "results" and d.campaign.quest == "retry" and d.campaign.gold == 0 and d.campaign.mech_hp == 30, "zero-gold loss reaches recoverable results")
	d._leave_results()
	d._village()
	check(d.phase == "battle" and d.campaign.pending_battle, "defeated campaign can retry without purchases")
	d.battle.unit("hero").hp = 1
	d._continue_demo()
	check(d.phase == "battle" and d.battle.unit("hero").hp == 30 and d.battle.round_number == 1, "interrupted battle resumes from full pre-battle checkpoint")
	check(Campaign.valid_snapshot(d.campaign.snapshot()), "flow ends in a valid campaign state")
	var checkpoint = d.campaign.snapshot()
	d.battle.unit("hero").hp = 1
	d.modal = "restart"
	d._confirm_modal()
	check(d.phase == "battle" and d.battle.unit("hero").hp == 30 and d.battle.round_number == 1, "confirmed restart restores initial deployment")
	check(d.campaign.snapshot() == checkpoint, "restart cannot mutate campaign checkpoint or pay rewards")
	d._start_practice()
	d.battle.unit("hero").hp = 0
	d.battle._check_outcome()
	d._finish_battle()
	check(d.campaign.snapshot() == checkpoint, "practice result cannot mutate real campaign")
	d._leave_results()
	check(d.phase == "title", "practice results return to title")
	# Inject an actual filesystem failure, then exercise the travel transaction/UI.
	d.practice = false
	d.campaign = Campaign.new()
	d.phase = "world"
	d.saves = Saves.new("/tmp/berania_qa_no_such_directory_1741/flow.json")
	checkpoint = d.campaign.snapshot()
	d._world_click(d.campaign.village)
	check(d.campaign.snapshot() == checkpoint and d.animation.is_empty(), "failed travel save rolls back location and movement budget")
	check(d.modal == "save_error", "failed save opens recovery modal")
	var retry_visible = false
	var base_hidden = false
	for child in d.ui.get_children():
		if child is Button and child.text == "Retry save":
			retry_visible = child.visible
		if child is Button and child.text == "End travel turn   [Space]":
			base_hidden = not child.visible
	check(retry_visible and base_hidden, "save-error retry controls exist and cover underlying controls")
	d.queue_free()
	await process_frame
	await process_frame
	await process_frame
	var file = FileAccess.open("res://qa/flow-results.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks": checks, "failures": failures, "suite": "greyford-demo-flow-0.1"}, "\t"))
	file.close()
	print("FLOW QA: %d checks; %d failures." % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
