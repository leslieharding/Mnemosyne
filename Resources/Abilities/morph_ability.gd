# res://Resources/Abilities/morph_ability.gd
class_name MorphAbility
extends CardAbility

func _init():
	ability_name = "Morph"
	description = "Rotate this cards stats every turn."
	trigger_condition = TriggerType.PASSIVE

func execute(context: Dictionary) -> bool:
	if not can_execute(context):
		return false
	
	var action = context.get("passive_action", "")
	var morphing_card = context.get("boosting_card")
	var morphing_position = context.get("boosting_position", -1)
	var game_manager = context.get("game_manager")
	
	print("MorphAbility: Action = ", action, " for card at position ", morphing_position)
	
	if not morphing_card or morphing_position == -1 or not game_manager:
		print("MorphAbility: Missing required context data")
		return false
	
	match action:
		"apply":
			return apply_morph(morphing_position, morphing_card, game_manager)
		"remove":
			return remove_morph(morphing_position, morphing_card, game_manager)
		"turn_start":
			return process_morph_turn(morphing_position, morphing_card, game_manager)
		_:
			print("MorphAbility: Unknown action: ", action)
			return false

func apply_morph(position: int, card: CardResource, game_manager) -> bool:
	print("Morph started for ", card.card_name, " at position ", position)
	
	# Mark this card as having morph active (works for both owners)
	card.set_meta("morph_active", true)
	print("Morph activated for card owned by ", game_manager.get_owner_name(game_manager.get_owner_at_position(position)))
	
	return true

func remove_morph(position: int, card: CardResource, game_manager) -> bool:
	print("Morph removed for ", card.card_name, " at position ", position)
	
	# Clean up metadata
	card.remove_meta("morph_active")
	
	return true

func process_morph_turn(position: int, card: CardResource, game_manager) -> bool:
	print("Processing Morph turn for ", card.card_name, " at position ", position)
	
	# Check if morph is still active
	if not card.has_meta("morph_active") or not card.get_meta("morph_active"):
		print("MorphAbility: Morph not active for this card")
		return false
	
	# Store original values for logging
	var original_north = card.values[0]
	var original_east = card.values[1]
	var original_south = card.values[2]
	var original_west = card.values[3]
	
	print("MorphAbility: Original stats - N:", original_north, " E:", original_east, " S:", original_south, " W:", original_west)
	
	# Perform the rotation: North→East, East→South, South→West, West→North
	card.values[0] = original_west   # North becomes West (West goes to North)
	card.values[1] = original_north  # East becomes North (North goes to East)
	card.values[2] = original_east   # South becomes East (East goes to South)
	card.values[3] = original_south  # West becomes South (South goes to West)
	
	print("MorphAbility: Rotated stats - N:", card.values[0], " E:", card.values[1], " S:", card.values[2], " W:", card.values[3])
	print("MorphAbility: ", card.card_name, "'s stats rotated! (N→E, E→S, S→W, W→N)")
	
	# Update the visual display using the same pattern as other abilities
	var slot = game_manager.grid_slots[position]
	for child in slot.get_children():
		if child is CardDisplay:
			child.card_data = card  # Update the card data reference
			child.update_display()  # Refresh the visual display
			print("MorphAbility: Updated CardDisplay visual for rotated card")
			break
	
	return true

func can_execute(context: Dictionary) -> bool:
	return true
