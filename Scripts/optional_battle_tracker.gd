# res://Scripts/optional_battle_tracker.gd
extends Node
class_name OptionalBattleTracker

# Maps battle_id to its configuration.
# battle_id format: "GodName_DeckName_EnemyName"
const OPTIONAL_BATTLE_DEFINITIONS: Dictionary = {
	"Apollo_The Sun_Cultists of Nyx": {
		"god": "Apollo",
		"deck": "The Sun",
		"enemy_name": "Cultists of Nyx",
		"enemy_difficulty": 2,
		"display_name": "Cultists of Nyx",
		"reward_description": "The sun's blessing intensifies",
	},
	"Apollo_Natural Harmonics_The Wrong Note": {
		"god": "Apollo",
		"deck": "Natural Harmonics",
		"enemy_name": "The Wrong Note",
		"enemy_difficulty": 2,
		"display_name": "The Wrong Note",
		"reward_description": "The rhythm no longer breaks when a beat is missed",
	},
	"Artemis_The Hunt_Acteon": {
		"god": "Artemis",
		"deck": "The Hunt",
		"enemy_name": "The Hunting Party",
		"enemy_difficulty": 2,
		"display_name": "The Hunting Party",
		"reward_description": "Placeholder: Acteon reward not yet implemented",
	},
	"Hermes_Tricksters_Argus Panoptes": {
		"god": "Hermes",
		"deck": "Tricksters",
		"enemy_name": "Argus Panoptes",
		"enemy_difficulty": 2,
		"display_name": "Argus Panoptes",
		"reward_description": "Placeholder: Argus Panoptes reward not yet implemented",
	},
	"Demeter_Natures Bounty_Erysichthon": {
		"god": "Hermes",
		"deck": "Natures Bounty",
		"enemy_name": "Erysichthon",
		"enemy_difficulty": 2,
		"display_name": "Erysichthon",
		"reward_description": "Placeholder: Erysichthon reward not yet implemented",
	},
}

# Per-run state — resets each new run
var optional_battle_active: bool = false
var optional_battle_attempted_this_run: bool = false
var current_run_god: String = ""
var current_run_deck: String = ""

func _ready():
	pass

# === RUN LIFECYCLE ===

func start_new_run(god_name: String, deck_name: String):
	optional_battle_active = false
	optional_battle_attempted_this_run = false
	current_run_god = god_name
	current_run_deck = deck_name
	print("OptionalBattleTracker: New run started - God: ", god_name, " Deck: ", deck_name)
	print("OptionalBattleTracker: Optional battle for this run: ", get_current_run_battle_id())

func reset_run_state():
	optional_battle_active = false
	optional_battle_attempted_this_run = false
	current_run_god = ""
	current_run_deck = ""
	print("OptionalBattleTracker: Run state reset")

# === BATTLE ID HELPERS ===

func get_battle_id(god_name: String, deck_name: String) -> String:
	for battle_id in OPTIONAL_BATTLE_DEFINITIONS:
		var def = OPTIONAL_BATTLE_DEFINITIONS[battle_id]
		if def["god"] == god_name and def["deck"] == deck_name:
			return battle_id
	return ""

func get_current_run_battle_id() -> String:
	return get_battle_id(current_run_god, current_run_deck)

# === AVAILABILITY ===

func has_optional_battle_this_run() -> bool:
	var battle_id = get_current_run_battle_id()
	if battle_id == "":
		return false
	return not is_permanently_won(battle_id)

func is_optional_node_accessible() -> bool:
	return optional_battle_active and not optional_battle_attempted_this_run

func notify_two_battles_completed():
	if not optional_battle_active and has_optional_battle_this_run():
		optional_battle_active = true
		print("OptionalBattleTracker: Optional battle is now active (2 battles completed)")

func mark_attempted():
	optional_battle_attempted_this_run = true
	print("OptionalBattleTracker: Optional battle marked as attempted this run")

