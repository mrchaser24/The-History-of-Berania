extends Control
## Ordinary campaign menus. Models own every payment, prerequisite and reward.
const Shop = preload("res://scripts/workshop_model.gd")
const Quest = preload("res://scripts/quest_model.gd")
const Economy = preload("res://scripts/economy_model.gd")
const Pilots = preload("res://scripts/pilot_model.gd")
const Politics = preload("res://scripts/politics_model.gd")
const Chronicle = preload("res://scripts/chronicle_model.gd")
const Battle = preload("res://scripts/battle_model.gd")
const Crest = preload("res://scripts/crest_view.gd")
signal requested(action: String, args: Dictionary)
signal closed
var campaign
var tab = "Location"
var status_text = "Menus do not advance strategic time."
var house_id = "asterfell"
var topic = "audience"
var pending_order = {}
var pending_terms = ""
var banner_draft = {}
var identity_name = ""
var appearance = 0
var assignments = {}
var root: MarginContainer

func _ready():
	size = Vector2(1600, 900)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var skin = Theme.new(); skin.default_font_size = 20
	skin.set_color("font_color", "Label", Color("eee5d1"))
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		var style = StyleBoxFlat.new()
		style.bg_color = Color("37535b") if state == "hover" else Color("243c45")
		style.border_color = Color("c5a46b") if state == "focus" else Color("5d726d")
		style.set_border_width_all(1); style.set_corner_radius_all(5)
		style.content_margin_left = 14; style.content_margin_right = 14
		skin.set_stylebox(state, "Button", style)
	theme = skin
	banner_draft = campaign.workshop.banner.duplicate(true)
	identity_name = campaign.journal.identity.name; appearance = campaign.journal.identity.appearance
	refresh()

func _draw():
	draw_rect(Rect2(Vector2.ZERO, size), Color("12262e"))

func label(parent: Node, text: String, heading: bool = false) -> Label:
	var node = Label.new(); node.text = text
	node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	node.add_theme_font_size_override("font_size", 25 if heading else 20)
	node.add_theme_color_override("font_color", Color("c5a46b") if heading else Color("eee5d1"))
	parent.add_child(node)
	return node

func button(parent: Node, text: String, action: Callable, disabled: bool = false) -> Button:
	var node = Button.new(); node.text = text; node.disabled = disabled
	node.custom_minimum_size = Vector2(140, 48)
	node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	node.pressed.connect(action); parent.add_child(node)
	return node

func row(parent: Node) -> HBoxContainer:
	var node = HBoxContainer.new(); node.add_theme_constant_override("separation", 12)
	parent.add_child(node); return node

func section(parent: Node, title: String) -> VBoxContainer:
	var panel = PanelContainer.new()
	var style = StyleBoxFlat.new(); style.bg_color = Color("1b333c")
	style.content_margin_left = 22; style.content_margin_right = 22; style.content_margin_top = 18; style.content_margin_bottom = 18
	panel.add_theme_stylebox_override("panel", style); parent.add_child(panel)
	var box = VBoxContainer.new(); box.add_theme_constant_override("separation", 12)
	panel.add_child(box); label(box, title, true); return box

func send(action: String, args: Dictionary = {}):
	requested.emit(action, args)

func change_tab(value: String):
	tab = value; pending_order = {}; refresh()

func command(parent: Node, title: String, action: String, args: Dictionary = {}, disabled: bool = false):
	button(parent, title, send.bind(action, args), disabled)

func review(action: String, args: Dictionary, terms: String):
	pending_order = {"action": action, "args": args.duplicate(true)}
	pending_terms = terms; refresh()

