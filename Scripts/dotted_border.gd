# res://Scripts/dotted_border.gd
class_name DottedBorder
extends Control

var border_color := Color(1.0, 1.0, 1.0, 1.0)  # White
var thickness := 3.0
var dot_length := 15.0
var gap_length := 20.0
var animation_speed := 30.0
var offset := 0.0
var wave_amplitude := 1.0
var wave_speed := 1.5
var time_elapsed := 0.0

func _process(delta):
	offset += animation_speed * delta
	time_elapsed += delta
	queue_redraw()

func _draw():
	var rect_size = size
	var total_length = dot_length + gap_length
	var current_offset = fmod(offset, total_length)
	
	# Pre-calculate all dashes and their wave positions
	var dash_segments = []
	
	# Top edge - wave only goes DOWN (inward)
	_collect_edge_dashes(0, rect_size.x, current_offset, total_length, func(x, wave):
		return Vector2(x, abs(wave)), 0.0, dash_segments)
	
	# Right edge - wave only goes LEFT (inward)
	_collect_edge_dashes(0, rect_size.y, current_offset, total_length, func(y, wave):
		return Vector2(rect_size.x - abs(wave), y), rect_size.x, dash_segments)
	
	# Bottom edge - wave only goes UP (inward)
	_collect_edge_dashes(0, rect_size.x, current_offset, total_length, func(x, wave):
		return Vector2(rect_size.x - x, rect_size.y - abs(wave)), rect_size.x + rect_size.y, dash_segments)
	
	# Left edge - wave only goes RIGHT (inward)
	_collect_edge_dashes(0, rect_size.y, current_offset, total_length, func(y, wave):
		return Vector2(abs(wave), rect_size.y - y), 2.0 * rect_size.x + rect_size.y, dash_segments)
	
	# Draw all collected dashes
	for segment in dash_segments:
		_draw_polyline(segment)

func _collect_edge_dashes(start: float, end: float, current_offset: float, total_length: float, point_func: Callable, perimeter_offset: float, dash_segments: Array):
	var current_dash = []
	var in_dash = false
	var current_wave = 0.0
	
	for i in range(int(start), int(end) + 1, 1):
		var perimeter_pos = perimeter_offset + i
		var pos_on_perimeter = perimeter_pos - current_offset
		
		# Normalize to 0-total_length range
		var normalized_pos = fmod(pos_on_perimeter, total_length)
		if normalized_pos < 0.0:
			normalized_pos += total_length
		
		var should_be_in_dash = normalized_pos < dot_length
		
		if should_be_in_dash:
			# Calculate wave based on which dash number this is
			var dot_index = floor(pos_on_perimeter / total_length)
			current_wave = sin(time_elapsed * wave_speed + dot_index * 0.8) * wave_amplitude
			
			var point = point_func.call(i, current_wave)
			current_dash.append(point)
			in_dash = true
		else:
			# We've exited the dash region
			if in_dash and current_dash.size() > 1:
				dash_segments.append(current_dash.duplicate())
			current_dash.clear()
			in_dash = false
	
	# Finish any remaining dash
	if current_dash.size() > 1:
		dash_segments.append(current_dash.duplicate())

func _draw_polyline(points: Array):
	for i in range(1, points.size()):
		draw_line(points[i-1], points[i], border_color, thickness, true)
