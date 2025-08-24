# res://Scripts/visual_effects_manager.gd
extends Node
class_name VisualEffectsManager

# Flash configuration
const FLASH_DURATION: float = 0.8
const FLASH_COLOR: Color = Color.WHITE
const PLAYER_FLASH_COLOR: Color = Color("#4499FF")  # Blue for player
const OPPONENT_FLASH_COLOR: Color = Color("#FF4444")  # Red for opponent

# Passive pulse configuration
const PASSIVE_PULSE_DURATION: float = 2.0  # Full pulse cycle duration
const PASSIVE_PULSE_COLOR: Color = Color("#9966FF")  # Purple for passive abilities
const PASSIVE_PULSE_MIN_ALPHA: float = 0.2  # Minimum opacity
const PASSIVE_PULSE_MAX_ALPHA: float = 0.6  # Maximum opacity

# Stat nullify arrow configuration
const STAT_NULLIFY_DURATION: float = 1.5  # Total effect duration
const STAT_NULLIFY_COLOR: Color = Color("#CC0000")  # Red color for the arrow
const ARROW_SIZE: float = 20.0  # Size of the arrow

# Track active passive pulses to avoid duplicates
var active_passive_pulses: Dictionary = {}  # card_display -> pulse_effect

var tremor_shake_effects: Dictionary = {}  # position -> shake_tween

const HUNT_FLASH_COLOR: Color = Color("#FF8800")  # Orange for hunt attacks
const HUNT_TRAP_FLASH_COLOR: Color = Color("#FFAA44")  # Lighter orange for trap triggers


func _ready():
	pass

# Main function to trigger capture flash effect
func show_capture_flash(attacking_card_display: CardDisplay, attack_direction: int, is_player: bool = true):
	if not attacking_card_display:
		print("VisualEffectsManager: No card display provided for flash effect")
		return
	
	if not attacking_card_display.panel:
		print("VisualEffectsManager: Card display has no panel")
		return
	
	# Determine which edge to flash based on attack direction
	var edge_to_flash = get_flash_edge_from_direction(attack_direction)
	
	# Choose color based on who is attacking
	var flash_color = PLAYER_FLASH_COLOR if is_player else OPPONENT_FLASH_COLOR
	
	# Debug output
	var attacker_type = "Player" if is_player else "Opponent"
	print("VisualEffectsManager: ", attacker_type, " flashing ", get_direction_name(attack_direction), " edge with color ", flash_color)
	
	# Trigger the flash
	flash_card_edge(attacking_card_display, edge_to_flash, flash_color)

# Convert attack direction to the edge that should flash
func get_flash_edge_from_direction(direction: int) -> String:
	match direction:
		0: return "north"  # Attacking north, so flash north edge of attacker
		1: return "east"   # Attacking east, so flash east edge of attacker  
		2: return "south"  # Attacking south, so flash south edge of attacker
		3: return "west"   # Attacking west, so flash west edge of attacker
		_: return "north"  # Default fallback

# Create and animate the flash effect on a specific edge
func flash_card_edge(card_display: CardDisplay, edge: String, color: Color):
	if not card_display or not card_display.panel:
		print("VisualEffectsManager: Invalid card display or panel")
		return
	
	# Wait one frame to ensure the card is fully rendered
	await get_tree().process_frame
	
	# Create the flash overlay
	var flash_rect = ColorRect.new()
	flash_rect.color = color
	flash_rect.modulate.a = 0.0  # Start transparent
	flash_rect.name = "FlashEffect"
	
	# Position and size the flash based on edge
	setup_flash_rect_for_edge(flash_rect, edge, card_display.panel.size)
	
	print("VisualEffectsManager: Creating flash rect at ", flash_rect.position, " with size ", flash_rect.size, " on edge ", edge)
	
	# Add to the card (on top of everything)
	card_display.panel.add_child(flash_rect)
	flash_rect.z_index = 100  # Much higher z-index to ensure it's on top
	
	# Force an immediate redraw
	flash_rect.queue_redraw()
	
	# Animate the flash with more dramatic effect
	var tween = create_tween()
	
	# Flash in very quickly and brightly
	tween.tween_property(flash_rect, "modulate:a", 0.9, FLASH_DURATION * 0.2)
	# Hold for a moment
	tween.tween_property(flash_rect, "modulate:a", 0.8, FLASH_DURATION * 0.1)
	# Fade out
	tween.tween_property(flash_rect, "modulate:a", 0.0, FLASH_DURATION * 0.7)
	
	# Clean up when done
	tween.tween_callback(func(): 
		print("VisualEffectsManager: Cleaning up flash effect")
		if is_instance_valid(flash_rect):
			flash_rect.queue_free()
	)

