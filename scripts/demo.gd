extends Node2D
const Hex = preload("res://scripts/hex_grid.gd")
const Battle = preload("res://scripts/battle_model.gd")
const Region = preload("res://scripts/region_model.gd")
const Campaign = preload("res://scripts/campaign_model.gd")
const Saves = preload("res://scripts/save_store.gd")
const Figures = preload("res://scripts/unit_art.gd")
const Mechs = preload("res://scripts/mech_art.gd")
const Story = preload("res://scripts/story.gd")
const Shop = preload("res://scripts/workshop_model.gd")
const WorkshopPanel = preload("res://scripts/workshop_panel.gd")
const MECH_REFERENCE = preload("res://assets/art/review/oathkeeper_reference.png")
const MEADOW = preload("res://assets/art/greyford_meadow.png")
const MARCH = preload("res://assets/art/greyford_march.png")
const PORTRAIT = preload("res://assets/art/captain_mira.png")
const INK = Color("243448")
const PAPER = Color("eee5d1")
const GOLD = Color("c5a46b")
const MUTED = Color("aeb8ae")
const TEAL = Color("8fb9af")
const RED = Color("d58e79")
const FIELD = Rect2(42, 142, 1134, 610)
const BATTLE_FIELD = Rect2(0, 0, 1600, 900)

var font: Font = ThemeDB.fallback_font
var serif: SystemFont
var ui: Control
var phase = "title"
var intro_page = 0
var campaign = Campaign.new()
var battle
var saves = Saves.new()
var selected = "hero"
var hovered = Vector2i(-999, -999)
var clock = 0.0
var animation = {}
var animation_time = 0.0
var speed_mode = 0
var reduced_motion = false
var muted = false
var grid_visible = false
var modal = ""
var message = ""
var combat_log = []
var practice = false
var continue_data = {}
var npc_motion = {}
var result_text = ""
var cached_reachable = []
var settings = ConfigFile.new()
var sounds = {}
var workshop_panel
var workshop_owner
var workshop_review = false
var workshop_training = false
var workshop_return_phase = "title"
var workshop_store
var region_review = false
var real_saves
var preparation = {}
var preparation_kind = ""
var preparation_id = ""
var selected_roster = []
var ability_mode = false
var mend_mode = false
var battle_zoom = 1.0
var battle_pan = Vector2.ZERO

func _ready():
	serif = SystemFont.new()
	serif.font_names = PackedStringArray(["Georgia", "Palatino", "Times New Roman"])
	ui = Control.new()
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ui)
	if "--qa" in OS.get_cmdline_user_args():
		saves = Saves.new("/tmp/berania_ui_qa.json")
		muted = true
	else:
		if settings.load("user://demo_settings.cfg") == OK:
			speed_mode = clampi(int(settings.get_value("play", "speed", 0)), 0, 2)
			reduced_motion = bool(settings.get_value("play", "reduced_motion", false))
			muted = bool(settings.get_value("play", "muted", false))
	continue_data = saves.load_data()
	if not saves.last_error.is_empty():
		message = saves.last_error
	for sound_name in ["click", "step", "sword", "gun", "impact", "victory"]:
		var player = AudioStreamPlayer.new()
		player.stream = load("res://assets/audio/" + sound_name + ".wav")
		player.volume_db = -15.0
		add_child(player)
		sounds[sound_name] = player
	_refresh_ui()

	if "--region-review" in OS.get_cmdline_user_args():
		_open_region_review("--fresh-region-review" in OS.get_cmdline_user_args())
		if "--capacity-15" in OS.get_cmdline_user_args(): _capacity_review(true)

func _exit_tree():
	for player in sounds.values():
		if is_instance_valid(player):
			player.stop()
	sounds.clear()

func _save_settings():
	if "--qa" in OS.get_cmdline_user_args():
		return
	settings.set_value("play", "speed", speed_mode)
	settings.set_value("play", "reduced_motion", reduced_motion)
	settings.set_value("play", "muted", muted)
	settings.save("user://demo_settings.cfg")

func _sound(id: String):
	if not muted and sounds.has(id):
		sounds[id].play()

func _process(delta):
	if modal.is_empty():
		clock += delta
		if not animation.is_empty():
			animation_time += delta * ([1.0, 2.0, 35.0][speed_mode])
			if animation.get("type") == "attack" and _progress() >= 0.48 and not animation.get("impact_played", false):
				animation.impact_played = true
				_sound("impact")
			if animation_time >= float(animation.get("duration", 0.6)):
				_finish_animation()
	queue_redraw()

func _input(event):
	if phase == "workshop":
		if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
			_close_workshop()
			get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			if modal.is_empty():
				modal = "pause"
			else:
				modal = ""
			_refresh_ui()
			get_viewport().set_input_as_handled()
		elif modal.is_empty():
			match event.keycode:
				KEY_SPACE:
					_end_turn()
					get_viewport().set_input_as_handled()
				KEY_G:
					grid_visible = not grid_visible
				KEY_F:
					_face()
				KEY_B:
					_guard()
				KEY_1, KEY_2, KEY_3:
					if phase == "battle":
						if battle.combined:
							var allies = battle.units.filter(func(u): return u.side == 0)
							if event.keycode - KEY_1 < allies.size(): _select(allies[event.keycode - KEY_1].id)
						else: _select(["hero", "blades", "gunners"][event.keycode - KEY_1])
				KEY_TAB:
					if phase == "battle": _cycle_unit()
				KEY_Q:
					if phase == "battle" and battle.combined: ability_mode = not ability_mode; mend_mode = false; _refresh_ui()
				KEY_E:
					if phase == "battle" and battle.combined: mend_mode = not mend_mode; ability_mode = false; _refresh_ui()
				KEY_HOME:
					battle_zoom = 1.0; battle_pan = Vector2.ZERO
				KEY_LEFT, KEY_RIGHT, KEY_UP, KEY_DOWN:
					if phase == "battle" and battle.combined:
						battle_pan += {KEY_LEFT: Vector2(60, 0), KEY_RIGHT: Vector2(-60, 0), KEY_UP: Vector2(0, 45), KEY_DOWN: Vector2(0, -45)}[event.keycode]
						battle_pan = battle_pan.clamp(Vector2(-300, -200), Vector2(300, 200))
				KEY_N:
					_cycle_speed()
				KEY_M:
					muted = not muted
					_save_settings()
					_refresh_ui()

func _unhandled_input(event):
	if not modal.is_empty():
		return
	if event is InputEventMouseMotion and phase in ["battle", "world"]:
		hovered = _cell_at(event.position, true) if phase == "world" else _battle_cell_at(event.position)
	if event is InputEventMouseButton and event.pressed and phase == "battle" and battle.combined and event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
		battle_zoom = clampf(battle_zoom + (0.1 if event.button_index == MOUSE_BUTTON_WHEEL_UP else -0.1), 0.8, 1.5)
	if event is InputEventMouseButton and event.pressed and animation.is_empty():
		if event.button_index == MOUSE_BUTTON_LEFT:
			if phase == "battle":
				_battle_click(_battle_cell_at(event.position))
			elif phase == "world":
				_world_click(_cell_at(event.position, true))
		elif event.button_index == MOUSE_BUTTON_RIGHT and phase == "battle":
			if battle.active_id.is_empty():
				selected = ""
				cached_reachable.clear()
				_refresh_ui()

func _button(text: String, box: Rect2, action: Callable, primary: bool = false, disabled: bool = false):
	var button = Button.new()
	if phase == "battle" and battle != null and battle.combined and "[Q]" in text:
		button.tooltip_text = Battle.ability_description(battle.unit(selected)) + " Cooldown: ready on the third subsequent own turn."
	button.text = text
	button.position = box.position
	button.size = box.size
	button.disabled = disabled
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_font_override("font", font)
	button.add_theme_font_size_override("font_size", 18)
	button.add_theme_color_override("font_color", INK if primary else PAPER)
	button.add_theme_color_override("font_hover_color", INK if primary else Color.WHITE)
	button.add_theme_color_override("font_disabled_color", Color("6c7777"))
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		var style = StyleBoxFlat.new()
		style.bg_color = GOLD if primary else Color("243b43")
		if state == "hover":
			style.bg_color = style.bg_color.lightened(0.16)
		if state == "pressed":
			style.bg_color = style.bg_color.darkened(0.12)
		if state == "disabled":
			style.bg_color = Color("293633")
		style.border_color = GOLD if state == "focus" else Color("5d6b60")
		style.set_border_width_all(2 if state == "focus" else 1)
		style.set_corner_radius_all(5)
		button.add_theme_stylebox_override(state, style)
	button.pressed.connect(func():
		_sound("click")
		action.call()
	)
	ui.add_child(button)

