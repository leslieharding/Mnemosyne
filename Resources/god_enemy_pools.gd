# res://Resources/god_enemy_pools.gd
class_name GodEnemyPools
extends Resource

# Weighting configuration
@export var deck_specific_weight: int = 3
@export var god_specific_weight: int = 2
@export var general_weight: int = 1

# TIER 1: General enemies - can appear in any run
@export var general_enemies: Array[String] = ["Pythons Gang", "The Plague", "Craftsmen", "Giants", "Bestial Labours", "Creature Foes of Heracles", "The Grudges", "Sleep", "Amazons", "The Graeae", "Pandora's box", "Crete", "Wicked Kings"]

# TIER 2: God-specific enemies - only appear for that god
# Structure: { "Apollo": ["enemy1", "enemy2"], "Hermes": [...] }
@export var god_specific_enemies: Dictionary = {"Apollo": ["Niobes Brood", ], "Hermes": ["The Way Home", "Isthmus Road"], "Artemis":["Niobes Brood", "The Hunting Party"], "Demeter":[], "Aphrodite":[], "Athena":[], "Dionysus":[]}

# TIER 3: Deck-specific enemies - only appear when using a specific deck
# Structure: { "Apollo": { "The Sun": ["enemy1"], "Natural Harmonics": ["enemy2"] }, ... }
@export var deck_specific_enemies: Dictionary = {"Apollo": { "The Sun": ["Cultists of Nyx"], "Natural Harmonics": ["The Wrong Note"] }}

# Get combined enemy pool for a specific god and deck
func get_enemy_pool(god_name: String, deck_name: String = "") -> Array[String]:
	var pool: Array[String] = []
	
	# Add deck-specific enemies first (highest priority)
	if deck_name != "" and god_name in deck_specific_enemies:
		if deck_name in deck_specific_enemies[god_name]:
			pool.append_array(deck_specific_enemies[god_name][deck_name])
			print("Added ", deck_specific_enemies[god_name][deck_name].size(), " deck-specific enemies for ", god_name, " - ", deck_name)
	
	# Add god-specific enemies
	if god_name in god_specific_enemies:
		pool.append_array(god_specific_enemies[god_name])
		print("Added ", god_specific_enemies[god_name].size(), " god-specific enemies for ", god_name)
	
	# Add general enemies to fill out the pool
	pool.append_array(general_enemies)
	print("Added ", general_enemies.size(), " general enemies")
	
	return pool

# Helper: Get just god + general pool (when deck is unknown)
func get_enemy_pool_for_god(god_name: String) -> Array[String]:
	return get_enemy_pool(god_name, "")


func get_weighted_enemy_pool(god_name: String, deck_name: String = "") -> Array[String]:
	var weighted_pool: Array[String] = []
	
	# Add deck-specific enemies with highest weight
	if deck_name != "" and god_name in deck_specific_enemies:
		if deck_name in deck_specific_enemies[god_name]:
			for enemy in deck_specific_enemies[god_name][deck_name]:
				for i in range(deck_specific_weight):
					weighted_pool.append(enemy)
	
	# Add god-specific enemies with medium weight
	if god_name in god_specific_enemies:
		for enemy in god_specific_enemies[god_name]:
			for i in range(god_specific_weight):
				weighted_pool.append(enemy)
	
	# Add general enemies with base weight
	for enemy in general_enemies:
		for i in range(general_weight):
			weighted_pool.append(enemy)
	
	return weighted_pool
