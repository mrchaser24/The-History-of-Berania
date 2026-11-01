extends Node2D
const Hex = preload("res://scripts/hex_grid.gd")
const Battle = preload("res://scripts/battle_model.gd")
const Campaign = preload("res://scripts/campaign_model.gd")
const Saves = preload("res://scripts/save_store.gd")
const Figures = preload("res://scripts/unit_art.gd")
const Story = preload("res://scripts/story.gd")
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
						_select(["hero", "blades", "gunners"][event.keycode - KEY_1])
				KEY_TAB:
					pass
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
	elif phase == "intro":
		if intro_page < Story.MEMORIES.size():
			_button("Continue the story   →", Rect2(1170, 792, 300, 52), _advance_intro, true)
		else:
			_button("I will help defend Greyford.   →", Rect2(1000, 735, 460, 48), _enter_world, true)
			_button("And the imperial patrols?" if intro_page == Story.MEMORIES.size() else "I understand. Let us go.", Rect2(1000, 796, 460, 48), _intro_question)
	elif phase == "world":
		var at_village = campaign.player == campaign.village
		_button("Enter Greyford" if not campaign.rewarded else "Visit Greyford", Rect2(1220, 594, 316, 52), _village, true, not at_village or not animation.is_empty())
		_button("End travel turn   [Space]", Rect2(1220, 663, 316, 52), _end_turn, false, not animation.is_empty())
		_button("Save checkpoint", Rect2(1220, 730, 316, 44), func(): _checkpoint(); _refresh_ui(), false, not animation.is_empty())
		_button("Return to title", Rect2(1220, 790, 316, 44), func(): modal = "home"; _refresh_ui())
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
	elif phase == "results":
		_button("Return to Greyford   →" if not practice else "Return to title   →", Rect2(600, 690, 400, 56), _leave_results, true)
	if phase != "title":
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
		_start_battle()
	elif previous == "home":
		phase = "title"
		continue_data = saves.load_data()
		message = saves.last_error
		_refresh_ui()

func _enter_world():
	phase = "world"
	message = "Follow the road to Greyford. Click a lit destination; each step costs one travel point."
	if campaign.rewarded:
		message = "Greyford is safe. Visit the village for free repairs, or begin a new prologue from the title."
	elif campaign.quest == "retry":
		message = "Your company has recovered. Enter Greyford when you are ready to retry the defense."
	_refresh_ui()

func _world_click(pos: Vector2i):
	if not animation.is_empty() or pos not in campaign.board:
		return
	if pos == campaign.player:
		if pos == campaign.village:
			_village()
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
		campaign.mech_hp = 30
		_checkpoint()
		message = "Greyford welcomes you. Your walker is fully repaired, free of charge. This prologue is complete."
	else:
		campaign.mech_hp = 30
		campaign.pending_battle = true
		if _checkpoint():
			_start_battle()
	_refresh_ui()

func _start_practice():
	practice = true
	_start_battle()

func _start_battle():
	phase = "battle"
	battle = Battle.new()
	selected = "hero"
	animation.clear()
	animation_time = 0.0
	combat_log = ["Greyford's smith repairs your walker without charge.", "The villagers form up beside your walker.", "Route the raiders. Oathkeeper must survive."]
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
	_reachable()
	_refresh_ui()

func _reachable():
	cached_reachable.clear()
	if phase == "battle" and not selected.is_empty():
		for p in battle.board:
			if not battle.movement_path(selected, p).is_empty():
				cached_reachable.append(p)

func _battle_click(pos: Vector2i):
	if battle.side != 0 or pos not in battle.board or not animation.is_empty():
		return
	var clicked = battle.occupant(pos)
	if not clicked.is_empty() and clicked.side == 0:
		_select(clicked.id)
		return
	if not _player_ready():
		message = "Choose an available friendly unit first, or End Turn."
		return
	var action = {}
	if not clicked.is_empty():
		action = battle.attack(selected, clicked.id)
		if action.is_empty():
			message = "Target unavailable: check weapon range and the rocks blocking line of sight."
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
	else:
		animation.duration = 0.28
		combat_log.append(battle.unit(action.id).name + " guards: incoming damage −2.")
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
		campaign.finish_battle(battle.outcome, int(battle.unit("hero").hp))
		_checkpoint()
	result_text = "The road remembers your banner." if battle.outcome == "victory" else "A lost battle is not the end of your cause."
	if battle.outcome == "victory":
		_sound("victory")
	_refresh_ui()

