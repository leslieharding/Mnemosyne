# res://Resources/enemy_deck_definition.gd
class_name EnemyDeckDefinition
extends Resource

# Enemy deck power types
enum EnemyDeckPowerType {
	NONE,
	DARKNESS_SHROUD,
	TITAN_STRENGTH,
	PLAGUE_CURSE
}

@export var deck_name: String
@export var deck_description: String
@export var difficulty_level: int = 0  # 0 = easy, 1 = medium, 2 = hard/boss
@export var card_indices: Array[int]  # 5 indices pointing to cards in the enemy collection

# NEW: Enemy deck power system
@export var deck_power_type: EnemyDeckPowerType = EnemyDeckPowerType.NONE
@export var power_config: Dictionary = {}  # For any power-specific configuration

# Get difficulty description for UI
func get_difficulty_description() -> String:
	match difficulty_level:
		0:
			return "Novice"
		1:
			return "Adept" 
		2:
			return "Master"
		_:
			return "Unknown"

# Get deck power description for UI
func get_power_description() -> String:
	match deck_power_type:
		EnemyDeckPowerType.DARKNESS_SHROUD:
			return "🌑 Darkness Shroud: Nullifies any sun power effects, plunging the battlefield into shadow"
		EnemyDeckPowerType.TITAN_STRENGTH:
			return "⚡ Titan Strength: All enemy cards gain +1 to their highest stat direction"
		EnemyDeckPowerType.PLAGUE_CURSE:
			return "☠️ Plague Curse: When enemy cards are captured, they weaken adjacent player cards by -1"
		EnemyDeckPowerType.NONE:
			return ""
		_:
			return ""
