# res://Resources/Abilities/charybdis_ability.gd
class_name CharybdisAbility
extends CardAbility

func _init():
	ability_name = "Whirlpool"
	description = "On play, destroys a random card from the player's hand, then destroys itself"
	trigger_condition = TriggerType.ON_PLAY

func execute(context: Dictionary) -> bool:
	if not can_execute(context):
		return false
	
	var placed_card = context.get("placed_card")
	var grid_position = context.get("grid_position", -1)
	var game_manager = context.get("game_manager")
	
	print("CharybdisAbility: Starting execution for card at position ", grid_position)
	
	if not placed_card or grid_position == -1 or not game_manager:
		print("CharybdisAbility: Missing required context data")
		return false
	
	print("CharybdisAbility activated! The whirlpool opens...")
	
	# STEP 1: Destroy a random card from player's hand
	if game_manager.player_deck.size() > 0:
		# Pick a random card from player's hand
		var random_index = randi() % game_manager.player_deck.size()
		var destroyed_card = game_manager.player_deck[random_index]
		
		print("CharybdisAbility: Whirlpool swallows ", destroyed_card.card_name, " from player's hand!")
		
		# Remove the card from hand
		game_manager.remove_card_from_hand(random_index)
		
		print("CharybdisAbility: ", destroyed_card.card_name, " has been destroyed!")
	else:
		print("CharybdisAbility: Player has no cards in hand - whirlpool finds nothing to destroy")
	
	# STEP 2: Destroy itself (remove Charybdis from the board)
	print("CharybdisAbility: The whirlpool collapses - Charybdis destroys itself")
	
	# Remove from board
	game_manager.grid_occupied[grid_position] = false
	game_manager.grid_ownership[grid_position] = game_manager.Owner.NONE
	game_manager.grid_card_data[grid_position] = null
	
	# Remove card display
	var slot = game_manager.grid_slots[grid_position]
	for child in slot.get_children():
		if child is CardDisplay:
			child.queue_free()
			print("CharybdisAbility: Removed Charybdis visual from grid position ", grid_position)
			break
	
	# Remove from tracking
	game_manager.grid_to_collection_index.erase(grid_position)
	if grid_position in game_manager.active_passive_abilities:
		game_manager.active_passive_abilities.erase(grid_position)
	
	# Update board visuals
	game_manager.update_board_visuals()
	
	print("CharybdisAbility: Complete - hand card destroyed, Charybdis removed from board, slot is now empty")
	
	return true

func can_execute(context: Dictionary) -> bool:
	return true
