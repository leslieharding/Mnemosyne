# Scripts/transition_manager.gd
extends Node
class_name TransitionManager

# Enums for tracking transition state
enum TransitionState {
	IDLE,
	TRANSITIONING_OUT,
	CHANGING_SCENE,
	TRANSITIONING_IN
}

enum TransitionMode {
	SIMPLE_FADE,
	SILHOUETTE
}

# Configuration properties
var silhouette_duration: float = 0.7
var full_cover_duration: float = 0.4
var fade_in_duration: float = 0.4
var silhouette_delay: float = 0.1

# Simple fade configuration
var simple_fade_out_duration: float = 0.3
var simple_fade_in_duration: float = 0.3
var default_transition_mode: TransitionMode = TransitionMode.SIMPLE_FADE

# Scene/silhouette mapping (only used for silhouette mode)
var silhouettes = {
	"default": "res://Assets/Images/Silhouettes/plant.png"
}

# Runtime variables
var current_state: int = TransitionState.IDLE
var target_scene: String = ""
var current_tween: Tween = null
var current_mode: TransitionMode

# UI Elements for transition
var canvas_layer: CanvasLayer
var silhouette_texture: TextureRect
var fullscreen_cover: ColorRect

func _ready():
	setup_transition_ui()
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
	silhouette_texture.modulate.a = 0
	fullscreen_cover.modulate.a = 0

# Main function - uses default mode
func change_scene_to(scene_path: String) -> void:
	change_scene_to_with_mode(scene_path, default_transition_mode)

# Function with explicit mode selection
func change_scene_to_with_mode(scene_path: String, mode: TransitionMode) -> void:
	# Don't start a new transition if one is in progress
	if current_state != TransitionState.IDLE:
		print("Transition already in progress, ignoring new request")
		return
	
	target_scene = scene_path
	current_mode = mode
	current_state = TransitionState.TRANSITIONING_OUT
	
	# Cancel any existing tween
	if current_tween:
		current_tween.kill()
	
	# Make sure elements are reset
	reset_transition_elements()
	
	# Start transition based on mode
	match current_mode:
		TransitionMode.SIMPLE_FADE:
			start_simple_fade_out()
		TransitionMode.SILHOUETTE:
			setup_silhouette_transition()
			start_silhouette_transition_out()

# Simple fade out (just black overlay)
func start_simple_fade_out() -> void:
	print("Starting simple fade out transition")
	
	current_tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	
	# Fade to black
	current_tween.tween_property(
		fullscreen_cover, 
		"modulate:a", 
		1.0, 
		simple_fade_out_duration
	)
	
	# Change scene when fully black
	current_tween.tween_callback(perform_scene_change)

# Setup for silhouette transition
func setup_silhouette_transition():
	var silhouette_path = silhouettes.get(target_scene, silhouettes["default"])
	silhouette_texture.texture = load(silhouette_path)

# Original silhouette transition out
func start_silhouette_transition_out() -> void:
	current_tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	
	current_tween.tween_interval(silhouette_delay)
	
	current_tween.tween_property(
		silhouette_texture, 
		"modulate:a", 
		1.0, 
		silhouette_duration
	)
	
	current_tween.parallel().tween_property(
		fullscreen_cover, 
		"modulate:a", 
		1.0, 
		full_cover_duration
	).set_delay(silhouette_duration * 0.3)
	
	current_tween.tween_interval(0.1)
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
	
	# For simple fade, hide silhouette immediately
	if current_mode == TransitionMode.SIMPLE_FADE:
		silhouette_texture.modulate.a = 0.0
	
	# Configure the tween for transitioning in
	current_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	
	# Use appropriate fade in duration
	var fade_duration = simple_fade_in_duration if current_mode == TransitionMode.SIMPLE_FADE else fade_in_duration
	
	# Fade out the black overlay
	current_tween.tween_property(fullscreen_cover, "modulate:a", 0.0, fade_duration)
	
	# Reset when complete
	current_tween.tween_callback(finish_transition)

func finish_transition() -> void:
	reset_transition_elements()
	current_state = TransitionState.IDLE
	target_scene = ""

# Utility functions
func is_transitioning() -> bool:
	return current_state != TransitionState.IDLE

# Set the default transition mode for all scene changes
func set_default_transition_mode(mode: TransitionMode) -> void:
	default_transition_mode = mode
	print("Default transition mode set to: ", "SIMPLE_FADE" if mode == TransitionMode.SIMPLE_FADE else "SILHOUETTE")

# Quick functions for specific modes
func change_scene_simple_fade(scene_path: String) -> void:
	change_scene_to_with_mode(scene_path, TransitionMode.SIMPLE_FADE)

func change_scene_with_silhouette(scene_path: String) -> void:
	change_scene_to_with_mode(scene_path, TransitionMode.SILHOUETTE)
