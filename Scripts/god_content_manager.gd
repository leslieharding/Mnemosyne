# res://Scripts/god_content_manager.gd
class_name GodContentManager
extends RefCounted

# God-specific content organized by mastery level
var god_profiles: Dictionary = {
	
	"Apollo": {
		"lore": [
			"The radiant god of light and prophecy awaits your understanding...",
			"Born on the floating island of Delos, Apollo emerged as one of the most powerful Olympians. His golden bow never misses its mark, and his light can both heal and destroy.",
			"At Delphi, Apollo established his most sacred oracle. The Pythia would breathe his sacred vapors and speak prophecies that shaped the fate of heroes and kingdoms alike.",
			"As patron of the nine Muses, Apollo governs all forms of art and knowledge. His lyre can calm savage beasts or drive mortals to divine madness with its perfect melodies.",
			"The god of rational thought and divine order, Apollo represents the balance between wild inspiration and disciplined craft. His solar chariot brings both revelation and judgment.",
			"In his highest aspect, Apollo embodies the eternal struggle between fate and free will. Those who achieve true mastery with him understand that prophecy does not constrain destiny—it illuminates the paths by which destiny unfolds.",
			"You have transcended the boundary between mortal and divine understanding. Apollo's essence flows through your very being, and his light reveals truths beyond the veil of reality."
		],
		"tactical_advice": [
			"", # Level 0 - no tactical info
			"", # Level 1 - still learning basics
			"Apollo's solar blessing enhances your ability to predict opponent movements. Focus on positioning cards to maximize his prophetic advantages.",
			"Master the Oracle's insight: Apollo's decks excel at long-term strategy. Build your board presence gradually while using his divine foresight to counter enemy plans.",
			"Advanced synergy: Combine Apollo's light-based cards with timing abilities. His solar chariot cards work best when you control the pace of battle through careful resource management.",
			"Divine mastery: Apollo's true power lies in perfect timing. Learn to read three moves ahead, using his prophetic abilities to create devastating combinations that seem impossible to opponents.",
			"Eternal wisdom: You have learned to channel Apollo's omniscience. Every card placement becomes a note in a divine symphony, every battle a perfectly orchestrated performance."
		]
	}
	
	# Future gods would follow this same structure:
	# "Artemis": {
	#     "lore": [...],
	#     "tactical_advice": [...]
	# },
	# "Hermes": {
	#     "lore": [...], 
	#     "tactical_advice": [...]
	# }
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
