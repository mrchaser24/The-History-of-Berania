extends RefCounted
## Small original layered 2D figures. Animation changes poses, never the model.
const INK = Color("25323a")
const STEEL = Color("9ba7a5")
const LIGHT = Color("d4d9cc")
const BRASS = Color("c7a565")

static func ellipse(c: CanvasItem, center: Vector2, radius: Vector2, color: Color):
	var points = PackedVector2Array()
	for i in 24:
		var angle = TAU * i / 24.0
		points.append(center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
	c.draw_colored_polygon(points, color)

static func polygon(c: CanvasItem, points: Array, color: Color):
	c.draw_colored_polygon(PackedVector2Array(points), color)

static func draw_unit(c: CanvasItem, u: Dictionary, origin: Vector2, time: float, moving: bool = false, attack: float = 0.0, hit: float = 0.0, reduced: bool = false):
	var friendly = u.side == 0
	var cloth = Color("35566b") if friendly else Color("8a4939")
	var accent = Color("e0c584") if friendly else Color("d39365")
	var facing = -1.0 if u.facing in [2, 3, 4] else 1.0
	var phase = time * (11.0 if moving else 2.0)
	var sway = 0.0 if reduced else sin(phase) * (2.0 if moving else 0.6)
	c.draw_set_transform(origin)
	ellipse(c, Vector2(0, 7), Vector2(39, 13), Color(0.09, 0.14, 0.12, 0.3))
	if u.kind == "mech":
		_mech(c, cloth, accent, phase, facing, moving, attack, hit, sway)
	else:
		var ratio = float(u.hp) / u.max_hp
		var count = mini(int(u.hp), 4 if ratio >= 0.75 else (3 if ratio >= 0.5 else 2))
		var positions = [Vector2(-16, -9), Vector2(13, -9), Vector2(-16, 11), Vector2(13, 11)]
		for i in count:
			c.draw_set_transform(origin + positions[i] + Vector2(0, sway), 0, Vector2(0.9, 0.9))
			_person(c, cloth, accent, phase + i * 0.45, facing, moving, u.kind == "gunner", attack, hit, u.guard)
		c.draw_set_transform(origin)
		# One little standard identifies a whole formation, not a fifth unit.
		c.draw_line(Vector2(-27, -7), Vector2(-27, -65), Color("b4a67a"), 2.5, true)
		var wave = sin(time * 3.0) * (0.0 if reduced else 2.0)
		polygon(c, [Vector2(-27, -65), Vector2(-8, -62 + wave), Vector2(-10, -47 + wave), Vector2(-27, -50)], cloth.lightened(0.14))
		c.draw_line(Vector2(-22, -59), Vector2(-14, -56 + wave), accent, 2.0, true)
	c.draw_set_transform(Vector2.ZERO)

static func _person(c: CanvasItem, cloth: Color, accent: Color, phase: float, facing: float, moving: bool, gun: bool, attack: float, hit: float, guarding: bool):
	var stride = sin(phase) * 5.0 if moving else 0.0
	var lift = sin(attack * PI) * 15.0
	var stagger = sin(hit * PI) * 3.0
	# Boots, leggings, cape and torso are separate layers.
	c.draw_line(Vector2(-4, -10), Vector2(-5 - stride, 1), INK, 6.0, true)
	c.draw_line(Vector2(4, -10), Vector2(5 + stride, 1), Color("4b5149"), 6.0, true)
	ellipse(c, Vector2(-5 - stride, 2), Vector2(5, 2.5), INK)
	ellipse(c, Vector2(6 + stride, 2), Vector2(5, 2.5), INK)
	polygon(c, [Vector2(-10, -33), Vector2(8, -33), Vector2(11 + stride * 0.3, -7), Vector2(-12, -9)], cloth.darkened(0.28))
	polygon(c, [Vector2(-8, -32), Vector2(8, -32), Vector2(7, -11), Vector2(-7, -11)], INK)
	polygon(c, [Vector2(-7, -32), Vector2(6, -32), Vector2(5 + stagger, -13), Vector2(-6, -13)], cloth.lightened(0.15))
	c.draw_line(Vector2(-6, -19), Vector2(6, -19), accent.darkened(0.3), 3.0, true)
	c.draw_circle(Vector2(0, -27), 2, accent)
	c.draw_circle(Vector2(0, -39), 7.0, INK)
	c.draw_circle(Vector2(-1.0, -40), 6.0, STEEL)
	c.draw_arc(Vector2(-1, -40), 5.0, PI, TAU, 12, LIGHT, 2.0, true)
	c.draw_line(Vector2(facing * 1, -41), Vector2(facing * 6, -41), INK, 2.0, true)
	c.draw_line(Vector2(facing * 4, -39), Vector2(facing * 4, -35), STEEL.darkened(0.2), 2.0, true)
	var hand = Vector2(facing * (12 + lift * 0.3), -24 - lift * 0.3)
	c.draw_line(Vector2(facing * 7, -30), hand, STEEL.darkened(0.2), 5.0, true)
	if gun:
		c.draw_line(hand + Vector2(-facing * 10, 3), hand + Vector2(facing * 14, -7), Color("634a34"), 5.0, true)
		c.draw_line(hand, hand + Vector2(facing * 19, -9), INK, 3.0, true)
	else:
		var tip = hand + Vector2(facing * (8 + lift), -22 + lift * 0.65)
		c.draw_line(hand, tip, INK, 5.0, true)
		c.draw_line(hand, tip, LIGHT, 3.0, true)
		c.draw_line(hand + Vector2(-5, -1), hand + Vector2(5, 1), BRASS, 3.0, true)
		var shield = Vector2(-facing * (10 if not guarding else 15), -24)
		polygon(c, [shield + Vector2(-7, -9), shield + Vector2(7, -9), shield + Vector2(6, 5), shield + Vector2(0, 11), shield + Vector2(-6, 5)], INK)
		polygon(c, [shield + Vector2(-5, -7), shield + Vector2(5, -7), shield + Vector2(4, 4), shield + Vector2(0, 8), shield + Vector2(-4, 4)], cloth.lightened(0.2))
		c.draw_line(shield + Vector2(0, -6), shield + Vector2(0, 6), accent, 2.0, true)

static func _mech(c: CanvasItem, cloth: Color, accent: Color, phase: float, facing: float, moving: bool, attack: float, hit: float, sway: float):
	var stride = sin(phase) * 7.0 if moving else 0.0
	var swing = sin(attack * PI)
	var body = Vector2(sin(hit * PI) * 4.0, sway)
	for sign_value in [-1.0, 1.0]:
		var hip = Vector2(sign_value * 12, -33) + body
		var knee = Vector2(sign_value * 17 - sign_value * stride * 0.4, -18)
		var foot = Vector2(sign_value * 17 + sign_value * stride, 2)
		c.draw_line(hip, knee, INK, 13.0, true)
		c.draw_line(hip + Vector2(-2, -1), knee, STEEL.darkened(0.3), 8.0, true)
		c.draw_line(knee, foot, INK, 12.0, true)
		c.draw_line(knee + Vector2(-2, 0), foot, STEEL, 6.0, true)
		c.draw_circle(knee, 6.0, BRASS.darkened(0.2))
		c.draw_rect(Rect2(foot + Vector2(-9, -2), Vector2(19, 7)), INK)
		c.draw_rect(Rect2(foot + Vector2(-8, -4), Vector2(17, 5)), STEEL.darkened(0.3))
	var torso = body + Vector2(0, -51)
	polygon(c, [torso + Vector2(-25, -19), torso + Vector2(23, -19), torso + Vector2(20, 16), torso + Vector2(-17, 20)], INK)
	polygon(c, [torso + Vector2(-22, -17), torso + Vector2(20, -17), torso + Vector2(16, 14), torso + Vector2(-15, 17)], STEEL.darkened(0.12))
	polygon(c, [torso + Vector2(-18, -14), torso + Vector2(8, -15), torso + Vector2(4, 12), torso + Vector2(-13, 14)], cloth)
	c.draw_line(torso + Vector2(-20, -17), torso + Vector2(18, -17), LIGHT, 3.0, true)
	for px in [-17, 14]:
		for py in [-12, 8]:
			c.draw_circle(torso + Vector2(px, py), 2, BRASS)
	c.draw_circle(torso + Vector2(-4, -2), 6, accent)
	c.draw_circle(torso + Vector2(-4, -2), 3, cloth.darkened(0.1))
	# Helmet, visor and exhaust stacks.
	c.draw_line(torso + Vector2(-17, -18), torso + Vector2(-18, -39), INK, 6.0, true)
	c.draw_line(torso + Vector2(15, -18), torso + Vector2(17, -34), INK, 6.0, true)
	ellipse(c, torso + Vector2(0, -26), Vector2(12, 13), INK)
	ellipse(c, torso + Vector2(-1, -28), Vector2(10, 10), STEEL)
	c.draw_line(torso + Vector2(facing * 2, -28), torso + Vector2(facing * 10, -28), Color("f6d89b"), 3.0, true)
	var arm = torso + Vector2(facing * (32 + swing * 8), 8 - swing * 18)
	c.draw_line(torso + Vector2(facing * 23, -9), arm, INK, 15.0, true)
	c.draw_line(torso + Vector2(facing * 23 - 2, -11), arm, STEEL.darkened(0.15), 9.0, true)
	c.draw_circle(torso + Vector2(facing * 25, -12), 11, INK)
	c.draw_circle(torso + Vector2(facing * 25 - 2, -15), 9, STEEL)
	var tip = arm + Vector2(facing * (4 + swing * 30), -48 + swing * 30)
	c.draw_line(arm, tip, INK, 10.0, true)
	c.draw_line(arm + Vector2(-2, 0), tip + Vector2(-2, 0), LIGHT, 5.0, true)
	c.draw_line(arm + Vector2(-9, -2), arm + Vector2(9, 2), BRASS, 5.0, true)
	var shield = torso + Vector2(-facing * 29, 2)
	polygon(c, [shield + Vector2(-12, -17), shield + Vector2(12, -17), shield + Vector2(10, 13), shield + Vector2(0, 21), shield + Vector2(-10, 13)], INK)
	polygon(c, [shield + Vector2(-9, -14), shield + Vector2(9, -14), shield + Vector2(7, 11), shield + Vector2(0, 17), shield + Vector2(-7, 11)], cloth.lightened(0.1))
	c.draw_line(shield + Vector2(0, -11), shield + Vector2(0, 12), accent, 3.0, true)
