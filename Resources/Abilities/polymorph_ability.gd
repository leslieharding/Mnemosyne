# res://Resources/Abilities/polymorph_ability.gd
class_name PolymorphAbility
extends CardAbility

func _init():
	ability_name = "Polymorph"
	description = "On play this card changes your opponent's strongest minion into a sheep for 2 turns"
	trigger_condition = TriggerType.ON_PLAY

func execute(context: Dictionary) -> bool:
	if not can_execute(context):
		return false
	
	var placed_card = context.get("placed_card")
	var grid_position = context.get("grid_position", -1)
	var game_manager = context.get("game_manager")
	var placing_owner = context.get("placing_owner")
	
	print("PolymorphAbility: Starting execution for card at position ", grid_position)
	
	if not placed_card or grid_position == -1 or not game_manager:
		print("PolymorphAbility: Missing required context data")
		return false
	
	# Determine opponent owner
	var opponent_owner = game_manager.Owner.OPPONENT if placing_owner == game_manager.Owner.PLAYER else game_manager.Owner.PLAYER
	
	# Find opponent's strongest card (highest sum of stats)
	var target_position = -1
	var highest_stat_sum = -1
	
	for i in range(game_manager.grid_occupied.size()):
		if game_manager.grid_occupied[i] and game_manager.grid_ownership[i] == opponent_owner:
			var card_at_pos = game_manager.get_card_at_position(i)
			if card_at_pos:
				var stat_sum = card_at_pos.values[0] + card_at_pos.values[1] + card_at_pos.values[2] + card_at_pos.values[3]
				if stat_sum > highest_stat_sum:
					highest_stat_sum = stat_sum
					target_position = i
	
	# No valid targets found
	if target_position == -1:
		print("PolymorphAbility: No opponent cards found to polymorph")
		return false
	
	var target_card = game_manager.get_card_at_position(target_position)
	print("PolymorphAbility: Targeting ", target_card.card_name, " at position ", target_position, " with stat sum ", highest_stat_sum)
	
	# Store original stats
	var original_stats = target_card.values.duplicate()
	target_card.set_meta("polymorph_original_stats", original_stats)
	target_card.set_meta("polymorph_active", true)
	target_card.set_meta("polymorph_turns_remaining", 8)
	
	# Reduce stats to sheep stats (1,1,1,1)
	target_card.values[0] = 1
	target_card.values[1] = 1
	target_card.values[2] = 1
	target_card.values[3] = 1
	
	print("PolymorphAbility: ", target_card.card_name, " transformed! Stats changed from ", original_stats, " to [1,1,1,1]")
	
	# Update visual display
	var slot = game_manager.grid_slots[target_position]
	for child in slot.get_children():
		if child is CardDisplay:
			child.card_data = target_card
			child.update_display()
			print("PolymorphAbility: Updated CardDisplay visual for polymorphed card")
			break
	
	# Remove any active passive abilities on the polymorphed card
	if game_manager.active_passive_abilities.has(target_position):
		print("PolymorphAbility: Disabling passive abilities on polymorphed card")
		var passive_abilities = game_manager.active_passive_abilities[target_position]
		for ability in passive_abilities:
			var remove_context = {
				"passive_action": "remove",
				"boosting_card": target_card,
				"boosting_position": target_position,
				"game_manager": game_manager
			}
			ability.execute(remove_context)
		game_manager.active_passive_abilities.erase(target_position)
	
	# Register polymorph in game_manager tracking
	if not game_manager.has_meta("active_polymorphs"):
		game_manager.set_meta("active_polymorphs", {})
	
	var active_polymorphs = game_manager.get_meta("active_polymorphs")
	active_polymorphs[target_position] = {
		"card": target_card,
		"original_stats": original_stats,
		"turns_remaining": 8,
		"position": target_position
	}
	game_manager.set_meta("active_polymorphs", active_polymorphs)
	
	print(ability_name, " activated! ", target_card.card_name, " has been turned into a sheep for 2 turns!")
	
	return true

func can_execute(context: Dictionary) -> bool:
	return true
