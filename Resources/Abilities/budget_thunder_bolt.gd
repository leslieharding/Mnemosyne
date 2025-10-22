# res://Resources/Abilities/budget_thunder_bolt_ability.gd
class_name BudgetThunderBoltAbility
extends CardAbility

func _init():
	ability_name = "Budget Thunder Bolt"
	description = "On play this zaps a random slot - any card struck changes owners"
	trigger_condition = TriggerType.ON_PLAY

func execute(context: Dictionary) -> bool:
	if not can_execute(context):
		return false
	
	var placed_card = context.get("placed_card")
	var grid_position = context.get("grid_position", -1)
	var game_manager = context.get("game_manager")
	
	print("BudgetThunderBoltAbility: Starting execution for card at position ", grid_position)
	
	if not placed_card or grid_position == -1 or not game_manager:
		print("BudgetThunderBoltAbility: Missing required context data")
		return false
	
	# Get the owner of the budget thunder bolt card
	var budget_bolt_owner = game_manager.get_owner_at_position(grid_position)
	
	# Get all possible target slots (all slots except the one the budget bolt is in)
	var possible_targets = []
	for i in range(game_manager.grid_slots.size()):
		if i != grid_position:
			possible_targets.append(i)
	
	# Select a random target
	var target_position = possible_targets[randi() % possible_targets.size()]
	
	print("BudgetThunderBoltAbility: Randomly selected slot ", target_position, " as target")
	
	# Show the yellow lightning flash effect on the TARGET SLOT (works even if empty)
	if game_manager.visual_effects_manager:
		var target_slot = game_manager.grid_slots[target_position]
		show_thunder_bolt_flash_on_slot(target_slot, game_manager.visual_effects_manager)
	
	# Wait for the flash to visually appear before processing capture
	await game_manager.get_tree().create_timer(0.3).timeout
	
	# Check if the target slot is occupied
	if not game_manager.grid_occupied[target_position]:
		print("BudgetThunderBoltAbility: Target slot is empty - budget thunder bolt missed!")
		print(ability_name, " activated! Thunder struck slot ", target_position, " but it was empty!")
		return true
	
	# Get the card at the target position
	var target_card = game_manager.get_card_at_position(target_position)
	var target_owner = game_manager.get_owner_at_position(target_position)
	
	# ===== CRITICAL SECTION: Budget version ALWAYS flips ownership =====
	# This is the downside - it can backfire on friendly cards!
	var new_owner
	if target_owner == game_manager.Owner.PLAYER:
		new_owner = game_manager.Owner.OPPONENT
	else:
		new_owner = game_manager.Owner.PLAYER
	
	print("BudgetThunderBoltAbility: Flipping ownership from ", target_owner, " to ", new_owner)
	game_manager.set_card_ownership(target_position, new_owner)
	# ===== END CRITICAL SECTION =====
	
	var ownership_text = ""
	if target_owner == budget_bolt_owner:
		ownership_text = " (oops, backfired on friendly card!)"
	else:
		ownership_text = " (successfully captured enemy card!)"
	
	print(ability_name, " activated! Budget thunder bolt struck and changed ownership of ", target_card.card_name, " at position ", target_position, ownership_text)
	
	# Award experience for capture (only if player benefits from it)
	# Don't award exp if player zapped their own card (backfire)
	if budget_bolt_owner == game_manager.Owner.PLAYER and new_owner == game_manager.Owner.PLAYER:
		var budget_bolt_card_index = game_manager.get_card_collection_index(grid_position)
		if budget_bolt_card_index != -1:
			var exp_tracker = game_manager.get_node_or_null("/root/RunExperienceTrackerAutoload")
			if exp_tracker:
				exp_tracker.add_capture_exp(budget_bolt_card_index, 10)
				print("Budget thunder bolt capture awarded 10 exp to card at collection index ", budget_bolt_card_index)
	
	# Execute ON_CAPTURE abilities on the captured card
	var target_card_collection_index = game_manager.get_card_collection_index(target_position)
	var target_card_level = game_manager.get_card_level(target_card_collection_index)
	
	if target_card.has_ability_type(CardAbility.TriggerType.ON_CAPTURE, target_card_level):
		print("BudgetThunderBoltAbility: Executing ON_CAPTURE abilities for budget bolt-captured card: ", target_card.card_name)
		
		var capture_context = {
			"capturing_card": placed_card,
			"capturing_position": grid_position,
			"captured_card": target_card,
			"captured_position": target_position,
			"game_manager": game_manager,
			"direction": "budget_thunder_bolt",
			"card_level": target_card_level
		}
		
		target_card.execute_abilities(CardAbility.TriggerType.ON_CAPTURE, capture_context, target_card_level)
	
	# Update visuals to show ownership change
	game_manager.update_board_visuals()
	
	return true

# Show thunder bolt flash on a slot (works even if slot is empty)
func show_thunder_bolt_flash_on_slot(slot: Control, visual_effects_manager: VisualEffectsManager):
	if not slot or not visual_effects_manager:
		return
	
	# Create a bright yellow lightning flash effect directly on the slot
	var flash_overlay = ColorRect.new()
	flash_overlay.color = Color("#FFFF00", 0.8)  # Bright yellow with transparency
	flash_overlay.size = slot.size
	flash_overlay.position = Vector2.ZERO
	flash_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	slot.add_child(flash_overlay)
	
	# Animate the thunder bolt flash with a quick, electric feel
	var tween = visual_effects_manager.create_tween()
	tween.set_parallel(true)
	
	# Quick electric pulse - fast flash to simulate lightning strike
	tween.tween_property(flash_overlay, "modulate:a", 1.0, 0.05)
	tween.tween_property(flash_overlay, "modulate:a", 0.3, 0.05).set_delay(0.05)
	tween.tween_property(flash_overlay, "modulate:a", 0.9, 0.05).set_delay(0.1)
	tween.tween_property(flash_overlay, "modulate:a", 0.0, 0.15).set_delay(0.15)
	
	# Clean up
	tween.tween_callback(func(): flash_overlay.queue_free()).set_delay(0.3)

func can_execute(context: Dictionary) -> bool:
	return true
