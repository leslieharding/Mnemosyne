# res://Scripts/visual_effects_manager.gd
extends Node
class_name VisualEffectsManager

# Flash configuration
const FLASH_DURATION: float = 0.8
const FLASH_COLOR: Color = Color.WHITE
const PLAYER_FLASH_COLOR: Color = Color("#4499FF")  # Blue for player
const OPPONENT_FLASH_COLOR: Color = Color("#FF4444")  # Red for opponent

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
