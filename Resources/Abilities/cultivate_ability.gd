# res://Resources/Abilities/cultivate_ability.gd
class_name CultivateAbility
extends CardAbility

func _init():
	ability_name = "Cultivate"
	description = "If still owned, this card gains 10 experience at the start of each of your turns"
	trigger_condition = TriggerType.PASSIVE

# Static helper function to get level-scaled exp amount
static func get_exp_for_level(card_level: int) -> int:
	# Every 3 levels: 10 * (1 + floor((level - 1) / 3))
	# Levels 1-3: 10, Levels 4-6: 20, Levels 7-9: 30, etc.
	return 10 * (1 + int(floor(float(card_level - 1) / 3.0)))

# Static helper function to get dynamic description based on level
static func get_description_for_level(card_level: int) -> String:
	var exp_amount = get_exp_for_level(card_level)
	return "If still owned, this card gains " + str(exp_amount) + " experience at the start of each of your turns"

# Static helper function to get base stat scaling for cards with Cultivate ability
# This gives permanent stat increases based on card level (separate from exp gain)
static func get_stat_bonus_for_level(card_level: int) -> int:
	# Every 3 levels, same as exp scaling
	# Levels 1-3: +0, Levels 4-6: +1, Levels 7-9: +2, etc.
	return int(floor(float(card_level - 1) / 4.0))

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
	
	var card_owner = game_manager.get_owner_at_position(position)
	if card_owner == game_manager.Owner.PLAYER:
		card.set_meta("cultivation_active", true)
		print("Cultivation activated for player-owned card")
	else:
		print("Cultivation not activated - card is opponent-owned")
	
	return true

func remove_cultivation(position: int, card: CardResource, game_manager) -> bool:
	print("Cultivation ended for ", card.card_name, " at position ", position)
	
	if card.has_meta("cultivation_active"):
		card.set_meta("cultivation_active", false)
		print("Cultivation deactivated")
	
	return true

func process_cultivation_turn(position: int, card: CardResource, game_manager) -> bool:
	if not card.has_meta("cultivation_active") or not card.get_meta("cultivation_active"):
		print("CultivateAbility: Card does not have active cultivation")
		return false
	
	print("CultivateAbility: Processing turn start for ", card.card_name)
	
	var card_collection_index = game_manager.get_card_collection_index(position)
	if card_collection_index == -1:
		print("CultivateAbility: Could not find collection index")
		return false
	
	var card_level = game_manager.get_card_level(card_collection_index)
	
	# Calculate level-scaled experience amount
	var exp_amount = get_exp_for_level(card_level)
	
	# Check for Seasons power
	if game_manager.has_method("is_seasons_power_active") and game_manager.is_seasons_power_active():
		var current_season = game_manager.get_current_season()
		match current_season:
			game_manager.Season.SUMMER:
				exp_amount *= 2
				print("CultivateAbility: Summer season - doubling experience to ", exp_amount)
			game_manager.Season.WINTER:
				exp_amount = -exp_amount
				print("CultivateAbility: Winter season - reversing experience to ", exp_amount)
	
	var exp_tracker = game_manager.get_node_or_null("/root/RunExperienceTrackerAutoload")
	if exp_tracker:
		if exp_amount > 0:
			exp_tracker.add_total_exp(card_collection_index, exp_amount)
			print("CultivateAbility: ", card.card_name, " gained ", exp_amount, " experience")
		elif exp_amount < 0:
			var current_exp_data = exp_tracker.get_card_experience(card_collection_index)
			var current_total = current_exp_data.get("total_exp", 0)
			var reduction_amount = min(abs(exp_amount), current_total)
			
			if reduction_amount > 0:
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
