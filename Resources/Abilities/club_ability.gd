# res://Resources/Abilities/club_ability.gd
class_name ClubAbility
extends CardAbility

func _init():
	ability_name = "Club"
	description = "On play, a random direction's attack is doubled"
	trigger_condition = TriggerType.ON_PLAY

func execute(context: Dictionary) -> bool:
	if not can_execute(context):
		return false
	
	var placed_card = context.get("placed_card")
	var grid_position = context.get("grid_position", -1)
	var game_manager = context.get("game_manager")
	
	print("ClubAbility: Starting execution for card at position ", grid_position)
	
	if not placed_card or grid_position == -1 or not game_manager:
		print("ClubAbility: Missing required context data")
		return false
	
	# Randomly select a direction (0=North, 1=East, 2=South, 3=West)
	var random_direction = randi() % 4
	var direction_name = get_direction_name(random_direction)
	
	# Get the current value for that direction
	var original_value = placed_card.values[random_direction]
	
	# Double the value
	var doubled_value = original_value * 2
	placed_card.values[random_direction] = doubled_value
	
	print("ClubAbility activated! ", placed_card.card_name, " doubled ", direction_name, " from ", original_value, " to ", doubled_value)
	
	# Update the card display to show the new stat
	var grid_slots = game_manager.grid_slots
	if grid_position < grid_slots.size():
		var slot = grid_slots[grid_position]
		for child in slot.get_children():
			if child is CardDisplay:
				child.card_data = placed_card
				child.update_display()
				print("ClubAbility: Updated CardDisplay to show doubled stat")
				break
	
	return true

func can_execute(context: Dictionary) -> bool:
	return true

func get_direction_name(direction: int) -> String:
	match direction:
		0: return "North"
		1: return "East"
		2: return "South"
		3: return "West"
		_: return "Unknown"
