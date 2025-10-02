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

# Get the current deck definition
func get_current_deck_definition() -> EnemyDeckDefinition:
	return current_deck_definition

# Setup fallback opponent if loading fails
func setup_fallback_opponent():
	print("Using fallback opponent (Apollo deck)")
	current_deck_definition = null  # No special powers for fallback
	
	var apollo_collection: GodCardCollection = load("res://Resources/Collections/Apollo.tres")
	if apollo_collection:
		opponent_deck = apollo_collection.get_deck(0)
		opponent_name = "Apollo's Shadow"
		opponent_description = "A reflection of divine power"
	else:
		push_error("Failed to load fallback opponent deck!")

# Take opponent's turn with improved AI
func take_turn(available_slots: Array[int]):
	if opponent_deck.is_empty():
		print("Opponent has no cards left!")
		return
	
	print("Opponent is thinking...")
	
	# Add thinking delay for more natural feel
	var think_time = randf_range(think_time_min, think_time_max)
	await get_tree().create_timer(think_time).timeout
	
	# AI Decision: Evaluate all card-slot combinations
	var best_move = evaluate_best_move(available_slots)
	
	if best_move:
		var chosen_card_index = best_move["card_index"]
		var chosen_slot = best_move["slot"]
		
		# Store the card before removing it
		last_played_card = opponent_deck[chosen_card_index]
		
		# Remove the card from the deck
		opponent_deck.remove_at(chosen_card_index)
		
		print("AI Decision: Playing ", last_played_card.card_name, " at slot ", chosen_slot, 
			  " (Score: ", best_move["score"], ", Captures: ", best_move["captures"], ")")
		
		# Emit signal with the chosen slot
		emit_signal("opponent_card_placed", chosen_slot)
	else:
		print("No valid move found - falling back to random")
		# Fallback: random card and slot
		var chosen_slot = available_slots[randi() % available_slots.size()]
		last_played_card = opponent_deck[0]
		opponent_deck.remove_at(0)
		emit_signal("opponent_card_placed", chosen_slot)

# Evaluate all possible moves and return the best one
func evaluate_best_move(available_slots: Array[int]) -> Dictionary:
	if not game_manager:
		print("AI Error: No game manager reference")
		return {}
	
	var best_move = null
	var best_score = -999999
	
	# Evaluate each card in hand
	for card_idx in range(opponent_deck.size()):
		var card = opponent_deck[card_idx]
		
		# Evaluate each available slot for this card
		for slot in available_slots:
			var move_evaluation = evaluate_move(card, slot)
			
			# Track the best move
			if move_evaluation["score"] > best_score:
				best_score = move_evaluation["score"]
				best_move = {
					"card_index": card_idx,
					"slot": slot,
					"score": move_evaluation["score"],
					"captures": move_evaluation["captures"]
				}
	
	return best_move

# Evaluate a specific card-slot combination
func evaluate_move(card: CardResource, slot: int) -> Dictionary:
	var score = 0
	var capture_count = 0
	
	# Get card stats (assuming level 1 for enemies, adjust if needed)
	var card_values = card.values
	
	# Calculate potential captures
	var adjacent_positions = get_adjacent_positions(slot)
	
	for adj_info in adjacent_positions:
		var adj_slot = adj_info["position"]
		var direction = adj_info["direction"]  # 0=North, 1=East, 2=South, 3=West
		
		# Check if adjacent slot has a player card
		if game_manager.grid_occupied[adj_slot]:
			var adj_owner = game_manager.get_owner_at_position(adj_slot)
			
			# Only consider player-owned cards as capture targets
			if adj_owner == game_manager.Owner.PLAYER:
				var adj_card = game_manager.get_card_at_position(adj_slot)
				if adj_card:
					# Get the opposing direction value for the adjacent card
					var opposing_direction = get_opposing_direction(direction)
					var adj_value = adj_card.values[opposing_direction]
					var our_value = card_values[direction]
					
					# Check if we can capture
					if our_value > adj_value:
						capture_count += 1
						# Score heavily for captures (50 points per capture)
						score += 50
						
						# Bonus for capturing high-value cards
						var card_total_stats = adj_card.values[0] + adj_card.values[1] + adj_card.values[2] + adj_card.values[3]
						score += card_total_stats * 2
	
	# If no captures, evaluate defensive positioning
	if capture_count == 0:
		score += evaluate_defensive_position(card, slot, adjacent_positions)
	
	return {
		"score": score,
		"captures": capture_count
	}

# Evaluate how defensively sound a position is
func evaluate_defensive_position(card: CardResource, slot: int, adjacent_positions: Array) -> int:
	var defensive_score = 0
	var card_values = card.values
	
	# Prefer corners and edges (fewer attack angles)
	var empty_adjacent_count = 0
	var player_threat_count = 0
	
	for adj_info in adjacent_positions:
		var adj_slot = adj_info["position"]
		var direction = adj_info["direction"]
		
		if not game_manager.grid_occupied[adj_slot]:
			# Empty adjacent slot = safer
			empty_adjacent_count += 1
			defensive_score += 5
		else:
			var adj_owner = game_manager.get_owner_at_position(adj_slot)
			
			if adj_owner == game_manager.Owner.PLAYER:
				# Player card adjacent = potential threat
				var adj_card = game_manager.get_card_at_position(adj_slot)
				if adj_card:
					var opposing_direction = get_opposing_direction(direction)
					var adj_value = adj_card.values[opposing_direction]
					var our_value = card_values[direction]
					
					# If player can capture us, penalty
					if adj_value >= our_value:
						player_threat_count += 1
						defensive_score -= 20
					else:
						# We're safe from this adjacent card
						defensive_score += 10
	
	# Bonus for corner positions (only 2 adjacent)
	if adjacent_positions.size() == 2:
		defensive_score += 15
	# Bonus for edge positions (3 adjacent)
	elif adjacent_positions.size() == 3:
		defensive_score += 10
	
	# Consider card strength when playing defensively
	var total_card_strength = card_values[0] + card_values[1] + card_values[2] + card_values[3]
	defensive_score += total_card_strength / 4  # Small bonus for stronger cards
	
	return defensive_score

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
