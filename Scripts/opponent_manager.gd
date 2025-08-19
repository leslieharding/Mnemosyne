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


func _ready():
	load_enemies_collection()

# Load the enemies collection
func load_enemies_collection():
	enemies_collection = load("res://Resources/Collections/Enemies.tres")
	if not enemies_collection:
		push_error("Failed to load enemies collection!")

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

# Add this new function to get the current deck definition
func get_current_deck_definition() -> EnemyDeckDefinition:
	return current_deck_definition

# Update the setup_fallback_opponent function to clear deck definition
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

# Take opponent's turn
func take_turn(available_slots: Array[int]):
	if opponent_deck.is_empty():
		print("Opponent has no cards left!")
		return
	
	print("Opponent is thinking...")
	
	# Add thinking delay for more natural feel
	var think_time = randf_range(think_time_min, think_time_max)
	await get_tree().create_timer(think_time).timeout
	
	# Simple AI: pick a random available slot
	if available_slots.size() > 0:
		var chosen_slot = available_slots[randi() % available_slots.size()]
		
		# Store the card before removing it so we can track what was played
		last_played_card = opponent_deck[0]
		
		# Remove the first card from opponent's hand
		opponent_deck.remove_at(0)
		
		print("Opponent plays: ", last_played_card.card_name, " at slot ", chosen_slot)
		
		# Emit signal with the chosen slot
		emit_signal("opponent_card_placed", chosen_slot)
	else:
		print("No available slots for opponent!")

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
