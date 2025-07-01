# res://Scripts/visual_effects_manager.gd
extends Node
class_name VisualEffectsManager

# Flash configuration
const FLASH_DURATION: float = 0.4
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
	
	# Determine which edge to flash based on attack direction
	var edge_to_flash = get_flash_edge_from_direction(attack_direction)
	
	# Choose color based on who is attacking
	var flash_color = PLAYER_FLASH_COLOR if is_player else OPPONENT_FLASH_COLOR
	
	# Trigger the flash
	flash_card_edge(attacking_card_display, edge_to_flash, flash_color)
	
	print("VisualEffectsManager: Flashing ", get_direction_name(attack_direction), " edge of card")

# Convert attack direction to the edge that should flash
func get_flash_edge_from_direction(direction: int) -> String:
	match direction:
		0: return "south"  # Attacking north, so flash south edge of attacker
		1: return "west"   # Attacking east, so flash west edge of attacker  
		2: return "north"  # Attacking south, so flash north edge of attacker
		3: return "east"   # Attacking west, so flash east edge of attacker
		_: return "north"  # Default fallback

# Create and animate the flash effect on a specific edge
func flash_card_edge(card_display: CardDisplay, edge: String, color: Color):
	if not card_display or not card_display.panel:
		return
	
	# Create the flash overlay
	var flash_rect = ColorRect.new()
	flash_rect.color = color
	flash_rect.modulate.a = 0.0  # Start transparent
	
	# Position and size the flash based on edge
	setup_flash_rect_for_edge(flash_rect, edge, card_display.panel.size)
	
	# Add to the card (on top of everything)
	card_display.panel.add_child(flash_rect)
	flash_rect.z_index = 10  # Ensure it's on top
	
	# Animate the flash
	var tween = create_tween()
	
	# Fade in quickly
	tween.tween_property(flash_rect, "modulate:a", 0.7, FLASH_DURATION * 0.3)
	# Fade out
	tween.tween_property(flash_rect, "modulate:a", 0.0, FLASH_DURATION * 0.7)
	
	# Clean up when done
	tween.tween_callback(func(): flash_rect.queue_free())

# Set up the flash rectangle for a specific edge
func setup_flash_rect_for_edge(flash_rect: ColorRect, edge: String, card_size: Vector2):
	var thickness = 4  # How thick the flash edge should be
	
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

# Helper function for debug output
func get_direction_name(direction: int) -> String:
	match direction:
		0: return "North"
		1: return "East"
		2: return "South"
		3: return "West"
		_: return "Unknown"
