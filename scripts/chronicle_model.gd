extends RefCounted
## Authored main-story state. World simulation never chooses a route or kills a required actor.
const Shop = preload("res://scripts/workshop_model.gd")
const Quest = preload("res://scripts/quest_model.gd")
const Politics = preload("res://scripts/politics_model.gd")
const CAPITAL = [6, 6]
const GRANT_GOLD = 120
const ACCEPT_TERMS = "PERMANENT DOMINION: abandon Aurelia's rescue and restoration. Rothmar, Vaust and Merrow deliver four veteran formations, one advanced unassigned Merrow frame, and 120 gold once. Aurelia will organize her own escape and survive abroad. Later betrayal cannot reopen restoration."
const REJECT_TERMS = "PERMANENT RESTORATION: refuse the sponsors. Defeat their four veterans and advanced mech, then raid the capital prison to rescue Aurelia. The raid does not capture the capital. Settle the civil war before the final confrontation."

static func defaults() -> Dictionary:
	return {"version": 1, "route": "", "physician": false, "evidence": [], "bargain_claimed": false, "elite_defeated": false, "princess": "imprisoned", "escape_due": 0, "capital": false, "ending": "", "epilogue": ""}

static func evidence(state: Dictionary, inventory: Dictionary, id: String) -> String:
	if id in state.evidence: return "This evidence is already recorded in the protected journal."
	state.evidence.append(id)
	if id not in inventory.quest_items: inventory.quest_items.append(id)
	if id == "testimony":
		state.physician = true
		return "The physician corroborates Aldren's murder of Selene and planned purge of the innocent Lucien. Roland knew nothing. He is already helping Aurelia send messages and preparing an independent escape route. Lucien's later imprisonment and persecution remain his responsibility."
	if id == "orders": return "Aldren's sealed order authorized Selene's assassination. A later warrant ordered Lucien's death. The archduke was deliberately excluded. These protected documents cannot be sold."
	return "Voss's courier orders corroborate the planned purge and Garrick's false accusations. The required investigation is complete; the three-house envoys will now meet at headquarters."

static func choose(state: Dictionary, journal: Dictionary, pilots: Dictionary, workshop: Dictionary, region: Dictionary, route: String, turn: int) -> bool:
	if route not in ["restoration", "dominion"] or not state.route.is_empty() or not Quest.claimed(journal, "investigation") or not state.physician: return false
	state.route = route
	if route == "dominion":
		state.bargain_claimed = true
		for definition in ["greyford_blades", "pikemen", "roadwardens", "cavalry"]:
			var Battle = load("res://scripts/battle_model.gd")
			var d = Battle.DEFINITIONS.get(definition, Battle.COMBINED.get(definition))
			var id = "formation_" + str(region.next_id); region.next_id += 1
			region.formations.append({"id": id, "definition": definition, "hp": d.hp, "owned": true, "xp": 24, "rank": 2})
		Shop.add_frame(workshop, "advanced", "Merrow Crownward")
		state.escape_due = turn + 2
	Quest.record(journal, "bargain", "The envoys' offer was accepted permanently." if route == "dominion" else "The envoys' offer was refused permanently; the elite force bars the prison road.")
	return true

static func tick(state: Dictionary, turn: int) -> String:
	if state.route == "dominion" and state.princess == "imprisoned" and turn >= state.escape_due:
		state.princess = "exiled"
		return "Aurelia and the physician organized her escape. She survives abroad and knows you accepted the bargain. Restoration remains permanently closed."
	return ""

static func ending(state: Dictionary, journal: Dictionary, politics: Dictionary, name: String, companions: Array):
	if not state.ending.is_empty(): return
	state.capital = true
	state.ending = state.route
	var text = "Lucien refuses surrender and dies fighting. The throne amplified his fear and choices; it did not absolve him. "
	if state.route == "restoration":
		text += "Aurelia is crowned empress. She and %s marry; he becomes prince-consort and military partner. Together they destroy the throne's magitech mechanism while retaining the imperial office." % name
	else:
		state.princess = "exiled"
		text += "%s takes the imperial crown and establishes his own dynasty. The throne's mechanism remains, with its dangerous promise of certainty. Aurelia survives in exile abroad." % name
	text += " All twenty-two seats have explicitly recognized the settlement."
	for pilot in companions:
		if pilot.id in ["protagonist", "princess"]: continue
		text += "\n%s ends the campaign with %d pilot experience, %s and %s." % [pilot.name, pilot.xp, "an assigned machine" if not pilot.frame.is_empty() else "a place in the reserve staff", "a recoverable injury" if pilot.injury > 0 else "no lasting injury"]
	for h in politics.houses:
		text += "\nHouse %s: %s recognizes the settlement; %s." % [h.name, h.ruler, "its domain remains under the warband's administration" if h.owner == "player" else "its domain retains local rule"]
	state.epilogue = text
	Quest.record(journal, "civil_war", text)

static func valid(state) -> bool:
	if not state is Dictionary or state.get("version") != 1 or state.get("route") not in ["", "restoration", "dominion"] or state.get("princess") not in ["imprisoned", "restored", "exiled"] or state.get("ending") not in ["", "restoration", "dominion"] or not state.get("epilogue") is String: return false
	for key in ["physician", "bargain_claimed", "elite_defeated", "capital"]:
		if not state.get(key) is bool: return false
	if not Shop.integer(state.get("escape_due"), 0, 1000000000) or not state.get("evidence") is Array: return false
	var seen = []
	for id in state.evidence:
		if id not in ["orders", "testimony", "courier"] or id in seen: return false
		seen.append(id)
	if state.physician != ("testimony" in seen): return false
	if not state.route.is_empty() and seen.size() != 3: return false
	if state.bargain_claimed != (state.route == "dominion"): return false
	if state.route == "dominion" and state.princess == "restored": return false
	if state.princess == "restored" and (state.route != "restoration" or not state.elite_defeated): return false
	if state.princess == "exiled" and state.route != "dominion": return false
	if not state.ending.is_empty() and (state.ending != state.route or not state.capital or state.epilogue.is_empty()): return false
	return true
