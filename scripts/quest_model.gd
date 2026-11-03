extends RefCounted
## Persistent authored objectives. Claims record outcomes without replaying rewards.
const CAMP = [5, 3]
const HQ = [4, 1]
const APPEARANCES = ["Valcrest sun", "Valcrest sword", "Valcrest tower"]
const DEFINITIONS = {
	"defense": {"title": "A debt to Greyford", "required": true, "requires": [], "objective": "Defend Greyford beside its temporary militia.", "reward": "40 gold, 1 trust and free essential repairs"},
	"camp": {"title": "Break the raiders", "required": true, "requires": ["defense"], "objective": "Clear the bandit camp southeast of Greyford (column 7, row 4). Defeat is retryable.", "reward": "30 gold, 2 trust; recurring camp raids cease"},
	"permission": {"title": "Permission to raise a banner", "required": true, "requires": ["camp"], "objective": "Ask Greyford's council for the abandoned watchhouse. Requires camp cleared and 3 trust.", "reward": "Headquarters permission; no fee"},
	"headquarters": {"title": "A banner without a country", "required": true, "requires": ["permission"], "objective": "Enter the watchhouse north of Greyford (column 5, row 2) and found your warband.", "reward": "Headquarters, shared reserves, 1 trust and one formal sword formation"},
	"delivery": {"title": "Grain for Millhaven", "required": false, "requires": ["defense"], "objective": "Accept a guild contract and deliver two carried grain to Millhaven.", "reward": "16 gold and 1 trust per completed contract"},
	"rescue": {"title": "The stranded merchant", "required": false, "requires": ["defense"], "objective": "At Stonebridge, volunteer to rescue the merchant on the eastern road. Available after camp clearance too.", "reward": "24 gold and merchant access"},
	"support": {"title": "An envoy under threat", "required": false, "requires": ["defense"], "objective": "Accept Asterfell's protection contract at Stonebridge, then defend the envoy.", "reward": "20 gold, 1 trust and 5 Asterfell opinion once"},
	"tournament": {"title": "The Stonebridge lists", "required": false, "requires": ["defense"], "objective": "Enter a solo mech duel at Stonebridge. Entry 5 gold; first victory earns 25 gold.", "reward": "25 gold once"},
	"investigation": {"title": "The emperor's sealed orders", "required": true, "requires": ["headquarters"], "objective": "Read the preserved orders at Millhaven, hear the physician at Stonebridge, then intercept Voss's courier at Emberwatch.", "reward": "Protected evidence; access to the three-house bargain"},
	"bargain": {"title": "The price of a crown", "required": true, "requires": ["investigation"], "objective": "Meet Rothmar, Vaust and Merrow's envoys at headquarters. Review the permanent choice before committing.", "reward": "Restoration or dominion, permanently"},
	"civil_war": {"title": "Settle the twenty-two seats", "required": true, "requires": ["bargain"], "objective": "Secure explicit sovereign recognition through coalition agreements, submission or conquest; then face Lucien.", "reward": "One of the two canon endings"}
}

static func defaults(defended: bool = false) -> Dictionary:
	return {"version": 1, "identity": {"name": "Alaric", "appearance": 0}, "claims": ["defense"] if defended else [], "outcomes": {"defense": "Greyford defended; prior reward retained."} if defended else {}, "formal_id": ""}

static func claimed(state: Dictionary, id: String) -> bool:
	return id in state.claims

static func record(state: Dictionary, id: String, outcome: String) -> bool:
	if claimed(state, id): return false
	state.claims.append(id)
	state.outcomes[id] = outcome
	return true

static func status(state: Dictionary, id: String) -> String:
	if claimed(state, id): return "Complete"
	for prerequisite in DEFINITIONS[id].requires:
		if not claimed(state, prerequisite): return "Locked"
	return "Available"

static func valid(state) -> bool:
	if not state is Dictionary or state.get("version") != 1: return false
	if not state.get("identity") is Dictionary or not state.identity.get("name") is String: return false
	var name = state.identity.name
	if name.strip_edges().is_empty() or name.length() > 28 or "\n" in name or "\r" in name: return false
	var Shop = load("res://scripts/workshop_model.gd")
	if not Shop.integer(state.identity.get("appearance"), 0, APPEARANCES.size() - 1): return false
	if not state.get("claims") is Array or not state.get("outcomes") is Dictionary or not state.get("formal_id") is String: return false
	var seen = []
	for id in state.claims:
		if id not in DEFINITIONS or id in seen or not state.outcomes.get(id) is String: return false
		for prerequisite in DEFINITIONS[id].requires:
			if prerequisite not in state.claims: return false
		seen.append(id)
	if state.outcomes.size() != seen.size(): return false
	return state.formal_id.is_empty() == (not claimed(state, "headquarters"))