# Set up the flash rectangle for a specific edge
func setup_flash_rect_for_edge(flash_rect: ColorRect, edge: String, card_size: Vector2):
	var thickness = 6  # Increased thickness for better visibility
	
	match edge:
		"north":
			flash_rect.position = Vector2(0, 0)
			flash_rect.size = Vector2(card_size.x, thickness)
		"south":
			flash_rect.position = Vector2(0, card_size.y - thickness)
			flash_rect.size = Vector2(card_size.x, thickness)
		"west":
			flash_rect.position = Vector2(0, 0)
			flash_rect.size = Vector2(thickness, card_size.y)
		"east":
			flash_rect.position = Vector2(card_size.x - thickness, 0)
			flash_rect.size = Vector2(thickness, card_size.y)

# Show defensive counter flash effect
func show_defensive_counter_flash(defending_card_display: CardDisplay, direction_name: String, is_player_defending: bool = true):
	if not defending_card_display:
		print("VisualEffectsManager: No defending card display provided for counter flash")
		return
	
	if not defending_card_display.panel:
		print("VisualEffectsManager: Defending card display has no panel")
		return
	
	# Convert direction name to direction index
	var direction_index = get_direction_index_from_name(direction_name)
	
	# For defensive counters, we want to flash the edge that was attacked
	# This is the opposite of offensive flashing
	var edge_to_flash = get_defensive_flash_edge_from_direction(direction_index)
	
	# Use a special color for defensive counters - purple/magenta to distinguish from regular captures
	var counter_flash_color = Color("#FF00FF") if is_player_defending else Color("#8800FF")
	
	# Debug output
	var defender_type = "Player" if is_player_defending else "Opponent"
	print("VisualEffectsManager: ", defender_type, " defensive counter flashing ", direction_name, " edge with color ", counter_flash_color)
	
	# Trigger the flash
	flash_card_edge(defending_card_display, edge_to_flash, counter_flash_color)

# Convert attack direction to the edge that should flash for DEFENSIVE actions
func get_defensive_flash_edge_from_direction(direction: int) -> String:
	# For defense, we flash the edge that was being attacked
	# If attack came from north, we flash our north edge (we defended our north side)
	match direction:
		0: return "south"  
		1: return "west"   
		2: return "north"  
		3: return "east"   
		_: return "north"  # Default fallback

# Convert direction name to index
func get_direction_index_from_name(direction_name: String) -> int:
	match direction_name.to_lower():
		"north": return 0
		"east": return 1
		"south": return 2
		"west": return 3
		_: return 0  # Default fallback

# Helper function for debug output
func get_direction_name(direction: int) -> String:
	match direction:
		0: return "North"
		1: return "East"
		2: return "South"
		3: return "West"
		_: return "Unknown"

# Show stat nullify arrow effect
func show_stat_nullify_arrow(affected_card_display: CardDisplay):
	if not affected_card_display:
		print("VisualEffectsManager: No card display provided for stat nullify arrow")
		return
	
	if not affected_card_display.panel:
		print("VisualEffectsManager: Card display has no panel")
		return
	
	print("VisualEffectsManager: Showing stat nullify arrow on card")
	
	# Wait one frame to ensure the card is fully rendered
	await get_tree().process_frame
	
	# Create the arrow label
	var arrow_label = Label.new()
	arrow_label.text = "↓"  # Downward arrow unicode
	arrow_label.add_theme_font_size_override("font_size", int(ARROW_SIZE))
	arrow_label.add_theme_color_override("font_color", STAT_NULLIFY_COLOR)
	arrow_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	arrow_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	arrow_label.name = "StatNullifyArrow"
	
	# Position in top-right corner of the card
	var card_size = affected_card_display.panel.size
	arrow_label.position = Vector2(card_size.x - 25, 5)  # 25px from right edge, 5px from top
	arrow_label.size = Vector2(20, 20)  # Small square area for the arrow
	
	# Start invisible
	arrow_label.modulate.a = 0.0
	
	print("VisualEffectsManager: Creating stat nullify arrow at ", arrow_label.position, " with size ", arrow_label.size)
	
	# Add to the card panel
	affected_card_display.panel.add_child(arrow_label)
	arrow_label.z_index = 110  # Higher than flash effects
	
	# Force an immediate redraw
	arrow_label.queue_redraw()
	
	# Animate the arrow: fade in, hold, fade out
	var tween = create_tween()
	
	# Fade in quickly
	tween.tween_property(arrow_label, "modulate:a", 1.0, STAT_NULLIFY_DURATION * 0.2)
	# Hold visible
	tween.tween_property(arrow_label, "modulate:a", 1.0, STAT_NULLIFY_DURATION * 0.6)
	# Fade out
	tween.tween_property(arrow_label, "modulate:a", 0.0, STAT_NULLIFY_DURATION * 0.2)
	
	# Clean up when done
	tween.tween_callback(func(): 
		print("VisualEffectsManager: Cleaning up stat nullify arrow")
		if is_instance_valid(arrow_label):
			arrow_label.queue_free()
	)

