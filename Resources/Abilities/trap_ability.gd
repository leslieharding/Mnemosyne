# res://Resources/Abilities/trap_ability.gd
class_name TrapAbility
extends CardAbility

func _init():
	ability_name = "Trap"
	description = "After placement, select an empty slot to set a trap. If an enemy plays there, your card attacks using its highest stat vs their lowest."
	trigger_condition = TriggerType.ON_PLAY

func execute(context: Dictionary) -> bool:
	if not can_execute(context):
		return false

	var placed_card = context.get("placed_card")
	var grid_position = context.get("grid_position", -1)
	var game_manager = context.get("game_manager")

	if not placed_card or grid_position == -1 or not game_manager:
		print("TrapAbility: Missing required context data")
		return false

	var trapper_owner = game_manager.get_owner_at_position(grid_position)

	print("TrapAbility activated! ", placed_card.card_name, " is setting a trap")
	game_manager.start_trap_mode(grid_position, trapper_owner, placed_card)

	return true

func can_execute(context: Dictionary) -> bool:
	return true
