extends Node2D
## Isolated, deterministic art gallery. Does not instantiate campaign state or saves.
const Figures = preload("res://scripts/unit_art.gd")
const Mechs = preload("res://scripts/mech_art.gd")
const Battle = preload("res://scripts/battle_model.gd")
const TITLES = ["01   IDLE", "02   WALKING", "03   ATTACK", "04   NORMAL HIT", "05   GUARDING", "06   GUARDED HIT"]
const NOTES = ["Quiet piston motion and weight shift", "Planted steps and articulated knees", "Anticipation / impact / recovery", "Body recoil, then ready stance", "Shield raised; defensive stance held", "Shield absorbs impact; guard resumes"]
var time = 0.0
var facing = 1
var speed = 0
var reduced = false
var paused = false
var ui: Control
var actors: Array = []
var direction_button: Button
var speed_button: Button
var motion_button: Button
var pause_button: Button
var capture_path = ""
var capture_time = 0.55
var capture_frame = 0
var rotation_gallery = false
var gallery_button: Button

class Actor extends Node2D:
	var unit: Dictionary
	var clip: Dictionary = {}
	var clock = 0.0
	var reduced = false
	func _draw():
		Figures.draw_unit(self, unit, Vector2.ZERO, clock, false, 0, 0, reduced, clip)

func _ready():
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--capture="):
			capture_path = argument.trim_prefix("--capture=")
		elif argument.begins_with("--preview-time="):
			capture_time = float(argument.trim_prefix("--preview-time="))
		elif argument.begins_with("--facing="):
			facing = posmod(int(argument.trim_prefix("--facing=")), 6)
		elif argument == "--rotation-gallery":
			rotation_gallery = true
	ui = Control.new()
	add_child(ui)
	for index in 6:
		var origin = Vector2(32 + (index % 3) * 522, 145 + floori(index / 3.0) * 360)
		for size_index in 2:
			var actor = Actor.new()
			actor.unit = Battle.DEFINITIONS.militia_mech.duplicate(true)
			actor.unit.merge({"id": "preview", "definition": "militia_mech", "side": 0, "facing": facing, "max_hp": 30, "guard": false})
			actor.position = origin + Vector2(157 if size_index == 0 else 372, 286)
			actor.scale = Vector2.ONE * (1.5 if size_index == 0 else 1.0)
			add_child(actor)
			actors.append(actor)
	var infantry = Actor.new()
	infantry.unit = Battle.DEFINITIONS.greyford_blades.duplicate(true)
	infantry.unit.merge({"side": 0, "facing": 0, "max_hp": 12, "guard": false})
	infantry.position = Vector2(1515, 855)
	add_child(infantry)
	direction_button = _button(Vector2(32, 81), 210, func(): facing = (facing + 1) % 6; _labels())
	speed_button = _button(Vector2(254, 81), 195, func(): speed = (speed + 1) % 3; _labels())
	motion_button = _button(Vector2(461, 81), 235, func(): reduced = not reduced; _labels())
	pause_button = _button(Vector2(708, 81), 155, func(): paused = not paused; _labels())
	_button(Vector2(875, 81), 185, func(): time = 0.0).text = "Restart loops  [R]"
	_button(Vector2(1072, 81), 210, func(): get_tree().change_scene_to_file("res://scenes/main.tscn")).text = "Return to game"
	gallery_button = _button(Vector2(1294, 81), 270, func(): rotation_gallery = not rotation_gallery; _labels())
	_labels()

func _button(pos: Vector2, width: float, action: Callable) -> Button:
	var button = Button.new()
	button.position = pos
	button.size = Vector2(width, 44)
	button.add_theme_font_size_override("font_size", 18)
	button.pressed.connect(action)
	ui.add_child(button)
	return button

func _labels():
	direction_button.text = "Facing: %s   [F]" % Mechs.DIRECTIONS[facing]
	speed_button.text = "Speed: %s   [N]" % ["Normal", "Fast", "Quick"][speed]
	motion_button.text = "Reduced motion: %s   [M]" % ("on" if reduced else "off")
	pause_button.text = "Resume  [Space]" if paused else "Pause  [Space]"
	gallery_button.text = "Show animations" if rotation_gallery else "Compare all six facings"

func _input(event):
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_F: facing = (facing + 1) % 6
			KEY_N: speed = (speed + 1) % 3
			KEY_M: reduced = not reduced
			KEY_SPACE: paused = not paused
			KEY_R: time = 0.0
		_labels()

func _process(delta):
	if not paused:
		time += delta * [1.0, 2.0, 35.0][speed]
	if not capture_path.is_empty():
		time = capture_time
	for index in 6:
		var clip = {"state": Mechs.STATES[index], "progress": 1.0}
		if rotation_gallery:
			clip.state = "idle"
		match clip.state:
			"walk": clip.travel_px = time * 96.0
			"attack": clip.progress = minf(fmod(time, 1.45) / 0.75, 1.0)
			"hit", "guard_hit": clip.progress = clampf((fmod(time, 1.45) - 0.35) / 0.39, 0, 1)
			"guard": clip.progress = minf(fmod(time, 2.2) / 0.28, 1.0)
		if speed == 2:
			clip.progress = 1.0
			clip.travel_px = 0.0
		for size_index in 2:
			var actor = actors[index * 2 + size_index]
			actor.unit.facing = (index + facing) % 6 if rotation_gallery else facing
			actor.clip = clip
			actor.clock = time
			actor.reduced = reduced
			actor.queue_redraw()
	queue_redraw()
	if not capture_path.is_empty():
		capture_frame += 1
		if capture_frame == 5:
			_capture.call_deferred()

func _capture():
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(capture_path)
	get_tree().quit()

func _draw():
	draw_rect(Rect2(0, 0, 1600, 900), Color("14252e"))
	_label("OATHKEEPER  /  IVORY KNIGHT", Vector2(32, 42), 28, Color("eee5d1"))
	_label("Six articulated animations · one master atlas · six facings", Vector2(32, 66), 16, Color("a4b4b6"))
	for index in 6:
		var rect = Rect2(32 + (index % 3) * 522, 145 + floori(index / 3.0) * 360, 504, 340)
		# Neutral review surface exposes proportions and joint gaps instead of hiding
		# the armor silhouette against a detailed battlefield at thumbnail scale.
		draw_rect(rect, Color("d8d4c9"))
		draw_rect(rect, Color("68746b"), false, 1.0)
		_label("FACING  " + Mechs.DIRECTIONS[(index + facing) % 6] if rotation_gallery else TITLES[index], rect.position + Vector2(17, 29), 20, Color("243448"))
		_label("Same armor, same shared limbs, one texture" if rotation_gallery else NOTES[index], rect.position + Vector2(17, 54), 15, Color("4f5b5c"))
		_label("DETAIL  150%", rect.position + Vector2(95, 328), 13, Color("4f5b5c"))
		_label("BATTLE  100%", rect.position + Vector2(319, 328), 13, Color("4f5b5c"))
	_label("Guard reduces damage by 2. Both hit reactions still take damage.   |   Infantry scale →", Vector2(32, 877), 17, Color("d9ddd0"))

func _label(value: String, pos: Vector2, size: int, color: Color):
	draw_string(ThemeDB.fallback_font, pos, value, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)
