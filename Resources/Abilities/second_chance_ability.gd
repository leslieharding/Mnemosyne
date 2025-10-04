# res://Resources/Abilities/second_chance_ability.gd
class_name SecondChanceAbility
extends CardAbility

func _init():
	ability_name = "Second Chance"
	description = "The first time this battle this card is captured return it to your hand"
	trigger_condition = TriggerType.ON_CAPTURE

func execute(context: Dictionary) -> bool:
	if not can_execute(context):
		return false
	
	var captured_card = context.get("captured_card")
	var captured_position = context.get("captured_position", -1)
	var game_manager = context.get("game_manager")
	
	print("SecondChanceAbility: Starting execution for captured card at position ", captured_position)
	
	# Safety checks
	if not captured_card:
		print("SecondChanceAbility: No captured card provided")
		return false
	
	if captured_position == -1:
		print("SecondChanceAbility: Invalid captured position")
		return false
	
	if not game_manager:
		print("SecondChanceAbility: No game manager provided")
		return false
	
	# Additional safety check - verify captured_card is a valid CardResource
	if not is_instance_valid(captured_card):
		print("SecondChanceAbility: captured_card is not a valid instance")
		return false
	
	# Check if this ability has already been used this battle
	if captured_card.has_meta("second_chance_used") and captured_card.get_meta("second_chance_used"):
		print("SecondChanceAbility: Already used this battle - no effect")
		return false
	
	# Mark ability as used for this battle
	captured_card.set_meta("second_chance_used", true)
	
	print("SecondChanceAbility activated! ", captured_card.card_name, " returns to hand!")
	
	# Determine which owner's hand to return to based on ownership BEFORE capture
	var original_owner = game_manager.get_owner_at_position(captured_position)
	
	# Return card to appropriate hand
	if original_owner == game_manager.Owner.PLAYER:
		return_card_to_player_hand(captured_card, captured_position, game_manager)
	elif original_owner == game_manager.Owner.OPPONENT:
		return_card_to_opponent_hand(captured_card, captured_position, game_manager)
	else:
		print("SecondChanceAbility: Invalid owner - cannot return card")
		return false
	
	# Clear the board position
	game_manager.grid_occupied[captured_position] = false
	game_manager.grid_ownership[captured_position] = game_manager.Owner.NONE
	game_manager.grid_card_data[captured_position] = null
	
	# Remove card display from slot
	var slot = game_manager.grid_slots[captured_position]
	for child in slot.get_children():
		if child is CardDisplay:
			child.queue_free()
			break
	
	# Remove from grid tracking
	game_manager.grid_to_collection_index.erase(captured_position)
	
	# Update visuals
	game_manager.update_board_visuals()
	
	# Set a flag to indicate that Second Chance prevented this capture
	game_manager.set_meta("second_chance_prevented_" + str(captured_position), true)
	
	return true

func return_card_to_player_hand(card: CardResource, position: int, game_manager) -> void:
	print("SecondChanceAbility: Returning card to player hand")
	
	# Get the card's collection index from the grid tracking
	var card_collection_index = game_manager.get_card_collection_index(position)
	
	if card_collection_index == -1:
		print("SecondChanceAbility: Warning - could not find collection index for card")
		card_collection_index = 0  # Default fallback
	
	# Add card back to player's deck array
	game_manager.player_deck.append(card)
	game_manager.deck_card_indices.append(card_collection_index)
	
	# Redisplay hand
	game_manager.display_player_hand()
	
	print("SecondChanceAbility: Card successfully returned to player hand")

func return_card_to_opponent_hand(card: CardResource, position: int, game_manager) -> void:
	print("SecondChanceAbility: Returning card to opponent hand")
	
	# Get opponent manager
	var opponent_manager = game_manager.opponent_manager
	if not opponent_manager:
		print("SecondChanceAbility: No opponent manager found")
		return
	
	# Add card back to opponent's deck
	opponent_manager.opponent_deck.append(card)
	
	print("SecondChanceAbility: Card successfully returned to opponent hand")

func can_execute(context: Dictionary) -> bool:
	var captured_card = context.get("captured_card")
	if not captured_card:
		return false
	
	# Additional safety check
	if not is_instance_valid(captured_card):
		return false
	
	# Can only execute if second chance hasn't been used yet
	return not (captured_card.has_meta("second_chance_used") and captured_card.get_meta("second_chance_used"))
