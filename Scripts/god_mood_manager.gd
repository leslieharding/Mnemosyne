# res://Scripts/god_mood_manager.gd
extends Node
class_name GodMoodManager

# All defined moods per god
const MOODS = {
	"Hermes": {
		"impatient": {
			"name": "Impatient",
			"description": "The mercurial and quick-silvered Hermes will play for you if you dont play fast enough"
		}
	},
	"Artemis": {
		"vengeful": {
			"name": "Vengeful",
			"description": "When you lose to an enemy they are permanently weakened"
		}
	}
}

# Active mood for the current run
var active_god: String = ""
var active_mood: String = ""  # empty string = no mood / vanilla run

func set_mood(god: String, mood: String):
	active_god = god
	active_mood = mood
	print("GodMoodManager: Mood set - ", god, " / ", mood)

func clear_mood():
	active_god = ""
	active_mood = ""
	print("GodMoodManager: Mood cleared")

func is_mood_active() -> bool:
	return active_mood != ""

func get_active_mood() -> String:
	return active_mood

func get_active_god() -> String:
	return active_god

func get_mood_description(god: String, mood: String) -> String:
	return MOODS.get(god, {}).get(mood, {}).get("description", "")

func get_mood_name(god: String, mood: String) -> String:
	return MOODS.get(god, {}).get(mood, {}).get("name", "")

func get_available_moods(god: String) -> Array:
	return MOODS.get(god, {}).keys()