func _leave_results():
	if not modal.is_empty():
		return
	if practice:
		phase = "title"
		continue_data = saves.load_data()
		message = saves.last_error
	else:
		phase = "world"
		message = campaign.news
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
	if world:
		return Vector2(176, 243) + Vector2((p.x + p.y * 0.5) * 156.0, p.y * 88.0)
	var origin = Vector2(260, 170)
	var step_x = 148.0
	var step_y = 82.0
	return origin + Vector2((p.x + p.y * 0.5) * step_x, p.y * step_y)

func _cell_at(point: Vector2, world: bool) -> Vector2i:
	var bounds = FIELD if world else BATTLE_FIELD
	if not bounds.has_point(point):
		return Vector2i(-999, -999)
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
	var front_to_back = battle.units.duplicate()
	front_to_back.sort_custom(func(a, b): return _pos(a.pos).y > _pos(b.pos).y)
	for u in front_to_back:
		if not battle.alive(u):
			continue
		var height = 98 if u.kind == "mech" else 72
		var body = Rect2(_pos(u.pos) + Vector2(-42, -height), Vector2(84, height + 49))
		if body.has_point(point):
			return u.pos
	return _cell_at(point, false)

func _hex(p: Vector2i, world: bool = false, factor: float = 0.96) -> PackedVector2Array:
	var center = _pos(p, world)
	var points = PackedVector2Array()
	var rx = (90.0 if world else 85.0) * factor
	var ry = (58.7 if world else 54.5) * factor
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
	_wrap("An archduke's son. A stolen walker.\nA promise to save the princess and the empire.", Rect2(90, 792, 700, 70), 19, PAPER, 27)
	_text("PLAYABLE PROLOGUE  /  0.1", Vector2(1200, 857), 16, PAPER)
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
		var u = Battle.DEFINITIONS.militia_mech.duplicate(true)
		u.merge({"side": 0, "facing": 0, "max_hp": 30, "guard": false})
		Figures.draw_unit(self, u, Vector2(1370, 545), clock)
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
	_text("FIELD NOTES", Vector2(1220, 549), 15, GOLD)
	var objective = "Reach the village and answer Captain Mira's call."
	if campaign.rewarded:
		objective = "Greyford is safe.\nThe prologue is complete."
	elif campaign.quest == "retry":
		objective = "Your company is recovered. Enter Greyford to retry the defense."
	_wrap(objective, Rect2(1220, 249, 306, 100), 22, PAPER, 33)
	_text("YOUR COMPANY", Vector2(1220, 380), 16, GOLD)
	_text("You + Oathkeeper", Vector2(1220, 421), 20)
	_text("Gold    %d" % campaign.gold, Vector2(1220, 459), 20, PAPER)
	_text("Local trust    %d" % campaign.trust, Vector2(1400, 459), 18, TEAL)
	_text("Walker hull    %d / 30" % campaign.mech_hp, Vector2(1220, 496), 18, MUTED)
	_wrap("Hover to preview a path.", Rect2(1220, 558, 306, 30), 16, MUTED, 23)
	_panel(Rect2(42, 776, 1134, 92), Color("1d3038"))
	_wrap(message, Rect2(66, 794, 1070, 66), 20, PAPER, 29)
	_text("CLICK: SELECT / MOVE / ATTACK     B: GUARD     F: FACE     SPACE: END TURN     G: GRID", Vector2(45, 891), 13, MUTED)

func _draw_battle_shell():
	draw_rect(Rect2(0, 0, 1600, 900), Color("15272e"))