func refresh():
	if not is_inside_tree(): return
	if root != null: remove_child(root); root.queue_free()
	root = MarginContainer.new(); add_child(root); root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]: root.add_theme_constant_override("margin_" + side, 26)
	var vertical = VBoxContainer.new(); vertical.add_theme_constant_override("separation", 14); root.add_child(vertical)
	var header = row(vertical)
	label(header, campaign.workshop.banner.name if Quest.claimed(campaign.journal, "headquarters") else "A BANNER WITHOUT A COUNTRY", true)
	button(header, "Return to map", func(): closed.emit())
	label(vertical, "%s Valcrest · Turn %d · %d gold · %d trust · cargo %d/20 · %s" % [campaign.journal.identity.name, campaign.turn, campaign.gold, campaign.trust, Shop.cargo_used(campaign.workshop), campaign.settlement().get("name", "On the road")])
	var tabs = GridContainer.new(); tabs.columns = 5; tabs.add_theme_constant_override("h_separation", 8); tabs.add_theme_constant_override("v_separation", 8); vertical.add_child(tabs)
	for value in ["Location", "Journal", "Headquarters", "Party", "Inventory", "Trade", "Houses", "Story", "Contacts", "Identity"]:
		button(tabs, ("◆ " if tab == value else "") + value, change_tab.bind(value))
	var scroll = ScrollContainer.new(); scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED; vertical.add_child(scroll)
	var body = VBoxContainer.new(); body.size_flags_horizontal = Control.SIZE_EXPAND_FILL; body.add_theme_constant_override("separation", 16); scroll.add_child(body)
	if not pending_order.is_empty():
		var terms = section(body, "REVIEW TERMS")
		label(terms, pending_terms)
		var choices = row(terms)
		button(choices, "Commit these terms", func():
			var order = pending_order.duplicate(true); pending_order = {}; send(order.action, order.args))
		button(choices, "Decline / go back", func(): pending_order = {}; refresh())
	else:
		match tab:
			"Location": _location(body)
			"Journal": _journal(body)
			"Headquarters": _headquarters(body)
			"Party": _party(body)
			"Inventory": _inventory(body)
			"Trade": _trade(body)
			"Houses": _houses(body)
			"Story": _story(body)
			"Contacts": _contacts(body)
			"Identity": _identity(body)
	label(vertical, status_text)

func _location(body: Node):
	var place = campaign.settlement()
	if not campaign.rewarded:
		var intro = section(body, "GREYFORD NEEDS HELP")
		label(intro, "Reach Greyford and enter the village to attempt the required defense. Your journey begins alone, penniless, in damaged Oathkeeper.")
		return
	if place.is_empty(): label(body, "Travel to a marked location for its services. Contacts and your journal remain accessible."); return
	var box = section(body, place.name)
	label(box, place.kind)
	if place.id == "camp":
		label(box, "Greyford's required mission. Victory grants 30 gold and 2 trust once and ends recurring camp raids. Emergency recovery is free; defeat leaves the camp retryable.")
		command(box, "Prepare bandit-camp mission", "prepare", {"kind": "camp"}, Quest.claimed(campaign.journal, "camp")); return
	if place.id == "merchant_rescue":
		command(box, "Prepare optional merchant rescue", "prepare", {"kind": "merchant_rescue"}); return
	if place.id == "headquarters": _headquarters(body); return
	if place.id == "capital":
		label(box, "The prison raid and final assault are separate operations. Required investigation and the permanent bargain cannot be bypassed by approaching early.")
		command(box, "Prepare prison raid · restoration", "prepare", {"kind": "prison"})
		command(box, "Prepare final throne encounter", "prepare", {"kind": "final"})
		return
	if place.id.begins_with("domain_") or place.id == "emberwatch":
		var h_id = place.get("house", "voss")
		button(box, "Audience / siege / custody", func(): house_id = h_id; tab = "Houses"; topic = "audience"; refresh())
	if place.id == "emberwatch":
		command(box, "Intercept Voss's courier · required evidence", "prepare", {"kind": "investigation"})
		command(box, "Raid imperial supply line", "prepare", {"kind": "raid"})
	if place.friendly:
		var services = row(box)
		command(services, "Shared workshop", "workshop", {}, not campaign._friendly_service())
		command(services, "Free emergency aid", "service", {"id": "repair"}, not campaign._friendly_service())
		command(services, "Replenish formations · 1g/strength", "service", {"id": "replenish"})
		var guild = row(box)
		command(guild, "Guild · accept grain contract", "service", {"id": "guild"})
		command(guild, "Deliver two grain at Millhaven", "service", {"id": "deliver"})
		command(guild, "Road clearance · prepare", "prepare", {"kind": "guild"})
		if place.id == "greyford":
			label(box, "Headquarters permission: camp cleared and trust ≥3. The defense and camp provide all required trust. No optional job, trade, tournament or companion is required.")
			command(box, "Ask council for headquarters permission", "service", {"id": "permission"})
		if place.id == "stonebridge":
			var jobs = row(box)
			command(jobs, "Accept stranded merchant rescue", "service", {"id": "rescue"})
			command(jobs, "Solo tournament · 5g entry / 25g prize", "prepare", {"kind": "tournament"}, campaign.inventory.tournament_won)
			command(box, "Road pact · 2 trust and 20 gold", "service", {"id": "diplomacy"})
			command(box, "Accept Asterfell envoy-protection quest", "service", {"id": "support"})
			command(box, "Prepare Asterfell protection mission", "prepare", {"kind": "house_support"})
		if place.id == "millhaven": command(box, "Read Aldren's preserved orders", "evidence", {"id": "orders"})
		if place.id == "stonebridge": command(box, "Hear the court physician", "evidence", {"id": "testimony"})
	if campaign.recruitment_access(): _recruitment(body)
	for id in Pilots.COMPANIONS:
		var info = Pilots.COMPANIONS[id]
		if info.place != place.id or not Pilots.pilot(campaign.pilots, id).is_empty(): continue
		var companion = section(body, "OPTIONAL PILOT · " + info.name)
		label(companion, "%s. Requires %s. Success offers the pilot and a usable %s as an explicit service loan at no gold cost. They join in reserve; enabling deployment and distinct frame assignment are required." % [info.title, info.requires, info.frame_name])
		command(companion, "Prepare personal quest", "prepare", {"kind": "companion", "id": id}, not Quest.claimed(campaign.journal, info.requires))