func _refresh_ui():
	if ui == null:
		return
	for node in ui.get_children():
		ui.remove_child(node)
		node.queue_free()
	if phase == "title":
		_button("Begin the prologue   →", Rect2(90, 625, 286, 58), _new_demo, true)
		_button("Continue", Rect2(390, 625, 180, 58), _continue_demo, false, continue_data.is_empty())
		_button("Practice battle", Rect2(90, 700, 210, 46), _start_practice)
		_button("How to play", Rect2(315, 700, 210, 46), func(): modal = "help"; _refresh_ui())
		_button("Legacy art study", Rect2(540, 700, 210, 46), func(): get_tree().change_scene_to_file("res://scenes/mech_preview.tscn"))
		_button("Regional review  ·  prototype 0.3", Rect2(770, 700, 430, 46), _open_region_review, true)
		_button("Workshop review  ·  prototype 0.2", Rect2(90, 758, 440, 46), func(): _open_workshop(true), true)
	elif phase == "intro":
		if intro_page < Story.MEMORIES.size():
			_button("Continue the story   →", Rect2(1170, 792, 300, 52), _advance_intro, true)
		else:
			_button("I will help defend Greyford.   →", Rect2(1000, 735, 460, 48), _enter_world, true)
			_button("And the imperial patrols?" if intro_page == Story.MEMORIES.size() else "I understand. Let us go.", Rect2(1000, 796, 460, 48), _intro_question)
	elif phase == "world":
		var place = Region.settlement(campaign.player)
		var at_village = campaign.player == campaign.village
		_button("Friendly workshop", Rect2(1220, 522, 316, 42), func(): _open_workshop(false), false, not campaign.rewarded or place.is_empty() or not place.friendly or not animation.is_empty())
		_button("Enter " + place.get("name", "settlement") if not place.is_empty() else "Help nearby incident", Rect2(1220, 578, 316, 52), _interact_region, true, not animation.is_empty() or (place.is_empty() and _incident_here().is_empty()))
		_button("End travel turn   [Space]", Rect2(1220, 649, 316, 52), _end_turn, false, not animation.is_empty())
		_button("Save checkpoint", Rect2(1220, 720, 316, 44), func(): _checkpoint(); _refresh_ui(), false, not animation.is_empty())
		_button("Leave regional review" if region_review else "Return to title", Rect2(1220, 785, 316, 44), func(): modal = "home"; _refresh_ui())
	elif phase == "settlement":
		_build_settlement_ui()
	elif phase == "preparation":
		_build_preparation_ui()
	elif phase == "battle":
		# Bottom-right action buttons — large, touch-friendly, stacked
		var btn_w = 160.0
		var btn_h = 56.0
		var btn_margin = 16.0
		var btn_gap = 10.0
		var bx = 1600 - btn_w - btn_margin
		var by_end = 900 - btn_margin - btn_h
		_button("End turn", Rect2(bx, by_end, btn_w, btn_h), _end_turn, true, battle.side != 0 or not animation.is_empty())
		if _player_ready():
			_button("Guard [B]", Rect2(bx - btn_w - btn_gap, by_end, btn_w, btn_h), _guard, false, not _player_ready())
			_button("Face [F]", Rect2(bx, by_end - btn_h - btn_gap, btn_w, btn_h), _face, false, not _player_ready() or battle.unit(selected).get("rotated", true))
		if battle.combined:
			_button(("◆ " if ability_mode else "") + Battle.ability_name(battle.unit(selected)) + " [Q]", Rect2(18, 466, 222, 42), func(): ability_mode = not ability_mode; mend_mode = false; _refresh_ui(), ability_mode, not _player_ready() or battle.unit(selected).get("cooldown", 1) > 0)
			if battle.unit(selected).get("kind") == "mage":
				_button("Mend +4 [E]", Rect2(18, 518, 222, 40), func(): mend_mode = not mend_mode; ability_mode = false; _refresh_ui(), mend_mode, not _player_ready() or battle.unit(selected).cooldown > 0)
			var index = 0
			for u in battle.units:
				if u.side != 0: continue
				var unit_id = u.id
				_button(str(index + 1) + " " + u.kind.capitalize() + (" ✓" if u.acted else ""), Rect2(260 + (index % 8) * 128, 790 + (index / 8) * 48, 122, 42), func(): _select(unit_id), selected == unit_id, not battle.can_activate(unit_id) or not animation.is_empty())
				index += 1

	elif phase == "results":
		_button("Return to region   →" if not practice else ("Return to region   →" if region_review else "Return to title   →"), Rect2(600, 690, 400, 56), _leave_results, true)
	if phase not in ["title", "workshop"]:
		if phase == "battle":
			_button(["Normal", "×2", "Quick"][speed_mode], Rect2(1400, 12, 80, 38), _cycle_speed)
			_button("Pause", Rect2(1490, 12, 94, 38), func(): modal = "pause"; _refresh_ui())
		else:
			_button(["Normal", "Fast ×2", "Quick"][speed_mode] + "   [N]", Rect2(1155, 31, 138, 38), _cycle_speed)
			_button("Pause   [Esc]", Rect2(1310, 31, 226, 38), func(): modal = "pause"; _refresh_ui())
	if not modal.is_empty():
		for node in ui.get_children():
			node.visible = false
		# A real Control intercepts clicks, including empty regions of the overlay.
		var blocker = Control.new()
		blocker.position = Vector2.ZERO
		blocker.size = Vector2(1600, 900)
		blocker.mouse_filter = Control.MOUSE_FILTER_STOP
		ui.add_child(blocker)
		match modal:
			"pause", "help":
				_button("Resume" if modal == "pause" else "Back", Rect2(580, 684, 440, 48), func(): modal = ""; _refresh_ui(), true)
				_button("Animation: " + ["Normal", "Fast ×2", "Quick"][speed_mode], Rect2(410, 560, 250, 45), _cycle_speed)
				_button("Reduced motion: " + ("on" if reduced_motion else "off"), Rect2(675, 560, 250, 45), func(): reduced_motion = not reduced_motion; _save_settings(); _refresh_ui())
				_button("Sound: " + ("off" if muted else "on"), Rect2(940, 560, 250, 45), func(): muted = not muted; _save_settings(); _refresh_ui())
				if modal == "pause" and phase == "battle":
					if region_review and practice:
						_button("Return to region", Rect2(580, 625, 440, 44), func(): animation.clear(); modal = ""; practice = false; phase = "world"; message = "Capacity practice ended. Regional resources and time are unchanged."; _refresh_ui())
					elif workshop_training:
						_button("Return to workshop", Rect2(580, 625, 440, 44), _return_from_workshop_trial)
					else:
						_button("Restart encounter", Rect2(580, 625, 440, 44), func(): modal = "restart"; _refresh_ui())
			"new", "restart", "home":
				_button("Confirm", Rect2(550, 575, 240, 52), _confirm_modal, true)
				_button("Cancel", Rect2(810, 575, 240, 52), func(): modal = ""; _refresh_ui())
			"save_error":
				_button("Retry save", Rect2(550, 575, 240, 52), func(): modal = ""; _checkpoint(); _refresh_ui(), true)
				_button("Stay here", Rect2(810, 575, 240, 52), func(): modal = ""; _refresh_ui())

func _new_demo():
	if not continue_data.is_empty() or FileAccess.file_exists(saves.path) or FileAccess.file_exists(saves.path + ".bak"):
		modal = "new"
		_refresh_ui()
	else:
		_begin_new()

func _begin_new():
	campaign = Campaign.new()
	practice = false
	workshop_training = false
	intro_page = 0
	phase = "intro"
	message = ""
	animation.clear()
	_checkpoint()
	_refresh_ui()

func _advance_intro():
	if phase == "intro" and intro_page < Story.MEMORIES.size():
		intro_page += 1
		_refresh_ui()

func _intro_question():
	if intro_page == Story.MEMORIES.size():
		intro_page += 1
		_refresh_ui()
	else:
		_enter_world()

func _continue_demo():
	var data = saves.load_data()
	if data.is_empty():
		message = saves.last_error
		_refresh_ui()
		return
	campaign = Campaign.new()
	campaign.restore(data)
	practice = false
	message = saves.last_error
	if campaign.pending_battle:
		_start_battle()
	else:
		_enter_world()

func _confirm_modal():
	var previous = modal
	modal = ""
	if previous == "new":
		_begin_new()
	elif previous == "restart":
		if practice and battle != null and battle.combined: _capacity_review(battle.cap == 15)
		else: _start_battle()
	elif previous == "home":
		if region_review:
			region_review = false
			saves = real_saves
		phase = "title"
		continue_data = saves.load_data()
		message = saves.last_error
		_refresh_ui()

func _enter_world():
	phase = "world"
	message = "Follow the road to Greyford. Click a lit destination; each step costs one travel point."
	if campaign.rewarded:
		message = "Greyford is safe. Recruit, take guild work, deliver grain to Millhaven or help a visible attack. Only End travel turn advances the region."
	elif campaign.quest == "retry":
		message = "Your company has recovered. Enter Greyford when you are ready to retry the defense."
	_refresh_ui()

func _world_click(pos: Vector2i):
	if not animation.is_empty() or pos not in campaign.board:
		return
	if pos == campaign.player:
		if campaign.rewarded: _interact_region()
		elif pos == campaign.village: _village()
		return
	var before = campaign.snapshot()
	var path = campaign.travel(pos)
	if path.is_empty():
		message = "That destination is beyond your sight or travel budget. End the turn to travel farther."
		return
	if not _checkpoint():
		campaign.restore(before)
		return
	animation = {"type": "travel", "path": path, "duration": 0.22 * (path.size() - 1)}
	animation_time = 0.0
	message = "Greyford reached. Enter the village to answer its call." if campaign.player == campaign.village else "The road continues. You have %d travel points left." % campaign.budget
	_sound("step")
	_refresh_ui()

func _village():
	if phase != "world" or campaign.player != campaign.village or not animation.is_empty():
		return
	if campaign.rewarded:
		campaign.mech_hp = campaign.max_hull()
		_checkpoint()
		message = "Greyford welcomes you. Your walker is fully repaired, free of charge. Regional roads are open."
	else:
		campaign.mech_hp = campaign.max_hull()
		campaign.pending_battle = true
		if _checkpoint():
			_start_battle()
	_refresh_ui()

func _start_practice():
	workshop_training = false
	practice = true
	_start_battle()

func _start_battle():
	phase = "battle"
	battle = Battle.new(campaign.region.pending) if not practice and not campaign.region.pending.is_empty() else Battle.new()
	ability_mode = false
	mend_mode = false
	battle_zoom = 1.0
	battle_pan = Vector2.ZERO
	if not battle.combined and (not practice or workshop_training):
		var owner_state = workshop_owner if workshop_training else campaign
		var values = Shop.stats(owner_state.workshop)
		var hero = battle.unit("hero")
		for key in ["attack", "armor", "move", "range"]:
			hero[key] = values[key]
		hero.max_hp = values.hp
		hero.hp = values.hp if workshop_training else owner_state.mech_hp
		hero.name = Shop.frame(owner_state.workshop).name
	selected = "hero"
	animation.clear()
	animation_time = 0.0
	combat_log = ["Greyford's smith repairs your walker without charge.", "The villagers form up beside your walker.", "Route the raiders. Oathkeeper must survive."]
	if battle.combined: combat_log = ["Deployment locked. Local and allied formations share your command limit."]
	message = "Select a unit, click a shaded hex to move, then click an enemy in range. Guard finishes an activation."
	_reachable()
	_refresh_ui()

func _player_ready() -> bool:
	return phase == "battle" and animation.is_empty() and battle.side == 0 and not selected.is_empty() and battle.can_activate(selected)

func _select(id: String):
	if phase != "battle" or not animation.is_empty() or battle.side != 0:
		return
	if not battle.can_activate(id):
		message = "Finish the active formation with an attack or Guard before choosing another unit."
		return
	selected = id
	ability_mode = false
	mend_mode = false
	_reachable()
	_refresh_ui()

func _reachable():
	cached_reachable.clear()
	if phase == "battle" and not selected.is_empty():
		cached_reachable = battle.reachable_paths(selected).keys()

func _battle_click(pos: Vector2i):
	if battle.side != 0 or pos not in battle.board or not animation.is_empty():
		return
	var clicked = battle.occupant(pos)
	if not clicked.is_empty() and clicked.side == 0:
		if mend_mode and _player_ready():
			var action = battle.mend(selected, clicked.id)
			if not action.is_empty(): _play_action(action)
			else: message = "Mend needs a wounded ally within 2 hexes and clear sight."
			return
		_select(clicked.id)
		return
	if not _player_ready():
		message = "Choose an available friendly unit first, or End Turn."
		return
	var action = {}
	if not clicked.is_empty():
		action = battle.attack(selected, clicked.id, ability_mode)
		if action.is_empty():
			message = "Target unavailable: check range, rocks, ability cooldown or its movement restriction."
	else:
		action = battle.move_unit(selected, pos)
		if action.is_empty():
			message = "You cannot move there. Occupied hexes and rocks block travel; a unit moves once per turn."
	if not action.is_empty():
		_play_action(action)

func _guard():
	if _player_ready():
		_play_action(battle.guard_unit(selected))

