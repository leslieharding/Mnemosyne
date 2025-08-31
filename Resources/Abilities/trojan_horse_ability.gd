# res://Resources/Abilities/trojan_horse_ability.gd
class_name TrojanHorseAbility
extends CardAbility

func _init():
	ability_name = "Trojan Horse"
	description = "Choose a slot to deploy a trojan horse."
	trigger_condition = TriggerType.ON_PLAY

func execute(context: Dictionary) -> bool:
	if not can_execute(context):
		return false
	
	# Get the card that was just placed
	var placed_card = context.get("placed_card")
	var grid_position = context.get("grid_position", -1)
	var game_manager = context.get("game_manager")
	
	print("TrojanHorseAbility: Starting execution for card at position ", grid_position)
	
	if not placed_card or grid_position == -1 or not game_manager:
		print("TrojanHorseAbility: Missing required context data")
		return false
	
	# Check for empty slots first (edge case handling)
	var has_empty_slots = false
	for i in range(game_manager.grid_slots.size()):
		if not game_manager.grid_occupied[i]:
			has_empty_slots = true
			break
	
	if not has_empty_slots:
		print("TrojanHorseAbility: No empty slots available - skipping slot selection phase")
		return false
	
	# Get the owner of the card that played the ability
	var ability_owner = game_manager.get_owner_at_position(grid_position)
	
	# Only allow player to use this ability (as specified)
	if ability_owner != game_manager.Owner.PLAYER:
		print("TrojanHorseAbility: Only player can use this ability")
		return false
	
	print("TrojanHorseAbility activated! ", placed_card.card_name, " can now deploy a trojan horse")
	
	# Enable trojan horse deployment mode in the game manager
	game_manager.start_trojan_horse_mode(grid_position, ability_owner, placed_card)
	
	return true

func can_execute(context: Dictionary) -> bool:
	return true
