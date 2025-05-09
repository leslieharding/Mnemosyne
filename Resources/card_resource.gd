# res://Resources/card_resource.gd
class_name CardResource
extends Resource

@export var card_name: String
@export var card_texture: Texture2D
@export var values: Array[int] = [1, 1, 1, 1]  # [Up, Right, Down, Left]
@export_multiline var description: String = ""
