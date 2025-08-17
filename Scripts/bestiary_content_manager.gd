# res://Scripts/bestiary_content_manager.gd
class_name BestiaryContentManager
extends RefCounted

# Enemy-specific content organized by memory level
var enemy_profiles: Dictionary = {
	
	"Pythons Gang": {
		"lore": [
			"A collection of serpentine entities.",
			"The children of the great Python, slain by Apollo's arrows yet somehow persisting in this realm.",
			"These serpentine spirits bear eternal grudges against the sun god and all who channel his power.",
			"Each serpent embodies a different aspect of primordial chaos that existed before the Olympian order.",
			"United by their shared hatred of divine tyranny, they test those who would claim godly authority.",
			"The eternal serpent collective - death and rebirth in endless cycles, representing the chaos that preceded creation."
		],
		"tactical_notes": [
			"",
			"Aggressive pack tactics with coordinated strikes.",
			"Individual serpents show distinct power patterns - some favor specific directions heavily.",
			"They attempt to overwhelm through numbers and varied approaches rather than individual strength.",
			"Master coordination - they sacrifice individual serpents strategically to create advantageous positions.",
			"Perfect serpentine fluidity - their movements become completely unpredictable, striking from any angle."
		],
		"weakness_hints": [
			"",
			"",
			"",
			"Pick off isolated serpents before they can coordinate attacks.",
			"Their coordination can be disrupted by forcing them into disadvantageous individual matchups.",
			"Even transcendent coordination has moments of transition - exploit the gaps between their movements."
		],
		"strategies": [
			"",
			"",
			"",
			"",
			"Divide and conquer - use high-power cards to eliminate key serpents early, disrupting their coordination.",
			"Become the serpent yourself - match their fluid unpredictability with your own adaptive chaos."
		],
		"flavor_quotes": [
			"*hissssss*",
			"'Apollo's children... you reek of his light...'",
			"'We remember the arrows... we remember the pain...'",
			"'Your sun god cannot protect you here, little flame.'",
			"'We are legion, we are eternal, we are the chaos you cannot tame.'",
			"'In our coils, all order returns to the void from which it came.'"
		]
	},
	
	"Niobes Brood": {
		"lore": [
			"Children born of tragedy and divine wrath.",
			"The fourteen children of Niobe, struck down by Apollo and Artemis for their mother's hubris against Leto.",
			"Resurrected by their mother's endless tears, they carry both love and resentment in equal measure.",
			"Each child represents a different aspect of pride, grief, and the price of challenging the gods.",
			"United in death as they never were in life, they fight to honor their mother's memory while questioning her choices.",
			"Eternal children of sorrow, they have transcended their tragic origins to become guardians of mortal emotion."
		],
		"tactical_notes": [
			"",
			"Emotional combat - their power fluctuates based on perceived threats to family.",
			"Protective formations - they shield weaker siblings while stronger ones take aggressive positions.",
			"Complex family dynamics affect their combat choices - some seek vengeance, others seek peace.",
			"Masterful emotional manipulation - they use guilt, anger, and protective instincts as weapons.",
			"Perfect unity in tragedy - their shared sorrow becomes an unbreakable bond that enhances all abilities."
		],
		"weakness_hints": [
			"",
			"",
			"",
			"Their protective instincts can be exploited - threaten the weaker siblings to force poor positioning.",
			"Internal conflict between vengeance and peace creates momentary vulnerabilities.",
			"Their perfect unity can become a weakness if you can make them doubt their shared cause."
		],
		"strategies": [
			"",
			"",
			"",
			"",
			"Target their emotional bonds - force them to choose between protecting each other and winning.",
			"Embrace your own capacity for both love and loss - only by understanding tragedy can you overcome it."
		],
		"flavor_quotes": [
			"*silent tears*",
			"'Mother... why must we fight again?'",
			"'For Niobe's pride, we pay eternal prices.'",
			"'You who serve Apollo... do you know what your god has done?'",
			"'In death we found the unity that life denied us.'",
			"'We are the price of hubris, the weight of divine justice, the eternal question of worth.'"
		]
	},
	
	"Cultists of Nyx": {
		"lore": [
			"Worshippers of the primordial night.",
			"These devotees seek to bring about eternal darkness by extinguishing all sources of light.",
			"Servants of Nyx who believe that the reign of light-bringing gods has corrupted the natural order.",
			"They practice rituals to merge shadow and substance, seeking to become living extensions of the night itself.",
			"Masters of darkness who can manipulate the very absence of light as a weapon against divine radiance.",
			"Primordial avatars who embody the fundamental darkness from which all existence emerged."
		],
		"tactical_notes": [
			"",
			"Prefer defensive, obscuring tactics that limit visibility of their true capabilities.",
			"Use misdirection and feints, making their actual power distribution difficult to predict.",
			"Masters of timing - they strike when opponents are most vulnerable, often during transitions.",
			"Perfect shadow warfare - they can appear weak when strong, strong when weak, becoming impossible to read.",
			"Transcendent darkness manipulation - they exist in quantum states of possibility until forced to solidify."
		],
		"weakness_hints": [
			"",
			"",
			"",
			"Light-based abilities and aggressive illumination tactics disrupt their shadow manipulation.",
			"Their reliance on misdirection fails against direct, overwhelming force that ignores their feints.",
			"Perfect darkness cannot exist without light to define it - become their necessary opposite."
		],
		"strategies": [
			"",
			"",
			"",
			"",
			"Aggressive illumination - use high-power, direct attacks that cannot be misdirected or obscured.",
			"Become the light that defines their darkness - embrace your role as their eternal, necessary opponent."
		],
		"flavor_quotes": [
			"*whispers in the dark*",
			"'The age of light draws to its close...'",
			"'In shadow, we find truth that light obscures.'",
			"'Your radiance is but a brief candle in infinite night.'",
			"'We are the darkness between stars, the silence between heartbeats.'",
			"'Before light, after light, through light - we are the eternal constant.'"
		]
	},
	
	"The Wrong Note": {
		"lore": [
			"Musicians who have lost their way.",
			"Bards and musicians whose pursuit of perfect harmony led them to dangerous musical territories.",
			"They sought to create music so beautiful it could challenge the Muses themselves, resulting in divine punishment.",
			"Each musician represents a different aspect of artistic ambition turned destructive through hubris.",
			"Masters of discordant harmony, they create beauty through controlled chaos and calculated imperfection.",
			"Transcendent artists who have learned that true music exists in the spaces between notes, the silence that gives sound meaning."
		],
		"tactical_notes": [
			"",
			"Chaotic rhythm - their attacks seem random but follow an underlying musical pattern.",
			"They build to crescendos, starting weak but building power through sustained sequences.",
			"Each musician complements the others, creating complex harmonies that enhance their collective strength.",
			"Perfect musical warfare - they turn combat into performance art, making every move part of a greater composition.",
			"Transcendent musical reality - they exist in multiple temporal states simultaneously, playing past, present, and future."
		],
		"weakness_hints": [
			"",
			"",
			"",
			"Disrupt their rhythm with off-beat timing and irregular attack patterns.",
			"Their dependence on musical harmony can be exploited by introducing discord at key moments.",
			"Perfect music requires perfect timing - introduce chaos at the precise moment of their crescendo."
		],
		"strategies": [
			"",
			"",
			"",
			"",
			"Become the rest between notes - time your moves to the gaps in their musical patterns.",
			"Compose your own counter-melody - create a rhythm that harmonizes with yet transcends their composition."
		],
		"flavor_quotes": [
			"♪...♫",
			"'Do you hear it? The melody that drives gods to madness?'",
			"'We play the songs that should not be played...'",
			"'In every perfect note lies the seed of its own destruction.'",
			"'Music is mathematics, and we have solved equations that reality cannot contain.'",
			"'We are the symphony of creation and destruction, playing eternally in the void between worlds.'"
		]
	},
	
	"The Plague": {
		"lore": [
			"Harbingers of pestilence and decay.",
			"These diseased entities spread corruption wherever they tread, turning health into sickness.",
			"They serve as instruments of divine judgment, bringing disease to cleanse the world of corruption.",
			"Each plague-bearer represents a different aspect of decay: physical, spiritual, moral, and cosmic.",
			"Masters of entropy, they understand that all things must return to dust, and they merely hasten the process.",
			"Transcendent forces of necessary destruction, they are the immune system of reality itself."
		],
		"tactical_notes": [
			"",
			"Spreading corruption - their influence grows stronger the longer the battle continues.",
			"They weaken opponents gradually while building their own strength through sustained contact.",
			"Master attrition warfare - they excel at long battles where they can wear down stronger opponents.",
			"Perfect entropic control - they can accelerate decay in their enemies while regenerating themselves.",
			"Transcendent disease vectors - they exist as pure concepts of corruption, impossible to fully cleanse."
		],
		"weakness_hints": [
			"",
			"",
			"",
			"Quick, decisive strikes prevent them from building their corruption effects.",
			"Their reliance on gradual weakening fails against overwhelming immediate force.",
			"Perfect entropy requires time - deny them duration and they cannot achieve transcendent decay."
		],
		"strategies": [
			"",
			"",
			"",
			"",
			"Swift annihilation - end battles quickly before their corruption can take hold and spread.",
			"Become the cure - embody healing and purification so completely that you counter their very existence."
		],
		"flavor_quotes": [
			"*diseased groaning*",
			"'Come closer... let us share our gifts...'",
			"'All flesh is temporary. We make it more honest about its nature.'",
			"'You fight against the natural order - all things must decay.'",
			"'We are the truth that health tries to deny, the reality that life attempts to postpone.'",
			"'In our embrace, all illusions of permanence dissolve into their constituent atoms.'"
		]
	},
	
	"Chronos": {
		"lore": [
			"The Titan of Time itself.",
			"Father of the Olympians, overthrown by his own children in the great war that shaped reality.",
			"Master of temporal manipulation, he exists across all moments simultaneously.",
			"His defeat was prophesied, yet he continues to fight, knowing the outcome but unable to change it.",
			"The eternal prisoner of paradox - powerful enough to see all futures, too bound by fate to alter them.",
			"Transcendent temporal entity who experiences all of time as a single, eternal moment."
		],
		"tactical_notes": [
			"",
			"Temporal advantages - seems to know your moves before you make them.",
			"Uses knowledge of future events to position cards with perfect anticipation.",
			"Master of inevitability - he plays as though the outcome is already decided.",
			"Perfect temporal warfare - he exists in all possible timelines simultaneously, choosing optimal moves.",
			"Transcendent time manipulation - past, present, and future become irrelevant concepts in his presence."
		],
		"weakness_hints": [
			"",
			"",
			"",
			"His knowledge of fate can become a weakness - he may not adapt to truly unprecedented moves.",
			"Paradoxical actions that shouldn't be possible can disrupt his temporal calculations.",
			"Perfect knowledge of time includes knowledge of his own defeat - use his awareness of fate against him."
		],
		"strategies": [
			"",
			"",
			"",
			"",
			"Embrace temporal paradox - make moves that defy prediction and causality itself.",
			"Accept that victory was always inevitable - not because of fate, but because you choose to make it so."
		],
		"flavor_quotes": [
			"*the tick of cosmic clockwork*",
			"'I have seen the end of this battle... yet we must play it out.'",
			"'Time is a river, child, and I am its source.'",
			"'Your victory is written in the stars... as is my eternal resistance to it.'",
			"'I am the grandfather paradox made flesh - I create the very futures that destroy me.'",
			"'In the end, there is no end. Time is a circle, and we are all prisoners of its eternal revolution.'"
		]
	},
	
	"?????": {
		"lore": [
			"An unknowable presence.",
			"Something that defies classification, existing beyond normal categories of being.",
			"This entity seems familiar yet impossible, as though it knows you better than you know yourself.",
			"A mirror of potential, reflecting what you could become under different circumstances.",
			"The shadow of your own divine ambition, manifested as an opponent who fights with your own techniques.",
			"The final test - yourself, perfected and unbound by mortal limitations."
		],
		"tactical_notes": [
			"",
			"Mirrors your own tactical preferences with impossible precision.",
			"Adapts to counter your strategies using knowledge that seems impossibly intimate.",
			"Fights as though it has been studying your every move since the beginning of time.",
			"Perfect adaptive counter-strategy - it becomes the ideal opponent for your specific approach.",
			"Transcendent mirror warfare - it doesn't just copy your tactics, it perfects them beyond your own capabilities."
		],
		"weakness_hints": [
			"",
			"",
			"",
			"Its perfection is also its limitation - it cannot be more than what you could become.",
			"Your own growth and evolution can outpace its adaptive mimicry.",
			"Perfect mirroring means it shares your weaknesses along with your strengths."
		],
		"strategies": [
			"",
			"",
			"",
			"",
			"Evolve beyond your own limitations - become more than what you were when this mirror was created.",
			"Embrace your flaws as well as your strengths - perfection without imperfection is not truly complete."
		],
		"flavor_quotes": [
			"...",
			"'Do you recognize me?'",
			"'I am what you could have been.'",
			"'Every choice you didn't make, every path you didn't take - I am all of them.'",
			"'You cannot defeat me without defeating yourself. You cannot defeat yourself without accepting me.'",
			"'I am your potential, your possibility, your question mark made manifest. The answer was always inside you.'"
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
		"weakness_hint": get_weakness_hint(profile, memory_level),
		"optimal_strategy": get_optimal_strategy(profile, memory_level),
		"flavor_quote": get_flavor_quote(profile, memory_level),
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

# Get weakness hint
func get_weakness_hint(profile: Dictionary, memory_level: int) -> String:
	if memory_level < 4:
		return ""
	
	return profile["weakness_hints"][memory_level] if memory_level < profile["weakness_hints"].size() else profile["weakness_hints"][-1]

# Get optimal strategy
func get_optimal_strategy(profile: Dictionary, memory_level: int) -> String:
	if memory_level < 5:
		return ""
	
	return profile["strategies"][memory_level] if memory_level < profile["strategies"].size() else profile["strategies"][-1]

# Get flavor quote
func get_flavor_quote(profile: Dictionary, memory_level: int) -> String:
	return profile["flavor_quotes"][memory_level] if memory_level < profile["flavor_quotes"].size() else profile["flavor_quotes"][-1]

# Get visible stats based on memory level
func get_visible_stats(memory_level: int) -> Array[String]:
	match memory_level:
		0:
			return []
		1:
			return ["encounters"]
		2:
			return ["encounters", "victories", "defeats", "win_rate"]
		3:
			return ["encounters", "victories", "defeats", "win_rate"]
		4:
			return ["encounters", "victories", "defeats", "win_rate"]
		5:
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
		"weakness_hint": "",
		"optimal_strategy": "",
		"flavor_quote": "...",
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
