# res://Resources/Abilities/tantalize_ability.gd
class_name TantalizeAbility
extends CardAbility

func _init():
	ability_name = "Tantalize"
	description = "If this card is captured the first turn it is played, it instead captures the capturing card"
	trigger_condition = TriggerType.ON_PLAY

func execute(context: Dictionary) -> bool:
	if not can_execute(context):
		return false
	
	var placed_card = context.get("placed_card")
	var grid_position = context.get("grid_position", -1)
	var game_manager = context.get("game_manager")
	
	print("TantalizeAbility: Starting execution for card at position ", grid_position)
	
	if not placed_card or grid_position == -1 or not game_manager:
		print("TantalizeAbility: Missing required context data")
		return false
	
	# Store the current turn number when this card is played
	var current_turn = game_manager.get_current_turn_number()
	placed_card.set_meta("tantalize_placed_turn", current_turn)
	placed_card.set_meta("tantalize_active", true)
	
	print("TantalizeAbility activated! ", placed_card.card_name, " is now protected on turn ", current_turn)
	print("Will remain active until turn ", current_turn + 2)
	
	return true

func can_execute(context: Dictionary) -> bool:
	return true

static func check_tantalize_trigger(defending_card: CardResource, defending_position: int, 
									attacking_card: CardResource, attacking_position: int, 
									game_manager) -> bool:
	if not defending_card:
		return false
	
	if not defending_card.has_meta("tantalize_active"):
		return false
	
	if not defending_card.get_meta("tantalize_active"):
		return false
	
	var placed_turn = defending_card.get_meta("tantalize_placed_turn", -1)
	if placed_turn == -1:
		return false
	
	var current_turn = game_manager.get_current_turn_number()
	var turns_elapsed = current_turn - placed_turn
	
	print("TantalizeAbility: Checking trigger - placed turn: ", placed_turn, ", current turn: ", current_turn, ", elapsed: ", turns_elapsed)
	
	if turns_elapsed > 2:
		print("TantalizeAbility: Window expired (", turns_elapsed, " > 2 turns)")
		defending_card.set_meta("tantalize_active", false)
		return false
	
	print("TantalizeAbility: TRIGGERED! ", defending_card.card_name, " counters the capture!")
	
	execute_tantalize_counter(defending_card, defending_position, attacking_card, attacking_position, game_manager)
	
	defending_card.set_meta("tantalize_active", false)
	
	return true

static func execute_tantalize_counter(defending_card: CardResource, defending_position: int,
										attacking_card: CardResource, attacking_position: int,
										game_manager):
	print("TantalizeAbility: Executing counter-capture")
	
	var defending_owner = game_manager.get_owner_at_position(defending_position)
	
	game_manager.set_card_ownership(attacking_position, defending_owner)
	
	print("TantalizeAbility: ", defending_card.card_name, " captured the attacking ", attacking_card.card_name, "!")
	
	
	
	var attacking_card_level = game_manager.get_card_level(game_manager.get_card_collection_index(attacking_position))
	if attacking_card.has_ability_type(CardAbility.TriggerType.ON_CAPTURE, attacking_card_level):
		print("TantalizeAbility: Executing ON_CAPTURE abilities for captured card: ", attacking_card.card_name)
		
		var capture_context = {
			"capturing_card": defending_card,
			"capturing_position": defending_position,
			"captured_card": attacking_card,
			"captured_position": attacking_position,
			"game_manager": game_manager,
			"card_level": attacking_card_level
		}
		
		attacking_card.execute_abilities(CardAbility.TriggerType.ON_CAPTURE, capture_context, attacking_card_level)
	
	if defending_owner == game_manager.Owner.PLAYER:
		var defending_card_index = game_manager.get_card_collection_index(defending_position)
		if defending_card_index != -1:
			var exp_tracker = game_manager.get_node("/root/RunExperienceTrackerAutoload")
			if exp_tracker:
				exp_tracker.add_capture_exp(defending_card_index, 20)
				print("Tantalize counter awarded 20 capture exp to card at collection index ", defending_card_index)

static func check_and_deactivate_expired_tantalize(game_manager):
	print("TantalizeAbility: Checking for expired tantalize effects")
	
	var current_turn = game_manager.get_current_turn_number()
	
	for i in range(game_manager.grid_occupied.size()):
		if not game_manager.grid_occupied[i]:
			continue
		
		var card = game_manager.get_card_at_position(i)
		if not card:
			continue
		
		if not card.has_meta("tantalize_active"):
			continue
		
		if not card.get_meta("tantalize_active"):
			continue
		
		var placed_turn = card.get_meta("tantalize_placed_turn", -1)
		if placed_turn == -1:
			continue
		
		var turns_elapsed = current_turn - placed_turn
		
		if turns_elapsed > 2:
			print("TantalizeAbility: Deactivating expired tantalize on ", card.card_name, 
				  " (placed turn ", placed_turn, ", current turn ", current_turn, ")")
			card.set_meta("tantalize_active", false)
