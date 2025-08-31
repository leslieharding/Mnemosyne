# res://Resources/Abilities/backstab_ability.gd
class_name BackstabAbility
extends CardAbility

func _init():
	ability_name = "Backstab"
	description = "This card attacks the defenders opposing stat instead of its adjacent one"
	trigger_condition = TriggerType.PASSIVE

func execute(context: Dictionary) -> bool:
	if not can_execute(context):
		return false
	
	# Handle passive ability management (when card is placed/removed)
	var passive_action = context.get("passive_action", "")
	if passive_action == "apply" or passive_action == "remove":
		print("BackstabAbility: Passive ability setup - backstab ready")
		return true
	
	# If we get here, backstab shouldn't be directly executed like other abilities
	# It should be checked during combat resolution instead
	print("BackstabAbility: Direct execution called - this should be handled during combat")
	return false

# Static method to check if a card can use backstab
static func can_use_backstab(card: CardResource) -> bool:
	if not card:
		return false
	
	# Check if backstab has already been used
	if card.has_meta("backstab_used") and card.get_meta("backstab_used"):
		return false
	
	return true

# Static method to mark backstab as used
static func mark_backstab_used(card: CardResource):
	if card:
		card.set_meta("backstab_used", true)
		print("BackstabAbility: Backstab charge consumed for ", card.card_name)

# Static method to get the backstab defense value (opposing stat instead of adjacent)
static func get_backstab_defense_value(defender_card: CardResource, normal_defense_index: int) -> int:
	if not defender_card:
		return 1
	
	# Get the opposing direction index
	var backstab_defense_index = get_opposing_direction_index(normal_defense_index)
	
	print("BackstabAbility: Backstab active! Using ", get_direction_name(backstab_defense_index), 
		  " (", defender_card.values[backstab_defense_index], ") instead of ", 
		  get_direction_name(normal_defense_index), " (", defender_card.values[normal_defense_index], ")")
	
	return defender_card.values[backstab_defense_index]

# Helper function to get opposing direction index
static func get_opposing_direction_index(direction_index: int) -> int:
	match direction_index:
		0: return 2  # North -> South
		1: return 3  # East -> West  
		2: return 0  # South -> North
		3: return 1  # West -> East
		_: return 0  # Default fallback

# Helper function for extended range backstab - get the base direction index from extended direction
static func get_base_defense_direction_for_extended(extended_direction: int) -> int:
	match extended_direction:
		0: return 2  # North attack -> South defense
		1: return 3  # East attack -> West defense  
		2: return 0  # South attack -> North defense
		3: return 1  # West attack -> East defense
		4: return 6  # Northeast -> Southwest (but we'll handle this specially)
		5: return 7  # Southeast -> Northwest
		6: return 4  # Southwest -> Northeast  
		7: return 5  # Northwest -> Southeast
		_: return 0  # Default fallback

# Special backstab calculation for extended range (handles diagonals properly)
static func get_extended_backstab_defense_value(defender_card: CardResource, attacking_direction: int) -> int:
	if not defender_card:
		return 1
	
	var normal_defense_direction = get_base_defense_direction_for_extended(attacking_direction)
	
	# For orthogonal directions (0-3), use normal backstab logic
	if attacking_direction <= 3:
		var backstab_direction = get_opposing_direction_index(normal_defense_direction)
		print("BackstabAbility (Extended): Orthogonal backstab - using ", get_direction_name(backstab_direction))
		return defender_card.values[backstab_direction]
	
	# For diagonal directions (4-7), we need to backstab the diagonal defense
	# The normal extended defense uses averaged values, so backstab should use the opposing averaged values
	match attacking_direction:
		4: # Northeast attack normally defends with Southwest, backstab uses Northeast
			var backstab_value = int(ceil((defender_card.values[0] + defender_card.values[1]) / 2.0))
			print("BackstabAbility (Extended): Diagonal backstab NE - using North+East average: ", backstab_value)
			return backstab_value
		5: # Southeast attack normally defends with Northwest, backstab uses Southeast  
			var backstab_value = int(ceil((defender_card.values[1] + defender_card.values[2]) / 2.0))
			print("BackstabAbility (Extended): Diagonal backstab SE - using East+South average: ", backstab_value)
			return backstab_value
		6: # Southwest attack normally defends with Northeast, backstab uses Southwest
			var backstab_value = int(ceil((defender_card.values[2] + defender_card.values[3]) / 2.0))
			print("BackstabAbility (Extended): Diagonal backstab SW - using South+West average: ", backstab_value)
			return backstab_value
		7: # Northwest attack normally defends with Southeast, backstab uses Northwest
			var backstab_value = int(ceil((defender_card.values[3] + defender_card.values[0]) / 2.0))
			print("BackstabAbility (Extended): Diagonal backstab NW - using West+North average: ", backstab_value)
			return backstab_value
		_:
			return defender_card.values[0]  # Fallback

# Helper function for debug output
static func get_direction_name(direction: int) -> String:
	match direction:
		0: return "North"
		1: return "East"
		2: return "South"
		3: return "West"
		_: return "Unknown"

func can_execute(context: Dictionary) -> bool:
	return true
