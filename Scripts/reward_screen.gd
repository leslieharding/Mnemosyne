extends Control

func _ready():
	# Connect the continue button
	$VBoxContainer/ContinueButton.pressed.connect(_on_continue_pressed)
	
	# Simple victory message
	$VBoxContainer/Title.text = "Victory!"
	$VBoxContainer/RewardText.text = "You gained 1 gold!"

func _on_continue_pressed():
	# Get the map data and return to map
	var params = get_scene_params()
	
	# Pass everything back to the map (unchanged for now)
	get_tree().set_meta("scene_params", {
		"god": params.get("god", "Apollo"),
		"deck_index": params.get("deck_index", 0),
		"map_data": params.get("map_data"),
		"returning_from_battle": true
	})
	
	get_tree().change_scene_to_file("res://Scenes/RunMap.tscn")

func get_scene_params() -> Dictionary:
	if get_tree().has_meta("scene_params"):
		return get_tree().get_meta("scene_params")
	return {}
