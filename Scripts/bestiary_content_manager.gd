# res://Scripts/bestiary_content_manager.gd
class_name BestiaryContentManager
extends RefCounted

# Enemy-specific content organized by memory level
var enemy_profiles: Dictionary = {
	
	"Pythons Gang": {
		"lore": [
			"Yes I found all the snakes, yes they all want to be here and no you can't join our club",
			"Python: Hera commanded Python to attack Leto. For she bore the divine twins Apollo and Artemis, the result of Zeus' latest infidelity. Hearing of this Apollo (a day old at this point) strode out to meet the beast striking it down with his golden bow.",
			"The Omphalos: Rhea once tricked Chronos into eating this stone instead of the infant Zeus. When Zeus returned to overthrow Chronos he flung this stone as far as he could. Where it landed became the Center of the world. Apollo would build his shrine to the Delphic Oracle here.",
			"Ismenian Dragon: Cadmus would strike down this fearsome foe unaware of its divine parentage. Enraged, Ares unleashed his curse upon the royal house of Thebes. Many generations later a prince would; kill his father, have children by his mother before stabbing his own eyes out. So you know, normal curse stuff.",
			"Ladon: Guard of the golden apples of the Hesperides, the fruit that confers immortality. Ladon would prevent mortals from getting close to the tree until Heracles cleared the way. Later a golden apple with the phrase 'to the fairest' on it, would send the known world to war.",
			"Calcian Dragon: Medea's soporific potion would make this beast easy pickings for the hero Jason. He would emerge with the golden fleece ecstatic. Having successfully led the Argo's voyage and with a wildly devoted wife he set off for home. To tragedy. "
		],
		
	},
	
	"Niobes Brood": {
		"lore": [
			"Fourteen infinities of weeping bore fruit, rise my children defend our pride",
			"The annual festival to the titaness Leto was taking place. Niobe looked on scornfully",
			"How could anyone consider Leto a paragon of fertility, for does she not only have the two children?",
			"I have fourteen, who's to say they won't go on to change the world, perhaps achieve divinity themselves",
			"Such sacrilege would not go unanswered. Apollo defending his mothers pride would slay Niobe's 7 daughters and 7 sons",
			"Forever bound in her grief Niobe was turned to stone, out of which tears still fall to this day"
		],
		
	},
	
	"Cultists of Nyx": {
		"lore": [
			"Who has the time to wait for an eclipse? Why not destroy the sun?",
			"Nyx: is one of the earliest beings to exist in Greek Cosmology. It wouldn't do to have Night itself for a foe. Zeus will usually find excuses not to confront Nyx out of respect (fear)",
			"Erebus: is also amongst the earliest primordial deities. His realm is that of the deep darkness or shadows, especially of those between worlds. Later his name would come to be synonymous with a region of the underworld itself. ",
			"Hemera: Somehow the union of night and deep darkness produced day. Thank goodness it did for it would be a sorry existence without her.",
			"Aether: Hemera gifted us the joy of day, but what of that brightness up on high? Surely the gods themselves needed a brightness too, for them Aether would provide. ",
			"Chaos: Where it all began and where it all ends."
		],
		
	},
	
	"The Wrong Note": {
		"lore": [
			"We can't all get lessons from Calliope and Euterpe directly",
			"Marsyas: Waking from a drunken stupor Marsyas had forgotten his boasting of the previous night, in which he professed his superior music ability to that of Apollo. He would arise in wonder to see a crowded amphitheatre and stage. The golden god was sitting on the stage, tuning his lyre and a flaying knife at his side.",
			"Thamyris: Confident in the strength of his musical prowess, Thamyris challenged the Muses themselves to a singing contest. If he won the prize was to be a night with each Muse in bed. The prospect of which must have been overwhelming because he promptly lost. Ever after his voice and Lyre strum never quite came out right and he was quickly forgotten.",
			"Colymbas: King Pierus had 9 daughters who thought themselves the Muses better. ",
			"Iynx: When the universe heard the Pierides performance, it was such an affront to beauty the world was plunged into darkness.",
			"Cissa: The lovely voice of Calliope pierced the darkness satisfying the cosmos. The Pierides reward for inviting such a cataclysm was to be turned into birds. To squark forever.."
		],
		
	},
	
	"The Plague": {
		"lore": [
			"Atone, Consult, Dose, Rest - but ultimately Pray",
			"Nosos: Nosos starts as a lingering cough, a gnawing at the bowels, a fit in the mind. But ends in haemoptosis, a palpable mass and a seizure. The embodiment of disease and everything that comes with it.",
			"Limos: The face of famine itself. You may have had times in life where you have been peckish, hungry, starving even. But I hope you never quite feel true Limos.",
			"The Keres: On the plain of Marathon a Greek soldier looks to the sky and knows his end time has come. Instead of a comely maiden, he sees 3 sisters arguing over who gets to drink his blood first.",
			"Achlys: In the form of a watery mist Achlys visits but once at the very end. To rob the life and soul from the eyes. One of the few more frightening abstract deities due to its undeniable presence, look next time.",
			"Smintheus: Of mice. Those curious little scurrying creatures forever associated with disease. As is typical in mythology; Apollo either used his healing powers to rid the world of mice thus healing those around him, or his powers of plague to rend the vermin unto you bringing devastation. "
		],
		
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
	},
	
	"Hermes Boss": {
		"lore": [
			"The trickster's illusions warp your perception",
			"",
			"",
			"",
			"",
			""
		],
	},
	
	"Fimbulwinter": {
		"lore": [
			"Winter will follow winter which follows winter",
			"",
			"",
			"",
			"",
			""
		],
	},
	
	"Artemis Boss": {
		"lore": [
			"The hunter's prey becomes the predator",
			"",
			"",
			"",
			"",
			""
		],
	},
	
	# GENERAL ENEMIES
	"Craftsmen": {
		"lore": [
			"Skilled artisans who create the tools of war",
			"",
			"",
			"",
			"",
			""
		],
	},
	
	"Giants": {
		"lore": [
			"Enormous beings born from the earth itself",
			"",
			"",
			"",
			"",
			""
		],
	},
	
	"Bestial Labours": {
		"lore": [
			"The beasts that tested the might of heroes",
			"",
			"",
			"",
			"",
			""
		],
	},
	
	"Creature Foes of Heracles": {
		"lore": [
			"Monsters that stood against the greatest of heroes",
			"",
			"",
			"",
			"",
			""
		],
	},
	
	"The Grudges": {
		"lore": [
			"Those who carry ancient grievances",
			"",
			"",
			"",
			"",
			""
		],
	},
	
	"Sleep": {
		"lore": [
			"The gentle embrace of Hypnos calls to all mortals",
			"",
			"",
			"",
			"",
			""
		],
	},
	
	"Amazons": {
		"lore": [
			"Fierce warrior women who bow to no man",
			"",
			"",
			"",
			"",
			""
		],
	},
	
	"The Graeae": {
		"lore": [
			"Three sisters who share a single eye and tooth",
			"",
			"",
			"",
			"",
			""
		],
	},
	
	"Pandora's box": {
		"lore": [
			"The vessel that unleashed suffering upon the world",
			"",
			"",
			"",
			"",
			""
		],
	},
	
	"Crete": {
		"lore": [
			"The island of labyrinths and hidden secrets",
			"",
			"",
			"",
			"",
			""
		],
	},
	
	"Wicked Kings": {
		"lore": [
			"Tyrants whose cruelty knew no bounds",
			"",
			"",
			"",
			"",
			""
		],
	},
	
	# GOD/DECK SPECIFIC ENEMIES
	"The Way Home": {
		"lore": [
			"The long journey back from war",
			"",
			"",
			"",
			"",
			""
		],
	},
	
	"Isthmus Road": {
		"lore": [
			"The dangerous path where brigands lurk",
			"",
			"",
			"",
			"",
			""
		],
	},
	
	"The Hunting Party": {
		"lore": [
			"Hunters who stalk their prey with deadly precision",
			"",
			"",
			"",
			"",
			""
		],
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