func _recruitment(body: Node):
	var box = section(body, "FORMAL RECRUITMENT")
	label(box, "Each formation is one commandable unit. Troops hired before headquarters remain yours; the headquarters story award is separate.")
	var grid = GridContainer.new(); grid.columns = 3; grid.add_theme_constant_override("h_separation", 12); grid.add_theme_constant_override("v_separation", 10); box.add_child(grid)
	var Region = load("res://scripts/region_model.gd")
	for id in campaign.recruitable_roles():
		var d = Battle.DEFINITIONS.get(id, Battle.COMBINED.get(id))
		command(grid, "%s · %dg" % [d.name, Region.PRICES[id]], "hire", {"id": id})

func _journal(body: Node):
	if not campaign.region.last_result.is_empty():
		var latest = section(body, "LATEST MISSION OUTCOME")
		label(latest, campaign.region.last_result)
	for id in Quest.DEFINITIONS:
		var q = Quest.DEFINITIONS[id]
		var box = section(body, "%s · %s · %s" % [q.title, "REQUIRED" if q.required else "OPTIONAL", Quest.status(campaign.journal, id)])
		label(box, "Prerequisites: " + (", ".join(q.requires) if not q.requires.is_empty() else "none"))
		label(box, q.objective + "\nReward: " + q.reward)
		if campaign.journal.outcomes.has(id): label(box, campaign.journal.outcomes[id])
	for id in Pilots.COMPANIONS:
		var info = Pilots.COMPANIONS[id]
		var box = section(body, "%s · OPTIONAL · %s" % [info.title, "Complete" if id in campaign.pilots.completed else ("Available" if Quest.claimed(campaign.journal, info.requires) else "Locked")])
		label(box, "Meet %s at %s. Prerequisite: %s. Reward: 12 gold, 1 trust, a personal pilot and the explicitly offered %s frame. No recruitment fee. Outcome: %s" % [info.name, info.place, info.requires, info.frame_name, "pilot and frame received once" if id in campaign.pilots.completed else "not completed"])
	label(body, "Optional companion missions are listed at their home settlements. No optional pilot gates a required story objective.")

func _headquarters(body: Node):
	var box = section(body, "THE WATCHHOUSE")
	if not Quest.claimed(campaign.journal, "permission"):
		label(box, "Clear the bandit camp, then ask Greyford's council for permission. Defense grants 1 trust; camp grants 2. Headquarters has no founding fee."); return
	if not Quest.claimed(campaign.journal, "headquarters"):
		label(box, "Travel to the watchhouse north of Greyford to found your warband. One formal sword formation and 1 trust are awarded once. Earlier hires are preserved.")
		_banner_editor(box)
		button(box, "Found this warband · free", func(): send("found", {"banner": banner_draft.duplicate(true)}), campaign.player != Vector2i(Quest.HQ[0], Quest.HQ[1])); return
	label(box, "Headquarters established: " + campaign.workshop.banner.name + ". Regional work remains open. Party and formation preferences are saved, while each battle shows its actual capped participants.")
	var actions = row(box)
	command(actions, "Garage / reserves / edit banner", "workshop", {}, campaign.settlement().get("id") != "headquarters")
	button(actions, "Manage party", change_tab.bind("Party"))
	button(actions, "Inventory and pending loot", change_tab.bind("Inventory"))
	if campaign.settlement().get("id") == "headquarters":
		_recruitment(body)
		command(box, "Free essential repair and pilot recovery", "service", {"id": "repair"})
		if campaign.chronicle.route == "restoration" and not campaign.chronicle.elite_defeated: command(box, "Face the sponsors' elite force", "prepare", {"kind": "elite"})
		if campaign.chronicle.princess == "restored": command(box, "Accept Aurelia's restoration frame loan · once", "princess_loan")

