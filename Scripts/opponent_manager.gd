# res://Scripts/opponent_manager.gd
extends Node
class_name OpponentManager

signal opponent_card_placed(grid_index: int)

# Opponent's deck - for now always the same, but structured for future variation
var opponent_deck: Array[CardResource] = []
var opponent_name: String = "Apollo's Shadow"

# AI decision making
var think_time_min: float = 1.0
var think_time_max: float = 2.5

func _ready():
	setup_default_opponent()

# Set up the default opponent with a fixed deck
func setup_default_opponent():
	# Load Apollo collection and use the first deck as opponent's deck
	var apollo_collection: GodCardCollection = load("res://Resources/Collections/Apollo.tres")
	if apollo_collection:
		# For now, opponent always uses "The Sun" deck (index 0)
		opponent_deck = apollo_collection.get_deck(0)
		print("Opponent deck loaded: ", opponent_deck.size(), " cards")
	else:
		push_error("Failed to load opponent deck!")

# Future method for setting different opponent types
func setup_opponent(opponent_type: String):
	match opponent_type:
		"basic":
			setup_default_opponent()
		"advanced":
			# Future: load different deck or AI behavior
			setup_default_opponent()
		_:
			setup_default_opponent()

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
		
		# Remove the first card from opponent's hand
		var played_card = opponent_deck[0]
		opponent_deck.remove_at(0)
		
		print("Opponent plays: ", played_card.card_name, " at slot ", chosen_slot)
		
		# Emit signal with the chosen slot
		emit_signal("opponent_card_placed", chosen_slot)
	else:
		print("No available slots for opponent!")

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
		"cards_remaining": opponent_deck.size()
	}
