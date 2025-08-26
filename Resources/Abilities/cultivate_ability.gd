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
		print("CultivateAbility: Cultivation not active for ", card.card_name)
		return false
	
	# Double-check ownership - only works for player-owned cards
	var card_owner = game_manager.get_owner_at_position(position)
	if card_owner != game_manager.Owner.PLAYER:
		print("CultivateAbility: Card no longer owned by player, ending cultivation")
		card.set_meta("cultivation_active", false)
		return false
	
	# Get the card's collection index for experience tracking
	var card_collection_index = game_manager.get_card_collection_index(position)
	if card_collection_index == -1:
		print("CultivateAbility: Could not find collection index for card")
		return false
	
	var exp_amount = 10
	
	# Add experience to run tracker
	var run_tracker = game_manager.get_node_or_null("/root/RunExperienceTrackerAutoload")
	if run_tracker:
		run_tracker.add_total_exp(card_collection_index, exp_amount)
		print("CultivateAbility: Added ", exp_amount, " cultivation experience to card at collection index ", card_collection_index)
	else:
		print("CultivateAbility: Warning - RunExperienceTrackerAutoload not found")
	
	# Show visual effect - green up arrow
	var card_display = game_manager.get_card_display_at_position(position)
	if card_display and game_manager.visual_effects_manager:
		game_manager.visual_effects_manager.show_cultivation_arrow(card_display)
	
	print("🌱 Cultivation activated! ", card.card_name, " gained ", exp_amount, " experience from growing!")
	
	return true

func can_execute(context: Dictionary) -> bool:
	return true