func _banner_editor(box: Node):
	label(box, "Warband name · two colors · one original centered emblem")
	var input = LineEdit.new(); input.text = banner_draft.name; input.max_length = 28; input.custom_minimum_size.y = 48
	input.text_changed.connect(func(value): banner_draft.name = value); box.add_child(input)
	var preview = Crest.new(); preview.banner = banner_draft; preview.custom_minimum_size = Vector2(140, 150); box.add_child(preview)
	for key in ["primary", "secondary"]:
		var colors = row(box); label(colors, key.capitalize())
		for color in Shop.COLORS:
			var swatch = button(colors, "●", func(): banner_draft[key] = color; preview.queue_redraw())
			swatch.add_theme_color_override("font_color", Color(color)); swatch.custom_minimum_size.x = 48
	var emblems = row(box)
	for emblem in Shop.EMBLEMS: button(emblems, emblem.capitalize(), func(): banner_draft.emblem = emblem; preview.queue_redraw())

func _party(body: Node):
	var summary = section(body, "PERSONAL PILOTS & FRAMES")
	label(summary, "Ten slots in ordinary encounters; fifteen in major battles and sieges. Personal mechs, allied support and settlement defenders all share the cap. Injuries recover in two End Turns or through free aid. Pilot levels add attack at 12, 24 and 36 XP.")
	for p in campaign.pilots.pilots:
		var box = section(body, p.name + " · pilot XP %d · level %d · injury %d turns" % [p.xp, Pilots.level(p.xp), p.injury])
		var f = Shop.frame(campaign.workshop, p.frame)
		label(box, "Assigned: " + ("none" if f.is_empty() else f.name) + (" · deploy requested" if p.deploy else " · reserve"))
		var controls = row(box)
		var select = OptionButton.new(); select.custom_minimum_size = Vector2(500, 48); controls.add_child(select)
		var choices = [""]; select.add_item("Unassigned / reserve")
		for frame in campaign.workshop.frames:
			choices.append(frame.id)
			select.add_item(frame.name + " · " + (Pilots.assigned(campaign.pilots, frame.id) if not Pilots.assigned(campaign.pilots, frame.id).is_empty() else "available"))
		var current = str(assignments.get(p.id, p.frame)); select.selected = maxi(0, choices.find(current))
		select.item_selected.connect(func(index): assignments[p.id] = choices[index])
		button(controls, "Assign selected frame", func(): send("assign", {"id": p.id, "frame": assignments.get(p.id, p.frame)}))
		command(controls, "Toggle deployment", "deploy_pilot", {"id": p.id}, p.id == "protagonist")
		command(controls, "Use field medicine", "medicine", {"id": p.id}, p.injury == 0)
	var troops = section(body, "FORMATIONS / RESERVE TROOPS")
	label(troops, "A selected preference may be displaced by personal pilots when the ordinary ten-slot cap is reached. Preparation lists the actual participants before you commit. Maximum formation rank 2; training costs 8 gold and 12/24 earned formation XP.")
	for f in campaign.region.formations:
		var d = Battle.DEFINITIONS.get(f.definition, Battle.COMBINED.get(f.definition))
		var controls = row(troops)
		label(controls, "%s · %d/%d · XP %d · rank %d" % [d.name, f.hp, d.hp, f.get("xp", 0), f.get("rank", 0)])
		command(controls, "Selected ✓" if f.id in campaign.region.selected else "Reserve", "select_formation", {"id": f.id})
		command(controls, "Train · 8g", "upgrade", {"id": f.id})
	if campaign.region.formations.is_empty(): label(troops, "No owned formations yet. Greyford's militia are temporary; headquarters awards your first formal troops.")

