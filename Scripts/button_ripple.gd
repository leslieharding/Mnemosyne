extends RefCounted
class_name ButtonRipple

var button: Button
var overlay: ColorRect
var shader_material: ShaderMaterial
var is_mouse_over: bool = false
var center1: Vector2 = Vector2(0.5, 0.5)
var center2: Vector2 = Vector2(0.5, 0.5)
var exit_tween: Tween

func _init(target_button: Button):
	button = target_button
	
	# Create overlay ColorRect as a child of the button
	overlay = ColorRect.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.color = Color(1, 1, 1, 0)  # Transparent
	button.add_child(overlay)
	
	# Load and set up shader on the overlay
	var shader = load("res://Shaders/button_ripple.gdshader")
	if not shader:
		push_error("Failed to load button_ripple.gdshader")
		return
	
	shader_material = ShaderMaterial.new()
	shader_material.shader = shader
	overlay.material = shader_material
	
	# Initialize shader parameters
	shader_material.set_shader_parameter("size", button.size)
	shader_material.set_shader_parameter("time1", 1.0)
	shader_material.set_shader_parameter("time2", 0.0)
	shader_material.set_shader_parameter("center1", center1)
	shader_material.set_shader_parameter("center2", center2)
	shader_material.set_shader_parameter("glow", 0.0)
	
	# Get corner radius from button style
	var normal_style = button.get_theme_stylebox("normal")
	if normal_style and normal_style is StyleBoxFlat:
		shader_material.set_shader_parameter("corner_radius", normal_style.corner_radius_top_left / button.size.y * 2)
	
	# Use white for the effect color (will blend with button colors)
	shader_material.set_shader_parameter("color", Color(1, 1, 1, 1))

func on_mouse_entered():
	is_mouse_over = true
	
	# Stop exit animation if running
	if exit_tween:
		exit_tween.kill()
	
	# Animate glow
	var tween = button.create_tween()
	tween.tween_property(shader_material, "shader_parameter/glow", 2.0, 0.2)
	
	# Animate hover highlight
	button.create_tween().tween_property(shader_material, "shader_parameter/time2", 0.35, 0.2)

func on_mouse_exited():
	is_mouse_over = false
	
	var center = Vector2(0.5, 0.5)
	var exit_target = center + (center2 - center).normalized() * 2.0
	
	# Create exit animation
	exit_tween = button.create_tween()
	exit_tween.parallel().tween_property(self, "center2", exit_target, 0.3)
	exit_tween.parallel().tween_property(shader_material, "shader_parameter/time2", 0.0, 0.3)
	exit_tween.parallel().tween_property(shader_material, "shader_parameter/glow", 0.0, 0.2)
	exit_tween.tween_callback(func(): center2 = Vector2(0.5, 0.5))

func on_pressed():
	# Set click position as center
	center1 = (button.get_global_transform().affine_inverse() * button.get_global_mouse_position()) / button.size
	
	# Create click animation
	button.create_tween().tween_property(shader_material, "shader_parameter/time1", 1.0, 0.5).from(0.0)

func update_mouse_position():
	if is_mouse_over:
		var local_mouse = (button.get_global_transform().affine_inverse() * button.get_global_mouse_position()) / button.size
		center2 = local_mouse
		shader_material.set_shader_parameter("center2", center2)
		shader_material.set_shader_parameter("center1", center1)
