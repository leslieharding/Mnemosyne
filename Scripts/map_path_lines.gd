# res://Scripts/map_path_lines.gd
class_name MapPathLines
extends Node2D

var map_nodes: Array = []
var dot_color: Color = Color(0.15, 0.1, 0.1, 0.9)
var dot_radius: float = 2.5
var dot_spacing: float = 18.0
var icon_radius: float = 48.0

# Stores per-connection curve data keyed by "from_id:to_id"
var curve_data: Dictionary = {}

func set_map_nodes(nodes: Array) -> void:
	map_nodes = nodes
	_generate_curve_data()
	queue_redraw()

func _generate_curve_data() -> void:
	curve_data.clear()
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for map_node in map_nodes:
		for connection_id in map_node.connections:
			var key := str(map_node.node_id) + ":" + str(connection_id)
			curve_data[key] = {
				# Amplitude in pixels — how far the curve bulges perpendicular to the line
				"amplitude": rng.randf_range(1.5, 5.5),
				# Phase shifts the sine so some lines dip first, others rise first
				"phase": rng.randf_range(0.0, TAU),
			}

func _draw() -> void:
	for map_node in map_nodes:
		for connection_id in map_node.connections:
			for other_node in map_nodes:
				if other_node.node_id == connection_id:
					var key := str(map_node.node_id) + ":" + str(connection_id)
					var amplitude: float = curve_data.get(key, {}).get("amplitude", 15.0)
					var phase: float    = curve_data.get(key, {}).get("phase", 0.0)
					_draw_curved_dotted_line(map_node.position, other_node.position, amplitude, phase)
					break

func _draw_curved_dotted_line(from: Vector2, to: Vector2, amplitude: float, phase: float) -> void:
	var total_length := from.distance_to(to)
	if total_length < icon_radius * 2.0:
		return

	var direction := (to - from).normalized()
	# Perpendicular to the line direction
	var perp := Vector2(-direction.y, direction.x)

	var draw_start := from + direction * icon_radius
	var draw_end   := to   - direction * icon_radius
	var draw_length := draw_start.distance_to(draw_end)

	var traveled := 0.0
	while traveled <= draw_length:
		# t goes 0→1 across the line; sine completes one full wave with the given phase
		var t := traveled / draw_length
		var wave_offset := sin(t * TAU + phase) * amplitude
		var point := draw_start + direction * traveled + perp * wave_offset
		draw_circle(point, dot_radius, dot_color)
		traveled += dot_spacing