# Start passive ability pulse effect on a card
func start_passive_pulse(card_display: CardDisplay):
	if not card_display or not card_display.panel:
		print("VisualEffectsManager: Invalid card display for passive pulse")
		return
	
	# Check if this card already has a passive pulse active
	if card_display in active_passive_pulses:
		return
	
	# Wait one frame to ensure the card is fully rendered
	await get_tree().process_frame
	
	# Create the pulse overlay that covers all edges
	var pulse_container = Control.new()
	pulse_container.name = "PassivePulseEffect"
	pulse_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	pulse_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Create individual edge overlays
	var edges = create_all_edge_overlays(card_display.panel.size)
	for edge in edges:
		pulse_container.add_child(edge)
	
	# Add to the card panel
	card_display.panel.add_child(pulse_container)
	pulse_container.z_index = 50
	
	# Store reference to track active pulse
	active_passive_pulses[card_display] = pulse_container
	
	# Start the pulsing animation
	start_pulse_animation(pulse_container)

# Stop passive ability pulse effect on a card
func stop_passive_pulse(card_display: CardDisplay):
	if not card_display in active_passive_pulses:
		return
	
	var pulse_container = active_passive_pulses[card_display]
	
	# Fade out before removing
	if is_instance_valid(pulse_container):
		var fade_tween = create_tween()
		fade_tween.tween_property(pulse_container, "modulate:a", 0.0, 0.3)
		fade_tween.tween_callback(func():
			if is_instance_valid(pulse_container):
				pulse_container.queue_free()
		)
	
	# Remove from tracking
	active_passive_pulses.erase(card_display)

# Create overlay rectangles for all four edges
func create_all_edge_overlays(card_size: Vector2) -> Array[ColorRect]:
	var edges: Array[ColorRect] = []
	var thickness = 3
	
	# Create all four edges
	var positions_and_sizes = [
		[Vector2(0, 0), Vector2(card_size.x, thickness)],  # North
		[Vector2(0, card_size.y - thickness), Vector2(card_size.x, thickness)],  # South
		[Vector2(0, 0), Vector2(thickness, card_size.y)],  # West
		[Vector2(card_size.x - thickness, 0), Vector2(thickness, card_size.y)]  # East
	]
	
	for pos_size in positions_and_sizes:
		var edge = ColorRect.new()
		edge.color = PASSIVE_PULSE_COLOR
		edge.position = pos_size[0]
		edge.size = pos_size[1]
		edges.append(edge)
	
	return edges

# Add this method to VisualEffectsManager
func show_toxic_counter_flash(card_display: CardDisplay):
	if not card_display or not card_display.panel:
		return
	
	# Create a toxic green flash effect
	var flash_overlay = ColorRect.new()
	flash_overlay.color = Color("#44FF44", 0.7)  # Bright green with transparency
	flash_overlay.size = card_display.panel.size
	flash_overlay.position = Vector2.ZERO
	flash_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	card_display.panel.add_child(flash_overlay)
	
	# Animate the toxic flash
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Pulse effect - in and out twice for toxic feel
	tween.tween_property(flash_overlay, "modulate:a", 0.8, 0.15)
	tween.tween_property(flash_overlay, "modulate:a", 0.2, 0.15).set_delay(0.15)
	tween.tween_property(flash_overlay, "modulate:a", 0.8, 0.15).set_delay(0.3)
	tween.tween_property(flash_overlay, "modulate:a", 0.0, 0.2).set_delay(0.45)
	
	# Clean up
	tween.tween_callback(func(): flash_overlay.queue_free()).set_delay(0.65)


# Start the continuous pulsing animation
func start_pulse_animation(pulse_container: Control):
	if not is_instance_valid(pulse_container):
		return
	
	pulse_container.modulate.a = PASSIVE_PULSE_MIN_ALPHA
	
	var pulse_tween = create_tween()
	pulse_tween.set_loops()
	
	pulse_tween.tween_property(pulse_container, "modulate:a", PASSIVE_PULSE_MAX_ALPHA, PASSIVE_PULSE_DURATION * 0.5).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	pulse_tween.tween_property(pulse_container, "modulate:a", PASSIVE_PULSE_MIN_ALPHA, PASSIVE_PULSE_DURATION * 0.5).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)


