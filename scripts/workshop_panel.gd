extends Control
const Shop = preload("res://scripts/workshop_model.gd")
const Crest = preload("res://scripts/crest_view.gd")
const REFERENCE = preload("res://assets/art/review/oathkeeper_reference.png")
const STUDY = preload("res://assets/art/review/oathkeeper_study.png")
signal requested(action: String, args: Dictionary)
signal closed
var owner_campaign
var review_mode = false
var tab = "Garage"
var selected_frame = ""
var status_text = "Choose a machine or explore the workshop."
var banner_draft = {}
var container: MarginContainer

func _ready():
	# Parent is Node2D, not a layout Control. Match the game's logical canvas;
	# project canvas_items stretching handles native window sizes.
	size = Vector2(1600, 900)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var skin = Theme.new()
	skin.default_font_size = 20
	skin.set_color("font_color", "Label", Color("eee5d1"))
	skin.set_color("font_color", "Button", Color("eee5d1"))
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		var style = StyleBoxFlat.new()
		style.bg_color = Color("29414a") if state != "hover" else Color("3d5860")
		style.border_color = Color("7c8a7f") if state != "focus" else Color("c5a46b")
		style.set_border_width_all(1)
		style.set_corner_radius_all(6)
		style.content_margin_left = 14
		style.content_margin_right = 14
		skin.set_stylebox(state, "Button", style)
	theme = skin
	banner_draft = owner_campaign.workshop.banner.duplicate(true)
	refresh()

func _draw():
	draw_rect(Rect2(Vector2.ZERO, size), Color("11232b"))
	for x in range(0, int(size.x), 48):
		draw_line(Vector2(x, 0), Vector2(x, size.y), Color(0.5,0.6,0.55,0.035))

func _label(parent: Node, text: String, font_size: int = 20, color: Color = Color("eee5d1")) -> Label:
	var label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(label)
	return label

func _button(parent: Node, text: String, action: Callable, disabled: bool = false) -> Button:
	var button = Button.new()
	button.text = text
	button.custom_minimum_size.y = 44
	button.disabled = disabled
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.pressed.connect(action)
	parent.add_child(button)
	return button

func _request(action: String, args: Dictionary = {}):
	requested.emit(action, args)

func _column(parent: Node, title: String, min_width: float = 260) -> VBoxContainer:
	var panel = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.custom_minimum_size.x = min_width
	var box = StyleBoxFlat.new()
	box.bg_color = Color("1c323b")
	box.border_color = Color("405b60")
	box.set_border_width_all(1)
	box.set_corner_radius_all(10)
	box.content_margin_left = 22
	box.content_margin_right = 22
	box.content_margin_top = 20
	box.content_margin_bottom = 20
	panel.add_theme_stylebox_override("panel", box)
	parent.add_child(panel)
	var contents = VBoxContainer.new()
	contents.add_theme_constant_override("separation", 12)
	panel.add_child(contents)
	_label(contents, title, 23, Color("c5a46b"))
	return contents

func _picture(parent: Node, texture: Texture2D, height: float = 350):
	var image = TextureRect.new()
	image.texture = texture
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.custom_minimum_size.y = height
	image.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(image)

func _choose_tab(value: String):
	tab = value
	refresh()

func refresh():
	if not is_inside_tree():
		return
	if container != null:
		remove_child(container)
		container.queue_free()
	if Shop.frame(owner_campaign.workshop, selected_frame).is_empty():
		selected_frame = owner_campaign.workshop.pilot_frame
	container = MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		container.add_theme_constant_override("margin_" + side, 32)
	add_child(container)
	container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var vertical = VBoxContainer.new()
	vertical.add_theme_constant_override("separation", 14)
	container.add_child(vertical)
	var header = HBoxContainer.new()
	vertical.add_child(header)
	var titles = VBoxContainer.new()
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(titles)
	_label(titles, "GREYFORD  /  THE WORKSHOP", 32)
	_label(titles, "REVIEW SANDBOX · separate save · 180 starting gold" if review_mode else "Shared garage · real campaign · purchases save immediately", 17, Color("8fb9af"))
	var balance = VBoxContainer.new()
	balance.custom_minimum_size.x = 250
	header.add_child(balance)
	_label(balance, "%d GOLD" % owner_campaign.gold, 27, Color("c5a46b"))
	_label(balance, "Cargo %d / %d · %d %s" % [Shop.cargo_used(owner_campaign.workshop), Shop.CARGO_CAPACITY, owner_campaign.workshop.frames.size(), "frame" if owner_campaign.workshop.frames.size() == 1 else "frames"], 17)
	var tabs = HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 12)
	vertical.add_child(tabs)
	for name in ["Garage", "Equipment", "Market", "Banner", "Art review"]:
		var button = _button(tabs, name, _choose_tab.bind(name))
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if name == tab:
			button.add_theme_color_override("font_color", Color("e6bd73"))
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size.y = 420
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vertical.add_child(scroll)
	var body = HBoxContainer.new()
	body.name = "WorkshopBody"
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 18)
	scroll.add_child(body)
	match tab:
		"Garage": _garage(body)
		"Equipment": _equipment(body)
		"Market": _market(body)
		"Banner": _banner(body)
		"Art review": _art_review(body)
	_label(vertical, status_text, 18, Color("8fb9af"))
	var footer = HBoxContainer.new()
	footer.add_theme_constant_override("separation", 20)
	vertical.add_child(footer)
	var note = _label(footer, "Prototype 0.2 · Complete 3D models → rendered 2D sprites. Animation replacement awaits visual review.", 16, Color("aeb8ae"))
	note.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if review_mode:
		_button(footer, "Reset review", _confirm_reset)
	_button(footer, "Return to title" if review_mode else "Return to campaign", func(): closed.emit())

