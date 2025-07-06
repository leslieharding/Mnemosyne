# res://Resources/character.gd
class_name Character
extends Resource

@export var character_name: String = ""
@export var character_color: Color = Color.WHITE
@export var portrait_texture: Texture2D = null
@export var default_position: String = "left"  # "left" or "right"

func _init(name: String = "", color: Color = Color.WHITE, texture: Texture2D = null, position: String = "left"):
	character_name = name
	character_color = color
	portrait_texture = texture
	default_position = position
