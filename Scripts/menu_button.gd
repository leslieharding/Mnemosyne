# res://Scripts/menu_button.gd
extends Button

signal menu_opened(menu_instance)

var pause_menu_instance: Control = null
var show_save_exit: bool = true
var hover_tween: Tween

func _ready():
	pressed.connect(_on_pressed)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func _on_mouse_entered():
	if hover_tween:
		hover_tween.kill()
	pivot_offset = size / 2
	hover_tween = create_tween()
	hover_tween.tween_property(self, "scale", Vector2(1.1, 1.1), 0.2).set_ease(Tween.EASE_OUT)

func _on_mouse_exited():
	if hover_tween:
		hover_tween.kill()
	hover_tween = create_tween()
	hover_tween.tween_property(self, "scale", Vector2.ONE, 0.2).set_ease(Tween.EASE_OUT)

func _on_pressed():
	SoundManagerAutoload.play("click")
	if pause_menu_instance and is_instance_valid(pause_menu_instance):
		return

	var menu_canvas = CanvasLayer.new()
	menu_canvas.layer = 90
	menu_canvas.name = "PauseMenuCanvas"
	get_tree().current_scene.add_child(menu_canvas)

	pause_menu_instance = preload("res://Scenes/PauseMenu.tscn").instantiate()
	pause_menu_instance.show_save_exit = show_save_exit
	menu_canvas.add_child(pause_menu_instance)

	pause_menu_instance.resumed.connect(_on_menu_resumed)
	emit_signal("menu_opened", pause_menu_instance)

func _on_menu_resumed():
	_cleanup_menu()

func _cleanup_menu():
	if pause_menu_instance and is_instance_valid(pause_menu_instance):
		var canvas = get_tree().current_scene.get_node_or_null("PauseMenuCanvas")
		if canvas:
			canvas.queue_free()
	pause_menu_instance = null