func _draw_battle_hud():
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
	_text(str(path.size() - 1) + (" MP" if world else ""), end + Vector2(-19, 35), 15, PAPER)

func _progress() -> float:
	return clampf(animation_time / maxf(float(animation.get("duration", 0.6)), 0.001), 0, 1)

func _path_position(path: Array, world: bool) -> Vector2:
	var sample = _progress() * (path.size() - 1)
	var index = mini(floori(sample), path.size() - 2)
	return _pos(path[index], world).lerp(_pos(path[index + 1], world), sample - index)

func _draw_battle():
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
		if u.id == selected:
			Figures.ellipse(self, center + Vector2(0, 6), Vector2(47, 19), Color(0.93, 0.83, 0.5, 0.3))
		if showing_hit and progress >= 0.48 and not battle.alive(u):
			if animation.routed:
				Figures.draw_unit(self, display_unit, center + Vector2((1 if u.side == 1 else -1) * 26 * progress, 0), clock, true, 0, 0, reduced_motion)
			else:
				draw_line(center + Vector2(-22, -10), center + Vector2(21, 2), Color("59665c"), 13, true)
		else:
			Figures.draw_unit(self, display_unit, center, clock, moving, progress if attacking else 0.0, hit, reduced_motion)
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

func _draw_impact():
	var progress = _progress()
	var source = _pos(animation.from) + Vector2(0, -36)
	var target = _pos(animation.to) + Vector2(0, -28)
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
		if animation.routed:
			_text("ROUTED", target + Vector2(-34, 6), 16, RED)

func _draw_results():
	_background()
	draw_rect(Rect2(0, 0, 1600, 900), Color(0.04, 0.1, 0.12, 0.77))
	_panel(Rect2(330, 195, 940, 590), Color(0.1, 0.18, 0.2, 0.97), GOLD)
	_crest(Vector2(800, 265), 1.5)
	var won = battle.outcome == "victory"
	_text("GREYFORD HOLDS" if won else "A BANNER BENT, NOT BROKEN", Vector2(467 if won else 425, 361), 42 if won else 34, PAPER, true)
	_wrap(result_text, Rect2(440, 398, 720, 70), 29, GOLD, 40, true)
	var detail = "Your first pay is forty gold. Mira's soldiers remain in Greyford. You have earned local trust, but your own army is still ahead of you."
	if not won:
		detail = "The villagers recover Oathkeeper and repair it without charge. You survive, and the defense remains available to retry."
	_wrap(detail, Rect2(440, 477, 720, 110), 23, PAPER, 34)
	var reward = "+40 GOLD    ·    +1 LOCAL TRUST    ·    VILLAGE DEFENDED" if won else "FREE RECOVERY    ·    NO PERMANENT LOSSES"
	if practice:
		reward = "PRACTICE ENCOUNTER    ·    CAMPAIGN UNCHANGED"
	_text(reward, Vector2(440, 623), 17, TEAL)
	_text("END OF THE PLAYABLE PROLOGUE" if won else "YOUR CAUSE CONTINUES", Vector2(570, 661), 15, MUTED)

func _draw_modal():
	draw_rect(Rect2(0, 0, 1600, 900), Color(0.02, 0.05, 0.07, 0.83))
	_panel(Rect2(365, 205, 870, 550), Color("20343c"), GOLD)
	if modal in ["help", "pause"]:
		_text("A moment by the road" if modal == "pause" else "Command your company", Vector2(416, 278), 40, PAPER, true)
		_wrap("Select a friendly unit, then a shaded hex to move. Click an enemy to attack; hover to inspect or preview damage.\nMove once, then attack or Guard. Rocks block travel and sight. Finish a moved unit before choosing another.\n1–3: select. B: guard. F: face. Space: end turn. G: grid. N: speed. Esc: pause.\nOn the map, travel to Greyford and enter the village. NPCs move only on End Turn.", Rect2(416, 310, 765, 235), 20, PAPER, 29)
		_text("All art and gameplay are 2D. Prototype names and narrative details are provisional.", Vector2(414, 645), 15, MUTED)
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
