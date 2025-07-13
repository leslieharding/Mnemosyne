# Updated res://Scripts/game_mode_select.gd
extends Control

var journal_button: JournalButton
# Chiron button will be added in the inspector, so we just need a reference
@onready var chiron_button: ChironButton = $ChironButton  # Assuming you name it ChironButton in the scene

func _ready():
	setup_journal_button()
	# No need to setup_chiron_button() since it's in the scene already

func setup_journal_button():
	if not journal_button:
		journal_button = preload("res://Scenes/JournalButton.tscn").instantiate()
		add_child(journal_button)

func _on_apollo_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Apollo.tscn")

func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/MainMenu.tscn")

func _on_hermes_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Hermes.tscn")

func _on_artemis_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Artemis.tscn")
