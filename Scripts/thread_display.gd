extends Control

const LINE_X: float = 0.95        # 85% across screen = right side
const LINE_TOP: float = 0.1       # line starts at 10% down
const LINE_BOTTOM: float = 0.9    # line ends at 90% down
const DOT_RADIUS: float = 8.0
const TWEEN_DURATION: float = 0.4

# Y positions as fractions of screen height for each score state
const POSITIONS: Dictionary = {
	2:  0.82,   # player +2 = dot low (winning, thread loose)
	1:  0.65,
	0:  0.50,
	-1: 0.35,
	-2: 0.18    # player -2 = dot high (losing, thread tight)
}

var dot_y_fraction: float = 0.5
var tween: Tween

func _draw():
	var w = size.x
	var h = size.y
	var x = w * LINE_X
	var top = h * LINE_TOP
	var bottom = h * LINE_BOTTOM

	# Draw the line
	draw_line(Vector2(x, top), Vector2(x, bottom), Color(0.8, 0.8, 0.8, 0.6), 2.0)

	# Draw the dot
	var dot_y = top + (bottom - top) * remap(dot_y_fraction, LINE_TOP, LINE_BOTTOM, 0.0, 1.0)
	draw_circle(Vector2(x, dot_y), DOT_RADIUS, Color(1.0, 1.0, 1.0, 0.9))

func update_score(player: int, opponent: int):
	var diff = clampi(player - opponent, -2, 2)
	var target_fraction = POSITIONS[diff]

	if tween:
		tween.kill()
	tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_method(_set_dot_y, dot_y_fraction, target_fraction, TWEEN_DURATION)

func _set_dot_y(val: float):
	dot_y_fraction = val
	queue_redraw()
