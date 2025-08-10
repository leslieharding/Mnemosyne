# res://Resources/Abilities/defensive_counter_ability.gd
class_name DefensiveCounterAbility
extends CardAbility

func _init():
	ability_name = "Defensive Counter"
	description = "When this card successfully defends against an enemy attack, capture the attacking card"
	trigger_condition = TriggerType.ON_DEFEND
	print("DefensiveCounterAbility _init called - trigger_condition set to: ", trigger_condition)

# This replaces the defensive counter ability in Resources/Abilities/defensive_counter_ability.gd
# Replace the execute function (around lines 30-80):

func execute(context: Dictionary) -> bool:
	if not can_execute(context):
		return false
	
	# Get the defending card and attacker information
	var defending_card = context.get("defending_card")
	var defending_position = context.get("defending_position", -1)
	var attacking_card = context.get("attacking_card")
	var attacking_position = context.get("attacking_position", -1)
	var game_manager = context.get("game_manager")
	var direction = context.get("direction", -1)  # Direction of the attack
	
	print("DefensiveCounterAbility: Starting execution for ", defending_card.card_name if defending_card else "unknown card", " at position ", defending_position)
	
	# Safety checks - ensure all required data is present
	if not defending_card:
		print("DefensiveCounterAbility: No defending card provided")
		return false
	
	if defending_position == -1:
		print("DefensiveCounterAbility: Invalid defending position")
		return false
	
	if not attacking_card:
		print("DefensiveCounterAbility: No attacking card provided")
		return false
	
	if attacking_position == -1:
		print("DefensiveCounterAbility: Invalid attacking position")
		return false
	
	if not game_manager:
		print("DefensiveCounterAbility: No game manager provided")
		return false
	
	# The defense was successful if we're here, so capture the attacking card
	print("DefensiveCounterAbility: Successful defense! Capturing attacking card at position ", attacking_position)
	
	# Get defending owner and determine if it's a player defending
	var defending_owner = game_manager.get_owner_at_position(defending_position)
	var is_player_defending = (defending_owner == game_manager.Owner.PLAYER)
	
	# VISUAL EFFECT: Show defensive counter flash on the defending card
	var defending_card_display = game_manager.get_card_display_at_position(defending_position)
	if defending_card_display and game_manager.visual_effects_manager:
		game_manager.visual_effects_manager.show_defensive_counter_flash(defending_card_display, direction, is_player_defending)
	
	# Change ownership of the attacking card to the defending player
	game_manager.set_card_ownership(attacking_position, defending_owner)
	
	print(ability_name, " activated! ", defending_card.card_name, " captured the attacking ", attacking_card.card_name, "!")
	
	# Award bonus experience for successful counter-capture - UNIFIED VERSION
	if defending_owner == game_manager.Owner.PLAYER:
		var defending_card_index = game_manager.get_card_collection_index(defending_position)
		if defending_card_index != -1:
			# Use the unified experience system
			var exp_tracker = game_manager.get_node("/root/RunExperienceTrackerAutoload")
			if exp_tracker:
				exp_tracker.add_capture_exp(defending_card_index, 15)  # Bonus exp for counter-capture
				print("Defensive counter awarded 15 capture exp to card at collection index ", defending_card_index)
			else:
				print("Warning: RunExperienceTrackerAutoload not found for defensive counter exp")
	
	return true

func can_execute(context: Dictionary) -> bool:
	# Basic check - could add more conditions here
	return true
