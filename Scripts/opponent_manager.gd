# res://Scripts/opponent_manager.gd
extends Node
class_name OpponentManager

signal opponent_card_placed(grid_index: int)

# Opponent's deck and info
var opponent_deck: Array[CardResource] = []
var opponent_name: String = "Unknown Enemy"
var opponent_description: String = ""
var last_played_card: CardResource = null

# AI decision making
var think_time_min: float = 1.0
var think_time_max: float = 2.5

# Enemy collection reference
var enemies_collection: EnemiesCollection

var current_deck_definition: EnemyDeckDefinition = null

# Reference to game manager for board state analysis
var game_manager = null
var turn_number: int = 0
var current_ai_profile: Dictionary = {}

var default_ai_profile: Dictionary = {
	"error_rate": 0.25,
	"error_multiplier": 1.5,
	"capture_weight": 50,
	"capture_value_bonus_weight": 1,
	"exposure_penalty_weight": 5,
	"shelter_bonus": 5,
	"efficient_capture_bonus": 20,
	"card_priorities": {},
	"card_order": [],
	"card_order_bonus": 200,
}

var ai_profiles: Dictionary = {
	"Pythons Gang": {
		"error_rate": 0.4,
		"error_multiplier": 1.5,
		"capture_weight": 55,
		"capture_value_bonus_weight": 1,
		"exposure_penalty_weight": 7,
		"shelter_bonus": 6,
		"efficient_capture_bonus": 25,
		"card_priorities": {
			"The Omphalos": {"score_bonus": 60, "max_turn": 4, "preferred_slots": [4], "slot_bonus": 80},
			"Python":  {"score_bonus": 70, "max_turn": 2},
			"Ladon": {"min_turn": 2, "too_early_penalty": -300},
		},
		"card_order": [],
		"card_order_bonus": 200,
	},
	"Niobes Brood": {
		"error_rate": 0.3,
		"error_multiplier": 1.5,
		"capture_weight": 55,
		"capture_value_bonus_weight": 1,
		"exposure_penalty_weight": 7,
		"shelter_bonus": 6,
		"efficient_capture_bonus": 25,
		"card_priorities": {
		},
		"card_order": [],
		"card_order_bonus": 200,
	},
	"Cultists of Nyx": {
		"error_rate": 0.3,
		"error_multiplier": 1.2,
		"capture_weight": 55,
		"capture_value_bonus_weight": 1,
		"exposure_penalty_weight": 7,
		"shelter_bonus": 6,
		"efficient_capture_bonus": 25,
		"card_priorities": {
			"Erebus":  {"score_bonus": 70, "max_turn": 2},
		},
		"card_order": [],
		"card_order_bonus": 200,
	},
	"The Wrong Note": {
		"error_rate": 0.3,
		"error_multiplier": 1.2,
		"capture_weight": 55,
		"capture_value_bonus_weight": 1,
		"exposure_penalty_weight": 7,
		"shelter_bonus": 6,
		"efficient_capture_bonus": 25,
		"card_priorities": {
			"Python":  {"score_bonus": 70, "max_turn": 2},
		},
		"card_order": [],
		"card_order_bonus": 200,
	},
	"The Plague": {
		"error_rate": 0.3,
		"error_multiplier": 1.5,
		"capture_weight": 50,
		"capture_value_bonus_weight": 1,
		"exposure_penalty_weight": 7,
		"shelter_bonus": 6,
		"efficient_capture_bonus": 25,
		"card_priorities": {
			"Nosos":  {"score_bonus": 70, "max_turn": 3},
			"Limos":  {"score_bonus": 60, "max_turn": 3},
		},
		"card_order": [],
		"card_order_bonus": 200,
	},
	"Chronos": {
		"error_rate": 0.2,
		"error_multiplier": 1.2,
		"capture_weight": 65,
		"capture_value_bonus_weight": 1,
		"exposure_penalty_weight": 7,
		"shelter_bonus": 6,
		"efficient_capture_bonus": 25,
		"card_priorities": {
			"Atlas":  {"score_bonus": 70, "max_turn": 2},
		},
		"card_order": [],
		"card_order_bonus": 200,
	},
	"?????": {
		"error_rate": 0.2,
		"error_multiplier": 1.2,
		"capture_weight": 60,
		"capture_value_bonus_weight": 1,
		"exposure_penalty_weight": 7,
		"shelter_bonus": 6,
		"efficient_capture_bonus": 25,
		"card_priorities": {
			"Fárbauti":  {"score_bonus": 70, "max_turn": 2},
			"Sigyn":  {"score_bonus": 60, "max_turn": 3},
		},
		"card_order": [],
		"card_order_bonus": 200,
	},
	"Hermes Boss": {
		"error_rate": 0.2,
		"error_multiplier": 1.2,
		"capture_weight": 45,
		"capture_value_bonus_weight": 1,
		"exposure_penalty_weight": 7,
		"shelter_bonus": 6,
		"efficient_capture_bonus": 25,
		"card_priorities": {
			"Ratatoskr":  {"score_bonus": 80, "max_turn": 1},
			"Útgarða-Loki":  {"score_bonus": 80, "max_turn": 2},
			"Skrymir":  {"score_bonus": 80, "max_turn": 2},
		},
		"card_order": [],
		"card_order_bonus": 200,
	},
	"Fimbulwinter": {
		"error_rate": 0.2,
		"error_multiplier": 1.2,
		"capture_weight": 70,
		"capture_value_bonus_weight": 1,
		"exposure_penalty_weight": 7,
		"shelter_bonus": 6,
		"efficient_capture_bonus": 25,
		"card_priorities": {
			"Python":  {"score_bonus": 70, "max_turn": 2},
		},
		"card_order": [],
		"card_order_bonus": 200,
	},
	"Artemis Boss": {
		"error_rate": 0.2,
		"error_multiplier": 1.2,
		"capture_weight": 55,
		"capture_value_bonus_weight": 1,
		"exposure_penalty_weight": 7,
		"shelter_bonus": 6,
		"efficient_capture_bonus": 25,
		"card_priorities": {
			"Garmr":  {"score_bonus": 70, "max_turn": 2},
			"Hati":  {"score_bonus": 60, "max_turn": 3},
		},
		"card_order": [],
		"card_order_bonus": 200,
	},
	"Craftsmen": {
		"error_rate": 0.3,
		"error_multiplier": 1.5,
		"capture_weight": 55,
		"capture_value_bonus_weight": 1,
		"exposure_penalty_weight": 7,
		"shelter_bonus": 6,
		"efficient_capture_bonus": 25,
		"card_priorities": {
			"Icarus":  {"min_turn": 2, "too_early_penalty": -500},
			"Daedalus":  {"score_bonus": 30, "max_turn": 2},
		},
		"card_order": [],
		"card_order_bonus": 200,
	},
	"Giants": {
		"error_rate": 0.3,
		"error_multiplier": 1.5,
		"capture_weight": 55,
		"capture_value_bonus_weight": 1,
		"exposure_penalty_weight": 7,
		"shelter_bonus": 6,
		"efficient_capture_bonus": 25,
		"card_priorities": {
			"Typhon":  {"score_bonus": 70, "max_turn": 1},
		},
		"card_order": [],
		"card_order_bonus": 200,
	},
	"Bestial Labours": {
		"error_rate": 0.3,
		"error_multiplier": 1.5,
		"capture_weight": 55,
		"capture_value_bonus_weight": 1,
		"exposure_penalty_weight": 7,
		"shelter_bonus": 6,
		"efficient_capture_bonus": 25,
		"card_priorities": {
			"Stymphalian Birds":  {"score_bonus": 80, "max_turn": 2},
			"Ceryneian Hind":  {"score_bonus": 50, "max_turn": 4},
			"Nemian Lion":  {"score_bonus": 70, "max_turn": 2},
		},
		"card_order": [],
		"card_order_bonus": 200,
	},
	"Creature Foes of Heracles": {
		"error_rate": 0.3,
		"error_multiplier": 1.5,
		"capture_weight": 55,
		"capture_value_bonus_weight": 1,
		"exposure_penalty_weight": 7,
		"shelter_bonus": 6,
		"efficient_capture_bonus": 25,
		"card_priorities": {
			"Nessus":  {"score_bonus": 70, "max_turn": 1},
			"Orthrus":  {"score_bonus": 50, "max_turn": 3},
			"Antaeus":  {"score_bonus": 50, "max_turn": 3, "preferred_slots": [6,7,8], "slot_bonus": 80},
		},
		"card_order": [],
		"card_order_bonus": 200,
	},
	"The Grudges": {
		"error_rate": 0.3,
		"error_multiplier": 1.5,
		"capture_weight": 55,
		"capture_value_bonus_weight": 1,
		"exposure_penalty_weight": 7,
		"shelter_bonus": 6,
		"efficient_capture_bonus": 25,
		"card_priorities": {
			"Laomedon":  {"score_bonus": 70, "max_turn": 2},
		},
		"card_order": [],
		"card_order_bonus": 200,
	},
	"Sleep": {
		"error_rate": 0.3,
		"error_multiplier": 1.5,
		"capture_weight": 50,
		"capture_value_bonus_weight": 1,
		"exposure_penalty_weight": 7,
		"shelter_bonus": 6,
		"efficient_capture_bonus": 25,
		"card_priorities": {
			"Phobetor":  {"score_bonus": 20, "max_turn": 4},
			"Hypnos":  {"score_bonus": 60, "max_turn": 2},
		},
		"card_order": [],
		"card_order_bonus": 200,
	},
	"Amazons": {
		"error_rate": 0.3,
		"error_multiplier": 1.5,
		"capture_weight": 55,
		"capture_value_bonus_weight": 1,
		"exposure_penalty_weight": 7,
		"shelter_bonus": 6,
		"efficient_capture_bonus": 25,
		"card_priorities": {
			"Python":  {"score_bonus": 70, "max_turn": 2},
		},
		"card_order": [],
		"card_order_bonus": 200,
	},
	"The Graeae": {
		"error_rate": 0.2,
		"error_multiplier": 1.5,
		"capture_weight": 55,
		"capture_value_bonus_weight": 1,
		"exposure_penalty_weight": 7,
		"shelter_bonus": 6,
		"efficient_capture_bonus": 25,
		"card_priorities": {
			"Pamphredo":  {"score_bonus": 1000, "max_turn": 1},
			"Deino":  {"score_bonus": 900, "max_turn": 2},
			"Enyo":  {"score_bonus": 800, "max_turn": 3},
		},
		"card_order": [],
		"card_order_bonus": 200,
	},
	"Rogue Love": {
		"error_rate": 0.2,
		"error_multiplier": 1.5,
		"capture_weight": 55,
		"capture_value_bonus_weight": 1,
		"exposure_penalty_weight": 7,
		"shelter_bonus": 6,
		"efficient_capture_bonus": 25,
		"card_priorities": {
			"Python":  {"score_bonus": 70, "max_turn": 2},
		},
		"card_order": [],
		"card_order_bonus": 200,
	},
	"Pandora's box": {
		"error_rate": 0.3,
		"error_multiplier": 1.5,
		"capture_weight": 50,
		"capture_value_bonus_weight": 1,
		"exposure_penalty_weight": 7,
		"shelter_bonus": 6,
		"efficient_capture_bonus": 25,
		"card_priorities": {
			"Phobos":  {"score_bonus": 70, "max_turn": 2},
			"Ponos":  {"score_bonus": 80, "max_turn": 2},
		},
		"card_order": [],
		"card_order_bonus": 200,
	},
	"So beautiful it hurts": {
		"error_rate": 0.3,
		"error_multiplier": 1.5,
		"capture_weight": 55,
		"capture_value_bonus_weight": 1,
		"exposure_penalty_weight": 7,
		"shelter_bonus": 6,
		"efficient_capture_bonus": 25,
		"card_priorities": {
			"Narcissus":  {"score_bonus": 70, "max_turn": 2},
		},
		"card_order": [],
		"card_order_bonus": 200,
	},
	"Crete": {
		"error_rate": 0.3,
		"error_multiplier": 1.5,
		"capture_weight": 55,
		"capture_value_bonus_weight": 1,
		"exposure_penalty_weight": 7,
		"shelter_bonus": 6,
		"efficient_capture_bonus": 25,
		"card_priorities": {
			"Ariadne":  {"score_bonus": 70, "max_turn": 3},
			"Cretan Bull":  {"score_bonus": 90, "max_turn": 2},
		},
		"card_order": [],
		"card_order_bonus": 200,
	},
	"The Hunting Party": {
		"error_rate": 0.3,
		"error_multiplier": 1.5,
		"capture_weight": 55,
		"capture_value_bonus_weight": 1,
		"exposure_penalty_weight": 7,
		"shelter_bonus": 6,
		"efficient_capture_bonus": 25,
		"card_priorities": {
			"Python":  {"score_bonus": 70, "max_turn": 2},
		},
		"card_order": [],
		"card_order_bonus": 200,
	},
	"The Way Home": {
		"error_rate": 0.3,
		"error_multiplier": 1.5,
		"capture_weight": 55,
		"capture_value_bonus_weight": 1,
		"exposure_penalty_weight": 7,
		"shelter_bonus": 6,
		"efficient_capture_bonus": 25,
		"card_priorities": {
			"Charybdis":  {"score_bonus": 1000, "max_turn": 1},
		},
		"card_order": [],
		"card_order_bonus": 200,
	},
	"Isthmus Road": {
		"error_rate": 0.3,
		"error_multiplier": 1.5,
		"capture_weight": 55,
		"capture_value_bonus_weight": 1,
		"exposure_penalty_weight": 7,
		"shelter_bonus": 6,
		"efficient_capture_bonus": 25,
		"card_priorities": {
			"Sinus":  {"score_bonus": 70, "max_turn": 2},
		},
		"card_order": [],
		"card_order_bonus": 200,
	},
	"Wicked Kings": {
		"error_rate": 0.3,
		"error_multiplier": 1.5,
		"capture_weight": 55,
		"capture_value_bonus_weight": 1,
		"exposure_penalty_weight": 7,
		"shelter_bonus": 6,
		"efficient_capture_bonus": 25,
		"card_priorities": {
			"Sisyphus":  {"score_bonus": 60, "max_turn": 4},
			"Tantalus":  {"score_bonus": 80, "max_turn": 2},
		},
		"card_order": [],
		"card_order_bonus": 200,
	},
	}

