# res://Scripts/bestiary_content_manager.gd
class_name BestiaryContentManager
extends RefCounted

# Enemy-specific content organized by memory level
var enemy_profiles: Dictionary = {
	
	"Pythons Gang": {
		"lore": [
			"",
			"",
			"",
			"",
			"",
			""
		],
		"tactical_notes": [
			"",
			"",
			"",
			"",
			"",
			""
		]
	},
	
	"Niobes Brood": {
		"lore": [
			"",
			"",
			"",
			"",
			"",
			""
		],
		"tactical_notes": [
			"",
			"",
			"",
			"",
			"",
			""
		]
	},
	
	"Cultists of Nyx": {
		"lore": [
			"",
			"",
			"",
			"",
			"",
			""
		],
		"tactical_notes": [
			"",
			"",
			"",
			"",
			"",
			""
		]
	},
	
	"The Wrong Note": {
		"lore": [
			"",
			"",
			"",
			"",
			"",
			""
		],
		"tactical_notes": [
			"",
			"",
			"",
			"",
			"",
			""
		]
	},
	
	"The Plague": {
		"lore": [
			"",
			"",
			"",
			"",
			"",
			""
		],
		"tactical_notes": [
			"",
			"",
			"",
			"",
			"",
			""
		]
	},
	
	"Chronos": {
		"lore": [
			"",
			"",
			"",
			"",
			"",
			""
		],
		"tactical_notes": [
			"",
			"",
			"",
			"",
			"",
			""
		]
	},
	
	"?????": {
		"lore": [
			"",
			"",
			"",
			"",
			"",
			""
		],
		"tactical_notes": [
			"",
			"",
			"",
			"",
			"",
			""
		]
	}
}

# Get complete enemy profile based on memory level and performance
func get_enemy_profile(enemy_name: String, memory_level: int, encounters: int = 0, victories: int = 0) -> Dictionary:
	if not enemy_name in enemy_profiles:
		return get_default_profile(enemy_name, memory_level)
	
	var profile = enemy_profiles[enemy_name]
	var win_rate = calculate_win_rate(encounters, victories)
	
	return {
		"name": enemy_name,
		"memory_level": memory_level,
		"memory_description": get_memory_level_description(memory_level),
		"total_experience": calculate_total_experience(encounters, victories),
		"encounters": encounters,
		"victories": victories,
		"defeats": encounters - victories,
		"win_rate": win_rate,
		"description": get_description(profile, memory_level, win_rate),
		"tactical_note": get_tactical_note(profile, memory_level, win_rate),
		"visible_stats": get_visible_stats(memory_level)
	}

# Get description based on memory level and win rate
func get_description(profile: Dictionary, memory_level: int, win_rate: float) -> String:
	var base_lore = profile["lore"][memory_level] if memory_level < profile["lore"].size() else profile["lore"][-1]
	
	# Add performance-based context for higher memory levels
	if memory_level >= 3:
		var performance_context = get_performance_context(win_rate)
		if performance_context != "":
			base_lore += " " + performance_context
	
	return base_lore

# Get performance context based on win rate
func get_performance_context(win_rate: float) -> String:
	if win_rate >= 0.8:
		return "Your mastery over this opponent is nearly complete."
	elif win_rate >= 0.6:
		return "You have gained significant advantage through understanding."
	elif win_rate >= 0.4:
		return "Your battles remain closely contested."
	elif win_rate >= 0.2:
		return "This opponent continues to challenge your abilities."
	else:
		return "This foe has proven particularly formidable."

# Get tactical note
func get_tactical_note(profile: Dictionary, memory_level: int, win_rate: float) -> String:
	if memory_level < 2:
		return ""
	
	var base_note = profile["tactical_notes"][memory_level] if memory_level < profile["tactical_notes"].size() else profile["tactical_notes"][-1]
	
	# Add win rate specific advice for levels 3+
	if memory_level >= 3 and base_note != "":
		var advice = get_tactical_advice(win_rate)
		if advice != "":
			base_note += " " + advice
	
	return base_note

# Get tactical advice based on win rate
func get_tactical_advice(win_rate: float) -> String:
	if win_rate >= 0.7:
		return "Continue using proven strategies."
	elif win_rate >= 0.4:
		return "Consider adapting your approach."
	else:
		return "Significant tactical revision recommended."

# Get visible stats based on memory level
func get_visible_stats(memory_level: int) -> Array[String]:
	match memory_level:
		0:
			return []
		1:
			return ["encounters"]
		2:
			return ["encounters", "victories", "defeats", "win_rate"]
		_:
			return ["encounters", "victories", "defeats", "win_rate"]

# Helper functions
func get_memory_level_description(level: int) -> String:
	match level:
		0: return "Unknown"
		1: return "Glimpsed"
		2: return "Observed"
		3: return "Understood"
		4: return "Analyzed"
		5: return "Mastered"
		_: return "Transcendent"

func calculate_win_rate(encounters: int, victories: int) -> float:
	if encounters == 0:
		return 0.0
	return round(float(victories) / float(encounters) * 100.0)

func calculate_total_experience(encounters: int, victories: int) -> int:
	return victories * 2 + (encounters - victories) * 1

# Fallback for unknown enemies
func get_default_profile(enemy_name: String, memory_level: int) -> Dictionary:
	return {
		"name": enemy_name,
		"memory_level": memory_level,
		"memory_description": get_memory_level_description(memory_level),
		"description": "An unknown adversary requiring further study.",
		"tactical_note": "",
		"visible_stats": get_visible_stats(memory_level)
	}

# Check if enemy has specific content
func has_enemy_profile(enemy_name: String) -> bool:
	return enemy_name in enemy_profiles

# Get list of all enemies with content
func get_available_enemies() -> Array[String]:
	var enemies: Array[String] = []
	for enemy_name in enemy_profiles.keys():
		enemies.append(enemy_name)
	return enemies