func show_tremor_capture_flash(card_display: CardDisplay):
	if not card_display or not card_display.panel:
		return
	
	# Create a brown/earth tremor flash effect
	var flash_overlay = ColorRect.new()
	flash_overlay.color = Color("#8B4513", 0.8)  # Brown earth color
	flash_overlay.size = card_display.panel.size
	flash_overlay.position = Vector2.ZERO
	flash_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	card_display.panel.add_child(flash_overlay)
	
	# Animate the tremor flash with a shake-like effect
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Shake effect while flashing
	var original_pos = flash_overlay.position
	tween.tween_method(_shake_overlay.bind(flash_overlay, original_pos), 0.0, 1.0, 0.6)
	
	# Fade effect
	tween.tween_property(flash_overlay, "modulate:a", 0.8, 0.1)
	tween.tween_property(flash_overlay, "modulate:a", 0.3, 0.2).set_delay(0.1)
	tween.tween_property(flash_overlay, "modulate:a", 0.7, 0.1).set_delay(0.3)
	tween.tween_property(flash_overlay, "modulate:a", 0.0, 0.2).set_delay(0.4)
	
	# Clean up
	tween.tween_callback(func(): flash_overlay.queue_free()).set_delay(0.6)

# Helper function for tremor shake effect
func _shake_overlay(overlay: Control, original_pos: Vector2, progress: float):
	if not is_instance_valid(overlay):
		return
	var shake_intensity = 3.0 * (1.0 - progress)  # Shake reduces over time
	var shake_x = randf_range(-shake_intensity, shake_intensity)
	var shake_y = randf_range(-shake_intensity, shake_intensity)
	overlay.position = original_pos + Vector2(shake_x, shake_y)

# Apply tremor shake effects to slots
func apply_tremor_shake_effects(tremor_zones: Array[int], grid_slots: Array):
	for tremor_zone in tremor_zones:
		if tremor_zone < 0 or tremor_zone >= grid_slots.size():
			continue
		
		var slot = grid_slots[tremor_zone]
		start_tremor_shake_animation(tremor_zone, slot)

# Start shake animation for a tremor slot
func start_tremor_shake_animation(grid_position: int, slot: Panel):
	# Remove any existing shake for this position
	stop_tremor_shake_animation(grid_position, slot)
	
	var original_position = slot.position
	
	# Create repeating shake animation
	var shake_tween = create_tween()
	shake_tween.set_loops()  # Infinite loop
	
	# Gentle shake sequence
	var shake_intensity = 2.0  # Subtle movement
	var shake_duration = 0.1
	
	# Shake pattern: slight movements in different directions
	shake_tween.tween_property(slot, "position", original_position + Vector2(-shake_intensity, 0), shake_duration)
	shake_tween.tween_property(slot, "position", original_position + Vector2(shake_intensity, 0), shake_duration)
	shake_tween.tween_property(slot, "position", original_position + Vector2(0, -shake_intensity), shake_duration)
	shake_tween.tween_property(slot, "position", original_position + Vector2(0, shake_intensity), shake_duration)
	shake_tween.tween_property(slot, "position", original_position, shake_duration)
	
	# Pause between shake cycles
	shake_tween.tween_interval(3.0)
	
	# Store the tween and original position for cleanup
	tremor_shake_effects[grid_position] = {
		"shake_tween": shake_tween,
		"original_position": original_position,
		"slot": slot
	}
	
	print("VisualEffects: Started tremor shake for slot ", grid_position)

# Remove tremor shake effects from specific zones
func remove_tremor_shake_effects(tremor_zones: Array[int], grid_slots: Array):
	for tremor_zone in tremor_zones:
		if tremor_zone < 0 or tremor_zone >= grid_slots.size():
			continue
		
		var slot = grid_slots[tremor_zone]
		stop_tremor_shake_animation(tremor_zone, slot)

# Stop shake animation for a single slot
func stop_tremor_shake_animation(grid_position: int, slot: Panel):
	if not grid_position in tremor_shake_effects:
		return
	
	var shake_data = tremor_shake_effects[grid_position]
	
	# Stop shake animation
	if shake_data.get("shake_tween"):
		shake_data["shake_tween"].kill()
	
	# Reset slot position to original
	if shake_data.get("original_position"):
		slot.position = shake_data["original_position"]
	
	# Clean up tracking
	tremor_shake_effects.erase(grid_position)
	
	print("VisualEffects: Stopped tremor shake for slot ", grid_position)

