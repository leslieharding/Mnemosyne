# res://Scripts/volley_direction_modal.gd
extends Control
class_name VolleyDirectionModal

signal direction_selected(direction: int)

var background_panel: ColorRect
var buttons_container: GridContainer
var up_button: Button
var down_button: Button
var left_button: Button
var right_button: Button

func _ready():
	setup_modal_ui()

func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_W, KEY_UP:
				select_direction(0)
			KEY_D, KEY_RIGHT:
				select_direction(1)
			KEY_S, KEY_DOWN:
				select_direction(2)
			KEY_A, KEY_LEFT:
				select_direction(3)

func setup_modal_ui():
	background_panel = $BackgroundPanel
	buttons_container = $ButtonsContainer
	up_button = $ButtonsContainer/UpButton
	right_button = $ButtonsContainer/RightButton
	down_button = $ButtonsContainer/DownButton
	left_button = $ButtonsContainer/LeftButton
	
	up_button.pressed.connect(func(): select_direction(0))
	right_button.pressed.connect(func(): select_direction(1))
	down_button.pressed.connect(func(): select_direction(2))
	left_button.pressed.connect(func(): select_direction(3))
	
	set_process_input(true)
	
	print("VolleyDirectionModal UI setup complete")

func select_direction(direction: int):
	print("Volley direction selected: ", direction)
	emit_signal("direction_selected", direction)
	queue_free()
