# res://Resources/Abilities/germinate_ability.gd
class_name GerminateAbility
extends CardAbility

func _init():
	ability_name = "Germinate"
	description = "On play, return a friendly Grow card from the board to your hand"
	trigger_condition = TriggerType.ON_PLAY

func execute(context: Dictionary) -> bool:
	if not can_execute(context):
		return false

	var game_manager = context.get("game_manager")
	if not game_manager:
		return false

	var valid_targets = game_manager.get_germinate_valid_targets()
	if valid_targets.is_empty():
		print("GerminateAbility: No valid grow cards on board - fizzling")
		return false

	var grid_position = context.get("grid_position", -1)
	var germinate_card = context.get("placed_card")
	print("GerminateAbility: Activating germinate mode from position ", grid_position)
	game_manager.start_germinate_mode(grid_position, germinate_card)
	return true

func can_execute(context: Dictionary) -> bool:
	var placed_card = context.get("placed_card")
	if not placed_card:
		return false
	if placed_card.has_meta("germinate_used") and placed_card.get_meta("germinate_used"):
		print("GerminateAbility: Already used this battle")
		return false
	return true
