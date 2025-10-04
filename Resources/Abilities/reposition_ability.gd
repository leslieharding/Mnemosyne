# res://Resources/Abilities/reposition_ability.gd
class_name RepositionAbility
extends CardAbility

func _init():
	ability_name = "Reposition"
	description = "This card trades places with its attacker when captured"
	trigger_condition = TriggerType.ON_CAPTURE

func execute(context: Dictionary) -> bool:
	if not can_execute(context):
		return false
	
	var captured_card = context.get("captured_card")
	var captured_position = context.get("captured_position", -1)
	var capturing_card = context.get("capturing_card")
	var capturing_position = context.get("capturing_position", -1)
	var game_manager = context.get("game_manager")
	
	print("RepositionAbility: Starting execution")
	print("  Captured card: ", captured_card.card_name if captured_card else "NULL", " at position ", captured_position)
	print("  Capturing card: ", capturing_card.card_name if capturing_card else "NULL", " at position ", capturing_position)
	
	# Validation
	if not captured_card or not capturing_card:
		print("RepositionAbility: Missing card data")
		return false
	
	if captured_position == -1 or capturing_position == -1:
		print("RepositionAbility: Invalid positions")
		return false
	
	if not game_manager:
		print("RepositionAbility: No game manager provided")
		return false
	
	# Swap the two cards' positions
	swap_card_positions(captured_position, capturing_position, captured_card, capturing_card, game_manager)
	
	print("RepositionAbility: Successfully swapped positions between ", captured_card.card_name, " and ", capturing_card.card_name)
	
	return true

func swap_card_positions(pos_a: int, pos_b: int, card_a: CardResource, card_b: CardResource, game_manager):
	"""Swap two cards' positions on the grid, including all data structures and visuals"""
	
	print("RepositionAbility: Swapping positions ", pos_a, " and ", pos_b)
	
	# Get both card displays
	var display_a = game_manager.get_card_display_at_position(pos_a)
	var display_b = game_manager.get_card_display_at_position(pos_b)
	
	# Get owners before swap
	var owner_a = game_manager.grid_ownership[pos_a]
	var owner_b = game_manager.grid_ownership[pos_b]
	
	# Get collection indices if they exist
	var collection_a = game_manager.grid_to_collection_index.get(pos_a, -1)
	var collection_b = game_manager.grid_to_collection_index.get(pos_b, -1)
	
	# Get slots
	var slot_a = game_manager.grid_slots[pos_a]
	var slot_b = game_manager.grid_slots[pos_b]
	
	# Swap visual displays
	if display_a and is_instance_valid(display_a):
		slot_a.remove_child(display_a)
		slot_b.add_child(display_a)
	
	if display_b and is_instance_valid(display_b):
		slot_b.remove_child(display_b)
		slot_a.add_child(display_b)
	
	# Swap data structures
	# Position A gets card B's data
	game_manager.grid_card_data[pos_a] = card_b
	game_manager.grid_ownership[pos_a] = owner_b
	
	# Position B gets card A's data
	game_manager.grid_card_data[pos_b] = card_a
	game_manager.grid_ownership[pos_b] = owner_a
	
	# Swap collection indices
	if collection_a != -1:
		game_manager.grid_to_collection_index[pos_b] = collection_a
	else:
		game_manager.grid_to_collection_index.erase(pos_b)
	
	if collection_b != -1:
		game_manager.grid_to_collection_index[pos_a] = collection_b
	else:
		game_manager.grid_to_collection_index.erase(pos_a)
	
	# Update visual styling for both slots
	if owner_b == game_manager.Owner.PLAYER:
		slot_a.add_theme_stylebox_override("panel", game_manager.player_card_style)
	else:
		slot_a.add_theme_stylebox_override("panel", game_manager.opponent_card_style)
	
	if owner_a == game_manager.Owner.PLAYER:
		slot_b.add_theme_stylebox_override("panel", game_manager.player_card_style)
	else:
		slot_b.add_theme_stylebox_override("panel", game_manager.opponent_card_style)
	
	print("RepositionAbility: Position swap complete")

func can_execute(context: Dictionary) -> bool:
	return true