func _inventory(body: Node):
	var cargo = section(body, "CARRIED TRADE GOODS · %d/20" % Shop.cargo_used(campaign.workshop))
	for good in Shop.GOODS:
		var controls = row(cargo); label(controls, "%s · %d" % [Shop.GOODS[good].name, campaign.workshop.cargo.get(good, 0)])
		command(controls, "Discard one", "discard", {"id": good}, campaign.workshop.cargo.get(good, 0) == 0)
	var protected = section(body, "PROTECTED QUEST ITEMS · NO CARGO COST")
	if campaign.inventory.quest_items.is_empty(): label(protected, "No evidence collected yet.")
	for id in campaign.inventory.quest_items: label(protected, Economy.EVIDENCE[id] + " · protected / cannot sell")
	var garage = section(body, "OWNED FRAMES · SHARED RESERVES")
	for f in campaign.workshop.frames:
		var stats = Shop.stats(campaign.workshop, f)
		label(garage, "%s · %s · %d/%d hull · atk %d / armor %d / move %d / range %d · pilot: %s" % [f.name, Shop.CHASSIS[f.chassis].name, f.hp, stats.hp, stats.attack, stats.armor, stats.move, stats.range, Pilots.assigned(campaign.pilots, f.id)])
	var modules = section(body, "INTERNAL MODULES · SHARED ARMORY")
	for item in campaign.workshop.items:
		if Shop.ITEMS[item.definition].kind != "module": continue
		var fitted = Shop.fitted_to(campaign.workshop, item.id)
		label(modules, "%s · %s · price %dg" % [Shop.ITEMS[item.definition].name, "stored" if fitted.is_empty() else "fitted to " + fitted, Shop.ITEMS[item.definition].price])
	label(modules, "Open the friendly workshop for fitting, comparisons and hull refits. Frames and modules consume no cargo capacity.")
	var loot = section(body, "PENDING LOOT · TAKE OR LEAVE")
	label(loot, "Rewards remain pending across travel and saves until taken or explicitly left. Full cargo transfers nothing; sell or discard goods first. Taking a module puts it in shared storage.")
	for entry in campaign.inventory.loot:
		var box = section(loot, entry.id)
		for good in entry.goods:
			var controls = row(box); label(controls, "%s ×%d" % [Shop.GOODS[good].name, entry.goods[good]])
			command(controls, "Take one", "loot", {"id": entry.id, "kind": "good", "key": good})
			command(controls, "Take all", "loot", {"id": entry.id, "kind": "good", "key": good, "quantity": entry.goods[good]})
		for module in entry.modules: command(box, "Take " + Shop.ITEMS[module].name, "loot", {"id": entry.id, "kind": "module", "key": module})
		button(box, "Leave remaining loot permanently", review.bind("leave_loot", {"id": entry.id}, "Leave all remaining items in " + entry.id + " permanently? Collected items and protected evidence are retained."))
	if campaign.inventory.loot.is_empty(): label(loot, "No pending loot.")

func _trade(body: Node):
	var box = section(body, "SETTLEMENT MARKET")
	var place = campaign.settlement()
	label(box, "Settlement prices differ. Carrying grain, ore and useful field medicine shares a twenty-good hold. Workshop reserves are separate.")
	for good in Shop.GOODS:
		var controls = row(box)
		var buy = Shop.price(good, place.get("id", ""), true); var sell = Shop.price(good, place.get("id", ""), false)
		label(controls, "%s · %d carried" % [Shop.GOODS[good].name, campaign.workshop.cargo.get(good, 0)])
		command(controls, "Buy one · %dg" % buy, "shop", {"action": "buy_good", "good": good, "quantity": 1}, not campaign.trade_access())
		command(controls, "Sell one · %dg" % sell, "shop", {"action": "sell_good", "good": good, "quantity": 1}, not campaign.trade_access())
	var caravan = section(body, "FUNDED MERCHANT CARAVAN")
	label(caravan, "Optional agreement: rescue the stranded merchant, then sign at Stonebridge. Each dispatch pays 18 gold for six grain, travels to Millhaven for 36 gold, then returns. A marked ambush reserves its cargo until rescued. Loss allows a newly funded dispatch; delivery pays once.")
	var choices = row(caravan)
	command(choices, "Sign merchant agreement", "service", {"id": "merchant"})
	command(choices, "Fund dispatch · 18g", "service", {"id": "dispatch"})
	var c = campaign.inventory.caravan
	if not c.is_empty():
		label(caravan, "%s · %s · position %s · %d grain reserved · delivered: %s" % [c.id, c.phase, str(c.cell), c.cargo, str(c.paid)])
		if c.phase == "ambushed":
			label(caravan, "Rescue by travel turn %d. Reach the marked caravan; cargo cannot deliver during this ambush." % c.expires)
			command(caravan, "Prepare caravan rescue here", "prepare", {"kind": "funded_rescue"})
	var reports = section(body, "ROAD REPORTS")
	for text in campaign.inventory.reports: label(reports, text)

