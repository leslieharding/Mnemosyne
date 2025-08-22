# res://Resources/Abilities/critical_strike_ability.gd
class_name CriticalStrikeAbility
extends CardAbility

func _init():
	ability_name = "Critical Strike"
	description = "When played, regardless of direction of attack, the opponents weakest stat will be used in defense"
	trigger_condition = TriggerType.PASSIVE

func execute(context: Dictionary) -> bool:
	if not can_execute(context):
		return false
	
	var action = context.get("passive_action", "")
	var card = context.get("boosting_card")
	var position = context.get("boosting_position", -1)
	var game_manager = context.get("game_manager")
	
	if not card or position == -1 or not game_manager:
		print("CriticalStrikeAbility: Missing required context data")
		return false
	
	# Only handle the "apply" action when card is first placed
	if action == "apply":
		return handle_placement(position, card, game_manager)
	
	# For "remove" action (when captured), we don't need to do anything special
	return false

func handle_placement(position: int, card: CardResource, game_manager) -> bool:
	print("CriticalStrikeAbility: Card placed at position ", position)
	
	# Check if there are any adjacent enemy cards to attack
	var has_adjacent_enemies = check_for_adjacent_enemies(position, card, game_manager)
	
	if not has_adjacent_enemies:
		# No adjacent enemies - critical strike opportunity is wasted
		card.set_meta("critical_strike_used", true)
		print("CriticalStrikeAbility: No adjacent enemies - opportunity wasted")
		return false
	else:
		# There are adjacent enemies - critical strike will be available for first combat
		print("CriticalStrikeAbility: Adjacent enemies found - critical strike ready")
		return true

func check_for_adjacent_enemies(position: int, card: CardResource, game_manager) -> bool:
	var grid_size = game_manager.grid_size
	var grid_x = position % grid_size
	var grid_y = position / grid_size
	var card_owner = game_manager.get_owner_at_position(position)
	
	# Check all 4 adjacent positions
	var directions = [
		{"dx": 0, "dy": -1},  # North
		{"dx": 1, "dy": 0},   # East
		{"dx": 0, "dy": 1},   # South
		{"dx": -1, "dy": 0}   # West
	]
	
	for direction in directions:
		var adj_x = grid_x + direction.dx
		var adj_y = grid_y + direction.dy
		var adj_index = adj_y * grid_size + adj_x
		
		# Check if adjacent position is within bounds and occupied
		if adj_x >= 0 and adj_x < grid_size and adj_y >= 0 and adj_y < grid_size:
			if game_manager.grid_occupied[adj_index]:
				var adjacent_owner = game_manager.get_owner_at_position(adj_index)
				# If there's an enemy card, we have a target
				if adjacent_owner != card_owner:
					return true
	
	return false

func can_execute(context: Dictionary) -> bool:
	return true

# Static helper function to check if a card can use critical strike
static func can_use_critical_strike(card: CardResource) -> bool:
	# Check if the card has critical strike and hasn't used it yet
	if not card.has_meta("critical_strike_used"):
		return true
	return not card.get_meta("critical_strike_used", false)

# Static helper function to mark critical strike as used
static func mark_critical_strike_used(card: CardResource):
	card.set_meta("critical_strike_used", true)
	print("CriticalStrikeAbility: Marked as used for ", card.card_name)
