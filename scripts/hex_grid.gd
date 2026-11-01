extends RefCounted
## Pointy hexes. Rendering may squash Y; rules always use axial coordinates.

const DIRECTIONS = [Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 1), Vector2i(-1, 0), Vector2i(0, -1), Vector2i(1, -1)]

static func cell(column: int, row: int) -> Vector2i:
	return Vector2i(column - floori(float(row) / 2.0), row)

static func column(pos: Vector2i) -> int:
	return pos.x + floori(float(pos.y) / 2.0)

static func distance(a: Vector2i, b: Vector2i) -> int:
	var d = a - b
	return maxi(maxi(absi(d.x), absi(d.y)), absi(d.x + d.y))

static func cells(width: int, height: int) -> Array:
	var result = []
	for row in height:
		for col in width:
			result.append(cell(col, row))
	return result

static func direction(a: Vector2i, b: Vector2i) -> int:
	var best = 0
	var score = 99999
	for i in 6:
		var value = distance(a + DIRECTIONS[i], b)
		if value < score:
			score = value
			best = i
	return best

static func round_axial(q: float, r: float) -> Vector2i:
	var x = roundi(q)
	var z = roundi(r)
	var y = roundi(-q - r)
	var dx = absf(x - q)
	var dz = absf(z - r)
	var dy = absf(y + q + r)
	if dx > dy and dx > dz:
		x = -y - z
	elif dz > dy:
		z = -x - y
	return Vector2i(x, z)

static func line(a: Vector2i, b: Vector2i) -> Array:
	var result = []
	var steps = distance(a, b)
	if steps == 0:
		return [a]
	for i in range(steps + 1):
		var t = float(i) / steps
		result.append(round_axial(lerpf(a.x, b.x, t) + 0.00001, lerpf(a.y, b.y, t) + 0.00002))
	return result

static func path(start: Vector2i, goal: Vector2i, allowed: Array, blocked: Array, costs: Dictionary = {}) -> Array:
	if goal not in allowed or goal in blocked:
		return []
	var frontier = [start]
	var cost = {start: 0}
	var previous = {}
	while not frontier.is_empty():
		var best = 0
		for i in frontier.size():
			if cost[frontier[i]] < cost[frontier[best]]:
				best = i
		var current = frontier.pop_at(best)
		if current == goal:
			var result = [goal]
			while result[0] != start:
				result.push_front(previous[result[0]])
			return result
		for delta in DIRECTIONS:
			var next = current + delta
			if next not in allowed or next in blocked:
				continue
			var next_cost = cost[current] + int(costs.get(next, 1))
			if not cost.has(next) or next_cost < cost[next]:
				cost[next] = next_cost
				previous[next] = current
				if next not in frontier:
					frontier.append(next)
	return []