func _houses(body: Node):
	if not Quest.claimed(campaign.journal, "headquarters"): label(body, "Found your headquarters to open diplomatic audiences."); return
	var register = section(body, "TWENTY-TWO SEATS · TEN BREAKAWAY / TWELVE LOYALIST")
	label(register, "Opening allegiance is history; current faction, ruler fate, ownership, opinion, stance and sovereign recognition are separate. Nobles supply strategic support and never become personal pilots through capture.")
	var select = OptionButton.new(); select.custom_minimum_size.y = 48; register.add_child(select)
	for i in campaign.politics.houses.size():
		var h = campaign.politics.houses[i]
		select.add_item(h.name + " · " + h.origin + " · " + h.stance + " · recognition: " + (h.recognition if not h.recognition.is_empty() else "none"))
		if h.id == house_id: select.selected = i
	select.item_selected.connect(func(index): house_id = campaign.politics.houses[index].id; topic = "audience"; refresh())
	var h = Politics.house(campaign.politics, house_id)
	var portrait = row(register)
	var crest = Crest.new(); crest.custom_minimum_size = Vector2(100, 120)
	var index = Politics.NAMES.find(h.name)
	crest.banner = {"created": true, "name": h.name, "primary": Shop.COLORS[index % Shop.COLORS.size()], "secondary": Shop.COLORS[(index + 1) % Shop.COLORS.size()], "emblem": Shop.EMBLEMS[index % 3]}
	portrait.add_child(crest)
	label(portrait, "%s\nHouse %s · ruler %s · faction %s\nOpinion %d · domain owner %s · garrison %d · administrator %s\nRecognition %s · obligations due %s" % [h.ruler, h.name, h.fate, h.faction, h.opinion, h.owner, h.garrison, h.administrator, h.recognition, str(h.obligation)])
	if topic == "audience":
		label(register, "“State the terms you seek. My seat, my domain and my allegiance are separate matters.”")
		var choices = row(register)
		button(choices, "Access and commerce", func(): topic = "civic"; refresh())
		button(choices, "Military terms", func(): topic = "military"; refresh())
		button(choices, "Domain and custody", func(): topic = "domain"; refresh())
		button(choices, "Sovereign recognition", func(): topic = "recognition"; refresh())
	elif topic in ["civic", "military"]:
		label(register, "“A charter is a commitment. Review its price, trust requirement and obligation before you sign.”")
		for kind in (["access", "recruitment", "trade"] if topic == "civic" else ["funding", "nonaggression", "alliance", "peace"]):
			var terms = Politics.terms(h, kind, campaign.trust, campaign.gold, campaign.turn)
			var text = "%s with House %s. Cost: %d gold. Requires %d local trust and an eligible, available ruler. %s Military obligations expire after 12 End Turns; failure withdraws support and costs 8 opinion. Repeated unchanged agreements cannot award opinion." % [terms.name, h.name, terms.cost, terms.trust, terms.effect]
			var offers = row(register)
			button(offers, "%s · %dg · trust %d%s" % [terms.name, terms.cost, terms.trust, " · already signed" if kind in h.agreements else ""], review.bind("pact", {"id": h.id, "kind": kind}, text), not terms.eligible)
			var counter = Politics.terms(h, kind, campaign.trust, campaign.gold, campaign.turn, true)
			button(offers, "Service counteroffer · %dg" % counter.cost, review.bind("pact", {"id": h.id, "kind": kind, "counteroffer": true}, "%s with House %s. Earned-service counteroffer: opinion ≥5, trust %d and %d gold. %s Same military obligations; the actual cost and accepted terms persist with the payment." % [counter.name, h.name, counter.trust, counter.cost, counter.effect]), not counter.eligible)
	elif topic == "domain":
		label(register, "“Announce a war before approaching. A warned garrison may surrender or fight; custody terms do not erase my house.”")
		var war = row(register)
		button(war, "Review war declaration", review.bind("war", {"id": h.id}, "Declare war on " + h.name + ". Attacks begin after one End Turn. Breaking non-aggression or an alliance costs this house 20 opinion and all other houses 3. Active truces block declaration."))
		command(war, "Approach / warn fort here", "siege", {"id": h.id})
		var siege = campaign.politics.siege
		if not siege.is_empty():
			label(register, "Active siege: %s · readiness %d/3. Remain at the marked domain; End Turn builds readiness. Assault and surrender open at readiness 2. Leaving withdraws the siege. At readiness 3, every second travel turn reduces defenders toward a minimum of 3; besieged defenders do not recover." % [siege.house, siege.readiness])
			var choices = row(register)
			command(choices, "Assault fort · prepare", "prepare", {"kind": "siege", "id": h.id})
			button(choices, "Demand surrender", review.bind("surrender", {"id": h.id}, "Demand this fort surrender. Requires readiness 2, a garrison no stronger than 6 and at least as many commandable units as defenders. Capture gives control and custody; recognition remains a separate commitment."))
			command(choices, "Withdraw siege", "withdraw_siege", {"id": h.id})
		if h.fate == "captured":
			var custody = section(body, "CUSTODY TERMS")
			for kind in ["release", "ransom", "submission", "execute"]:
				var terms = {"release": "Release the ruler into displacement. +5 house opinion; no automatic recognition.", "ransom": "Ransom the ruler for 20 gold. −3 house opinion; no automatic recognition.", "submission": "Accept submission to the chosen sovereign and release the ruler into displacement. Explicit recognition is committed with this settlement.", "execute": "Execute the captured ruler. An authored house heir succeeds; this seat survives. This house falls to −30 opinion and all other houses lose 5. Required scenes continue through successors and envoys."}[kind]
				button(custody, kind.capitalize(), review.bind("custody", {"id": h.id, "kind": kind}, terms))
		if h.owner == "player":
			var offices = row(register)
			for kind in ["quartermaster", "steward", "captain"]: command(offices, "Appoint " + kind, "administrator", {"id": h.id, "kind": kind})
		if h.obligation > 0: command(register, "Honor military obligation here · prepare", "prepare", {"kind": "obligation", "id": h.id})
	elif topic == "recognition":
		label(register, "“Friendship and occupation are insufficient. Name the sovereign this seat is asked to recognize.”")
		label(register, "%d / 22 seats recognize the chosen sovereign. Individual terms: settled rescue/escape, 5 trust, non-negative opinion and no active war; a controlled domain can instead settle through custody and submission." % Politics.recognized(campaign.politics, campaign.chronicle.route))
		var choices = row(register)
		button(choices, "Request this seat's recognition", review.bind("recognize", {"id": h.id}, "House " + h.name + " explicitly recognizes " + ("Empress Aurelia" if campaign.chronicle.route == "restoration" else campaign.journal.identity.name + " as emperor") + ". No fee; this is a sovereign settlement, separate from alliance, ownership or inherited identity."))
		for kind in ["breakaway", "loyalist"]:
			button(choices, kind.capitalize() + " coalition settlement", review.bind("recognize", {"id": h.id, "kind": kind}, "Authored coalition settlement for every " + kind + " seat. Requires two of these seats already recognizing the chosen sovereign, 5 trust and settled rescue/escape. All seats in the bloc explicitly recognize the sovereign; active wars with this bloc end by submission and captive rulers become displaced. No fee or conquest repetition."))
	if topic != "audience": button(register, "Return to audience", func(): topic = "audience"; refresh())
	var reports = section(body, "POLITICAL REPORTS")
	for text in campaign.politics.reports: label(reports, text)

