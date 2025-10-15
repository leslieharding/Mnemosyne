# res://Scripts/graeae_tracker.gd
extends Node
class_name GraeaeTracker

# Track all active Graeae on the board
# Structure: {position: {card: CardResource, state: GraeaeState}}
var active_graeae: Dictionary = {}

# Reference to GraeaeAbility for state enum
const GraeaeState = preload("res://Resources/Abilities/graeae_ability.gd").GraeaeState

func _ready():
	pass

func register_graeae(position: int, card: CardResource) -> int:
	"""Register a new Graeae card and assign initial state"""
	print("GraeaeTracker: Registering ", card.card_name, " at position ", position)
	print("GraeaeTracker: Current Graeae count: ", active_graeae.size())
	
	var assigned_state = assign_initial_state()
	
	active_graeae[position] = {
		"card": card,
		"state": assigned_state,
		"name": card.card_name
	}
	
	print("GraeaeTracker: Assigned state: ", get_state_name(assigned_state))
	print("GraeaeTracker: Total Graeae now: ", active_graeae.size())
	
	return assigned_state

func unregister_graeae(position: int):
	"""Remove a Graeae from tracking"""
	if position in active_graeae:
		print("GraeaeTracker: Unregistering Graeae at position ", position)
		active_graeae.erase(position)
		print("GraeaeTracker: Remaining Graeae: ", active_graeae.size())

func assign_initial_state() -> int:
	"""Assign state based on how many Graeae are already active"""
	var count = active_graeae.size()
	
	match count:
		0:
			# First Graeae gets TOOTH
			return GraeaeState.TOOTH
		1:
			# Second Graeae gets EYE
			return GraeaeState.EYE
		2:
			# Third Graeae gets NOTHING
			return GraeaeState.NOTHING
		_:
			# Shouldn't happen, but default to NOTHING
			return GraeaeState.NOTHING

func get_graeae_state(position: int) -> int:
	"""Get the current state of a Graeae at a position"""
	if position in active_graeae:
		return active_graeae[position]["state"]
	return -1

func get_graeae_count() -> int:
	"""Get the number of active Graeae"""
	return active_graeae.size()

func rotate_abilities(game_manager):
	"""Rotate abilities between all active Graeae"""
	var count = active_graeae.size()
	
	print("=== GRAEAE ROTATION START ===")
	print("Active Graeae count: ", count)
	
	if count <= 1:
		print("GraeaeTracker: Only 1 or fewer Graeae - no rotation")
		return
	
	# Store current states
	var positions = active_graeae.keys()
	var old_states = {}
	for pos in positions:
		old_states[pos] = active_graeae[pos]["state"]
		print("Graeae at ", pos, " (", active_graeae[pos]["name"], ") has: ", get_state_name(old_states[pos]))
	
	# Perform rotation
	var new_states = calculate_new_states(old_states, count)
	
	# Apply new states
	var ability_script = preload("res://Resources/Abilities/graeae_ability.gd")
	var ability_instance = ability_script.new()
	
	for pos in positions:
		var card = active_graeae[pos]["card"]
		var old_state = old_states[pos]
		var new_state = new_states[pos]
		
		print("Rotating: ", card.card_name, " from ", get_state_name(old_state), " to ", get_state_name(new_state))
		
		# Remove old state effects
		ability_instance.remove_state_effects(pos, card, old_state, game_manager)
		
		# Update tracked state
		active_graeae[pos]["state"] = new_state
		
		# Apply new state effects
		ability_instance.apply_state_effects(pos, card, new_state, game_manager)
		
		# If gained TOOTH via rotation, trigger extra attack
		if new_state == GraeaeState.TOOTH and old_state != GraeaeState.TOOTH:
			print("GraeaeTracker: ", card.card_name, " received the TOOTH - triggering attack!")
			# Small delay for visual clarity
			await game_manager.get_tree().create_timer(0.3).timeout
			ability_instance.trigger_tooth_attack(pos, card, game_manager)
	
	print("=== GRAEAE ROTATION COMPLETE ===")

func calculate_new_states(old_states: Dictionary, count: int) -> Dictionary:
	"""Calculate the new state for each Graeae based on rotation rules"""
	var new_states = {}
	
	if count == 2:
		# With 2 Graeae: swap TOOTH and EYE
		for pos in old_states:
			match old_states[pos]:
				GraeaeState.TOOTH:
					new_states[pos] = GraeaeState.EYE
				GraeaeState.EYE:
					new_states[pos] = GraeaeState.TOOTH
				_:
					# Shouldn't happen with 2
					new_states[pos] = old_states[pos]
	
	elif count == 3:
		# With 3 Graeae: TOOTH→EYE, EYE→NOTHING, NOTHING→TOOTH
		for pos in old_states:
			match old_states[pos]:
				GraeaeState.TOOTH:
					new_states[pos] = GraeaeState.EYE
				GraeaeState.EYE:
					new_states[pos] = GraeaeState.NOTHING
				GraeaeState.NOTHING:
					new_states[pos] = GraeaeState.TOOTH
	
	return new_states

func get_state_name(state: int) -> String:
	match state:
		GraeaeState.TOOTH:
			return "TOOTH"
		GraeaeState.EYE:
			return "EYE"
		GraeaeState.NOTHING:
			return "NOTHING"
		_:
			return "UNKNOWN"

func is_graeae_card(card_name: String) -> bool:
	"""Check if a card name is one of the three Graeae"""
	return card_name in ["Pamphredo", "Deino", "Enyo"]

func reset():
	"""Reset tracker for new battle"""
	active_graeae.clear()
	print("GraeaeTracker: Reset complete")
