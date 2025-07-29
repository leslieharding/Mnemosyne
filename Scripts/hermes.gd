extends Node2D


func _on_button_pressed() -> void:
	TransitionManagerAutoload.change_scene_to("res://Scenes/GameModeSelect.tscn")