func _story(body: Node):
	var box = section(body, "THE PROMISE & THE CROWN")
	var story = campaign.chronicle
	label(box, "Aurelia is the lawful eldest heir and your established love. Lucien was your childhood friend. Aldren secretly had Selene murdered and planned to kill the initially innocent Lucien; Roland knew nothing. Lucien's fear does not excuse his coup, Aurelia's imprisonment or the hunt against your family.")
	label(box, "Current route: %s · Aurelia: %s · investigation %d/3" % ["undecided" if story.route.is_empty() else story.route, story.princess, story.evidence.size()])
	if not story.ending.is_empty(): label(box, story.epilogue); return
	if not Quest.claimed(campaign.journal, "headquarters"): label(box, "First defend Greyford, clear the camp and establish headquarters."); return
	if not Quest.claimed(campaign.journal, "investigation"):
		label(box, "Required evidence: preserved orders at Millhaven → court physician at Stonebridge → Voss's courier at Emberwatch. The physician introduces Aurelia's own efforts to escape before the branch. No optional companion supplies the only evidence.")
		command(box, "Read orders here at Millhaven", "evidence", {"id": "orders"})
		command(box, "Hear physician here at Stonebridge", "evidence", {"id": "testimony"})
		command(box, "Intercept courier here at Emberwatch", "prepare", {"kind": "investigation"})
	elif story.route.is_empty():
		label(box, "Rothmar, Vaust and Merrow's house envoys await at headquarters. Their offices continue through any captured, displaced or executed ruler. Review either permanent choice before committing.")
		var choices = row(box)
		button(choices, "Review refusal · restoration", review.bind("branch", {"id": "restoration"}, Chronicle.REJECT_TERMS))
		button(choices, "Review acceptance · dominion", review.bind("branch", {"id": "dominion"}, Chronicle.ACCEPT_TERMS))
	elif story.route == "restoration" and not story.elite_defeated:
		label(box, "The sponsors field their four veteran formations and the advanced Merrow mech under their own pilot. Defeat them at headquarters to open the prison raid.")
		command(box, "Prepare elite-force battle here at headquarters", "prepare", {"kind": "elite"})
	elif story.route == "restoration" and story.princess != "restored":
		label(box, "Approach the imperial capital and raid the prison. This midpoint operation rescues Aurelia without capturing the city or killing Lucien.")
		command(box, "Prepare prison raid here at the capital", "prepare", {"kind": "prison"})
	elif story.route == "dominion" and story.princess != "exiled":
		label(box, "The physician and Aurelia's own network are completing her independent escape. End Turn resolves their operation. Your permanent acceptance cannot reopen restoration.")
	else:
		if story.route == "restoration":
			label(box, "Aurelia: “I have read every order and heard the physician. My father's crimes cannot be erased, and my brother remains responsible for his choices. I will lead our coalition; the throne is an office to restore, not a prize to inherit through marriage. Let us secure the houses' explicit recognition before we end this war.”")
			command(box, "Accept Aurelia's frame loan here at headquarters", "princess_loan")
		else: label(box, "Aurelia survives abroad. The houses recognize your new claim, not a transferred hereditary right. Your sponsors cannot undo the route or grant their reward again.")
		label(box, "Recognition: %d/22. Settle seats individually, through custody/submission or via each bloc's coalition. Coalition terms require two recognized seats in that bloc and 5 trust. Then approach the capital for Lucien's final refusal and battle." % Politics.recognized(campaign.politics, story.route))
		command(box, "Prepare final battle here at the capital", "prepare", {"kind": "final"})

