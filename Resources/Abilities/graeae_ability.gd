# res://Resources/Abilities/graeae_ability.gd
class_name GraeaeAbility
extends CardAbility

# Graeae ability states
enum GraeaeState {
	TOOTH,
	EYE,
	NOTHING
}

func _init():
	ability_name = "Graeae"
	description = "Theres 3 of us and only one tooth and eye, you do the math."
	# Keep as PASSIVE so it gets applied on placement
	# Eye defense is handled via manual check in check_for_cheat_death()
	trigger_condition = TriggerType.PASSIVE

func execute(context: Dictionary) -> bool:
	if not can_execute(context):
		return false
	
	var action = context.get("passive_action", "")
	
	# Handle ON_DEFEND trigger for Eye capture immunity
	if action == "":
		# This is being called as an ON_DEFEND ability
		return execute_eye_defense(context)
	
	var graeae_card = context.get("boosting_card")
	var graeae_position = context.get("boosting_position", -1)
	var game_manager = context.get("game_manager")
	
	if not graeae_card or graeae_position == -1 or not game_manager:
		print("GraeaeAbility: Missing required context data")
		return false
	
	match action:
		"apply":
			return apply_graeae(graeae_position, graeae_card, game_manager)
		"remove":
			return remove_graeae(graeae_position, graeae_card, game_manager)
		"turn_start":
			# This gets called by the game manager for rotation logic
			return true
		_:
			print("GraeaeAbility: Unknown action: ", action)
			return false

func execute_eye_defense(context: Dictionary) -> bool:
	"""Handle Eye's capture immunity when used as ON_DEFEND"""
	var defending_card = context.get("defending_card")
	var defending_position = context.get("defending_position", -1)
	var game_manager = context.get("game_manager")
	
	if not defending_card or defending_position == -1 or not game_manager:
		return false
	
	# Check if this Graeae has the Eye
	if not (defending_card.has_meta("graeae_has_eye") and defending_card.get_meta("graeae_has_eye")):
		# This Graeae doesn't have the Eye, so no capture immunity
		return false
	
	# Set flag to prevent capture (same as elusive/earthbound)
	game_manager.set_meta("cheat_death_prevented_" + str(defending_position), true)
	
	print("GraeaeAbility: THE EYE! ", defending_card.card_name, " cannot be captured!")
	
	return true

func apply_graeae(position: int, card: CardResource, game_manager) -> bool:
	print("=== GRAEAE ABILITY ACTIVATED ===")
	print("Position: ", position, " Card: ", card.card_name)
	
	# Get the tracker
	var tracker = game_manager.get_graeae_tracker()
	if not tracker:
		print("GraeaeAbility: ERROR - No tracker found!")
		return false
	
	# Register this Graeae card
	var state = tracker.register_graeae(position, card)
	
	# Apply initial state effects
	apply_state_effects(position, card, state, game_manager)
	
	print("GraeaeAbility: ", card.card_name, " registered with state: ", get_state_name(state))
	return true

func remove_graeae(position: int, card: CardResource, game_manager) -> bool:
	print("GraeaeAbility: Removing ", card.card_name, " from position ", position)
	
	# Get the tracker
	var tracker = game_manager.get_graeae_tracker()
	if not tracker:
		return false
	
	# Remove state effects before unregistering
	var current_state = tracker.get_graeae_state(position)
	if current_state == GraeaeState.TOOTH:
		# Remove tooth stat doubling
		remove_tooth_effects(position, card, game_manager)
	
	# Unregister
	tracker.unregister_graeae(position)
	
	return true

func apply_state_effects(position: int, card: CardResource, state: GraeaeState, game_manager):
	"""Apply the effects for a given state"""
	match state:
		GraeaeState.TOOTH:
			apply_tooth_effects(position, card, game_manager)
		GraeaeState.EYE:
			# Eye is passive - handled in execute_eye_defense via ON_DEFEND
			card.set_meta("graeae_has_eye", true)
			print("GraeaeAbility: ", card.card_name, " has the Eye (capture immunity)")
		GraeaeState.NOTHING:
			# No effects
			card.set_meta("graeae_has_nothing", true)
			print("GraeaeAbility: ", card.card_name, " has nothing (waiting for tooth or eye)")

