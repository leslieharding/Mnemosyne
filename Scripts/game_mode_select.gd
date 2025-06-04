extends Control

var journal_button: JournalButton


func _ready():
	setup_journal_button()


func _on_apollo_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Apollo.tscn")


func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/MainMenu.tscn")


func _on_hermes_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Hermes.tscn")


func _on_artemis_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Artemis.tscn")


func setup_journal_button():
	journal_button = preload("res://Scenes/JournalButton.tscn").instantiate()
	add_child(journal_button)
