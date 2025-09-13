# res://Resources/Abilities/coerce_ability.gd
class_name CoerceAbility
extends CardAbility

func _init():
	ability_name = "Coerce"
	description = "On play designates a card in your opponent's hand that they must play next turn."
	trigger_condition = TriggerType.ON_PLAY

func execute(context: Dictionary) -> bool:
	if not can_execute(context):
		return false
	
	# Get the card that was just placed and game manager
	var placed_card = context.get("placed_card")
	var grid_position = context.get("grid_position", -1)
	var game_manager = context.get("game_manager")
	print("CoerceAbility: Starting execution for card at position ", grid_position)
	
	if not placed_card or grid_position == -1 or not game_manager:
		print("CoerceAbility: Missing required context data")
		return false
	
	# Get the owner of the coercing card from the game manager
	var card_owner = game_manager.get_owner_at_position(grid_position)
	
	# Only opponents should use Coerce ability
	if card_owner != game_manager.Owner.OPPONENT:
		print("CoerceAbility: Only opponent cards can use Coerce")
		return false
	
	# Start coerce mode - this will handle the card selection
	if game_manager.has_method("start_coerce_mode"):
		game_manager.start_coerce_mode(grid_position, card_owner, placed_card)
		print("CoerceAbility activated! Opponent is coercing player's next card choice.")
		return true
	else:
		print("CoerceAbility: Game manager doesn't support coerce mode")
		return false

func can_execute(context: Dictionary) -> bool:
	return true
