# res://Resources/level_data.gd
class_name LevelData
extends Resource

@export var level: int = 1
@export var values: Array[int] = [1, 1, 1, 1]
@export var abilities: Array[CardAbility] = []
@export_multiline var description: String = ""