func _confirm_reset():
	var confirmation = ConfirmationDialog.new()
	confirmation.title = "Reset workshop review?"
	confirmation.dialog_text = "Start this separate review again with Oathkeeper and 180 gold. Your campaign save is unaffected."
	confirmation.confirmed.connect(func(): _request("reset_review", {}); confirmation.queue_free())
	confirmation.canceled.connect(confirmation.queue_free)
	add_child(confirmation)
	confirmation.popup_centered(Vector2i(550, 200))

func _frame_list(parent: Node) -> VBoxContainer:
	var left = _column(parent, "YOUR MACHINES", 255)
	for f in owner_campaign.workshop.frames:
		_button(left, f.name + ("  ·  YOUR PILOT" if f.id == owner_campaign.workshop.pilot_frame else "  ·  RESERVE"), func(): selected_frame = f.id; refresh())
	_label(left, "Reserve machines remain yours. They take no cargo or battle slots until deployed.", 17, Color("aeb8ae"))
	return left

func _garage(body: Node):
	_frame_list(body)
	var f = Shop.frame(owner_campaign.workshop, selected_frame)
	var values = Shop.stats(owner_campaign.workshop, f)
	var art = _column(body, "KNIGHT-PATTERN CHASSIS", 330)
	_picture(art, REFERENCE)
	_label(art, "Approved concept reference · final animation pending", 15, Color("aeb8ae"))
	var detail = _column(body, f.name, 310)
	_label(detail, "HULL %d / %d\nATTACK %d  ·  ARMOR %d\nMOVE %d  ·  RANGE %d\nHULL REFIT %d / 2" % [f.hp, values.hp, values.attack, values.armor, values.move, values.range, f.refit], 23)
	_button(detail, "Pilot this frame", _request.bind("assign", {"frame": f.id}), f.id == owner_campaign.workshop.pilot_frame or f.hp <= 0)
	_button(detail, "Try this loadout  ·  practice battle", _request.bind("trial", {}), f.id != owner_campaign.workshop.pilot_frame)
	_button(detail, "Hull refit  ·  18 gold  ·  +4 max hull", _request.bind("refit", {"frame": f.id}), f.refit >= 2)
	var repair_cost = maxi(1, ceili((values.hp - f.hp) / 5.0))
	_button(detail, "Hull fully repaired" if f.hp == values.hp else "Repair  ·  %d gold" % repair_cost, _request.bind("repair", {"frame": f.id}), f.hp == values.hp)
	var name_input = LineEdit.new()
	name_input.text = f.name
	name_input.max_length = 40
	detail.add_child(name_input)
	_button(detail, "Rename machine", func(): _request("rename", {"frame": f.id, "name": name_input.text}))
	_button(detail, "Sell frame  ·  +45 gold", _request.bind("sell_frame", {"frame": f.id}), f.id == owner_campaign.workshop.pilot_frame)
	_label(detail, "Refits preserve current damage. Modules and equipment stay with the machine when you change pilots.", 16, Color("aeb8ae"))

func _equipment(body: Node):
	_frame_list(body)
	var f = Shop.frame(owner_campaign.workshop, selected_frame)
	var slots = _column(body, "FITTINGS  /  " + f.name, 330)
	_label(slots, "Right mount: Knight's sword\nLeft mount: Kite shield", 22)
	_label(slots, "This prototype supports the starting sword/shield set. New weapon classes need reviewed animations.", 17, Color("aeb8ae"))
	for slot in ["module_a", "module_b"]:
		var owned = Shop.item(owner_campaign.workshop, f[slot])
		_label(slots, slot.replace("_", " ").to_upper() + "\n" + ("Empty" if owned.is_empty() else Shop.ITEMS[owned.definition].name), 21, Color("c5a46b"))
		_button(slots, "Remove " + slot.replace("_", " "), _request.bind("equip", {"frame": f.id, "slot": slot, "item": ""}), owned.is_empty())
	var stats = Shop.stats(owner_campaign.workshop, f)
	_label(slots, "Result: %d max hull · %d armor · %d move" % [stats.hp, stats.armor, stats.move], 21)
	var armory = _column(body, "SHARED ARMORY", 310)
	var available = 0
	for owned in owner_campaign.workshop.items:
		if Shop.ITEMS[owned.definition].kind != "module":
			continue
		var fitted = Shop.fitted_to(owner_campaign.workshop, owned.id)
		_label(armory, Shop.ITEMS[owned.definition].name + (" · stored" if fitted.is_empty() else " · " + fitted), 20)
		if fitted.is_empty():
			available += 1
			for slot in ["module_a", "module_b"]:
				_button(armory, "Fit to " + slot.replace("_", " "), _request.bind("equip", {"frame": f.id, "slot": slot, "item": owned.id}))
	if available == 0:
		_label(armory, "Buy a module in Market to try a build. A physical item can only be fitted once.", 18, Color("aeb8ae"))

