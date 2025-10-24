# res://Resources/Abilities/sun_dance_ability.gd
class_name SunDanceAbility
extends CardAbility

func _init():
	ability_name = "Sun Dance"
	description = "If this card is played in a sun spot, it creates another in a random empty slot"
	trigger_condition = TriggerType.ON_PLAY

func execute(context: Dictionary) -> bool:
	if not can_execute(context):
		return false
	
	# Get the card that was just placed
	var placed_card = context.get("placed_card")
	var grid_position = context.get("grid_position", -1)
	var game_manager = context.get("game_manager")
	
	print("SunDanceAbility: Starting execution for card at position ", grid_position)
	
	if not placed_card or grid_position == -1 or not game_manager:
		print("SunDanceAbility: Missing required context data")
		return false
	
	# Check if sun power is active
	if game_manager.active_deck_power != DeckDefinition.DeckPowerType.SUN_POWER:
		print("SunDanceAbility: No sun power active")
		return false
	
	# Check for darkness shroud (which would negate sun effects)
	if game_manager.darkness_shroud_active:
		print("SunDanceAbility: Darkness shroud blocks sun dance")
		return false
	
	# Check if this position is sunlit
	if not grid_position in game_manager.sunlit_positions:
		print("SunDanceAbility: Card not placed in a sun spot, ability does not trigger")
		return false
	
	print("☀️ SUN DANCE ACTIVATED! Card placed in sun spot, creating new sun spot...")
	
	# Find all empty slots that are NOT already sunlit
	var empty_slots: Array[int] = []
	for i in range(game_manager.grid_slots.size()):
		if not game_manager.grid_occupied[i] and not i in game_manager.sunlit_positions:
			empty_slots.append(i)
	
	# If no empty slots available, fail silently
	if empty_slots.is_empty():
		print("SunDanceAbility: No empty slots available for new sun spot")
		return false
	
	# Randomly select an empty slot for the new sun spot
	var random_index = randi() % empty_slots.size()
	var new_sunlit_position = empty_slots[random_index]
	
	# Add the new position to the sunlit positions array
	game_manager.sunlit_positions.append(new_sunlit_position)
	
	print("SunDanceAbility: Created new sun spot at position ", new_sunlit_position)
	print("SunDanceAbility: Total sunlit positions now: ", game_manager.sunlit_positions)
	
	# Apply the visual styling to the new sun spot
	game_manager.apply_sunlit_styling(new_sunlit_position)
	
	return true

func can_execute(context: Dictionary) -> bool:
	return true