func _face():
	if _player_ready() and battle.rotate_unit(selected):
		animation = {"type": "turn", "id": selected, "duration": 0.18}
		animation_time = 0.0
		message = "Facing adjusted. The gold chevron shows the front; flank and rear hits do more damage."
		_refresh_ui()

func _play_action(action: Dictionary):
	if action.is_empty():
		return
	animation = action.duplicate(true)
	animation_time = 0.0
	if action.type == "move":
		animation.duration = 0.18 * (action.path.size() - 1)
		_sound("step")
	elif action.type == "attack":
		animation.duration = 0.75 if battle.unit(action.id).kind == "mech" else 0.55
		_sound("gun" if action.ranged else "sword")
		combat_log.append("%s → %s: %d damage (%s)." % [battle.unit(action.id).name, battle.unit(action.target).name, action.damage, action.label])
		if action.routed:
			combat_log.append(battle.unit(action.target).name + " breaks and retreats.")
	elif action.type == "mend":
		animation.duration = 0.4
		combat_log.append("%s restores %d strength to %s." % [battle.unit(action.id).name, action.restored, battle.unit(action.target).name])
	else:
		animation.duration = 0.28
		combat_log.append(battle.unit(action.id).name + " guards: incoming damage −%d." % battle.guard_reduction(battle.unit(action.id), {"kind": "sword"}))
	_reachable()
	_refresh_ui()

func _finish_animation():
	var previous_type = animation.get("type", "")
	animation.clear()
	animation_time = 0.0
	if phase == "battle":
		if not battle.outcome.is_empty():
			_finish_battle()
		elif battle.side == 1:
			_enemy_step()
		else:
			if not selected.is_empty() and battle.unit(selected).acted:
				selected = ""
			_reachable()
			var available = 0
			for u in battle.units:
				if u.side == 0 and battle.can_activate(u.id):
					available += 1
			if not battle.active_id.is_empty():
				message = "Finish this unit's activation: attack a valid target or Guard."
			else:
				message = "All formations have acted. End the turn to continue." if available == 0 else "Choose another ready formation, or End Turn."
	elif phase == "world" and previous_type == "npc":
		npc_motion.clear()
	_refresh_ui()

func _end_turn():
	if not animation.is_empty() or not modal.is_empty():
		return
	if phase == "battle" and battle.side == 0:
		battle.end_side()
		selected = ""
		cached_reachable.clear()
		message = "The enemy is taking its turn."
		_refresh_ui()
		_enemy_step()
	elif phase == "world":
		var snapshot = campaign.snapshot()
		npc_motion = campaign.end_turn()
		if not _checkpoint():
			campaign.restore(snapshot)
			return
		animation = {"type": "npc", "duration": 0.5}
		animation_time = 0.0
		message = "Travel points restored. " + campaign.news
		_refresh_ui()

func _enemy_step():
	for u in battle.units:
		if u.side == 1 and battle.can_activate(u.id):
			var action = battle.ai_action(u.id)
			if not action.is_empty():
				_play_action(action)
				return
	# No legal actions is a valid end-of-side state, not an AI stall.
	battle.end_side()
	selected = "hero" if battle.alive(battle.unit("hero")) else ""
	message = "Your turn. Guard expires at the start of that unit's next turn."
	_reachable()
	_refresh_ui()

func _finish_battle():
	phase = "results"
	if not practice:
		if battle.combined:
			campaign.finish_region(battle)
		else:
			campaign.finish_battle(battle.outcome, int(battle.unit("hero").hp))
		_checkpoint()
	result_text = "The road remembers your banner." if battle.outcome == "victory" else "A lost battle is not the end of your cause."
	if battle.outcome == "victory":
		_sound("victory")
	_refresh_ui()

func _leave_results():
	if not modal.is_empty():
		return
	if workshop_training:
		_return_from_workshop_trial()
		return
	elif practice and region_review:
		phase = "world"
		practice = false
		message = "Capacity review ended. Regional resources and time are unchanged."
	elif practice:
		phase = "title"
		continue_data = saves.load_data()
		message = saves.last_error
	else:
		phase = "world"
		message = campaign.news
	_refresh_ui()

func _open_workshop(review: bool = false):
	if not review and (phase not in ["world", "settlement"] or Region.settlement(campaign.player).is_empty() or not Region.settlement(campaign.player).friendly or not campaign.rewarded or not animation.is_empty()):
		return
	workshop_return_phase = phase
	workshop_review = review
	workshop_training = false
	if review:
		workshop_owner = Campaign.new()
		var review_path = "/tmp/berania_workshop_ui_qa.json" if "--qa" in OS.get_cmdline_user_args() else "user://workshop_review.json"
		workshop_store = Saves.new(review_path)
		var data = workshop_store.load_data()
		if data.is_empty():
			workshop_owner.gold = 180
			workshop_owner.mech_hp = 30
			workshop_owner.workshop.headquarters = true
		else:
			workshop_owner.restore(data)
	else:
		workshop_owner = campaign
		workshop_store = saves
	phase = "workshop"
	modal = ""
	_refresh_ui()
	workshop_panel = WorkshopPanel.new()
	workshop_panel.owner_campaign = workshop_owner
	workshop_panel.review_mode = review
	workshop_panel.requested.connect(_workshop_order)
	workshop_panel.closed.connect(_close_workshop)
	add_child(workshop_panel)

func _workshop_order(action: String, args: Dictionary):
	if phase != "workshop":
		return
	if action == "reset_review":
		if not workshop_review:
			return
		var fresh = Campaign.new()
		fresh.gold = 180
		fresh.mech_hp = 30
		fresh.workshop.headquarters = true
		if workshop_store.write(fresh.snapshot()):
			workshop_owner.restore(fresh.snapshot())
			workshop_panel.banner_draft = workshop_owner.workshop.banner.duplicate(true)
			workshop_panel.status_text = "Review reset to Oathkeeper and 180 gold. Your campaign is unaffected."
		else:
			workshop_panel.status_text = workshop_store.last_error
		workshop_panel.refresh()
		return
	if action == "trial":
		workshop_training = true
		practice = true
		workshop_panel.visible = false
		_start_battle()
		return
	var before = workshop_owner.snapshot()
	var result = Shop.transact(workshop_owner.workshop, workshop_owner.gold, action, args)
	if result.ok:
		workshop_owner.workshop = result.state
		workshop_owner.gold = result.gold
		if not workshop_store.write(workshop_owner.snapshot()):
			workshop_owner.restore(before)
			result.message = workshop_store.last_error + " Your order was rolled back."
		elif not workshop_review:
			continue_data = campaign.snapshot()
	workshop_panel.status_text = result.message
	if action == "banner" and result.ok:
		workshop_panel.banner_draft = workshop_owner.workshop.banner.duplicate(true)
	workshop_panel.refresh()

func _close_workshop():
	if workshop_panel != null:
		remove_child(workshop_panel)
		workshop_panel.queue_free()
		workshop_panel = null
	workshop_training = false
	practice = false
	phase = workshop_return_phase
	_refresh_ui()

func _return_from_workshop_trial():
	animation.clear()
	animation_time = 0.0
	modal = ""
	workshop_training = false
	practice = false
	phase = "workshop"
	workshop_panel.visible = true
	workshop_panel.status_text = "Practice ended. No gold, frame damage, or campaign progress changed."
	workshop_panel.refresh()
	_refresh_ui()

func _checkpoint() -> bool:
	var ok = saves.write(campaign.snapshot())
	if not ok:
		message = saves.last_error
		modal = "save_error"
		_refresh_ui()
	else:
		continue_data = campaign.snapshot()
	return ok

func _cycle_speed():
	speed_mode = (speed_mode + 1) % 3
	_save_settings()
	_refresh_ui()

func _pos(p: Vector2i, world: bool = false) -> Vector2:
	if world and campaign.rewarded:
		return Vector2(108, 262) + Vector2((p.x + p.y * 0.5) * 104.0, p.y * 69.0)
	if world:
		return Vector2(176, 243) + Vector2((p.x + p.y * 0.5) * 156.0, p.y * 88.0)
	if battle != null and battle.combined:
		var step = 63.0 if battle.cap == 15 else 80.0
		var local = Vector2((p.x + p.y * 0.5) * step, p.y * step * 0.7)
		return Vector2(308, 184) + local * battle_zoom + battle_pan
	var origin = Vector2(260, 170)
	var step_x = 148.0
	var step_y = 82.0
	return origin + Vector2((p.x + p.y * 0.5) * step_x, p.y * step_y)

func _cell_at(point: Vector2, world: bool) -> Vector2i:
	var bounds = FIELD if world else BATTLE_FIELD
	if not bounds.has_point(point):
		return Vector2i(-999, -999)
	if world and campaign.rewarded:
		var row = (point.y - 262.0) / 69.0
		return Hex.round_axial((point.x - 108.0) / 104.0 - row * 0.5, row)
	if not world and battle != null and battle.combined:
		var step = 63.0 if battle.cap == 15 else 80.0
		var local = (point - Vector2(308, 184) - battle_pan) / battle_zoom
		var row = local.y / (step * 0.7)
		return Hex.round_axial(local.x / step - row * 0.5, row)
	if world:
		var row = (point.y - 243.0) / 88.0
		var q = (point.x - 176.0) / 156.0 - row * 0.5
		return Hex.round_axial(q, row)
	var row = (point.y - 170.0) / 82.0
	var q = (point.x - 260.0) / 148.0 - row * 0.5
	return Hex.round_axial(q, row)

func _battle_cell_at(point: Vector2) -> Vector2i:
	if battle == null or not BATTLE_FIELD.has_point(point):
		return Vector2i(-999, -999)
	if battle.combined:
		return _cell_at(point, false) if Rect2(253, 110, 1347, 660).has_point(point) else Vector2i(-999, -999)
	var front_to_back = battle.units.duplicate()
	front_to_back.sort_custom(func(a, b): return _pos(a.pos).y > _pos(b.pos).y)
	for u in front_to_back:
		if not battle.alive(u):
			continue
		var art_bounds = Mechs.bounds(u)
		# Body art follows its occupied hex; labels keep the existing touch allowance.
		var body = Rect2(_pos(u.pos) + art_bounds.position, Vector2(art_bounds.size.x, art_bounds.size.y + (36 if Mechs.has_art(u) else 0)))
		if body.has_point(point):
			return u.pos
	return _cell_at(point, false)

func _hex(p: Vector2i, world: bool = false, factor: float = 0.96) -> PackedVector2Array:
	var center = _pos(p, world)
	var points = PackedVector2Array()
	var rx = (60.0 if world and campaign.rewarded else (90.0 if world else 85.0)) * factor
	var ry = (46.0 if world and campaign.rewarded else (58.7 if world else 54.5)) * factor
	if not world and battle != null and battle.combined:
		rx = (36.4 if battle.cap == 15 else 46.2) * battle_zoom * factor
		ry = rx * 0.81
	for i in 6:
		var angle = TAU * i / 6.0 - PI / 2.0
		points.append(center + Vector2(cos(angle) * rx, sin(angle) * ry))
	return points

