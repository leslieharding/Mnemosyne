# res://Resources/Abilities/awakening_ability.gd
class_name AwakeningAbility
extends CardAbility

func _init():
	ability_name = "Awakening"
	description = "Do not under any circumstances disturb"
	trigger_condition = TriggerType.PASSIVE

func execute(context: Dictionary) -> bool:
	if not can_execute(context):
		return false
	
	var action = context.get("passive_action", "")
	var awakening_card = context.get("boosting_card")
	var awakening_position = context.get("boosting_position", -1)
	var game_manager = context.get("game_manager")
	
	if not awakening_card or awakening_position == -1 or not game_manager:
		print("AwakeningAbility: Missing required context data")
		return false
	
	match action:
		"apply":
			return apply_awakening(awakening_position, awakening_card, game_manager)
		"remove":
			return remove_awakening(awakening_position, awakening_card, game_manager)
		"turn_start":
			return handle_turn_start_attack(awakening_position, awakening_card, game_manager)
		_:
			print("AwakeningAbility: Unknown action: ", action)
			return false

func apply_awakening(position: int, card: CardResource, game_manager) -> bool:
	print("=== AWAKENING ABILITY ACTIVATED ===")
	print("Position: ", position, " Card: ", card.card_name)
	
	card.set_meta("has_awakening", true)
	card.set_meta("awakening_dormant", true)
	
	print("AwakeningAbility: ", card.card_name, " is dormant, waiting for disturbance...")
	return true

func remove_awakening(position: int, card: CardResource, game_manager) -> bool:
	print("AwakeningAbility: Removing awakening from ", card.card_name)
	
	card.remove_meta("has_awakening")
	card.remove_meta("awakening_dormant")
	card.remove_meta("awakening_awakened")
	
	return true

func handle_turn_start_attack(position: int, card: CardResource, game_manager) -> bool:
	if not card.has_meta("awakening_awakened") or not card.get_meta("awakening_awakened"):
		return false
	
	print("AwakeningAbility: Turn start attack for awakened ", card.card_name)
	
	var owner = game_manager.get_owner_at_position(position)
	var captures = game_manager.resolve_combat(position, owner, card)
	
	if captures > 0:
		print("AwakeningAbility: Turn start attack captured ", captures, " cards!")
	
	return true

func check_and_trigger_awakening(position: int, card: CardResource, game_manager) -> bool:
	if not card.has_meta("awakening_dormant") or not card.get_meta("awakening_dormant"):
		return false
	
	print("=== AWAKENING TRIGGERED ===")
	print(card.card_name, " has been disturbed!")
	
	card.values[0] = 30
	card.values[1] = 30
	card.values[2] = 30
	card.values[3] = 30
	
	card.set_meta("awakening_dormant", false)
	card.set_meta("awakening_awakened", true)
	
	print("AwakeningAbility: Stats transformed to 30/30/30/30!")
	
	var slot = game_manager.grid_slots[position]
	for child in slot.get_children():
		if child is CardDisplay:
			child.card_data = card
			child.update_display()
			print("AwakeningAbility: Updated CardDisplay visual for awakened card")
			break
	
	var owner = game_manager.get_owner_at_position(position)
	
	await game_manager.get_tree().create_timer(0.3).timeout
	
	var captures = game_manager.resolve_combat(position, owner, card)
	
	if captures > 0:
		print("AwakeningAbility: Awakening attack captured ", captures, " cards!")
	else:
		print("AwakeningAbility: Awakening attack completed (no captures)")
	
	return true

static func is_dormant_awakening(card: CardResource) -> bool:
	if not card:
		return false
	return card.has_meta("awakening_dormant") and card.get_meta("awakening_dormant")

func can_execute(context: Dictionary) -> bool:
	return true
