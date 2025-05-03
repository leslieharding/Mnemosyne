extends Node
class_name TransitionManager

# Enums for tracking transition state
enum TransitionState {
	IDLE,
	TRANSITIONING_OUT,
	CHANGING_SCENE,
	TRANSITIONING_IN
}

# Configuration properties
var silhouette_duration: float = 0.7  # Slower silhouette fade-in
var full_cover_duration: float = 0.4  # Faster full screen cover fade-in
var fade_in_duration: float = 0.4  # New scene fade in duration
var silhouette_delay: float = 0.1  # Small delay before starting the silhouette

# Scene/silhouette mapping
var silhouettes = {
	# Add your mappings here, for example:
	"res://scenes/main_menu.tscn": "res://assets/silhouettes/menu_silhouette.png",
	"res://scenes/level_1.tscn": "res://assets/silhouettes/level1_silhouette.png",
	# Default silhouette used when a specific one isn't defined
	"default": "res://Assets/Images/Silhouettes/plant.png"
}

# Runtime variables
var current_state: int = TransitionState.IDLE
var target_scene: String = ""
var current_tween: Tween = null

# UI Elements for transition
var canvas_layer: CanvasLayer
var silhouette_texture: TextureRect
var fullscreen_cover: ColorRect

func _ready():
	# Set up the UI elements for transitions
	setup_transition_ui()
	
	# Hide everything initially
	reset_transition_elements()

func setup_transition_ui():
	# Create canvas layer (high layer to be on top)
	canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 100
	add_child(canvas_layer)
	
	# Create silhouette texture as a full-screen element
	silhouette_texture = TextureRect.new()
	silhouette_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	silhouette_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	silhouette_texture.set_anchors_preset(Control.PRESET_FULL_RECT)
	silhouette_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas_layer.add_child(silhouette_texture)
	
	# Create full screen cover
	fullscreen_cover = ColorRect.new()
	fullscreen_cover.color = Color.BLACK
	fullscreen_cover.set_anchors_preset(Control.PRESET_FULL_RECT)
	fullscreen_cover.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas_layer.add_child(fullscreen_cover)

func reset_transition_elements():
	# Reset all transition elements to initial state
	silhouette_texture.modulate.a = 0
	fullscreen_cover.modulate.a = 0

func change_scene_to(scene_path: String) -> void:
	# Don't start a new transition if one is in progress
	if current_state != TransitionState.IDLE:
		print("Transition already in progress, ignoring new request")
		return
	
	target_scene = scene_path
	current_state = TransitionState.TRANSITIONING_OUT
	
	# Set the appropriate silhouette
	var silhouette_path = silhouettes.get(scene_path, silhouettes["default"])
	silhouette_texture.texture = load(silhouette_path)
	
	# Make sure elements are reset
	reset_transition_elements()
	
	# Cancel any existing tween
	if current_tween:
		current_tween.kill()
	
	# Start the transition sequence
	start_transition_out()

func start_transition_out() -> void:
	# Configure the tween for transitioning out
	current_tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	
	# Optional small delay before starting
	current_tween.tween_interval(silhouette_delay)
	
	# Step 1: Start fading in the silhouette (slower)
	current_tween.tween_property(
		silhouette_texture, 
		"modulate:a", 
		1.0, 
		silhouette_duration
	)
	
	# Step 2: Start fading in the black overlay (faster) after a short delay
	# The delay ensures the silhouette has time to become visible first
	current_tween.parallel().tween_property(
		fullscreen_cover, 
		"modulate:a", 
		1.0, 
		full_cover_duration
	).set_delay(silhouette_duration * 0.3)  # Start after 30% of silhouette duration
	
	# Step 3: Change scene when fully black
	# Wait until both animations are complete
	current_tween.tween_interval(0.1)  # Small buffer to ensure animations complete
	current_tween.tween_callback(perform_scene_change)

func perform_scene_change() -> void:
	current_state = TransitionState.CHANGING_SCENE
	
	# Change the scene
	get_tree().change_scene_to_file(target_scene)
	
	# Wait one frame to ensure scene is changed before starting fade in
	await get_tree().process_frame
	
	# Start fade in
	start_transition_in()

func start_transition_in() -> void:
	current_state = TransitionState.TRANSITIONING_IN
	
	# Ensure fullscreen cover is fully visible
	fullscreen_cover.modulate.a = 1.0
	# Make sure silhouette is hidden
	silhouette_texture.modulate.a = 0.0
	
	# Configure the tween for transitioning in (simple fade)
	current_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	
	# Fade out the black overlay
	current_tween.tween_property(fullscreen_cover, "modulate:a", 0.0, fade_in_duration)
	
	# Reset when complete
	current_tween.tween_callback(finish_transition)

func finish_transition() -> void:
	reset_transition_elements()
	current_state = TransitionState.IDLE
	target_scene = ""

# Utility function to check if a transition is in progress
func is_transitioning() -> bool:
	return current_state != TransitionState.IDLE
