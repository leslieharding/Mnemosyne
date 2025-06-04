# res://Resources/enemies_collection.gd
class_name EnemiesCollection
extends Resource

@export var enemies: Array[EnemyCardCollection]

# Get enemy by name
func get_enemy(enemy_name: String) -> EnemyCardCollection:
	for enemy in enemies:
		if enemy.enemy_name == enemy_name:
			return enemy
	return null

# Get all available enemy names
func get_enemy_names() -> Array[String]:
	var names: Array[String] = []
	for enemy in enemies:
		names.append(enemy.enemy_name)
	return names

# Get a random enemy (useful for random encounters)
func get_random_enemy() -> EnemyCardCollection:
	if enemies.size() > 0:
		return enemies[randi() % enemies.size()]
	return null

# Get enemy deck directly by name and difficulty
func get_enemy_deck(enemy_name: String, difficulty: int = 0) -> Array[CardResource]:
	var enemy = get_enemy(enemy_name)
	if enemy:
		return enemy.get_deck_by_difficulty(difficulty)
	return []

# Get enemy info for UI display
func get_enemy_info(enemy_name: String, difficulty: int = 0) -> Dictionary:
	var enemy = get_enemy(enemy_name)
	if not enemy:
		return {}
	
	var deck_def = enemy.get_deck_definition_by_difficulty(difficulty)
	if not deck_def:
		return {}
	
	return {
		"enemy_name": enemy.enemy_name,
		"enemy_description": enemy.enemy_description,
		"deck_name": deck_def.deck_name,
		"deck_description": deck_def.deck_description,
		"difficulty": deck_def.difficulty_level,
		"difficulty_text": deck_def.get_difficulty_description()
	}
