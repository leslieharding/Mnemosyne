# res://Resources/Abilities/hunt_ability.gd
class_name HuntAbility
extends CardAbility

func _init():
	ability_name = "Hunt"
	description = "After placement, select a slot to hunt. Forces combat using your highest stat vs their lowest stat."
	trigger_condition = TriggerType.ON_PLAY

func execute(context: Dictionary) -> bool:
	if not can_execute(context):
		return false
	
	# Get the card that was just placed
	var placed_card = context.get("placed_card")
	var grid_position = context.get("grid_position", -1)
	var game_manager = context.get("game_manager")
	
	print("HuntAbility: Starting execution for card at position ", grid_position)
	
	if not placed_card or grid_position == -1 or not game_manager:
		print("HuntAbility: Missing required context data")
		return false
	
	# Get the owner of the hunting card
	var hunter_owner = game_manager.get_owner_at_position(grid_position)
	
	print("HuntAbility activated! ", placed_card.card_name, " can now hunt a target slot")
	
	# Enable hunt mode in the game manager
	game_manager.start_hunt_mode(grid_position, hunter_owner, placed_card)
	
	return true

func can_execute(context: Dictionary) -> bool:
	return true

# Helper function to find highest stat value and its index
static func get_highest_stat(card_values: Array[int]) -> Dictionary:
	var highest_value = card_values[0]
	var highest_index = 0
	
	for i in range(1, card_values.size()):
		if card_values[i] > highest_value:
			highest_value = card_values[i]
			highest_index = i
	
	return {"value": highest_value, "index": highest_index}

# Helper function to find lowest stat value and its index
static func get_lowest_stat(card_values: Array[int]) -> Dictionary:
	var lowest_value = card_values[0]
	var lowest_index = 0
	
	for i in range(1, card_values.size()):
		if card_values[i] < lowest_value:
			lowest_value = card_values[i]
			lowest_index = i
	
	return {"value": lowest_value, "index": lowest_index}