func remove_state_effects(position: int, card: CardResource, state: GraeaeState, game_manager):
	"""Remove the effects for a given state"""
	match state:
		GraeaeState.TOOTH:
			remove_tooth_effects(position, card, game_manager)
		GraeaeState.EYE:
			card.remove_meta("graeae_has_eye")
		GraeaeState.NOTHING:
			card.remove_meta("graeae_has_nothing")

func apply_tooth_effects(position: int, card: CardResource, game_manager):
	"""Double all stats for the tooth bearer"""
	# Store base stats if not already stored
	if not card.has_meta("graeae_base_stats"):
		card.set_meta("graeae_base_stats", card.values.duplicate())
	
	# Double all stats
	var base_stats = card.get_meta("graeae_base_stats")
	card.values[0] = base_stats[0] * 2  # North
	card.values[1] = base_stats[1] * 2  # East
	card.values[2] = base_stats[2] * 2  # South
	card.values[3] = base_stats[3] * 2  # West
	
	card.set_meta("graeae_has_tooth", true)
	
	print("GraeaeAbility: TOOTH applied - stats doubled from ", base_stats, " to ", card.values)
	
	# FIXED: Update visual display using the standard pattern
	var slot = game_manager.grid_slots[position]
	for child in slot.get_children():
		if child is CardDisplay:
			child.card_data = card  # Update the card data reference
			child.update_display()  # Refresh the visual display
			print("GraeaeAbility: Updated CardDisplay visual for tooth card at position ", position)
			break

func remove_tooth_effects(position: int, card: CardResource, game_manager):
	"""Return stats to base values"""
	if not card.has_meta("graeae_base_stats"):
		print("GraeaeAbility: Warning - no base stats found for tooth removal")
		return
	
	var base_stats = card.get_meta("graeae_base_stats")
	card.values[0] = base_stats[0]
	card.values[1] = base_stats[1]
	card.values[2] = base_stats[2]
	card.values[3] = base_stats[3]
	
	card.remove_meta("graeae_has_tooth")
	
	print("GraeaeAbility: TOOTH removed - stats returned to ", card.values)
	
	# FIXED: Update visual display using the standard pattern
	var slot = game_manager.grid_slots[position]
	for child in slot.get_children():
		if child is CardDisplay:
			child.card_data = card  # Update the card data reference
			child.update_display()  # Refresh the visual display
			print("GraeaeAbility: Updated CardDisplay visual after tooth removal at position ", position)
			break

func trigger_tooth_attack(position: int, card: CardResource, game_manager):
	"""Trigger an extra attack when receiving the tooth via rotation"""
	print("GraeaeAbility: TOOTH ATTACK triggered for ", card.card_name, " at position ", position)
	
	# Resolve combat at this position (this will attack all adjacent enemies)
	var owner = game_manager.get_owner_at_position(position)
	var captures = game_manager.resolve_combat(position, owner, card)
	
	if captures > 0:
		print("GraeaeAbility: Tooth attack captured ", captures, " cards!")
	else:
		print("GraeaeAbility: Tooth attack completed (no captures)")

func get_state_name(state: GraeaeState) -> String:
	match state:
		GraeaeState.TOOTH:
			return "TOOTH"
		GraeaeState.EYE:
			return "EYE"
		GraeaeState.NOTHING:
			return "NOTHING"
		_:
			return "UNKNOWN"

# Static helper to get ability name based on current state
static func get_ability_name_for_state(card: CardResource) -> String:
	if card.has_meta("graeae_has_tooth") and card.get_meta("graeae_has_tooth"):
		return "The Tooth"
	elif card.has_meta("graeae_has_eye") and card.get_meta("graeae_has_eye"):
		return "The Eye"
	elif card.has_meta("graeae_has_nothing") and card.get_meta("graeae_has_nothing"):
		return "Waiting"
	else:
		return "Graeae"

# Static helper to get description based on current state
static func get_description_for_state(card: CardResource) -> String:
	if card.has_meta("graeae_has_tooth") and card.get_meta("graeae_has_tooth"):
		return "Double stats and attacks when receiving the tooth. Rotates each turn."
	elif card.has_meta("graeae_has_eye") and card.get_meta("graeae_has_eye"):
		return "Cannot be captured. Rotates each turn."
	elif card.has_meta("graeae_has_nothing") and card.get_meta("graeae_has_nothing"):
		return "Waiting for the eye or tooth to rotate to this sister."
	else:
		return "The three sisters share the tooth and eye between them."

func can_execute(context: Dictionary) -> bool:
	return true
