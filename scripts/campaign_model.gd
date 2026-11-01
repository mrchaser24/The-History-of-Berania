extends RefCounted
const Hex = preload("res://scripts/hex_grid.gd")
var board = Hex.cells(6, 5)
var player = Hex.cell(2, 2)
var village = Hex.cell(4, 2)
var patrol = Hex.cell(2, 1)
var bandit = Hex.cell(5, 3)
var turn = 1
var budget = 3
var gold = 0
var trust = 0
var explored = []
var visible = []
var quest = "travel"
var rewarded = false
var mech_hp = 18
var pending_battle = false
var news = "Smoke rises beyond the eastern road. Greyford needs help."

func _init():
	update_visibility()

func update_visibility():
	visible.clear()
	for p in board:
		if Hex.distance(player, p) <= 2:
			visible.append(p)
			if p not in explored:
				explored.append(p)

func path_to(goal: Vector2i) -> Array:
	if goal not in explored:
		return []
	var path = Hex.path(player, goal, board, [])
	if path.size() <= 1 or path.size() - 1 > budget:
		return []
	return path

func travel(goal: Vector2i) -> Array:
	var path = path_to(goal)
	if path.is_empty():
		return []
	budget -= path.size() - 1
	player = goal
	update_visibility()
	return path

func end_turn() -> Dictionary:
	var before = {"patrol": patrol, "bandit": bandit}
	turn += 1
	budget = 3
	patrol = Hex.cell(3 if turn % 2 == 0 else 2, 1)
	if not rewarded:
		bandit = Hex.cell(4 if turn % 2 == 0 else 5, 3)
	update_visibility()
	news = "Roadwardens patrol the northern road."
	if bandit in visible and not rewarded:
		news = "A raider banner has been sighted east of Greyford."
	return before

func finish_battle(outcome: String, remaining_hp: int) -> bool:
	if rewarded:
		return false
	pending_battle = false
	if outcome == "victory":
		mech_hp = maxi(1, remaining_hp)
		if not rewarded:
			gold += 40
			trust += 1
			rewarded = true
			quest = "complete"
			news = "Greyford is safe. Your banner has been remembered."
			return true
	else:
		player = village
		mech_hp = 30
		quest = "retry"
		news = "The villagers recovered your walker. Repairs are free; the defense can be retried."
	return false

func snapshot() -> Dictionary:
	var memory = []
	for p in explored:
		memory.append([p.x, p.y])
	return {"schema": 1, "build": "greyford-demo-0.1", "player": [player.x, player.y], "patrol": [patrol.x, patrol.y], "bandit": [bandit.x, bandit.y], "turn": turn, "budget": budget, "gold": gold, "trust": trust, "quest": quest, "rewarded": rewarded, "mech_hp": mech_hp, "pending_battle": pending_battle, "explored": memory, "news": news}

static func valid_snapshot(data) -> bool:
	if not data is Dictionary or data.get("schema") != 1 or data.get("build") != "greyford-demo-0.1":
		return false
	for key in ["player", "patrol", "bandit"]:
		if not data.get(key) is Array or data[key].size() != 2:
			return false
		for value in data[key]:
			if not (value is int or value is float) or value != int(value):
				return false
		if Hex.cells(6, 5).find(Vector2i(int(data[key][0]), int(data[key][1]))) < 0:
			return false
	for key in ["turn", "budget", "gold", "trust", "mech_hp"]:
		if not (data.get(key) is int or data.get(key) is float) or data[key] != int(data[key]):
			return false
	if data.turn < 1 or data.budget < 0 or data.budget > 3 or data.gold < 0 or data.trust < 0 or data.mech_hp < 1 or data.mech_hp > 30:
		return false
	if data.get("quest") not in ["travel", "retry", "complete"] or not data.get("rewarded") is bool or not data.get("pending_battle") is bool:
		return false
	if data.rewarded != (data.quest == "complete") or (data.rewarded and data.pending_battle):
		return false
	if not data.get("explored") is Array or not data.get("news") is String:
		return false
	var seen = []
	for point in data.explored:
		if not point is Array or point.size() != 2:
			return false
		for value in point:
			if not (value is int or value is float) or value != int(value):
				return false
		var p = Vector2i(int(point[0]), int(point[1]))
		if p not in Hex.cells(6, 5) or p in seen:
			return false
		seen.append(p)
	return true

func restore(data: Dictionary) -> bool:
	if not valid_snapshot(data):
		return false
	player = Vector2i(int(data.player[0]), int(data.player[1]))
	patrol = Vector2i(int(data.patrol[0]), int(data.patrol[1]))
	bandit = Vector2i(int(data.bandit[0]), int(data.bandit[1]))
	turn = int(data.turn)
	budget = int(data.budget)
	gold = int(data.gold)
	trust = int(data.trust)
	quest = data.quest
	rewarded = data.rewarded
	mech_hp = int(data.mech_hp)
	pending_battle = data.pending_battle
	news = data.news
	explored.clear()
	for point in data.explored:
		explored.append(Vector2i(int(point[0]), int(point[1])))
	update_visibility()
	return true
