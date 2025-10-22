# res://Scripts/god_content_manager.gd
class_name GodContentManager
extends RefCounted

# God-specific content organized by mastery level
var god_profiles: Dictionary = {
	
	"Apollo": {
	"lore": [
		"The rational, logical, harmonious, musical, healing and golden god of Olympus. The tales that survive regarding him are somewhat at odds with the glowing descriptions of his character. Just ask Daphne transformed into a Laurel to escape his pursuits. Or Hyacinthus whom he accidently struck (and killed) with a discus. Or his jealous mess of a relationship with Coronis of which you will learn of in this game. Or the flaying of Marsyas the satyr after their musical competition. Or his spiteful treatment of Cassandra when she rejected him. Or his impulsive slaying of the cyclopes. Or his vicious eradication of the sons of Niobe. But you know outside of those he's a really chill, down to earth, sensible dude. I promise.",
		"", "", "", "", ""
	],
	
},
	"Artemis": {
	"lore": [
		"Ever done the wrong thing to the wrong person? Sometimes without even knowing it? Well; Actaeon, Callisto, Orion, The daughters of Niobe, the people of Calydon, Iphigenia, Otis and Ephialte, have had the pleasure. The protectress of the chase and the chaste is most clearly remembered for her aptitude for enacting revenge. At times, the direction and force of said revenge could be random, arbitrary, even nonsensical. Plain old boring tit for tat reprisal did occur regularly enough too. This dichotomy speaks to the obvious, gods are made in our image not the inverse. Who hasn't seen someone drenched in vengeance but pointed at the wrong target and blind to it?",
		"", "", "", "", ""
	],
},
	"Hermes": {
	"lore": [
		"Mercurial quick silver. Wildly intelligent from birth these days he would be called a; genius, phenom, prodigy, savant or some such. Mythologically he features more so as the messenger than the mess. Chaotic neutral would be a fair description. The slaying of Argus would show he's not above being directly involved and harshly lethal. He stands as a patron saint of tricksters and thieves, but specifically the sort of trickery that treads the boundary of justification. Think Robin Hood. Speaking of boundaries, his role as Archpsychopomp or chief conductor of souls finds him literally between life and death.",
		"", "", "", "", ""
	],
	
},
	"Demeter": {
	"lore": [
		"Grief takes many flavours. Avoidance. A rational 'moving on'. Revenge. Escapism. But to some, Demeter included, grief can bind and imprison. That being said; can you really blame loving someone so hard their absence causes winter of the soul? Thus the natural flow of the seasons arose with grief followed by joy. Life by death by life. It's interesting to note that Demeter (and Hestia) had more shrines dedicated to them than the more glamorous gods. It doesn't take long to see that you only need Hephaestus to calm a volcano rarely but hoping the food would grow would be a more constant concern.",
		"", "", "", "", ""
	],
	
}
}

# Get complete god profile based on mastery level and achievements
func get_god_profile(god_name: String, mastery_level: int, battles_fought: int = 0, achievements: Dictionary = {}) -> Dictionary:
	if not god_name in god_profiles:
		return get_default_profile(god_name, mastery_level)
	
	var profile = god_profiles[god_name]
	
	return {
		"name": god_name,
		"mastery_level": mastery_level,
		"mastery_description": get_mastery_level_description(mastery_level),
		"battles_fought": battles_fought,
		"description": get_description(profile, mastery_level),
		"tactical_advice": get_tactical_advice(profile, mastery_level),
		"divine_insights": get_divine_insights(mastery_level, achievements),
		"visible_content": get_visible_content_types(mastery_level)
	}

# Get lore description based on mastery level
func get_description(profile: Dictionary, mastery_level: int) -> String:
	var complete_lore = ""
	
	# Build up lore from level 0 to current mastery level
	for level in range(mastery_level + 1):
		if level < profile["lore"].size():
			var level_lore = profile["lore"][level]
			if level_lore != "":  # Only add non-empty lore entries
				if complete_lore != "":
					complete_lore += "\n\n"  # Add spacing between lore sections
				complete_lore += level_lore
	
	return complete_lore