func _contacts(body: Node):
	var contacts = campaign.contacts_at(campaign.player)
	var box = section(body, "LOCAL PARTY CONTACTS")
	label(box, "Longer travel orders stop when they meet a party. An audience, withdrawal or menu never advances time. Committing an encounter reserves its participants; only End Turn moves the world.")
	if contacts.is_empty(): label(box, "No party shares your current hex. Visible markers disclose current positions; remembered terrain does not reveal unseen parties.")
	for party in contacts:
		var contact = section(body, party.kind + " · " + party.owner)
		label(contact, "Strength %d · job: %s · destination %s" % [party.strength, party.job, str(party.goal)])
		var choices = row(contact)
		if party.id == "caravan":
			button(choices, "Ask about merchant routes", change_tab.bind("Trade"))
		elif party.id == "envoy":
			button(choices, "Discuss house terms", func(): house_id = "asterfell"; tab = "Houses"; refresh())
		elif party.id == "patrol":
			label(contact, "“Defend Greyford, break the raider camp, then ask the council for the watchhouse. Our militia cannot leave with you until formally recruited.”")
		else:
			label(contact, "“This road is watched.” You may withdraw legally; meeting a hostile marker never starts a battle without your deployment decision.")
			command(choices, "Prepare road intervention", "prepare", {"kind": "contact", "id": party.id}, party.ready > campaign.region.ticks)
		button(choices, "Withdraw / leave contact", func(): status_text = "Contact declined. No time, payment or battle applied."; refresh())
	var c = campaign.inventory.caravan
	if not c.is_empty() and c.phase == "ambushed":
		var rescue = section(body, "FUNDED CARAVAN AMBUSH")
		label(rescue, "Your reserved caravan waits at %s until turn %d." % [str(c.cell), c.expires])
		command(rescue, "Prepare rescue here", "prepare", {"kind": "funded_rescue"})

func _identity(body: Node):
	var box = section(body, "THE ARCHDUKE'S SON")
	label(box, "Your name and bounded heraldic portrait use the available original emblems. Your male identity, Valcrest history and existing romance with Aurelia remain fixed. No new face artwork is implied by this choice.")
	var input = LineEdit.new(); input.text = identity_name; input.max_length = 28; input.custom_minimum_size.y = 48
	input.text_changed.connect(func(value): identity_name = value); box.add_child(input)
	var preview = Crest.new(); preview.banner = {"created": true, "name": identity_name, "primary": "243448", "secondary": "c5a46b", "emblem": Shop.EMBLEMS[appearance]}; preview.custom_minimum_size = Vector2(150, 180); box.add_child(preview)
	var portraits = row(box)
	for index in Quest.APPEARANCES.size():
		button(portraits, Quest.APPEARANCES[index], func(): appearance = index; refresh())
	button(box, "Save identity", func(): send("identity", {"name": identity_name, "appearance": appearance}))
