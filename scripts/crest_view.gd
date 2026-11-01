extends Control
## A cosmetic crest rendered from the same saved definition everywhere.
var banner = {"primary": "243448", "secondary": "c5a46b", "emblem": "sun"}

func _draw():
	var center = size * 0.5
	var scale_value = minf(size.x / 240.0, size.y / 300.0)
	var outline = PackedVector2Array()
	for p in [Vector2(-93, -125), Vector2(93, -125), Vector2(93, 55), Vector2(0, 132), Vector2(-93, 55)]:
		outline.append(center + p * scale_value)
	draw_colored_polygon(outline, Color(banner.primary))
	var closed = outline.duplicate()
	closed.append(outline[0])
	draw_polyline(closed, Color(banner.secondary), 5 * scale_value, true)
	var color = Color(banner.secondary)
	if banner.emblem == "sun":
		draw_circle(center, 34 * scale_value, color, true, -1, true)
		for i in 12:
			var ray = Vector2.from_angle(i * TAU / 12)
			draw_line(center + ray * 44 * scale_value, center + ray * 64 * scale_value, color, 5 * scale_value, true)
	elif banner.emblem == "sword":
		var points = PackedVector2Array()
		for p in [Vector2(0,-82),Vector2(12,-55),Vector2(9,25),Vector2(39,25),Vector2(39,34),Vector2(8,34),Vector2(8,65),Vector2(-8,65),Vector2(-8,34),Vector2(-39,34),Vector2(-39,25),Vector2(-9,25),Vector2(-12,-55)]:
			points.append(center + p * scale_value)
		draw_colored_polygon(points, color)
	else:
		for rect in [Rect2(-44,-34,88,101),Rect2(-51,-60,24,38),Rect2(-12,-60,24,38),Rect2(27,-60,24,38)]:
			draw_rect(Rect2(center + rect.position * scale_value, rect.size * scale_value), color)
		draw_rect(Rect2(center + Vector2(-12,20) * scale_value, Vector2(24,47) * scale_value), Color(banner.primary))
