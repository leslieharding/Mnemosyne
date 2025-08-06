# res://Resources/dialogue_line.gd
class_name DialogueLine
extends Resource

@export var speaker_id: String = ""
@export var text: String = ""
@export var speaker_position: String = "auto"

# NEW: Timing controls
@export var typing_speed_multiplier: float = 1.0  # 1.0 = normal, 0.5 = slower, 2.0 = faster
@export var pre_line_delay: float = 0.0  # Pause before starting typewriter (seconds)
@export var post_line_delay: float = 0.0  # Pause after finishing before allowing advance (seconds)
@export var mid_line_pauses: Array[Dictionary] = []  # Array of {position: int, delay: float}

func _init(speaker: String = "", dialogue_text: String = "", position: String = "auto", 
		   typing_speed: float = 1.0, pre_delay: float = 0.0, post_delay: float = 0.0):
	speaker_id = speaker
	text = dialogue_text
	speaker_position = position
	typing_speed_multiplier = typing_speed
	pre_line_delay = pre_delay
	post_line_delay = post_delay

# Helper function to add mid-line pauses
func add_mid_pause(character_position: int, delay_duration: float):
	mid_line_pauses.append({"position": character_position, "delay": delay_duration})
	# Sort by position to ensure pauses happen in correct order
	mid_line_pauses.sort_custom(func(a, b): return a.position < b.position)
