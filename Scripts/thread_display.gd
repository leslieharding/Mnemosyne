extends Control

const LINE_X: float = 0.98
const LINE_TOP: float = 0.1
const LINE_BOTTOM: float = 0.9
const DOT_RADIUS: float = 8.0
const TWEEN_DURATION: float = 0.4
const THREAD_WIDTH: float = 80.0

# Shake constants - escalate with losing severity
const SHAKE_AMPLITUDE: Array = [0.0, 0.1, 0.3, 0.8, 1.0]  # index = losing level 0-4
const SHAKE_FREQ: Array     = [0.0, 1.0, 1.5, 1.8, 2.0]  # index = losing level 0-4

# Y positions as fractions of screen height
# Normalized diff = (player - opponent) / 2, range -4 to +4
# Positive = winning (dot moves DOWN = thread loose)
# Negative = losing  (dot moves UP   = thread tight)
const POSITIONS: Dictionary = {
	 4: 0.90,
	 3: 0.80,
	 2: 0.70,
	 1: 0.60,
	 0: 0.50,
	-1: 0.40,
	-2: 0.30,
	-3: 0.20,
	-4: 0.10,
}

var dot_y_fraction: float = 0.5
var tween: Tween
var thread_texture: Texture2D

var shake_amplitude: float = 0.0
var shake_frequency: float = 0.0
var shake_time: float = 0.0
var shake_offset: float = 0.0

func _ready():
	thread_texture = load("res://Assets/Images/thread_placeholder.png")

func _process(delta: float):
	if shake_amplitude > 0.0:
		shake_time += delta
		shake_offset = sin(shake_time * shake_frequency) * shake_amplitude
		queue_redraw()
	elif shake_offset != 0.0:
		shake_offset = 0.0
		queue_redraw()

func _draw():
	var w = size.x
	var h = size.y
	var x = w * LINE_X
	var top = h * LINE_TOP
	var bottom = h * LINE_BOTTOM

	# Draw the thread image rotated 90 degrees to run vertically
	var thread_length = bottom - top
	if thread_texture:
		var cx = x + shake_offset
		var cy = (top + bottom) / 2.0
		draw_set_transform(Vector2(cx, cy), PI / 2.0, Vector2.ONE)
		draw_texture_rect(
			thread_texture,
			Rect2(-thread_length / 2.0, -THREAD_WIDTH / 2.0, thread_length, THREAD_WIDTH),
			false
		)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	else:
		draw_line(Vector2(x, top), Vector2(x, bottom), Color(0.8, 0.8, 0.8, 0.6), 2.0)

	# Draw the dot
	var dot_y = top + (bottom - top) * remap(dot_y_fraction, LINE_TOP, LINE_BOTTOM, 0.0, 1.0)
	draw_circle(Vector2(x + shake_offset, dot_y), DOT_RADIUS, Color(1.0, 1.0, 1.0, 0.9))

func update_score(player: int, opponent: int):
	# Normalize: each capture = 1 unit, scores always sum to 10
	var diff = clampi((player - opponent) / 2, -4, 4)
	var target_fraction = POSITIONS[diff]

	# Set shake based on how many captures behind
	var losing_level = clampi(-diff, 0, 4)
	shake_amplitude = SHAKE_AMPLITUDE[losing_level]
	shake_frequency = SHAKE_FREQ[losing_level]
	if losing_level == 0:
		shake_time = 0.0

	if tween:
		tween.kill()
	tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_method(_set_dot_y, dot_y_fraction, target_fraction, TWEEN_DURATION)

func _set_dot_y(val: float):
	dot_y_fraction = val
	queue_redraw()