# Get tactical advice based on mastery level
func get_tactical_advice(profile: Dictionary, mastery_level: int) -> String:
	if mastery_level < 2:  # No tactical advice until "Practiced" level
		return ""
	
	var complete_tactical = ""
	
	# Build up tactical advice from level 2 to current mastery level
	for level in range(2, mastery_level + 1):  # Start from level 2
		if level < profile["tactical_advice"].size():
			var level_tactical = profile["tactical_advice"][level]
			if level_tactical != "":  # Only add non-empty tactical entries
				if complete_tactical != "":
					complete_tactical += "\n\n"  # Add spacing between tactical sections
				complete_tactical += level_tactical
	
	return complete_tactical

# Get divine insights based on mastery level and special achievements
func get_divine_insights(mastery_level: int, achievements: Dictionary) -> String:
	if mastery_level < 4:  # Divine insights only at Expert level and above
		return ""
	
	var insights: Array[String] = []
	
	# Add mastery-based insights
	match mastery_level:
		4:
			insights.append("Your understanding of divine strategy deepens with each battle.")
		5:
			insights.append("You have achieved perfect harmony with this deity's essence.")
		_:
			insights.append("Your bond transcends mortality—you and the god move as one.")
	
	# Add achievement-based insights (examples for future implementation)
	if achievements.get("max_level_cards", 0) >= 3:
		insights.append("Your dedication to perfecting their cards has not gone unnoticed.")
	
	if achievements.get("all_decks_used", false):
		insights.append("You have explored every facet of their divine domain.")
	
	if achievements.get("perfect_runs", 0) >= 5:
		insights.append("Your flawless victories demonstrate true mastery of their teachings.")
	
	return "\n".join(insights)

# Get what content types are visible at this mastery level
func get_visible_content_types(mastery_level: int) -> Array[String]:
	var visible_types: Array[String] = ["lore"]  # Lore always visible
	
	if mastery_level >= 2:
		visible_types.append("tactical_advice")
	
	if mastery_level >= 4:
		visible_types.append("divine_insights")
	
	return visible_types

# Helper functions
func get_mastery_level_description(level: int) -> String:
	match level:
		0: return "Unfamiliar"
		1: return "Novice"
		2: return "Practiced" 
		3: return "Skilled"
		4: return "Expert"
		5: return "Divine Mastery"
		_: return "Eternal Bond"

# Fallback for unknown gods
func get_default_profile(god_name: String, mastery_level: int) -> Dictionary:
	return {
		"name": god_name,
		"mastery_level": mastery_level,
		"mastery_description": get_mastery_level_description(mastery_level),
		"description": "A divine presence you have yet to fully understand. Fight more battles to unlock their mysteries.",
		"tactical_advice": "",
		"divine_insights": "",
		"visible_content": get_visible_content_types(mastery_level)
	}

# Check if god has specific content available
func has_god_profile(god_name: String) -> bool:
	return god_name in god_profiles

# Get list of all gods with content
func get_available_gods() -> Array[String]:
	var gods: Array[String] = []
	for god_name in god_profiles.keys():
		gods.append(god_name)
	return gods

# Future achievement tracking methods (for when you implement specific triggers)

# Record special achievement for a god (examples of future triggers)
func record_god_achievement(god_name: String, achievement_type: String, value: Variant = true) -> bool:
	# This would integrate with a god achievements system
	# Examples:
	# record_god_achievement("Apollo", "first_victory", true)
	# record_god_achievement("Apollo", "max_level_cards", 3)
	# record_god_achievement("Apollo", "deck_mastery", "Solar Ascendant")
	
	print("God achievement recorded: ", god_name, " - ", achievement_type, ": ", value)
	return true

# Calculate bonus experience from achievements (for future implementation)
func calculate_achievement_bonus_exp(god_name: String, achievements: Dictionary) -> int:
	var bonus_exp = 0
	
	# Examples of future achievement bonuses:
	# if achievements.get("first_victory", false):
	#     bonus_exp += 10
	# 
	# bonus_exp += achievements.get("max_level_cards", 0) * 5
	# 
	# if achievements.get("all_decks_mastered", false):
	#     bonus_exp += 25
	
	return bonus_exp

# Get achievement progress description (for UI display)
func get_achievement_progress(god_name: String, achievements: Dictionary) -> String:
	var progress_text = ""
	
	# Examples of future achievement tracking:
	# var max_cards = achievements.get("max_level_cards", 0)
	# if max_cards > 0:
	#     progress_text += "Cards at max level: " + str(max_cards) + "\n"
	# 
	# var decks_used = achievements.get("decks_discovered", [])
	# progress_text += "Deck variations discovered: " + str(decks_used.size()) + "\n"
	
	return progress_text
