# res://Resources/Abilities/earthbound_ability.gd
class_name EarthboundAbility
extends CardAbility

func _init():
	ability_name = "Earthbound"
	description = "Cannot be captured while in the bottom row"
	trigger_condition = TriggerType.ON_DEFEND

func execute(context: Dictionary) -> bool:
	if not can_execute(context):
		return false
	
	# Get context information
	var defending_card = context.get("defending_card")
	var defending_position = context.get("defending_position", -1)
	var attacking_card = context.get("attacking_card")
	var game_manager = context.get("game_manager")
	
	print("EarthboundAbility: Starting execution for ", defending_card.card_name if defending_card else "unknown card", " at position ", defending_position)
	
	# Safety checks
	if not defending_card or defending_position == -1 or not game_manager:
		print("EarthboundAbility: Missing required context data")
		return false
	
	# Check if card is in the bottom row (positions 6, 7, 8)
	var is_in_earth = is_touching_earth(defending_position)
	
	if is_in_earth:
		print("EarthboundAbility: Card is in contact with earth (bottom row) - preventing capture!")
		
		# Set flag in game manager to prevent capture for this specific position
		game_manager.set_meta("cheat_death_prevented_" + str(defending_position), true)
		
		print(ability_name, " activated! ", defending_card.card_name, " draws strength from the earth and cannot be captured!")
		return true
	else:
		print("EarthboundAbility: Card is NOT in contact with earth - can be captured normally")
		return false

func is_touching_earth(position: int) -> bool:
	"""Check if the position is in the bottom row (6, 7, or 8)"""
	return position >= 6 and position <= 8

func can_execute(context: Dictionary) -> bool:
	var defending_card = context.get("defending_card")
	if not defending_card:
		return false
	
	# This ability always checks (no usage limit, infinite as long as touching earth)
	return true
