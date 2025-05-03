extends Control

func _ready():
	pass


func _on_quit_button_pressed() -> void:
	get_tree().quit()  


func _on_settings_button_pressed() -> void:
	TransitionManagerAutoload.change_scene_to("res://Scenes/SettingsMenu.tscn")
	


func _on_new_game_button_pressed() -> void:
	TransitionManagerAutoload.change_scene_to("res://Scenes/GameModeSelect.tscn")
