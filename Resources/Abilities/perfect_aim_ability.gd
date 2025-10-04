# res://Resources/Abilities/perfect_aim_ability.gd
class_name PerfectAimAbility
extends CardAbility

func _init():
	ability_name = "Perfect Aim"
	description = "Always attacks using its highest stat"
	unlock_level = 0
	trigger_condition = TriggerType.ON_PLAY

func execute(context: Dictionary) -> bool:
	if not can_execute(context):
		return false
	
	var placed_card = context.get("placed_card")
	var grid_position = context.get("grid_position", -1)
	var game_manager = context.get("game_manager")
	
	print("PerfectAimAbility: Starting execution for card at position ", grid_position)
	
	if not placed_card or grid_position == -1 or not game_manager:
		print("PerfectAimAbility: Missing required context data")
		return false
	
	# Set metadata flag to indicate this card uses perfect aim
	placed_card.set_meta("perfect_aim_active", true)
	
	print("Perfect Aim activated! ", placed_card.card_name, " will use its highest stat value for all attacks")
	
	# Store the highest value for easy access during combat
	var highest_value = get_highest_stat_value(placed_card.values)
	placed_card.set_meta("perfect_aim_value", highest_value)
	
	print("Highest stat value: ", highest_value)
	
	return true

func can_execute(context: Dictionary) -> bool:
	return true

# Helper function to get the highest stat value
static func get_highest_stat_value(card_values: Array[int]) -> int:
	var highest_value = card_values[0]
	
	for i in range(1, card_values.size()):
		if card_values[i] > highest_value:
			highest_value = card_values[i]
	
	return highest_value

# Static helper function to check if a card has perfect aim active
static func has_perfect_aim(card: CardResource) -> bool:
	return card.has_meta("perfect_aim_active") and card.get_meta("perfect_aim_active")

# Static helper function to get the perfect aim attack value
static func get_perfect_aim_value(card: CardResource) -> int:
	if has_perfect_aim(card):
		return card.get_meta("perfect_aim_value")
	return 0
