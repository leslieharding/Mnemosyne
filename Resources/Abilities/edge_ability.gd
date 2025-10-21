# res://Resources/Abilities/edge_ability.gd
class_name EdgeAbility
extends CardAbility

func _init():
	ability_name = "Edge"
	description = "This card has double effectiveness attacking cards on non-corner board edges"
	trigger_condition = TriggerType.ON_PLAY

func execute(context: Dictionary) -> bool:
	if not can_execute(context):
		return false
	
	var placed_card = context.get("placed_card")
	var grid_position = context.get("grid_position", -1)
	var game_manager = context.get("game_manager")
	
	print("EdgeAbility: Starting execution for card at position ", grid_position)
	
	if not placed_card or grid_position == -1 or not game_manager:
		print("EdgeAbility: Missing required context data")
		return false
	
	# Set metadata flag to indicate this card has edge ability active
	placed_card.set_meta("edge_active", true)
	
	print("EdgeAbility activated! ", placed_card.card_name, " will have double effectiveness against edge slots (1, 3, 5, 7)")
	
	return true

func can_execute(context: Dictionary) -> bool:
	return true

# Static helper function to check if a card has edge ability active
static func has_edge_active(card: CardResource) -> bool:
	if not card:
		return false
	return card.has_meta("edge_active") and card.get_meta("edge_active")

# Static helper function to check if a position is a non-corner edge slot
static func is_edge_slot(position: int) -> bool:
	# Edge slots are: 1 (top center), 3 (left middle), 5 (right middle), 7 (bottom center)
	return position == 1 or position == 3 or position == 5 or position == 7

# Static helper function to get the edge-boosted attack value
static func get_edge_attack_value(base_attack_value: int, defender_position: int) -> int:
	if is_edge_slot(defender_position):
		var doubled_value = base_attack_value * 2
		print("EdgeAbility: Doubling attack from ", base_attack_value, " to ", doubled_value, " against edge slot ", defender_position)
		return doubled_value
	return base_attack_value
