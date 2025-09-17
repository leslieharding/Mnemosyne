# res://Scripts/boss_config.gd
class_name BossConfig
extends RefCounted

# Centralized boss name configuration
# Change these values here to update boss names throughout the entire game
const APOLLO_BOSS_NAME: String = "?????"
const HERMES_BOSS_NAME: String = "Hermes Boss"
const DEMETER_BOSS_NAME: String = "Fimbulwinter"


# Helper function to get boss name by god
static func get_boss_name_for_god(god_name: String) -> String:
	match god_name:
		"Apollo":
			return APOLLO_BOSS_NAME
		"Hermes":
			return HERMES_BOSS_NAME
		"Demeter":
			return DEMETER_BOSS_NAME
		_:
			return APOLLO_BOSS_NAME  # Default fallback