func _ready():
	load_enemies_collection()

# Load the enemies collection
func load_enemies_collection():
	enemies_collection = load("res://Resources/Collections/Enemies.tres")
	if not enemies_collection:
		push_error("Failed to load enemies collection!")

# Set reference to game manager
func set_game_manager(manager):
	game_manager = manager
	print("OpponentManager: Game manager reference set")

# Setup opponent (main function called by battle manager)
func setup_opponent(enemy_name: String, difficulty: int = 0):
	print("OpponentManager: Setting up opponent: ", enemy_name, " with difficulty ", difficulty)
	
	if not enemies_collection:
		load_enemies_collection()
		if not enemies_collection:
			print("OpponentManager: Failed to load enemies collection")
			setup_fallback_opponent()
			return
	
	print("OpponentManager: Enemies collection loaded, available enemies: ", enemies_collection.get_enemy_names())
	
	# Get the enemy collection for this enemy type
	var enemy_collection = enemies_collection.get_enemy(enemy_name)
	if not enemy_collection:
		print("Warning: Enemy '", enemy_name, "' not found")
		setup_fallback_opponent()
		return
	
	# Get the deck definition (this contains the power info)
	current_deck_definition = enemy_collection.get_deck_definition_by_difficulty(difficulty)
	if not current_deck_definition:
		print("Warning: No deck definition found for enemy '", enemy_name, "' with difficulty ", difficulty)
		setup_fallback_opponent()
		return
	
	# Get the opponent deck
	opponent_deck = enemies_collection.get_enemy_deck(enemy_name, difficulty)
	
	print("OpponentManager: Got deck with ", opponent_deck.size(), " cards")
	
	if opponent_deck.is_empty():
		print("Warning: No deck found for enemy '", enemy_name, "' with difficulty ", difficulty)
		setup_fallback_opponent()
		return
	
	# Debug: Print all cards in the deck
	for i in range(opponent_deck.size()):
		print("OpponentManager: Deck card ", i, ": ", opponent_deck[i].card_name if opponent_deck[i] else "NULL")
	
	# Get enemy info for display
	var enemy_info = enemies_collection.get_enemy_info(enemy_name, difficulty)
	if enemy_info.has("enemy_name"):
		opponent_name = enemy_info["deck_name"] + " (" + enemy_info["enemy_name"] + ")"
		opponent_description = enemy_info["deck_description"]
	else:
		opponent_name = enemy_name
		opponent_description = "A mysterious opponent"
	
	print("OpponentManager: Opponent loaded: ", opponent_name, " with ", opponent_deck.size(), " cards")
	
	# Debug deck power info
	if current_deck_definition.deck_power_type != EnemyDeckDefinition.EnemyDeckPowerType.NONE:
		print("OpponentManager: Deck has power: ", current_deck_definition.get_power_description())
	else:
		print("OpponentManager: Deck has no special power")
		
	current_ai_profile = ai_profiles.get(enemy_name, default_ai_profile)
	turn_number = 0
	print("OpponentManager: AI profile loaded for '", enemy_name,
		"' | error_rate: ", current_ai_profile.get("error_rate", 0.25),
		" | card_order: ", current_ai_profile.get("card_order", []))	

