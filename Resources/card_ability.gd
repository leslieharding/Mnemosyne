# res://Resources/card_ability.gd
class_name CardAbility
extends Resource

enum TriggerType {
	ON_PLAY,
	ON_DEFEND,
	ON_CAPTURE,
	PASSIVE,
	ON_DESTROY
}

@export var ability_name: String = ""
@export_multiline var description: String = ""
@export var unlock_level: int = 0
@export var trigger_condition: TriggerType = TriggerType.ON_PLAY

# Virtual method to be overridden by specific abilities
# Returns true if the ability was successfully executed
func execute(context: Dictionary) -> bool:
	print("Base CardAbility.execute() called - this should be overridden")
	return false

# Virtual method to check if the ability can be executed
func can_execute(context: Dictionary) -> bool:
	return true