# === WIN RECORDING & REWARDS ===

func record_win(battle_id: String):
	if is_permanently_won(battle_id):
		print("OptionalBattleTracker: Battle ", battle_id, " already won - skipping")
		return
	var progress_tracker = get_node_or_null("/root/GlobalProgressTrackerAutoload")
	if not progress_tracker:
		print("OptionalBattleTracker: ERROR - GlobalProgressTrackerAutoload not found!")
		return
	progress_tracker.add_optional_battle_win(battle_id)
	print("OptionalBattleTracker: Win recorded for ", battle_id)
	apply_reward(battle_id)

func record_current_run_win():
	var battle_id = get_current_run_battle_id()
	if battle_id != "":
		record_win(battle_id)

# === REWARD APPLICATION ===

func apply_reward(battle_id: String):
	print("OptionalBattleTracker: Applying reward for ", battle_id)
	match battle_id:
		"Apollo_The Sun_Cultists of Nyx":
			_apply_sun_bonus()
		"Apollo_Natural Harmonics_The Wrong Note":
			_apply_wrong_note_bonus()
		"Artemis_The Hunting Party_Acteon":
			_apply_acteon_bonus()
		"Hermes_Argus Panoptes_Argus Panoptes":
			_apply_argus_bonus()
		_:
			print("OptionalBattleTracker: WARNING - No reward handler for: ", battle_id)

func _apply_sun_bonus():
	print("OptionalBattleTracker: Sun bonus applied - sunlit cards will now grant +2 instead of +1")

func _apply_wrong_note_bonus():
	print("OptionalBattleTracker: Wrong Note bonus applied - rhythm boost no longer resets when a beat is missed")

func _apply_acteon_bonus():
	print("OptionalBattleTracker: Acteon bonus - PLACEHOLDER - not yet implemented")

func _apply_argus_bonus():
	print("OptionalBattleTracker: Argus Panoptes bonus - PLACEHOLDER - not yet implemented")

# === PERSISTENT WIN QUERIES ===

func is_permanently_won(battle_id: String) -> bool:
	var progress_tracker = get_node_or_null("/root/GlobalProgressTrackerAutoload")
	if not progress_tracker:
		return false
	return progress_tracker.is_optional_battle_won(battle_id)

func is_current_run_battle_won() -> bool:
	return is_permanently_won(get_current_run_battle_id())

# === ENEMY POOL HELPERS ===

func get_optional_enemy_name(god_name: String, deck_name: String) -> String:
	var battle_id = get_battle_id(god_name, deck_name)
	if battle_id == "":
		return ""
	return OPTIONAL_BATTLE_DEFINITIONS[battle_id].get("enemy_name", "")

func should_exclude_from_regular_pool(enemy_name: String, god_name: String, deck_name: String) -> bool:
	var battle_id = get_battle_id(god_name, deck_name)
	if battle_id == "":
		return false
	var def = OPTIONAL_BATTLE_DEFINITIONS[battle_id]
	if def.get("enemy_name", "") != enemy_name:
		return false
	return not is_permanently_won(battle_id)

# === SAVE/RESTORE ===

func get_run_save_data() -> Dictionary:
	return {
		"optional_battle_active": optional_battle_active,
		"optional_battle_attempted_this_run": optional_battle_attempted_this_run,
		"current_run_god": current_run_god,
		"current_run_deck": current_run_deck,
	}

func restore_from_save_data(data: Dictionary):
	optional_battle_active = data.get("optional_battle_active", false)
	optional_battle_attempted_this_run = data.get("optional_battle_attempted_this_run", false)
	current_run_god = data.get("current_run_god", "")
	current_run_deck = data.get("current_run_deck", "")
	print("OptionalBattleTracker: Restored - active: ", optional_battle_active,
		" attempted: ", optional_battle_attempted_this_run,
		" god: ", current_run_god, " deck: ", current_run_deck)
