# res://Resources/Abilities/refraction_ability.gd
class_name RefractionAbility
extends CardAbility

func _init():
	ability_name = "Refraction"
	description = "On capture, this card generates a random sun spot"
	trigger_condition = TriggerType.ON_CAPTURE

func execute(context: Dictionary) -> bool:
	if not can_execute(context):
		return false
	
	var captured_card = context.get("captured_card")
	var captured_position = context.get("captured_position", -1)
	var game_manager = context.get("game_manager")
	
	print("RefractionAbility: Starting execution for card at position ", captured_position)
	
	if not captured_card or captured_position == -1 or not game_manager:
		print("RefractionAbility: Missing required context data")
		return false
	
	# Prevent double execution in the same turn
	var current_turn = game_manager.get_current_turn_number()
	if captured_card.has_meta("refraction_used_turn") and captured_card.get_meta("refraction_used_turn") == current_turn:
		print("RefractionAbility: Already executed this turn - skipping")
		return false
	
	# Mark as used this turn
	captured_card.set_meta("refraction_used_turn", current_turn)
	
	# Check if sun power is active
	if game_manager.active_deck_power != DeckDefinition.DeckPowerType.SUN_POWER:
		print("RefractionAbility: No sun power active")
		return false
	
	# Check for darkness shroud (which would negate sun effects)
	if game_manager.darkness_shroud_active:
		print("RefractionAbility: Darkness shroud blocks refraction")
		return false
	
	print("☀️ REFRACTION ACTIVATED! Card captured, creating new sun spot...")
	
	# Find all empty slots that are NOT already sunlit
	var empty_slots: Array[int] = []
	for i in range(game_manager.grid_slots.size()):
		if not game_manager.grid_occupied[i] and not i in game_manager.sunlit_positions:
			empty_slots.append(i)
	
	# If no empty slots available, fail silently
	if empty_slots.is_empty():
		print("RefractionAbility: No empty slots available for new sun spot")
		return false
	
	# Randomly select an empty slot for the new sun spot
	var random_index = randi() % empty_slots.size()
	var new_sunlit_position = empty_slots[random_index]
	
	# Add the new position to the sunlit positions array
	game_manager.sunlit_positions.append(new_sunlit_position)
	
	print("RefractionAbility: Created new sun spot at position ", new_sunlit_position)
	print("RefractionAbility: Total sunlit positions now: ", game_manager.sunlit_positions)
	
	# Apply the visual styling to the new sun spot
	game_manager.apply_sunlit_styling(new_sunlit_position)
	
	return true

func can_execute(context: Dictionary) -> bool:
	return true
