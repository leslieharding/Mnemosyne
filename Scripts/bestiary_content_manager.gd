# res://Scripts/bestiary_content_manager.gd
class_name BestiaryContentManager
extends RefCounted

# Enemy-specific content organized by memory level
var enemy_profiles: Dictionary = {
	
	"Pythons Gang": {
		"lore": [
			"Yes I found all the snakes, yes they all want to be here and no you can't join our club",
			"Python: Hera commanded Python to attack Leto. For she bore the divine twins Apollo and Artemis, the result of Zeus’ latest infidelity. Hearing of this Apollo (a day old at this point) strode out to meet the beast striking it down with his golden bow.",
			"The Omphalos: Rhea once tricked Chronos into eating this stone instead of the infant Zeus. When Zeus returned to overthrow Chronos he flung this stone as far as he could. Where it landed became the Center of the world. Apollo would build his shrine to the Delphic Oracle here.",
			"Ismenian Dragon: Cadmus would strike down this fearsome foe unaware of its divine parentage. Enraged, Ares unleashed his curse upon the royal house of Thebes. Many generations later a prince would; kill his father, have children by his mother before stabbing his own eyes out. So you know, normal curse stuff.",
			"Ladon: Guard of the golden apples of the Hesperides, the fruit that confers immortality. Ladon would prevent mortals from getting close to the tree until Heracles cleared the way. Later a golden apple with the phrase ‘to the fairest’ on it, would send the known world to war.",
			"Calcian Dragon: Medea’s soporific potion would make this beast easy pickings for the hero Jason. He would emerge with the golden fleece ecstatic. Having successfully led the Argo’s voyage and with a wildly devoted wife he set off for home. To tragedy. "
		],
		"tactical_notes": [
			"",
			"The Calcian Dragon slumbers under the effect of Medea’s potion making it an easy target for capture experience farming.",
			"",
			"Ladon has an extreme north-facing power level. Filling the southern slots will result in it being relatively useless.",
			"",
			""
		]
	},
	
	"Niobes Brood": {
		"lore": [
			"Fourteen infinities of weeping bore fruit, rise my children defend our pride",
			"The annual festival to the titaness Leto was taking place. Niobe looked on scornfully",
			"How could anyone consider Leto a paragon of fertility, for does she not only have the two children?",
			"I have fourteen, who's to say they won't go on to change the world, perhaps achieve divinity themselves",
			"Such sacrilege would not go unanswered. Apollo defending his mothers pride would slay Niobe’s 7 daughters and 7 sons",
			"Forever bound in her grief Niobe was turned to stone, out of which tears still fall to this day"
		],
		"tactical_notes": [
			"",
			"Just like every family, this lot doesn't get along",
			"",
			"Target the faltering family members and they will fight on your side",
			"",
			""
		]
	},
	
	"Cultists of Nyx": {
		"lore": [
			"Who has the time to wait for an eclipse? Why not destroy the sun?",
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
			"We can't all get lessons from Calliope and Euterpe directly",
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
			"Atone, Consult, Dose, Rest - but ultimately Pray",
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
			"I rule here and I have all the time in the world",
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
			"Who could it be",
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
	var complete_lore = ""
	
	# Build up lore from level 0 to current memory level
	for level in range(memory_level + 1):
		if level < profile["lore"].size():
			var level_lore = profile["lore"][level]
			if level_lore != "":  # Only add non-empty lore entries
				if complete_lore != "":
					complete_lore += "\n\n"  # Add spacing between lore sections
				complete_lore += level_lore
	
	# Add performance-based context for higher memory levels
	if memory_level >= 3 and complete_lore != "":
		var performance_context = get_performance_context(win_rate)
		if performance_context != "":
			complete_lore += "\n\n" + performance_context
	
	return complete_lore

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
	
	var complete_tactical = ""
	
	# Build up tactical notes from level 2 to current memory level
	for level in range(2, memory_level + 1):  # Start from level 2 since tactical info starts there
		if level < profile["tactical_notes"].size():
			var level_tactical = profile["tactical_notes"][level]
			if level_tactical != "":  # Only add non-empty tactical entries
				if complete_tactical != "":
					complete_tactical += "\n\n"  # Add spacing between tactical sections
				complete_tactical += level_tactical
	
	# Add win rate specific advice for levels 3+
	if memory_level >= 3 and complete_tactical != "":
		var advice = get_tactical_advice(win_rate)
		if advice != "":
			complete_tactical += "\n\n" + advice
	
	return complete_tactical

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