# Get the current deck definition
func get_current_deck_definition() -> EnemyDeckDefinition:
	return current_deck_definition

# Setup fallback opponent if loading fails
func setup_fallback_opponent():
	print("Using fallback opponent (Apollo deck)")
	current_ai_profile = default_ai_profile
	turn_number = 0
	current_deck_definition = null  # No special powers for fallback
	
	var apollo_collection: GodCardCollection = load("res://Resources/Collections/Apollo.tres")
	if apollo_collection:
		opponent_deck = apollo_collection.get_deck(0)
		opponent_name = "Apollo's Shadow"
		opponent_description = "A reflection of divine power"
	else:
		push_error("Failed to load fallback opponent deck!")

func take_turn(available_slots: Array[int]):
	if opponent_deck.is_empty():
		print("Opponent has no cards left!")
		return

	turn_number += 1
	print("Opponent is thinking... (turn ", turn_number, ")")

	var think_time = randf_range(think_time_min, think_time_max)
	await get_tree().create_timer(think_time).timeout

	# Card order enforcement — runs before everything, immune to error rate
	var ordered_move = check_card_order(available_slots)
	if not ordered_move.is_empty():
		execute_move(ordered_move)
		return

	# Score all combinations then select via error rate cascade
	var ranked_moves = evaluate_best_move(available_slots)

	if ranked_moves.is_empty():
		print("No valid move found — falling back to random")
		var chosen_slot = available_slots[randi() % available_slots.size()]
		last_played_card = opponent_deck[0]
		opponent_deck.remove_at(0)
		emit_signal("opponent_card_placed", chosen_slot)
		return

	var chosen_move = select_move_with_error(ranked_moves)
	execute_move(chosen_move)

