# res://Resources/Abilities/cultivate_ability.gd
class_name CultivateAbility
extends CardAbility

func _init():
	ability_name = "Cultivate"
	description = "If still owned, this card gains 10 experience at the start of each of your turns"
	trigger_condition = TriggerType.PASSIVE

func execute(context: Dictionary) -> bool:
	if not can_execute(context):
		return false
	
	var action = context.get("passive_action", "")
	var cultivating_card = context.get("boosting_card")
	var cultivating_position = context.get("boosting_position", -1)
	var game_manager = context.get("game_manager")
	
	print("CultivateAbility: Action = ", action, " for card at position ", cultivating_position)
	
	if not cultivating_card or cultivating_position == -1 or not game_manager:
		print("CultivateAbility: Missing required context data")
		return false
	
	match action:
		"apply":
			return apply_cultivation(cultivating_position, cultivating_card, game_manager)
		"remove":
			return remove_cultivation(cultivating_position, cultivating_card, game_manager)
		"turn_start":
			return process_cultivation_turn(cultivating_position, cultivating_card, game_manager)
		_:
			print("CultivateAbility: Unknown action: ", action)
			return false

func apply_cultivation(position: int, card: CardResource, game_manager) -> bool:
	print("Cultivation started for ", card.card_name, " at position ", position)
	
	# Only activate cultivation for player-owned cards
	var card_owner = game_manager.get_owner_at_position(position)
	if card_owner == game_manager.Owner.PLAYER:
		# Mark this card as having cultivation active
		card.set_meta("cultivation_active", true)
		print("Cultivation activated for player-owned card")
	else:
		# Mark cultivation as inactive for enemy-owned cards
		card.set_meta("cultivation_active", false)
		print("Cultivation NOT activated for enemy-owned card")
	
	# Always start visual pulse effect (it will show red for enemy, purple for player)
	var card_display = game_manager.get_card_display_at_position(position)
	if card_display and game_manager.visual_effects_manager:
		game_manager.visual_effects_manager.start_passive_pulse(card_display)
	
	return true

func remove_cultivation(position: int, card: CardResource, game_manager) -> bool:
	print("Cultivation ended for ", card.card_name, " at position ", position)
	
	# Mark cultivation as inactive
	card.set_meta("cultivation_active", false)
	
	# Stop visual pulse effect
	var card_display = game_manager.get_card_display_at_position(position)
	if card_display and game_manager.visual_effects_manager:
		game_manager.visual_effects_manager.stop_passive_pulse(card_display)
	
	return true

func process_cultivation_turn(position: int, card: CardResource, game_manager) -> bool:
	# Check if cultivation is still active (card might have been captured)
	if not card.has_meta("cultivation_active") or not card.get_meta("cultivation_active"):
		print("Cultivation not active for ", card.card_name)
		return false
	
	# Get card collection index for experience tracking
	var card_collection_index = game_manager.get_card_collection_index(position)
	if card_collection_index == -1:
		print("CultivateAbility: Could not find collection index for card at position ", position)
		return false
	
	# Calculate experience amount based on Seasons power
	var exp_amount = 10  # Default experience gain
	if game_manager.has_method("is_seasons_power_active") and game_manager.is_seasons_power_active():
		var current_season = game_manager.get_current_season()
		match current_season:
			game_manager.Season.SUMMER:
				exp_amount = 20  # Double experience in Summer
				print("CultivateAbility: Summer season - doubling experience to 20")
			game_manager.Season.WINTER:
				exp_amount = -10  # Negative experience in Winter
				print("CultivateAbility: Winter season - reversing experience to -10")
	
	# Award the experience (including negative amounts in Winter)
	var exp_tracker = game_manager.get_node_or_null("/root/RunExperienceTrackerAutoload")
	if exp_tracker:
		if exp_amount > 0:
			exp_tracker.add_total_exp(card_collection_index, exp_amount)
			print("CultivateAbility: ", card.card_name, " gained ", exp_amount, " experience")
		elif exp_amount < 0:
			# Winter effect: reduce experience but not below 0
			# Get current experience for this card in the run
			var current_exp_data = exp_tracker.get_card_experience(card_collection_index)
			var current_total = current_exp_data.get("total_exp", 0)
			var reduction_amount = min(abs(exp_amount), current_total)  # Don't reduce below 0
			
			if reduction_amount > 0:
				# Subtract experience using negative value
				exp_tracker.add_total_exp(card_collection_index, -reduction_amount)
				print("CultivateAbility: ", card.card_name, " lost ", reduction_amount, " experience (Winter effect)")
			else:
				print("CultivateAbility: ", card.card_name, " experience already at minimum (0)")
		else:
			print("CultivateAbility: ", card.card_name, " gains no experience this turn")
	else:
		print("CultivateAbility: RunExperienceTrackerAutoload not found!")
		return false
	
	return true

func can_execute(context: Dictionary) -> bool:
	return true
