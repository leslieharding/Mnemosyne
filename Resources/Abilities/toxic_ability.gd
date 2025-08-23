# res://Resources/Abilities/toxic_ability.gd
class_name ToxicAbility
extends CardAbility

func _init():
	ability_name = "Toxic"
	description = "When this card is captured, it also captures the card that captured it"
	trigger_condition = TriggerType.ON_CAPTURE

func execute(context: Dictionary) -> bool:
	if not can_execute(context):
		return false
	
	# Get the card that was just captured (this toxic card)
	var captured_card = context.get("captured_card")
	var captured_position = context.get("captured_position", -1)
	var capturing_card = context.get("capturing_card")
	var capturing_position = context.get("capturing_position", -1)
	var game_manager = context.get("game_manager")
	
	print("ToxicAbility: Starting execution for captured card at position ", captured_position)
	
	# Safety checks
	if not captured_card:
		print("ToxicAbility: No captured card provided")
		return false
	
	if captured_position == -1:
		print("ToxicAbility: Invalid captured position")
		return false
	
	if not capturing_card:
		print("ToxicAbility: No capturing card provided")
		return false
	
	if capturing_position == -1:
		print("ToxicAbility: Invalid capturing position")
		return false
	
	if not game_manager:
		print("ToxicAbility: No game manager provided")
		return false
	
	# Determine who captured the toxic card and who should get the capturing card
	var capturing_owner = game_manager.get_owner_at_position(capturing_position)
	var toxic_current_owner = game_manager.get_owner_at_position(captured_position)  # Who owns toxic card now (after capture)
	
	print("ToxicAbility: Toxic card was captured by ", "Player" if capturing_owner == game_manager.Owner.PLAYER else "Opponent")
	print("ToxicAbility: Toxic card is now owned by ", "Player" if toxic_current_owner == game_manager.Owner.PLAYER else "Opponent")
	
	# NEW: Record trap encounter if player captured toxic and lost their card to opponent
	if capturing_owner == game_manager.Owner.PLAYER and toxic_current_owner == game_manager.Owner.OPPONENT:
		# FIXED: Use game_manager to access the global progress tracker
		var progress_tracker = game_manager.get_node("/root/GlobalProgressTrackerAutoload")
		if progress_tracker:
			progress_tracker.record_trap_fallen_for("toxic", "Poisoned by toxic card counter-capture")
		
		if game_manager.notification_manager:
			game_manager.notification_manager.show_notification("Artemis observes your trap encounter")
	
	# TOXIC EFFECT: The capturing card gets captured by whoever now owns the toxic card
	# This works both ways - if player captures toxic, they lose their attacking card to opponent
	# If opponent re-captures toxic, they lose their attacking card to player
	game_manager.set_card_ownership(capturing_position, toxic_current_owner)
	
	print(ability_name, " activated! ", captured_card.card_name, " was captured, but its toxicity captured ", capturing_card.card_name, " in return!")
	
	# VISUAL EFFECT: Show toxic counter-capture effect
	var capturing_card_display = game_manager.get_card_display_at_position(capturing_position)
	if capturing_card_display and game_manager.visual_effects_manager:
		# Use a different visual effect than defensive counter - maybe a green/poison effect
		game_manager.visual_effects_manager.show_toxic_counter_flash(capturing_card_display)
	
	# Award experience for the toxic counter-capture
	if toxic_current_owner == game_manager.Owner.PLAYER:
		# Player's toxic card counter-captured an opponent card
		var toxic_card_index = game_manager.get_card_collection_index(captured_position)
		if toxic_card_index != -1:
			var exp_tracker = game_manager.get_node_or_null("/root/RunExperienceTrackerAutoload")
			if exp_tracker:
				exp_tracker.add_capture_exp(toxic_card_index, 10)  # Standard capture exp
				print("Toxic counter-capture awarded 10 capture exp to card at collection index ", toxic_card_index)
	
	# Update visuals for both affected cards
	game_manager.update_board_visuals()
	
	return true

func can_execute(context: Dictionary) -> bool:
	return true