func execute_move(move: Dictionary):
	var chosen_card_index = move["card_index"]
	var chosen_slot = move["slot"]
	last_played_card = opponent_deck[chosen_card_index]
	opponent_deck.remove_at(chosen_card_index)
	print("AI Decision: Playing '", last_played_card.card_name, "' at slot ", chosen_slot,
		" | Score: ", move["score"],
		" | Captures: ", move.get("captures", 0))
	emit_signal("opponent_card_placed", chosen_slot)

func check_card_order(available_slots: Array[int]) -> Dictionary:
	var card_order: Array = current_ai_profile.get("card_order", [])
	if card_order.is_empty():
		return {}

	for ordered_card_name in card_order:
		for card_idx in range(opponent_deck.size()):
			if opponent_deck[card_idx].card_name == ordered_card_name:
				# Found — pick best slot for it using full scoring
				var card = opponent_deck[card_idx]
				var best_slot = -1
				var best_score = -999999
				for slot in available_slots:
					var eval = evaluate_move(card, slot)
					if eval["score"] > best_score:
						best_score = eval["score"]
						best_slot = slot
				if best_slot != -1:
					print("AI: Card order enforcing '", ordered_card_name, "' at slot ", best_slot)
					return {
						"card_index": card_idx,
						"slot": best_slot,
						"score": best_score,
						"captures": 0,
					}

	return {}