func _market(body: Node):
	var machines = _column(body, "MACHINES & MODULES", 365)
	_label(machines, "Refurbished Knight\n90 gold · 30 hull · sword & shield", 23)
	_button(machines, "Buy reserve frame  ·  90 gold", _request.bind("buy_frame", {}))
	for definition in ["armor", "actuator"]:
		var data = Shop.ITEMS[definition]
		_label(machines, data.name + ("\n+1 armor · −1 move" if definition == "armor" else "\n+1 move · −1 armor"), 20)
		_button(machines, "Buy  ·  %d gold" % data.price, _request.bind("buy_item", {"definition": definition}))
	var trade = _column(body, "TRADE GOODS", 330)
	for good in ["grain", "ore"]:
		var data = Shop.GOODS[good]
		_label(trade, "%s  ·  carrying %d\nBuy %d / sell %d gold each" % [data.name, owner_campaign.workshop.cargo.get(good, 0), data.buy, data.sell], 22)
		_button(trade, "Buy 5 " + data.name.to_lower(), _request.bind("buy_good", {"good": good, "quantity": 5}))
		_button(trade, "Sell 5 " + data.name.to_lower(), _request.bind("sell_good", {"good": good, "quantity": 5}))
	var ledger = _column(body, "THE QUARTERMASTER", 290)
	_label(ledger, "Cargo %d / 20\nWorkshop reserves use no cargo capacity." % Shop.cargo_used(owner_campaign.workshop), 23)
	_label(ledger, "Gold changes only after a validated order. Full holds, unavailable goods, and unaffordable purchases leave everything unchanged.", 19, Color("aeb8ae"))
	_label(ledger, "One chassis is available for this prototype. Cinderjack, Kestrel, and Bastion remain future production designs.", 18, Color("aeb8ae"))

func _banner(body: Node):
	var options = _column(body, "YOUR WARBAND", 360)
	var unlocked = owner_campaign.workshop.headquarters
	_label(options, "Found your cause. Choose two colors and one emblem.", 23)
	if not unlocked:
		_label(options, "Headquarters is not yet established in the prologue. Workshop review lets you try this later milestone.", 19, Color("8fb9af"))
	var name_input = LineEdit.new()
	name_input.text = banner_draft.name
	name_input.max_length = 28
	name_input.editable = unlocked
	name_input.text_changed.connect(func(value): banner_draft.name = value)
	options.add_child(name_input)
	var preview = Crest.new()
	preview.banner = banner_draft
	for key in ["primary", "secondary"]:
		_label(options, key.capitalize() + " color", 19, Color("c5a46b"))
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		options.add_child(row)
		for hex in Shop.COLORS:
			var swatch = _button(row, "●", func(): banner_draft[key] = hex; preview.queue_redraw(), not unlocked)
			swatch.custom_minimum_size.x = 42
			swatch.add_theme_color_override("font_color", Color(hex))
	_label(options, "Centered emblem", 19, Color("c5a46b"))
	var emblems = HBoxContainer.new()
	emblems.add_theme_constant_override("separation", 10)
	options.add_child(emblems)
	for emblem in Shop.EMBLEMS:
		var button = _button(emblems, emblem.capitalize(), func(): banner_draft.emblem = emblem; preview.queue_redraw(), not unlocked)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_button(options, "Save banner", func(): _request("banner", {"banner": banner_draft.duplicate(true)}), not unlocked)
	var display = _column(body, "BANNER PREVIEW", 400)
	preview.custom_minimum_size = Vector2(260, 380)
	preview.size_flags_vertical = Control.SIZE_EXPAND_FILL
	display.add_child(preview)
	_label(display, "Cosmetic identity · no combat bonus", 19, Color("c5a46b"))
	_label(display, "The same saved crest can appear on standards and campaign markers. Animated mech-panel compositing remains an art-pipeline milestone.", 18, Color("aeb8ae"))

func _art_review(body: Node):
	var original = _column(body, "APPROVED ORIGINAL", 450)
	_picture(original, REFERENCE, 445)
	_label(original, "Oathkeeper's visual authority: complete ivory/navy knight, sword, and shield.", 18, Color("aeb8ae"))
	var source = _column(body, "3D SOURCE STUDY  /  AWAITING REVIEW", 450)
	_picture(source, STUDY, 445)
	_label(source, "Unapproved blockout · not rigged · not animated · not used as battle art", 18, Color("8fb9af"))
	_label(source, "Next: refine the model to the original, then review smooth motion at game size. The game stays 2D; complete 3D animations will be rendered into sprites.", 18)
