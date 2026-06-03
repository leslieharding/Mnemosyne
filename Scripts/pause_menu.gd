# res://Scripts/pause_menu.gd
extends Control

signal resumed
signal save_exited
signal abandoned

@export var show_save_exit: bool = true

func _ready():
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var save_exit_button = find_child("SaveExitButton")
	if save_exit_button:
		save_exit_button.visible = show_save_exit

func _on_resume_button_pressed():
	SoundManagerAutoload.play("click")
	emit_signal("resumed")
	queue_free()

func _on_save_exit_button_pressed():
	SoundManagerAutoload.play("click")
	emit_signal("save_exited")
	queue_free()

func _on_options_button_pressed():
	SoundManagerAutoload.play("click")
	var settings_canvas = CanvasLayer.new()
	settings_canvas.layer = 95
	settings_canvas.name = "SettingsCanvas"
	get_tree().current_scene.add_child(settings_canvas)

	var settings = preload("res://Scenes/SettingsMenu.tscn").instantiate()
	settings.is_overlay = true
	settings_canvas.add_child(settings)

	# When settings closes, clean up its canvas layer
	settings.tree_exited.connect(func():
		if settings_canvas and is_instance_valid(settings_canvas):
			settings_canvas.queue_free()
	)

func _on_abandon_button_pressed():
	SoundManagerAutoload.play("click")
	emit_signal("abandoned")
	queue_free()