func evaluate_best_move(available_slots: Array[int]) -> Array:
	if not game_manager:
		print("AI Error: No game manager reference")
		return []

	var all_moves: Array = []

	for card_idx in range(opponent_deck.size()):
		var card = opponent_deck[card_idx]
		for slot in available_slots:
			var eval = evaluate_move(card, slot)
			all_moves.append({
				"card_index": card_idx,
				"slot": slot,
				"score": eval["score"],
				"captures": eval["captures"],
				"defensive_alignment": eval["defensive_alignment"],
			})

	# Post-pass: bonus for the most efficiently positioned capturer at each slot
	apply_efficient_capture_bonus(all_moves, available_slots)

	# Sort highest score first
	all_moves.sort_custom(func(a, b): return a["score"] > b["score"])

	return all_moves

func evaluate_move(card: CardResource, slot: int) -> Dictionary:
	var profile = current_ai_profile
	var card_values = card.values
	var capture_weight: int = profile.get("capture_weight", 50)
	var capture_value_bonus_weight: int = profile.get("capture_value_bonus_weight", 1)

	# Capture scoring
	var capture_score = 0
	var capture_count = 0
	var adjacent_positions = get_adjacent_positions(slot)

	for adj_info in adjacent_positions:
		var adj_slot = adj_info["position"]
		var direction = adj_info["direction"]

		if game_manager.grid_occupied[adj_slot]:
			var adj_owner = game_manager.get_owner_at_position(adj_slot)
			if adj_owner == game_manager.Owner.PLAYER:
				var adj_card = game_manager.get_card_at_position(adj_slot)
				if adj_card:
					var opposing_dir = get_opposing_direction(direction)
					var adj_value = adj_card.values[opposing_dir]
					var our_value = card_values[direction]
					if our_value > adj_value:
						capture_count += 1
						capture_score += capture_weight
						var target_total = adj_card.values[0] + adj_card.values[1] \
							+ adj_card.values[2] + adj_card.values[3]
						capture_score += target_total * capture_value_bonus_weight

	# Defensive alignment — always contributes, not just when no captures exist
	var defensive_alignment = get_defensive_alignment_score(card, slot)

	# Card priority bonus
	var priority_bonus = 0
	var card_priorities: Dictionary = profile.get("card_priorities", {})
	if card.card_name in card_priorities:
		var priority = card_priorities[card.card_name]
		var min_turn: int = priority.get("min_turn", 0)
		var max_turn: int = priority.get("max_turn", 0)
		if min_turn > 0 and turn_number < min_turn:
			priority_bonus = priority.get("too_early_penalty", -500)
		elif max_turn == 0 or turn_number <= max_turn:
			priority_bonus = priority.get("score_bonus", 0)
		
		var preferred_slots: Array = priority.get("preferred_slots", [])
		if preferred_slots.size() > 0 and slot in preferred_slots:
			priority_bonus += priority.get("slot_bonus", 0)

	return {
		"score": capture_score + defensive_alignment + priority_bonus,
		"captures": capture_count,
		"defensive_alignment": defensive_alignment,
	}

