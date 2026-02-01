# res://Scripts/portrait_breathing_config.gd
extends Node

const BREATHING_PARAMS = {
	"Mnemosyne": {
		"face_center": Vector2(0.5, 0.45),
		"face_radius": 0.4,
		"breath_speed": 0.25,
		"breath_strength_min": 0.015,  # Increased from 0.005
		"breath_strength_max": 0.025,  # Increased from 0.008
		"variation_speed": 0.25
	},
	"Chiron": {
		"face_center": Vector2(0.5, 0.4),
		"face_radius": 0.45,
		"breath_speed": 0.2,
		"breath_strength_min": 0.012,  # Increased from 0.004
		"breath_strength_max": 0.020,  # Increased from 0.007
		"variation_speed": 0.35
	},
	"Chronos": {
		"face_center": Vector2(0.5, 0.5),
		"face_radius": 0.5,
		"breath_speed": 0.2,
		"breath_strength_min": 0.018,  # Increased from 0.006
		"breath_strength_max": 0.028,  # Increased from 0.010
		"variation_speed": 0.2
	}
}

static func has_breathing(character_name: String) -> bool:
	return BREATHING_PARAMS.has(character_name)

static func get_params(character_name: String) -> Dictionary:
	if BREATHING_PARAMS.has(character_name):
		return BREATHING_PARAMS[character_name]
	return {}
