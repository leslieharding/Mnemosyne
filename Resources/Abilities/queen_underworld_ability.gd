# res://Resources/Abilities/queen_underworld_ability.gd
extends CardAbility
class_name QueenUnderworldAbility

func _init():
	ability_name = "Queen of the Underworld"
	description = "On play summon a random ally from the underworld."
	trigger_condition = TriggerType.ON_PLAY
	unlock_level = 0

func get_description_for_level(card_level: int) -> String:
	if card_level >= 2:
		return "On play choose an ally from the underworld to summon."
	else:
		return "On play summon a random ally from the underworld."

func execute(context: Dictionary) -> bool:
	print("=== QUEEN OF THE UNDERWORLD ABILITY EXECUTING ===")
	
	var placed_card = context.get("placed_card")
	var grid_position = context.get("grid_position")
	var game_manager = context.get("game_manager")
	var card_level = context.get("card_level", 1)
	
	if not placed_card or grid_position == null or not game_manager:
		print("QueenUnderworldAbility: Missing required context")
		return false
	
	if placed_card.card_name != "Persephone":
		print("QueenUnderworldAbility: Can only be used by Persephone")
		return false
	
	print("Persephone summoning from the underworld at level ", card_level)
	
	# Load the Demeter collection to get underworld allies (indices 5-7)
	var demeter_collection = load("res://Resources/Collections/Demeter.tres") as GodCardCollection
	if not demeter_collection:
		print("ERROR: Could not load Demeter collection")
		return false
	
	# Validate we have the underworld allies
	if demeter_collection.cards.size() < 8:
		print("ERROR: Demeter collection doesn't have enough cards for underworld allies")
		return false
	
	var underworld_allies = []
	for i in range(5, 8):  # Indices 5, 6, 7 (Cerberus, Hades, Hecate)
		if i < demeter_collection.cards.size():
			underworld_allies.append(demeter_collection.cards[i])
	
	if underworld_allies.size() == 0:
		print("ERROR: No underworld allies found")
		return false
	
	print("Found ", underworld_allies.size(), " underworld allies:")
	for ally in underworld_allies:
		print("  - ", ally.card_name)
	
	# Determine which ally to summon based on card level
	var chosen_ally: CardResource
	if card_level >= 2:
		# Choice mode - let player choose
		chosen_ally = game_manager.let_player_choose_underworld_ally(underworld_allies)
		if not chosen_ally:
			print("Player choice cancelled or failed")
			return false
	else:
		# Random mode
		chosen_ally = underworld_allies[randi() % underworld_allies.size()]
	
	print("Summoning ally: ", chosen_ally.card_name)
	
	# Simply replace Persephone with the chosen ally (no proxy needed)
	game_manager.replace_card_with_summon(grid_position, chosen_ally)
	
	print("=== QUEEN OF THE UNDERWORLD ABILITY COMPLETED ===")
	return true

func can_execute(context: Dictionary) -> bool:
	return true