func get_defensive_alignment_score(card: CardResource, slot: int) -> int:
	var profile = current_ai_profile
	var exposure_weight: int = profile.get("exposure_penalty_weight", 5)
	var shelter: int = profile.get("shelter_bonus", 5)
	var card_values = card.values
	var grid_size = 3
	var score = 0

	var row = slot / grid_size
	var col = slot % grid_size

	var direction_checks = [
		{"stat_idx": 0, "in_bounds": row > 0,             "adj": slot - grid_size},  # North
		{"stat_idx": 1, "in_bounds": col < grid_size - 1, "adj": slot + 1},           # East
		{"stat_idx": 2, "in_bounds": row < grid_size - 1, "adj": slot + grid_size},   # South
		{"stat_idx": 3, "in_bounds": col > 0,             "adj": slot - 1},            # West
	]

	for d in direction_checks:
		var stat: int = min(card_values[d["stat_idx"]], 10)
		if not d["in_bounds"]:
			score += shelter                          # Board edge — fully sheltered
		elif game_manager.grid_occupied[d["adj"]]:
			score += shelter                          # Occupied neighbour — sheltered
		else:
			score -= exposure_weight * (10 - stat)   # Empty — penalise weak stat here

	return score

func apply_efficient_capture_bonus(all_moves: Array, available_slots: Array[int]):
	var bonus: int = current_ai_profile.get("efficient_capture_bonus", 20)
	if bonus == 0:
		return

	for slot in available_slots:
		var capturing_at_slot: Array = []
		for move in all_moves:
			if move["slot"] == slot and move["captures"] > 0:
				capturing_at_slot.append(move)

		if capturing_at_slot.is_empty():
			continue

		var best = capturing_at_slot[0]
		for move in capturing_at_slot:
			if move["defensive_alignment"] > best["defensive_alignment"]:
				best = move

		best["score"] += bonus