func _text(text: String, pos: Vector2, size: int = 20, color: Color = PAPER, heading: bool = false):
	draw_string(serif if heading else font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

func _wrap(text: String, rect: Rect2, size: int = 21, color: Color = PAPER, line_height: float = 32.0, heading: bool = false):
	var chosen_font = serif if heading else font
	var y = rect.position.y + size
	for paragraph in text.split("\n"):
		var line = ""
		for word in paragraph.split(" "):
			var candidate = word if line.is_empty() else line + " " + word
			if chosen_font.get_string_size(candidate, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x > rect.size.x and not line.is_empty():
				if y > rect.end.y:
					return
				_text(line, Vector2(rect.position.x, y), size, color, heading)
				y += line_height
				line = word
			else:
				line = candidate
		if not line.is_empty():
			if y > rect.end.y:
				return
			_text(line, Vector2(rect.position.x, y), size, color, heading)
		y += line_height

func _panel(rect: Rect2, color: Color = Color("1e3038"), border: Color = Color("677363")):
	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.shadow_color = Color(0.02, 0.05, 0.06, 0.25)
	style.shadow_size = 8
	draw_style_box(style, rect)

func _crest(center: Vector2, scale_value: float = 1.0, color: Color = GOLD):
	var poly = PackedVector2Array([Vector2(-15, -18), Vector2(15, -18), Vector2(14, 5), Vector2(0, 21), Vector2(-14, 5)])
	for i in poly.size():
		poly[i] = center + poly[i] * scale_value
	draw_colored_polygon(poly, color)
	draw_circle(center + Vector2(0, -3) * scale_value, 6 * scale_value, INK)
	for i in 8:
		var vec = Vector2.from_angle(i * TAU / 8)
		draw_line(center + (Vector2(0, -3) + vec * 8) * scale_value, center + (Vector2(0, -3) + vec * 11) * scale_value, INK, 1.5 * scale_value, true)

func _background():
	draw_rect(Rect2(0, 0, 1600, 900), Color("14252d"))
	draw_texture_rect(MEADOW, Rect2(0, 0, 1600, 900), false)

func _draw():
	if serif == null:
		return
	if phase == "title":
		_draw_title()
	elif phase == "intro":
		_draw_intro()
	elif phase in ["settlement", "preparation"]:
		_draw_regional_screen()
	elif phase in ["world", "battle"]:
		_draw_game_shell()
		if phase == "world":
			_draw_world()
		else:
			_draw_battle()
			_draw_battle_hud()
	elif phase == "results":
		_draw_results()
	if not modal.is_empty():
		_draw_modal()

func _draw_title():
	_background()
	for i in 80:
		draw_rect(Rect2(i * 20, 0, 20, 900), Color(0.04, 0.1, 0.13, maxf(0.12, 0.91 - i * 0.011)))
	_crest(Vector2(116, 106), 1.4)
	_text("A CHRONICLE OF STEEL & BANNERS", Vector2(160, 114), 18, GOLD)
	_text("THE HISTORY OF", Vector2(90, 226), 26, PAPER)
	_text("Berania", Vector2(82, 350), 116, PAPER, true)
	draw_line(Vector2(92, 392), Vector2(534, 392), GOLD, 1.5, true)
	_text("A banner falls.", Vector2(90, 457), 36, PAPER, true)
	_text("A cause begins.", Vector2(90, 505), 36, PAPER, true)
	_text("DAWN AT GREYFORD", Vector2(91, 573), 18, GOLD)
	_wrap("An archduke's son. A stolen walker.\nA promise to save the princess and the empire.", Rect2(90, 824, 760, 65), 18, PAPER, 25)
	_text("THE LIVING MARCH  /  0.3", Vector2(1180, 857), 16, PAPER)
	if not message.is_empty():
		_wrap(message, Rect2(750, 742, 730, 100), 18, PAPER, 26)

func _draw_intro():
	_background()
	draw_rect(Rect2(0, 0, 1600, 900), Color(0.04, 0.1, 0.12, 0.32))
	_panel(Rect2(55, 33, 570, 62), Color(0.08, 0.15, 0.18, 0.94))
	_text("I   /   THE BROKEN PROMISE", Vector2(80, 77), 22, GOLD)
	if intro_page < Story.MEMORIES.size():
		var memory = Story.MEMORIES[intro_page]
		_panel(Rect2(85, 165, 1130, 430), Color(0.08, 0.15, 0.18, 0.94))
		_text(memory.title, Vector2(120, 238), 44, PAPER, true)
		_wrap(memory.body, Rect2(120, 280, 1055, 255), 26, PAPER, 39)
		_text("MEMORY %d / %d" % [intro_page + 1, Story.MEMORIES.size()], Vector2(120, 565), 16, GOLD)
		draw_texture_rect(MECH_REFERENCE, Rect2(1230, 165, 300, 360), false)
		_text("OATHKEEPER  /  CONCEPT", Vector2(1230, 563), 15, GOLD)
		_panel(Rect2(80, 676, 1440, 185), PAPER)
		_text(memory.caption, Vector2(112, 720), 17, Color("6f6c53"))
		_wrap(memory.closing, Rect2(112, 741, 960, 108), 26, INK, 36, true)
	else:
		var bob = sin(clock * 1.6) * (0 if reduced_motion else 2)
		draw_texture_rect(PORTRAIT, Rect2(80, 115 + bob, 443, 665), false)
		_panel(Rect2(795, 178, 680, 345), Color(0.08, 0.15, 0.18, 0.91))
		_text("Your first foothold.", Vector2(830, 244), 41, PAPER, true)
		_wrap(Story.MIRA_INTRO, Rect2(831, 285, 600, 195), 23, PAPER, 33)
		_panel(Rect2(70, 650, 1460, 215), PAPER)
		_text("CAPTAIN MIRA  /  GREYFORD ROADWARDENS", Vector2(105, 695), 18, Color("6f6c53"))
		var dialogue = Story.MIRA_REPLY
		if intro_page > Story.MEMORIES.size():
			dialogue = Story.MIRA_WARNING
		_wrap(dialogue, Rect2(105, 724, 822, 125), 24, INK, 35, true)

func _draw_game_shell():
	if phase == "battle":
		_draw_battle_shell()
		return
	# World phase: keep original chrome layout.
	draw_rect(Rect2(0, 0, 1600, 900), Color("15272e"))
	draw_rect(Rect2(0, 0, 1600, 104), Color("1d3038"))
	_crest(Vector2(66, 50), 0.9)
	_text("BERANIA", Vector2(98, 49), 29, PAPER, true)
	_text("DAWN AT GREYFORD", Vector2(99, 75), 13, GOLD)
	_text("THE BORDER ROAD", Vector2(413, 47), 20, PAPER)
	_text("TRAVEL TURN %d  ·  %d / 3 MOVEMENT" % [campaign.turn, campaign.budget], Vector2(413, 76), 16, TEAL)
	_panel(FIELD, Color("5c7053"))
	_panel(Rect2(1198, 142, 360, 633))
	_text("WANTED BY THE CROWN", Vector2(1220, 181), 17, GOLD)
	_text("Greyford", Vector2(1220, 224), 34, PAPER, true)

	var objective = "Reach the village and answer Captain Mira's call."
	if campaign.rewarded:
		objective = "Trade, recruit and help the march. Reach Stonebridge for a road pact."
	elif campaign.quest == "retry":
		objective = "Your company is recovered. Enter Greyford to retry the defense."
	_wrap(objective, Rect2(1220, 249, 306, 100), 22, PAPER, 33)
	_text("YOUR COMPANY", Vector2(1220, 380), 16, GOLD)
	_text("You + %d formations" % campaign.region.formations.size() if campaign.rewarded else "You + Oathkeeper", Vector2(1220, 421), 20)
	_text("Gold    %d" % campaign.gold, Vector2(1220, 459), 20, PAPER)
	_text("Local trust    %d" % campaign.trust, Vector2(1400, 459), 18, TEAL)
	_text("Walker hull    %d / %d" % [campaign.mech_hp, campaign.max_hull()], Vector2(1220, 496), 18, MUTED)

	_panel(Rect2(42, 776, 1134, 92), Color("1d3038"))
	_wrap(message, Rect2(66, 794, 1070, 66), 20, PAPER, 29)
	_text("CLICK: SELECT / MOVE / ATTACK     B: GUARD     F: FACE     SPACE: END TURN     G: GRID", Vector2(45, 891), 13, MUTED)

func _draw_battle_shell():
	draw_rect(Rect2(0, 0, 1600, 900), Color("15272e"))

func _draw_battle_hud():
	if battle.combined:
		_draw_combined_hud()
		return
	# Round pill — top center
	var round_text = "ROUND %d  ·  %s" % [battle.round_number, "YOUR TURN" if battle.side == 0 else "ENEMY TURN"]
	var pill_w = 280.0
	var pill_x = (1600 - pill_w) / 2.0
	_panel(Rect2(pill_x, 12, pill_w, 38), Color(0.08, 0.14, 0.18, 0.82))
	_text(round_text, Vector2(pill_x + 18, 39), 17, TEAL if battle.side == 0 else RED)

	# Unit card — top left (selected friendly or hovered enemy)
	var card_unit: Dictionary = {}
	var card_enemy = false
	var inspected = battle.occupant(hovered) if hovered in battle.board else {}
	if not inspected.is_empty() and inspected.side == 1 and battle.alive(inspected):
		card_unit = inspected
		card_enemy = true
	elif not selected.is_empty():
		var sel = battle.unit(selected)
		if battle.alive(sel):
			card_unit = sel
	if not card_unit.is_empty():
		var cx = 16.0
		var cy = 16.0
		var cw = 230.0
		var ch = 160.0
		var border_color = RED if card_enemy else GOLD
		_panel(Rect2(cx, cy, cw, ch), Color(0.08, 0.14, 0.18, 0.85), border_color)
		_text(card_unit.name, Vector2(cx + 14, cy + 30), 22, PAPER, true)
		_text(card_unit.role, Vector2(cx + 14, cy + 50), 13, MUTED)
		# HP bar
		var bar_x = cx + 14
		var bar_y = cy + 60
		var bar_w = cw - 28
		var bar_h = 10.0
		draw_rect(Rect2(bar_x - 1, bar_y - 1, bar_w + 2, bar_h + 2), INK)
		var hp_color = TEAL if not card_enemy else RED
		draw_rect(Rect2(bar_x, bar_y, bar_w * maxf(0, float(card_unit.hp) / card_unit.max_hp), bar_h), hp_color)
		var hp_label = "Hull" if card_unit.kind == "mech" else "Troops"
		_text("%s  %d / %d" % [hp_label, card_unit.hp, card_unit.max_hp], Vector2(bar_x, bar_y + 26), 14, PAPER)
		# Stats
		_text("ATK %d" % card_unit.attack, Vector2(cx + 14, cy + 112), 15, GOLD)
		_text("ARM %d" % card_unit.armor, Vector2(cx + 80, cy + 112), 15, GOLD)
		_text("MOV %d" % card_unit.move, Vector2(cx + 14, cy + 132), 15, GOLD)
		_text("RNG %d" % card_unit.range, Vector2(cx + 80, cy + 132), 15, GOLD)
		# Status badge
		if card_unit.guard:
			_text("GUARD", Vector2(cx + 148, cy + 112), 14, GOLD)
		elif card_unit.cohesion == 1:
			_text("SHAKEN", Vector2(cx + 148, cy + 112), 14, RED)
		elif card_unit.get("acted", false) and card_unit.side == 0:
			_text("DONE", Vector2(cx + 148, cy + 112), 14, MUTED)

	# Objective overlay — bottom left
	_panel(Rect2(16, 810, 320, 72), Color(0.08, 0.14, 0.18, 0.75))
	_wrap("Route every enemy.\nOathkeeper must survive.", Rect2(28, 822, 296, 56), 16, PAPER, 24)

	# Message toast — top, below pill
	if not message.is_empty() and animation.is_empty():
		_panel(Rect2(200, 58, 700, 42), Color(0.08, 0.14, 0.18, 0.82))
		_wrap(message, Rect2(214, 64, 672, 34), 15, PAPER, 22)

func _draw_world():
	if campaign.rewarded:
		_draw_region_world()
		return
	# A continuous illustrated landmass; only selection and fog use logical hexes.
	draw_texture_rect(MARCH, FIELD.grow(-2), false)
	for p in campaign.board:
		if p not in campaign.explored:
			draw_colored_polygon(_hex(p, true, 1.025), Color("263c3e"))
		elif p not in campaign.visible:
			draw_colored_polygon(_hex(p, true, 1.025), Color(0.1, 0.2, 0.22, 0.45))
		if grid_visible:
			var outline = _hex(p, true)
			outline.append(outline[0])
			draw_polyline(outline, Color(0.9, 0.85, 0.65, 0.3), 1, true)
	if campaign.village in campaign.explored:
		var v = _pos(campaign.village, true)
		_panel(Rect2(v + Vector2(-63, 30), Vector2(145, 31)), INK)
		_text("GREYFORD", v + Vector2(-49, 52), 16, PAPER)
		if not campaign.rewarded:
			for i in 6:
				var drift = fmod(clock * 14 + i * 17, 90.0)
				draw_circle(v + Vector2(13 + sin(i + clock) * 7, -38 - drift), 7 + drift * 0.09, Color(0.25, 0.26, 0.22, 0.27 * (1 - drift / 90)))
	if campaign.patrol in campaign.visible:
		var p = _npc_position("patrol", campaign.patrol)
		_party(p, TEAL, "PATROL", false)
	if campaign.bandit in campaign.visible and not campaign.rewarded:
		_party(_npc_position("bandit", campaign.bandit), RED, "RAIDERS", false)
	var player_pos = _pos(campaign.player, true)
	if animation.get("type") == "travel":
		player_pos = _path_position(animation.path, true)
	var at_village = campaign.player == campaign.village and animation.get("type") != "travel"
	_party(player_pos + (Vector2(-42, 2) if at_village else Vector2.ZERO), GOLD, "" if at_village else "YOUR WALKER", true)
	if hovered in campaign.board and animation.is_empty():
		var path = campaign.path_to(hovered)
		if not path.is_empty():
			_draw_path(path, true)
	_panel(Rect2(62, 161, 522, 72), Color(0.1, 0.18, 0.2, 0.91))
	_text("THE GREYFORD MARCH", Vector2(78, 190), 24, PAPER, true)
	_text("A frontier road in the fractured empire", Vector2(78, 218), 16, PAPER)
	# Mini compass is a map ornament, never a second control scheme.
	draw_line(Vector2(1111, 666), Vector2(1111, 715), GOLD, 2, true)
	draw_line(Vector2(1090, 691), Vector2(1132, 691), GOLD, 2, true)
	_text("N", Vector2(1104, 657), 17, PAPER)

func _npc_position(id: String, destination: Vector2i) -> Vector2:
	if animation.get("type") == "npc" and npc_motion.has(id):
		# Do not animate a hidden origin into view; reveal the final known marker only.
		if npc_motion[id] in campaign.visible:
			return _pos(npc_motion[id], true).lerp(_pos(destination, true), _progress())
	return _pos(destination, true)

func _tree(p: Vector2, s: float):
	Figures.ellipse(self, p + Vector2(5, 4), Vector2(21, 9) * s, Color(0.19, 0.28, 0.2, 0.25))
	draw_line(p, p + Vector2(0, -27) * s, Color("625c3d"), 5 * s, true)
	for offset in [Vector2(0, -27), Vector2(-10, -20), Vector2(10, -18), Vector2(0, -36)]:
		draw_circle(p + offset * s, 15 * s, Color("50654a"))
		draw_arc(p + offset * s + Vector2(-3, -3), 10 * s, PI, 1.8 * PI, 8, Color("83915c"), 6 * s, true)

func _settlement(p: Vector2, large: bool):
	Figures.ellipse(self, p + Vector2(4, 8), Vector2(57, 22), Color(0.22, 0.27, 0.16, 0.2))
	for i in (5 if large else 3):
		var o = p + Vector2((i % 3 - 1) * 27, floori(i / 3.0) * 17)
		draw_rect(Rect2(o + Vector2(-10, -25), Vector2(22, 30)), Color("c4b89b"))
		draw_colored_polygon(PackedVector2Array([o + Vector2(-15, -25), o + Vector2(0, -45), o + Vector2(17, -25)]), Color("525e66"))
		draw_rect(Rect2(o + Vector2(-2, -8), Vector2(7, 13)), Color("424e4d"))
		draw_rect(Rect2(o + Vector2(-5, -21), Vector2(4, 6)), Color("ebd09a"))

func _party(p: Vector2, color: Color, label: String, hero: bool):
	Figures.ellipse(self, p + Vector2(0, 8), Vector2(28, 12), Color(0.08, 0.15, 0.15, 0.3))
	draw_circle(p + Vector2(0, -7), 18 if hero else 13, INK)
	_crest(p + Vector2(0, -10), 0.78 if hero else 0.55, color)
	if not label.is_empty():
		_panel(Rect2(p + Vector2(-66, 20), Vector2(132, 26)), Color("233c3e"))
		_text(label, p + Vector2(-57, 39), 13, color)

func _draw_path(path: Array, world: bool):
	var points = PackedVector2Array()
	for p in path:
		points.append(_pos(p, world))
	draw_polyline(points, Color(0.96, 0.89, 0.64, 0.9), 3, true)
	for i in range(1, points.size()):
		draw_circle(points[i], 5, GOLD)
	var end = points[-1]
	_panel(Rect2(end + Vector2(-28, 15), Vector2(58, 27)), INK)
	_text(str(path.size() - 1 if world or battle == null else battle.path_cost(path)) + " MP", end + Vector2(-19, 35), 15, PAPER)

func _progress() -> float:
	return clampf(animation_time / maxf(float(animation.get("duration", 0.6)), 0.001), 0, 1)

func _path_position(path: Array, world: bool) -> Vector2:
	var sample = _progress() * (path.size() - 1)
	var index = mini(floori(sample), path.size() - 2)
	return _pos(path[index], world).lerp(_pos(path[index + 1], world), sample - index)

func _draw_battle():
	if battle.combined:
		_draw_combined_battle()
		return
	draw_texture_rect(MEADOW, BATTLE_FIELD, false)
	draw_rect(BATTLE_FIELD, Color(0.13, 0.2, 0.16, 0.07))
	for p in battle.board:
		if p in cached_reachable and animation.is_empty() and battle.side == 0:
			draw_colored_polygon(_hex(p, false, 0.92), Color(0.81, 0.9, 0.64, 0.16))
		if grid_visible:
			var outline = _hex(p)
			outline.append(outline[0])
			draw_polyline(outline, Color(0.93, 0.9, 0.72, 0.35), 1, true)
	for p in battle.blocked:
		var center = _pos(p)
		Figures.ellipse(self, center + Vector2(6, 10), Vector2(39, 15), Color(0.09, 0.15, 0.12, 0.3))
		Figures.polygon(self, [center + Vector2(-31, 8), center + Vector2(-26, -19), center + Vector2(-5, -33), center + Vector2(22, -23), center + Vector2(33, 4), center + Vector2(10, 15)], Color("737d72"))
		Figures.polygon(self, [center + Vector2(-26, -19), center + Vector2(-5, -33), center + Vector2(22, -23), center + Vector2(6, -7)], Color("a4a998"))
	if hovered in battle.board and animation.is_empty():
		var outline = _hex(hovered, false, 0.94)
		outline.append(outline[0])
		draw_polyline(outline, GOLD, 2, true)
		if selected != "":
			var target = battle.occupant(hovered)
			if target.is_empty():
				var path = battle.movement_path(selected, hovered)
				if not path.is_empty():
					_draw_path(path, false)
			elif target.side == 1:
				var preview = battle.attack_preview(selected, target.id)
				if not preview.is_empty():
					var v = _pos(hovered)
					_panel(Rect2(v + Vector2(-88, -132), Vector2(188, 40)), INK, RED)
					_text("%d DAMAGE  ·  %s" % [preview.damage, preview.label], v + Vector2(-76, -105), 14, PAPER)
	var sorted_units = battle.units.duplicate()
	sorted_units.sort_custom(func(a, b): return _pos(a.pos).y < _pos(b.pos).y)
	for u in sorted_units:
		var showing_hit = animation.get("type") == "attack" and animation.get("target") == u.id
		if not battle.alive(u) and not showing_hit:
			continue
		var center = _pos(u.pos)
		var moving = animation.get("type") == "move" and animation.get("id") == u.id
		if moving:
			center = _path_position(animation.path, false)
		var attacking = animation.get("type") == "attack" and animation.get("id") == u.id
		var progress = _progress()
		if attacking and not animation.ranged:
			center += (_pos(animation.to) - center).normalized() * sin(progress * PI) * (5 if reduced_motion else 16)
		var hit = sin(maxf(0, (progress - 0.4) / 0.6) * PI) if showing_hit and not reduced_motion else 0.0
		var display_hp = animation.old_hp if showing_hit and progress < 0.48 else u.hp
		var display_unit = u.duplicate()
		display_unit.hp = maxi(1, display_hp)
		var presentation = Mechs.context(u, animation, progress)
		if moving:
			var travel = _mech_travel(animation.path, progress)
			presentation.travel_px = travel.distance
			display_unit.facing = travel.facing
		if u.id == selected:
			Figures.ellipse(self, center + Vector2(0, 6), Vector2(47, 19), Color(0.93, 0.83, 0.5, 0.3))
		if showing_hit and progress >= 0.48 and not battle.alive(u):
			if animation.routed:
				Figures.draw_unit(self, display_unit, center + Vector2((1 if u.side == 1 else -1) * 26 * progress, 0), clock, true, 0, 0, reduced_motion)
			else:
				draw_line(center + Vector2(-22, -10), center + Vector2(21, 2), Color("59665c"), 13, true)
		else:
			Figures.draw_unit(self, display_unit, center, clock, moving, progress if attacking else 0.0, hit, reduced_motion, presentation)
		var faction_color = TEAL if u.side == 0 else RED
		var bar = Rect2(center + Vector2(-31, 24), Vector2(62, 6))
		draw_rect(bar.grow(1), INK)
		draw_rect(Rect2(bar.position, Vector2(bar.size.x * maxf(0, float(display_hp) / u.max_hp), 6)), faction_color)
		_text(str(maxi(0, display_hp)) + (" H" if u.kind == "mech" else " T"), center + Vector2(-15, 46), 13, PAPER)
		if u.guard:
			_text("GUARD", center + Vector2(-22, 62), 12, GOLD)
		elif u.cohesion == 1:
			_text("SHAKEN", center + Vector2(-25, 62), 12, RED)
		elif u.acted and u.side == 0:
			_text("DONE", center + Vector2(-18, 62), 12, MUTED)
		var facing_vector = (_pos(u.pos + Hex.DIRECTIONS[u.facing]) - _pos(u.pos)).normalized()
		var arrow = center + facing_vector * 45
		draw_line(arrow - facing_vector.rotated(0.5) * 8, arrow, GOLD, 2, true)
		draw_line(arrow - facing_vector.rotated(-0.5) * 8, arrow, GOLD, 2, true)
	if animation.get("type") == "attack":
		_draw_impact()

func _mech_travel(path: Array, progress: float) -> Dictionary:
	var segments = path.size() - 1
	if segments <= 0:
		return {"distance": 0.0, "facing": 0}
	var cursor = clampf(progress, 0, 1) * segments
	var index = mini(floori(cursor), segments - 1)
	var distance = 0.0
	for i in index:
		distance += _pos(path[i]).distance_to(_pos(path[i + 1]))
	distance += _pos(path[index]).distance_to(_pos(path[index + 1])) * (cursor - index)
	return {"distance": distance, "facing": Hex.direction(path[index], path[index + 1])}

func _draw_impact():
	var progress = _progress()
	var source = _pos(animation.from) + Vector2(0, -36)
	var target = _pos(animation.to) + Vector2(0, -28)
	var target_unit = battle.unit(animation.target)
	if Mechs.has_art(target_unit):
		var target_pose = Mechs.pose(target_unit, clock, Mechs.context(target_unit, animation, progress), reduced_motion)
		target = _pos(animation.to) + (target_pose.hands[0] if animation.get("guarded", false) else target_pose.chest)
	if animation.ranged and progress >= 0.17 and progress < 0.48:
		var travel = (progress - 0.17) / 0.31
		var p = source.lerp(target, travel)
		draw_line(p, p - (target - source).normalized() * 24, Color("ffe3a2"), 3, true)
		draw_circle(source, 4, GOLD)
	if progress >= 0.45:
		var spread = (progress - 0.45) / 0.55
		if not reduced_motion:
			for i in 7:
				var delta = Vector2.from_angle(i * TAU / 7) * spread * 35
				draw_line(target + delta * 0.7, target + delta, Color(1, 0.84, 0.49, 1 - spread), 2, true)
		_text("−%d" % animation.damage, target + Vector2(-15, -18 - spread * 27), 28, Color("ffe6c0"), true)
		if animation.get("guarded", false):
			_text("GUARD", target + Vector2(-24, 9), 13, GOLD)
		if animation.routed:
			_text("ROUTED", target + Vector2(-34, 6), 16, RED)

func _draw_results():
	_background()
	draw_rect(Rect2(0, 0, 1600, 900), Color(0.04, 0.1, 0.12, 0.77))
	_panel(Rect2(330, 195, 940, 590), Color(0.1, 0.18, 0.2, 0.97), GOLD)
	_crest(Vector2(800, 265), 1.5)
	var won = battle.outcome == "victory"
	_text(("CROSSING SECURED" if battle.combined else "GREYFORD HOLDS") if won else "A BANNER BENT, NOT BROKEN", Vector2(467 if won else 425, 361), 42 if won else 34, PAPER, true)
	_wrap(result_text, Rect2(440, 398, 720, 70), 29, GOLD, 40, true)
	var detail = "Your first pay is forty gold. Mira's soldiers remain in Greyford. You have earned local trust, but your own army is still ahead of you."
	if not won:
		detail = "The villagers recover Oathkeeper and repair it without charge. You survive, and the defense remains available to retry."
	if battle.combined:
		detail = campaign.region.last_result if not practice else "Capacity review complete. This practice has no effect on your regional save."
	_wrap(detail, Rect2(440, 477, 720, 110), 23, PAPER, 34)
	var reward = "+40 GOLD    ·    +1 LOCAL TRUST    ·    VILLAGE DEFENDED" if won else "FREE RECOVERY    ·    NO PERMANENT LOSSES"
	if battle.combined:
		reward = "+%d GOLD · +1 TRUST" % campaign.region.last_reward if won else "FREE FRAME RECOVERY · FORMATIONS WOUNDED"
	if practice:
		reward = "PRACTICE ENCOUNTER    ·    CAMPAIGN UNCHANGED"
	_text(reward, Vector2(440, 623), 17, TEAL)
	_text("THE MARCH AWAITS" if won else "YOUR CAUSE CONTINUES", Vector2(570, 661), 15, MUTED)

func _draw_modal():
	draw_rect(Rect2(0, 0, 1600, 900), Color(0.02, 0.05, 0.07, 0.83))
	_panel(Rect2(365, 205, 870, 550), Color("20343c"), GOLD)
	if modal in ["help", "pause"]:
		_text("A moment by the road" if modal == "pause" else "Command your company", Vector2(416, 278), 40, PAPER, true)
		_wrap("Select a friendly unit, then a shaded hex to move. Click an enemy to attack; hover to inspect or preview damage.\nMove once, then attack or Guard. Rocks block travel and sight. Finish a moved unit before choosing another.\n1–3: select. Tab: next. B: guard. F: face. Q: ability. E: mage mend. Space: end turn. G: grid. N: speed. Esc: pause.\nOn the map, travel to Greyford and enter the village. NPCs move only on End Turn.", Rect2(416, 310, 765, 235), 20, PAPER, 29)
	else:
		var title = "Start a new journey?"
		var detail = "This replaces the demo's single campaign checkpoint. Your settings remain unchanged."
		if modal == "restart":
			title = "Restart this encounter?"
			detail = "The battle returns to its initial deployment. Your campaign checkpoint and unclaimed reward remain unchanged."
		elif modal == "home":
			title = "Return to the title?"
			detail = "Your last committed campaign checkpoint remains available through Continue."
		elif modal == "save_error":
			title = "The checkpoint could not be saved"
			detail = message
		_text(title, Vector2(416, 306), 36, PAPER, true)
		_wrap(detail, Rect2(416, 361, 765, 156), 24, PAPER, 36)

func _open_region_review(fresh_qa: bool = false):
	if not region_review: real_saves = saves
	region_review = true
	saves = Saves.new("/tmp/berania_region_review_qa.json" if "--qa" in OS.get_cmdline_user_args() else "user://region_review.json")
	var data = {} if fresh_qa and "--qa" in OS.get_cmdline_user_args() else saves.load_data()
	campaign = Campaign.new()
	if data.is_empty():
		campaign.rewarded = true
		campaign.quest = "complete"
		campaign.player = campaign.village
		campaign.mech_hp = 30
		campaign.gold = 130
		campaign.trust = 1
		campaign.update_visibility()
		for definition in ["greyford_blades", "roadwardens", "pikemen", "cavalry", "cannon", "mages"]: campaign.recruit(definition)
		for place in Region.SETTLEMENTS:
			if Region.pos(place.cell) not in campaign.explored: campaign.explored.append(Region.pos(place.cell))
		_checkpoint()
	else:
		campaign.restore(data)
	practice = false
	if campaign.pending_battle: _start_battle()
	else: _enter_world()
	message = "REGIONAL REVIEW · separate save. Six hired formations; real campaign resources are unaffected."

func _incident_here() -> Dictionary:
	for incident in campaign.region.incidents:
		if Region.pos(incident.cell) == campaign.player: return incident
	return {}

func _interact_region():
	if not campaign.rewarded:
		_village()
		return
	var incident = _incident_here()
	if not incident.is_empty():
		_open_preparation(incident.kind, incident.id)
		return
	if Region.settlement(campaign.player).is_empty(): return
	phase = "settlement"
	message = "Settlement services do not advance travel time."
	_refresh_ui()

func _service(action: String):
	var before = campaign.snapshot()
	message = campaign.regional_order(action)
	if campaign.snapshot() != before and not _checkpoint(): campaign.restore(before)
	_refresh_ui()

func _hire(definition: String):
	var before = campaign.snapshot()
	message = campaign.recruit(definition)
	if campaign.snapshot() != before and not _checkpoint(): campaign.restore(before)
	_refresh_ui()

func _trade_cargo(action: String, good: String):
	var before = campaign.snapshot()
	var order = Shop.transact(campaign.workshop, campaign.gold, action, {"good": good, "quantity": 1})
	message = order.message
	if order.ok:
		campaign.workshop = order.state
		campaign.gold = order.gold
		if not _checkpoint(): campaign.restore(before)
	_refresh_ui()

func _build_settlement_ui():
	var place = Region.settlement(campaign.player)
	_button("Return to regional map", Rect2(1160, 796, 354, 48), func(): phase = "world"; _refresh_ui(), true)
	if not place.friendly:
		_button("Raid supply line · prepare", Rect2(100, 340, 520, 56), func(): _open_preparation("raid"), true)
		return
	_button("Mech workshop", Rect2(90, 258, 312, 44), func(): _open_workshop(false), true)
	_button("Free emergency repair", Rect2(420, 258, 312, 44), func(): _service("repair"))
	_button("Guild · grain contract", Rect2(90, 318, 312, 44), func(): _service("guild"))
	_button("Deliver 2 grain", Rect2(420, 318, 312, 44), func(): _service("deliver"))
	_button("Road clearance · prepare", Rect2(90, 378, 312, 44), func(): _open_preparation("guild"), true)
	_button("Replenish formations", Rect2(420, 378, 312, 44), func(): _service("replenish"))
	_button("Envoy · road pact terms", Rect2(90, 438, 642, 44), func(): _service("diplomacy"))
	var index = 0
	for definition in Region.PRICES:
		var role = definition
		var info = Battle.DEFINITIONS.get(role, Battle.COMBINED.get(role))
		_button(info.role + " · " + str(Region.PRICES[role]) + "g", Rect2(840, 258 + index * 57, 640, 45), func(): _hire(role))
		index += 1
	_button("Buy grain · 3g", Rect2(90, 554, 306, 44), func(): _trade_cargo("buy_good", "grain"))
	_button("Sell grain · 2g", Rect2(420, 554, 312, 44), func(): _trade_cargo("sell_good", "grain"))
	_button("Buy ore · 6g", Rect2(90, 611, 306, 44), func(): _trade_cargo("buy_good", "ore"))
	_button("Sell ore · 4g", Rect2(420, 611, 312, 44), func(): _trade_cargo("sell_good", "ore"))
	if region_review:
		_button("10 vs 10 capacity practice", Rect2(840, 650, 310, 44), func(): _capacity_review(false))
		_button("15 vs 15 major practice", Rect2(1170, 650, 310, 44), func(): _capacity_review(true))

func _open_preparation(kind: String, id: String = ""):
	preparation_kind = kind
	preparation_id = id
	preparation = campaign.prepare_region(kind, id)
	if preparation.is_empty():
		message = "No work available here now. Guild / supply jobs reopen two travel turns after a victory."
		_refresh_ui()
		return
	selected_roster = campaign.region.selected.duplicate()
	phase = "preparation"
	message = "Select up to 9 owned formations. You and any local or allied formations share the 10-slot limit."
	_refresh_ui()

func _toggle_roster(id: String):
	if id in selected_roster: selected_roster.erase(id)
	elif selected_roster.size() < 9: selected_roster.append(id)
	else: message = "Nine formations plus your mech fill the ten command slots."
	_refresh_ui()

func _preview_preparation() -> Dictionary:
	var previous = campaign.region.selected.duplicate()
	campaign.region.selected = selected_roster.duplicate()
	var result = campaign.prepare_region(preparation_kind, preparation_id)
	campaign.region.selected = previous
	return result

func _build_preparation_ui():
	var index = 0
	for f in campaign.region.formations:
		var id = f.id
		var definition = Battle.DEFINITIONS.get(f.definition, Battle.COMBINED.get(f.definition))
		_button(("✓ " if id in selected_roster else "+ ") + definition.name + " · %d/%d" % [f.hp, definition.hp], Rect2(90 + (index / 10) * 365, 265 + (index % 10) * 43, 350, 38), func(): _toggle_roster(id), id in selected_roster)
		index += 1
	_button("Deploy · lock encounter", Rect2(1100, 783, 380, 54), _commit_preparation, true)
	_button("Return to map", Rect2(90, 783, 330, 54), func(): phase = "world"; _refresh_ui())

func _commit_preparation():
	var before = campaign.snapshot()
	var prepared = _preview_preparation()
	campaign.region.selected = selected_roster.duplicate()
	if not campaign.commit_region(prepared):
		campaign.restore(before)
		message = "The deployment could not be validated."
		return
	if not _checkpoint():
		campaign.restore(before)
		return
	practice = false
	_start_battle()
	message = "Hold the crossing 3 consecutive turns or route the enemy. Q: ability, E: mage mend. Tab: next unit."

func _capacity_review(major: bool):
	var roster = [{"id": "hero", "definition": "militia_mech"}]
	var definitions = ["greyford_blades", "pikemen", "roadwardens", "cavalry", "mages", "cannon"]
	var cap = 15 if major else 10
	for i in cap - 1: roster.append({"id": "review_" + str(i), "definition": definitions[i % definitions.size()]})
	practice = true
	workshop_training = false
	phase = "battle"
	battle = Battle.new({"id": "capacity", "name": "Capacity practice", "major": major, "friendly": roster, "enemy": Region.enemies(cap)})
	selected = "hero"
	ability_mode = false
	mend_mode = false
	battle_zoom = 1.0
	battle_pan = Vector2.ZERO
	animation.clear()
	message = "ISOLATED CAPACITY PRACTICE · %d vs %d. Pause offers a direct return to the region." % [cap, cap]
	_reachable()
	_refresh_ui()

func _cycle_unit():
	if battle.side != 0 or not animation.is_empty(): return
	var ready = []
	for u in battle.units:
		if u.side == 0 and battle.can_activate(u.id): ready.append(u.id)
	if not ready.is_empty(): _select(ready[(ready.find(selected) + 1) % ready.size()])

func _draw_regional_screen():
	_background()
	draw_rect(Rect2(0, 0, 1600, 900), Color(0.04, 0.1, 0.13, 0.9))
	_panel(Rect2(58, 50, 1484, 720), Color("1b3037"), GOLD)
	if phase == "settlement":
		var place = Region.settlement(campaign.player)
		_text(place.name, Vector2(90, 118), 42, PAPER, true)
		_text(place.kind + (" · REGIONAL REVIEW SAVE" if region_review else ""), Vector2(90, 156), 19, GOLD)
		_text("%d gold · %d trust · %d/20 cargo · Grain %d · Ore %d" % [campaign.gold, campaign.trust, Shop.cargo_used(campaign.workshop), campaign.workshop.cargo.get("grain", 0), campaign.workshop.cargo.get("ore", 0)], Vector2(90, 203), 21, TEAL)
		if place.friendly:
			_text("VILLAGE & GUILD", Vector2(90, 241), 15, MUTED)
			_text("RECRUIT FORMATIONS · %d / 20 OWNED" % campaign.region.formations.size(), Vector2(840, 241), 15, MUTED)
			_text("House support: " + ("road pact active" if campaign.region.allied else "no agreement"), Vector2(90, 515), 19, GOLD)
			_text("Reserve equipment is shared; trade goods travel with you.", Vector2(90, 699), 17, MUTED)
		else:
			_wrap("Imperial banners hold this fort. You can strike its supply line. A raid changes regional relations; conquest and sieges remain outside this slice.", Rect2(100, 240, 1200, 80), 23, PAPER, 31)
	else:
		var preview = _preview_preparation()
		_text(preparation.name, Vector2(90, 118), 38, PAPER, true)
		_text("DEPLOYMENT · %d / 10 FRIENDLY · %d ENEMY · %d GOLD REWARD" % [preview.get("friendly", []).size(), preview.get("enemy", []).size(), preview.get("reward", 0)], Vector2(90, 161), 20, GOLD)
		_text("OWNED FORMATIONS · EACH ROW IS ONE SLOT", Vector2(90, 235), 16, MUTED)
		_text("LOCKED PARTICIPANTS", Vector2(880, 235), 17, GOLD)
		var row = 0
		for entry in preview.get("friendly", []):
			var info = Battle.DEFINITIONS.get(entry.definition, Battle.COMBINED.get(entry.definition))
			_text(entry.get("name", info.name) + (" · owned" if entry.get("owned", false) else " · local / allied"), Vector2(880, 282 + row * 32), 19, TEAL if entry.get("owned", false) else MUTED)
			row += 1
		_wrap("14 × 10 hex field. Directional stone cover blocks 2 ranged damage from its marked face; rough ground costs 2 movement. Hold the crossing for 3 turns or route every enemy. Oathkeeper must survive.", Rect2(880, 622, 580, 126), 19, PAPER, 28)
	_panel(Rect2(70, 705 if phase == "settlement" else 848, 1460, 60), Color("12262e"))
	_wrap(message, Rect2(90, 714 if phase == "settlement" else 854, 1410, 49), 18, PAPER, 24)

func _draw_region_world():
	draw_texture_rect(MARCH, FIELD.grow(-2), false)
	draw_rect(FIELD.grow(-2), Color(0.15, 0.23, 0.18, 0.16))
	for pair in [[0, 1], [0, 2], [1, 3]]:
		var route = Hex.line(Region.pos(Region.SETTLEMENTS[pair[0]].cell), Region.pos(Region.SETTLEMENTS[pair[1]].cell))
		var line = PackedVector2Array()
		for p in route: line.append(_pos(p, true))
		draw_polyline(line, Color(0.78, 0.70, 0.48, 0.45), 9, true)
	for p in campaign.board:
		if p not in campaign.explored: draw_colored_polygon(_hex(p, true, 1.04), Color("263c3e"))
		elif p not in campaign.visible: draw_colored_polygon(_hex(p, true, 1.04), Color(0.06, 0.14, 0.17, 0.61))
		if grid_visible:
			var line = _hex(p, true); line.append(line[0]); draw_polyline(line, Color(0.9, 0.85, 0.65, 0.2), 1, true)
	for place in Region.SETTLEMENTS:
		var p = Region.pos(place.cell)
		if p not in campaign.explored: continue
		var center = _pos(p, true)
		_settlement(center, place.id in ["stonebridge", "emberwatch"])
		_panel(Rect2(center + Vector2(-65, 20), Vector2(140, 26)), INK)
		_text(place.name.to_upper(), center + Vector2(-58, 39), 14, PAPER if place.friendly else RED)
	for party in campaign.region.parties:
		if Region.pos(party.cell) not in campaign.visible: continue
		var offset = {"caravan": Vector2(23, -22), "patrol": Vector2(-8, -22), "bandits": Vector2(-20, -25), "envoy": Vector2(-24, -32), "army": Vector2(18, -28)}[party.id]
		var center = _npc_position(party.id, Region.pos(party.cell)) + offset
		var color = {"caravan": Color("e3c697"), "patrol": TEAL, "bandits": RED, "envoy": Color("b8a6c8"), "army": RED}[party.id]
		_party(center, color, "", false)
	for incident in campaign.region.incidents:
		if Region.pos(incident.cell) not in campaign.visible: continue
		var center = _pos(Region.pos(incident.cell), true)
		draw_arc(center, 42, 0, TAU, 32, RED, 3, true)
		_text("ATTACK · %d turns" % (incident.expires - campaign.region.ticks + 1), center + Vector2(-67, -55), 16, RED)
	var player_pos = _path_position(animation.path, true) if animation.get("type") == "travel" else _pos(campaign.player, true)
	_party(player_pos + Vector2(-27, 5), GOLD, "" if not Region.settlement(campaign.player).is_empty() else "YOUR COMPANY", true)
	if hovered in campaign.board and animation.is_empty():
		var path = campaign.path_to(hovered)
		if not path.is_empty(): _draw_path(path, true)
	_panel(Rect2(62, 161, 670, 66), Color(0.07, 0.15, 0.18, 0.94))
	_text("THE LIVING MARCH" + (" · REVIEW" if region_review else ""), Vector2(80, 191), 23, PAPER, true)
	_text("Visible parties are current · dim land is remembered · turns move the world", Vector2(80, 216), 15, MUTED)
	if hovered in campaign.visible:
		var descriptions = []
		for party in campaign.region.parties:
			if Region.pos(party.cell) == hovered: descriptions.append(party.kind)
		for incident in campaign.region.incidents:
			if Region.pos(incident.cell) == hovered: descriptions.append(incident.name)
		if not descriptions.is_empty():
			_panel(Rect2(64, 707, 960, 30), INK)
			_text(" · ".join(descriptions), Vector2(80, 729), 17, GOLD)

func _draw_combined_battle():
	draw_texture_rect(MEADOW, Rect2(250, 65, 1350, 710), false)
	draw_rect(Rect2(250, 65, 1350, 710), Color(0.10, 0.19, 0.16, 0.24))
	for p in battle.board:
		var center = _pos(p)
		var terrain_color = Color("71805a") if (Hex.column(p) + p.y) % 3 == 0 else Color("697953")
		draw_colored_polygon(_hex(p, false, 1.0), Color(terrain_color, 0.38))
		if battle.terrain.has(p):
			for i in 3: draw_line(center + Vector2(-15 + i * 10, 4), center + Vector2(-9 + i * 10, -2), Color("b4a47a"), 2, true)
		if p in cached_reachable and animation.is_empty() and battle.side == 0: draw_colored_polygon(_hex(p, false, 0.94), Color(0.62, 0.86, 0.79, 0.23))
		if grid_visible:
			var outline = _hex(p); outline.append(outline[0]); draw_polyline(outline, Color(0.9, 0.9, 0.7, 0.28), 1, true)
		if battle.cover.has(p):
			var facing = battle.cover[p].facing
			var direction = (_pos(p + Hex.DIRECTIONS[facing]) - center).normalized()
			var edge = center + direction * 24 * battle_zoom
			var tangent = direction.orthogonal() * 19 * battle_zoom
			draw_line(edge - tangent + Vector2(0, 3), edge + tangent + Vector2(0, 3), Color("384442"), 10 * battle_zoom, true)
			draw_line(edge - tangent, edge + tangent, Color("bfbea5"), 6 * battle_zoom, true)
			draw_circle(edge, 3, TEAL)
	for p in battle.blocked:
		var center = _pos(p)
		Figures.polygon(self, [center + Vector2(-24, 10), center + Vector2(-25, -12), center + Vector2(0, -27), center + Vector2(24, -14), center + Vector2(25, 10)], Color("68796c"))
		draw_line(center + Vector2(-22, -12), center + Vector2(0, -26), Color("adbaa4"), 3, true)
	var goal = _pos(battle.objective)
	draw_arc(goal, 30 * battle_zoom, 0, TAU, 32, GOLD, 3, true)
	_text("SUPPLY", goal + Vector2(-26, 5), 12, GOLD)
	var sorted = battle.units.duplicate()
	sorted.sort_custom(func(a, b): return a.pos.y < b.pos.y)
	for u in sorted:
		if not battle.alive(u): continue
		var center = _pos(u.pos)
		if animation.get("type") == "move" and animation.get("id") == u.id: center = _path_position(animation.path, false)
		var color = TEAL if u.side == 0 else RED
		var radius = (24 if u.kind == "mech" else 20) * battle_zoom
		Figures.ellipse(self, center + Vector2(2, 5), Vector2(radius + 3, radius * 0.6), Color(0.03, 0.1, 0.12, 0.45))
		draw_circle(center + Vector2(0, -5), radius, Color("1d333b"))
		draw_arc(center + Vector2(0, -5), radius, 0, TAU, 20, GOLD if selected == u.id else color, 3 if selected == u.id else 1.5, true)
		_draw_role_icon(u.kind, center + Vector2(0, -5), color, battle_zoom)
		var front = (_pos(u.pos + Hex.DIRECTIONS[u.facing]) - _pos(u.pos)).normalized()
		draw_circle(center + Vector2(0, -5) + front * (radius + 4), 3, GOLD)
		var hp = Rect2(center + Vector2(-22, radius - 1), Vector2(44, 5))
		draw_rect(hp.grow(1), INK)
		draw_rect(Rect2(hp.position, Vector2(44 * float(u.hp) / u.max_hp, 5)), color)
		_text(str(u.hp) + (" ◆" if u.guard else (" ✓" if u.acted else "")), center + Vector2(-12, radius + 19), 12, PAPER)
	if hovered in battle.board and animation.is_empty():
		var outline = _hex(hovered, false, 0.94); outline.append(outline[0]); draw_polyline(outline, GOLD, 2, true)
		if _player_ready():
			var target = battle.occupant(hovered)
			if target.is_empty():
				var path = battle.movement_path(selected, hovered)
				if not path.is_empty(): _draw_path(path, false)
			elif target.side == 1:
				var preview = battle.attack_preview(selected, target.id, ability_mode)
				if not preview.is_empty():
					draw_line(_pos(battle.unit(selected).pos), _pos(target.pos), GOLD, 2, true)
					_panel(Rect2(460, 705, 960, 52), Color("172c34"), GOLD)
					_text("%d EXACT DAMAGE · %s · armor %d · guard %d" % [preview.damage, preview.label, preview.armor, preview.guard], Vector2(478, 738), 18, PAPER)
	if animation.get("type") == "attack":
		var progress = _progress()
		var target = _pos(animation.to)
		draw_line(_pos(animation.from), target, Color(GOLD, 1.0 - progress), 3, true)
		if progress >= 0.48: _text("−%d" % animation.damage, target + Vector2(-14, -42 - progress * 14), 25, PAPER, true)
	elif animation.get("type") == "mend":
		var target = _pos(battle.unit(animation.target).pos)
		_text("+%d" % animation.restored, target + Vector2(-14, -38), 25, TEAL, true)
	# HUD regions mask the pan/zoom playfield so tokens never cover controls.
	draw_rect(Rect2(0, 0, 253, 900), Color("142a33"))
	draw_rect(Rect2(250, 772, 1350, 128), Color("142a33"))

func _draw_role_icon(kind: String, center: Vector2, color: Color, scale_value: float):
	# Original vector silhouettes. Each marker is a whole formation, not one soldier.
	draw_set_transform(center, 0, Vector2.ONE * scale_value)
	if kind in ["sword", "pike"]:
		draw_line(Vector2(-7, 10), Vector2(7, -13), color, 3, true)
		Figures.polygon(self, [Vector2(7, -16), Vector2(3, -8), Vector2(10, -10)], color)
		if kind == "sword":
			draw_line(Vector2(-10, 3), Vector2(2, 9), GOLD, 3, true)
			Figures.polygon(self, [Vector2(-14, -7), Vector2(-5, -7), Vector2(-5, 0), Vector2(-9, 5), Vector2(-14, 0)], color)
		else:
			draw_line(Vector2(7, 11), Vector2(-7, -12), color, 2, true)
			Figures.polygon(self, [Vector2(-7, -16), Vector2(-10, -9), Vector2(-3, -10)], color)
	elif kind == "gunner":
		draw_line(Vector2(-12, 9), Vector2(12, -11), color, 5, true)
		draw_line(Vector2(-12, 9), Vector2(-12, 2), GOLD, 4, true)
		draw_line(Vector2(-1, -3), Vector2(4, -10), color, 2, true)
	elif kind == "cannon":
		draw_circle(Vector2(-7, 7), 6, color)
		draw_circle(Vector2(-7, 7), 3, INK)
		draw_line(Vector2(-6, 2), Vector2(12, -8), color, 8, true)
		draw_line(Vector2(10, -11), Vector2(14, -5), GOLD, 2, true)
		draw_line(Vector2(-2, 9), Vector2(12, 13), color, 3, true)
	elif kind == "mage":
		for i in 6:
			var tip = Vector2.from_angle(i * TAU / 6) * 13
			draw_line(tip * 0.45, tip, color, 2, true)
		Figures.polygon(self, [Vector2(0, -10), Vector2(6, 0), Vector2(0, 10), Vector2(-6, 0)], GOLD)
		draw_arc(Vector2.ZERO, 15, 0, TAU, 24, Color(color, 0.5), 1, true)
	elif kind == "cavalry":
		Figures.polygon(self, [Vector2(-12, 12), Vector2(-9, 0), Vector2(0, -7), Vector2(1, -15), Vector2(7, -11), Vector2(13, -3), Vector2(10, 3), Vector2(4, 1), Vector2(4, 12)], color)
		draw_circle(Vector2(7, -5), 1.5, INK)
		draw_line(Vector2(-13, 14), Vector2(9, 14), GOLD, 2, true)
	else:
		# A heraldic whole-machine symbol; no unapproved source-model rendering.
		Figures.polygon(self, [Vector2(-12, -5), Vector2(-5, -9), Vector2(5, -9), Vector2(12, -5), Vector2(9, 7), Vector2(3, 10), Vector2(-3, 10), Vector2(-9, 7)], color)
		draw_rect(Rect2(-4, -15, 8, 8), PAPER)
		draw_line(Vector2(-2, -12), Vector2(3, -12), INK, 2, true)
		draw_line(Vector2(-6, 8), Vector2(-8, 16), color, 4, true)
		draw_line(Vector2(6, 8), Vector2(8, 16), color, 4, true)
		draw_line(Vector2(15, -8), Vector2(15, 12), GOLD, 2, true)
	draw_set_transform(Vector2.ZERO)

func _draw_combined_hud():
	_text("THE CROSSING", Vector2(273, 35), 22, PAPER, true)
	_text("ROUND %d · %s · HOLD %d/3" % [battle.round_number, "YOUR TURN" if battle.side == 0 else "ENEMY TURN", battle.objective_progress], Vector2(680, 36), 20, TEAL)
	_text("%d vs %d · %d × %d field" % [battle.deployment.friendly.size(), battle.deployment.enemy.size(), battle.width, battle.height], Vector2(18, 38), 18, GOLD)
	var u = battle.occupant(hovered)
	if u.is_empty() or not battle.alive(u): u = battle.unit(selected)
	if not u.is_empty():
		_wrap(u.name, Rect2(18, 72, 220, 70), 24, PAPER, 29, true)
		_text(u.role, Vector2(18, 169), 15, MUTED)
		_text("Strength %d / %d" % [u.hp, u.max_hp], Vector2(18, 208), 20, TEAL if u.side == 0 else RED)
		_text("ATK %d   ARM %d" % [u.attack, u.armor], Vector2(18, 245), 18, GOLD)
		_text("MOVE %d   RANGE %d" % [u.move, u.range], Vector2(18, 274), 18, GOLD)
		_wrap("Ability: " + Battle.ability_name(u) + "\n" + ("Ready" if u.cooldown == 0 else "Cooldown: %d own turns" % u.cooldown), Rect2(18, 302, 220, 80), 18, PAPER, 26)
		_wrap("Guard " + str(battle.guard_reduction({"kind": u.kind, "guard": true}, {"kind": "sword"})) + " reduction.\n" + ("Shaken: one more cohesion loss routes." if u.cohesion == 1 else "Facing sets flank / rear exposure."), Rect2(18, 385, 220, 78), 16, MUTED, 23)
	_wrap("Hold the gold crossing for 3 consecutive player turns or route all enemies. Hero must survive. Round limit: 16.", Rect2(18, 582, 220, 145), 17, PAPER, 25)
	_wrap("Tab: next · Q: ability\nE: mage mend · B: guard\nWheel: zoom · Arrows: pan\nHome: fit · G: grid", Rect2(18, 756, 220, 132), 15, MUTED, 24)
	_panel(Rect2(263, 61, 1322, 56), Color(0.06, 0.14, 0.18, 0.94), Color("40574f"))
	_wrap(message, Rect2(277, 72, 1290, 42), 17, PAPER, 24)
	if not combat_log.is_empty():
		_panel(Rect2(263, 736, 1322, 34), Color(0.06, 0.14, 0.18, 0.94), Color("40574f"))
		_wrap(combat_log[-1], Rect2(277, 741, 1288, 28), 15, GOLD, 20)
	_text("TEMPORARY 2D TACTICAL MARKERS · ART REVIEW GATE RETAINED", Vector2(465, 889), 12, MUTED)
