extends RefCounted
## Keep the complete landscape canvas inside a handset's display cutouts.
const CANVAS = Vector2(1600, 900)

static func fit(root: Node2D):
	root.position = Vector2.ZERO; root.scale = Vector2.ONE
	if OS.get_name() not in ["Android", "iOS"]: return
	var physical = Rect2(DisplayServer.get_display_safe_area())
	if not physical.has_area(): return
	var screen_to_canvas = root.get_viewport().get_screen_transform().affine_inverse()
	var safe = (screen_to_canvas * physical).intersection(Rect2(Vector2.ZERO, CANVAS))
	if not safe.has_area(): return
	var factor = minf(safe.size.x / CANVAS.x, safe.size.y / CANVAS.y)
	root.scale = Vector2.ONE * factor
	root.position = safe.position + (safe.size - CANVAS * factor) * .5