func select_move_with_error(ranked_moves: Array) -> Dictionary:
	if ranked_moves.size() == 1:
		return ranked_moves[0]

	var error_rate: float = current_ai_profile.get("error_rate", 0.0)
	var multiplier: float = current_ai_profile.get("error_multiplier", 1.5)

	var try_count = min(3, ranked_moves.size() - 1)
	var current_error = error_rate

	for attempt in range(try_count):
		if randf() >= current_error:
			print("AI: Error cascade — playing rank ", attempt + 1,
				" (skip chance was %.2f)" % current_error)
			return ranked_moves[attempt]
		print("AI: Error cascade — skipped rank ", attempt + 1,
			" (skip chance was %.2f)" % current_error)
		current_error *= multiplier

	var fallback_idx = min(3, ranked_moves.size() - 1)
	print("AI: Error cascade — guaranteed fallback at rank ", fallback_idx + 1)
	return ranked_moves[fallback_idx]

# Get adjacent grid positions for a given slot
func get_adjacent_positions(slot: int) -> Array:
	var grid_size = 3  # Assuming 3x3 grid
	var adjacent = []
	
	var row = slot / grid_size
	var col = slot % grid_size
	
	# North (direction 0)
	if row > 0:
		adjacent.append({"position": slot - grid_size, "direction": 0})
	
	# East (direction 1)
	if col < grid_size - 1:
		adjacent.append({"position": slot + 1, "direction": 1})
	
	# South (direction 2)
	if row < grid_size - 1:
		adjacent.append({"position": slot + grid_size, "direction": 2})
	
	# West (direction 3)
	if col > 0:
		adjacent.append({"position": slot - 1, "direction": 3})
	
	return adjacent

# Get the opposing direction (for comparing card values)
func get_opposing_direction(direction: int) -> int:
	match direction:
		0: return 2  # North <-> South
		1: return 3  # East <-> West
		2: return 0  # South <-> North
		3: return 1  # West <-> East
	return 0

# Get the last card that was played by the opponent
func get_last_played_card() -> CardResource:
	return last_played_card

# Get remaining cards count
func get_remaining_cards() -> int:
	return opponent_deck.size()

# Check if opponent has cards left
func has_cards() -> bool:
	return opponent_deck.size() > 0

# Get opponent info for UI display
func get_opponent_info() -> Dictionary:
	return {
		"name": opponent_name,
		"description": opponent_description,
		"cards_remaining": opponent_deck.size()
	}