# Clean up all tremor shake effects (useful for game end or reset)
func clear_all_tremor_shake_effects(grid_slots: Array):
	for grid_position in tremor_shake_effects.keys():
		if grid_position < grid_slots.size():
			var slot = grid_slots[grid_position]
			stop_tremor_shake_animation(grid_position, slot)

# Show hunt combat flash effect
func show_hunt_combat_flash(hunter_display: CardDisplay, hunted_display: CardDisplay):
	if not hunter_display or not hunted_display:
		return
	
	# Flash both cards with hunt colors
	flash_hunt_card(hunter_display, true)   # Hunter flashes brighter
	flash_hunt_card(hunted_display, false)  # Hunted flashes dimmer

# Show hunt trap triggered flash
func show_hunt_trap_flash(hunter_display: CardDisplay, hunted_display: CardDisplay):
	if not hunter_display or not hunted_display:
		return
	
	# Flash with trap colors (slightly different for distinction)
	flash_hunt_card(hunter_display, true, HUNT_TRAP_FLASH_COLOR)
	flash_hunt_card(hunted_display, false, HUNT_TRAP_FLASH_COLOR)

# Flash a card with hunt-specific styling
func flash_hunt_card(card_display: CardDisplay, is_hunter: bool, override_color: Color = HUNT_FLASH_COLOR):
	if not card_display or not card_display.panel:
		return
	
	# Wait one frame to ensure card is rendered
	await get_tree().process_frame
	
	# Create hunt flash overlay
	var flash_overlay = ColorRect.new()
	flash_overlay.color = override_color
	flash_overlay.size = card_display.panel.size
	flash_overlay.position = Vector2.ZERO
	flash_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash_overlay.modulate.a = 0.0
	
	card_display.panel.add_child(flash_overlay)
	flash_overlay.z_index = 120  # Higher than other effects
	
	# Animate hunt flash
	var tween = create_tween()
	tween.set_parallel(true)
	
	if is_hunter:
		# Hunter gets a strong, predatory flash
		tween.tween_property(flash_overlay, "modulate:a", 0.9, 0.1)
		tween.tween_property(flash_overlay, "modulate:a", 0.7, 0.2).set_delay(0.1)
		tween.tween_property(flash_overlay, "modulate:a", 0.9, 0.1).set_delay(0.3)
		tween.tween_property(flash_overlay, "modulate:a", 0.0, 0.3).set_delay(0.4)
	else:
		# Hunted gets a quick defensive flash
		tween.tween_property(flash_overlay, "modulate:a", 0.6, 0.15)
		tween.tween_property(flash_overlay, "modulate:a", 0.3, 0.2).set_delay(0.15)
		tween.tween_property(flash_overlay, "modulate:a", 0.0, 0.25).set_delay(0.35)
	
	# Clean up
	tween.tween_callback(func(): flash_overlay.queue_free()).set_delay(0.7)

# Clear all hunt effects (add this method)
func clear_all_hunt_effects(grid_slots: Array):
	# Remove hunt icons from all slots
	for slot in grid_slots:
		var hunt_icon = slot.get_node_or_null("HuntIcon")
		if hunt_icon:
			hunt_icon.queue_free()
	print("All hunt visual effects cleared")


const HARMONY_FLASH_COLOR: Color = Color("#FFD700")  # Gold color for harmony

# Show harmony capture flash effect
func show_harmony_capture_flash(card_display: CardDisplay):
	if not card_display or not card_display.panel:
		return
	
	# Create a golden harmony flash effect
	var flash_overlay = ColorRect.new()
	flash_overlay.color = HARMONY_FLASH_COLOR
	flash_overlay.size = card_display.panel.size
	flash_overlay.position = Vector2.ZERO
	flash_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash_overlay.modulate.a = 0.0
	
	card_display.panel.add_child(flash_overlay)
	flash_overlay.z_index = 120  # Higher than other effects
	
	# Animate harmony flash with a gentle, musical pulsing
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Gentle harmonic pulse - in and out like a musical note
	tween.tween_property(flash_overlay, "modulate:a", 0.8, 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	tween.tween_property(flash_overlay, "modulate:a", 0.4, 0.3).set_delay(0.2).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	tween.tween_property(flash_overlay, "modulate:a", 0.7, 0.2).set_delay(0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	tween.tween_property(flash_overlay, "modulate:a", 0.0, 0.4).set_delay(0.7).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
	
	# Clean up
	tween.tween_callback(func(): flash_overlay.queue_free()).set_delay(1.1)
