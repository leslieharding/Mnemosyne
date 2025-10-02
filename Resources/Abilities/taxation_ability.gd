# res://Resources/Abilities/taxation_ability.gd
class_name TaxationAbility
extends CardAbility

func _init():
	ability_name = "Taxation"
	description = "On play this card steals +1 from each enemy card"
	trigger_condition = TriggerType.ON_PLAY

func execute(context: Dictionary) -> bool:
	if not can_execute(context):
		return false
	
	var placed_card = context.get("placed_card")
	var grid_position = context.get("grid_position", -1)
	var game_manager = context.get("game_manager")
	
	print("TaxationAbility: Starting execution for card at position ", grid_position)
	
	if not placed_card or grid_position == -1 or not game_manager:
		print("TaxationAbility: Missing required context data")
		return false
	
	var taxation_owner = game_manager.get_owner_at_position(grid_position)
	var enemy_owner = game_manager.Owner.OPPONENT if taxation_owner == game_manager.Owner.PLAYER else game_manager.Owner.PLAYER
	
	# Find all enemy cards on the board
	var enemy_positions = []
	for i in range(game_manager.grid_occupied.size()):
		if game_manager.grid_occupied[i]:
			var card_owner = game_manager.get_owner_at_position(i)
			if card_owner == enemy_owner:
				enemy_positions.append(i)
	
	if enemy_positions.is_empty():
		print("TaxationAbility: No enemy cards found on board")
		return false
	
	print("TaxationAbility: Found ", enemy_positions.size(), " enemy cards to tax")
	
	var total_enemies_taxed = 0
	
	# Steal 1 from all directions of each enemy card
	for enemy_pos in enemy_positions:
		var enemy_card = game_manager.get_card_at_position(enemy_pos)
		if enemy_card:
			print("TaxationAbility: Taxing ", enemy_card.card_name, " at position ", enemy_pos)
			print("  Stats before taxation: ", enemy_card.values)
			
			# Remove 1 from each direction
			for i in range(enemy_card.values.size()):
				if enemy_card.values[i] > 0:
					enemy_card.values[i] -= 1
			
			print("  Stats after taxation: ", enemy_card.values)
			total_enemies_taxed += 1
			
			# Update the visual display for the taxed card
			var enemy_slot = game_manager.grid_slots[enemy_pos]
			for child in enemy_slot.get_children():
				if child is CardDisplay:
					child.card_data = enemy_card
					child.update_display()
					print("TaxationAbility: Updated CardDisplay visual for taxed card at position ", enemy_pos)
					break
	
	# Add stolen stats to taxation card (+X to all directions, where X = number of enemies)
	if total_enemies_taxed > 0:
		print("TaxationAbility: Adding stolen stats to taxation card")
		print("  Stats before gaining: ", placed_card.values)
		
		for i in range(placed_card.values.size()):
			placed_card.values[i] += total_enemies_taxed
		
		print("  Stats after gaining: ", placed_card.values)
		print(ability_name, " activated! ", placed_card.card_name, " taxed ", total_enemies_taxed, " enemy cards and gained +", total_enemies_taxed, " to all stats!")
		
		# Update the visual display for the taxation card
		var taxation_slot = game_manager.grid_slots[grid_position]
		for child in taxation_slot.get_children():
			if child is CardDisplay:
				child.card_data = placed_card
				child.update_display()
				print("TaxationAbility: Updated CardDisplay visual for taxation card at position ", grid_position)
				break
		
		return true
	
	return false

func can_execute(context: Dictionary) -> bool:
	return true
