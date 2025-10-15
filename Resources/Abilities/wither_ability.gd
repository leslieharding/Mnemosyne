# res://Resources/Abilities/wither_ability.gd
class_name WitherAbility
extends CardAbility

func _init():
	ability_name = "Wither"
	description = "Each turn this card's stats are decreased"
	trigger_condition = TriggerType.PASSIVE

func execute(context: Dictionary) -> bool:
	if not can_execute(context):
		return false
	
	var passive_action = context.get("passive_action", "")
	
	# Handle initial placement - just mark the card as placed this turn
	if passive_action == "apply":
		var wither_card = context.get("boosting_card")
		var game_manager = context.get("game_manager")
		
		if wither_card and game_manager:
			# Mark the turn this card was placed
			wither_card.set_meta("wither_placed_turn", game_manager.get_current_turn_number())
			print("WitherAbility: Card placed on turn ", game_manager.get_current_turn_number())
		return true
	
	# Handle removal - clean up metadata
	elif passive_action == "remove":
		var wither_card = context.get("boosting_card")
		if wither_card:
			wither_card.remove_meta("wither_placed_turn")
			print("WitherAbility: Wither metadata cleaned up")
		return true
	
	# Handle turn start - decrease stats
	elif passive_action == "turn_start":
		var wither_card = context.get("boosting_card")
		var wither_position = context.get("boosting_position", -1)
		var game_manager = context.get("game_manager")
		
		if not wither_card or wither_position == -1 or not game_manager:
			print("WitherAbility: Missing required context for turn_start")
			return false
		
		# Check if this card was just placed this turn - if so, skip withering
		var current_turn = game_manager.get_current_turn_number()
		var placed_turn = wither_card.get_meta("wither_placed_turn", -1)
		
		if placed_turn == current_turn:
			print("WitherAbility: Card placed this turn - skipping wither effect")
			return true
		
		print("WitherAbility: Processing wither for ", wither_card.card_name, " at position ", wither_position)
		print("Stats before wither: ", wither_card.values)
		
		# Decrease all stats by 1, minimum 0
		var stats_decreased = false
		for i in range(wither_card.values.size()):
			if wither_card.values[i] > 0:
				wither_card.values[i] -= 1
				stats_decreased = true
		
		print("Stats after wither: ", wither_card.values)
		
		# Update the visual display
		if stats_decreased:
			var slot = game_manager.grid_slots[wither_position]
			for child in slot.get_children():
				if child is CardDisplay:
					child.card_data = wither_card
					child.update_display()
					print("WitherAbility: Updated CardDisplay visual for withered card")
					break
			
			print("Wither activated! ", wither_card.card_name, " lost 1 stat in each direction")
		else:
			print("WitherAbility: All stats already at 0, no change applied")
		
		return true
	
	return false

func can_execute(context: Dictionary) -> bool:
	return true
