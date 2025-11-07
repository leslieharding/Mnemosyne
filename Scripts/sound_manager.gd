extends Node

# Sound effect paths - change sounds here in one place
const SOUNDS = {
	"click": "res://Assets/SoundEffects/default_click.wav",
	"hover": "res://Assets/SoundEffects/default_on_hover.wav",
}

# Audio players pool
var sfx_players: Array[AudioStreamPlayer] = []
var max_players = 8
var current_player_index = 0

func _ready():
	# Create a pool of AudioStreamPlayer nodes
	for i in range(max_players):
		var player = AudioStreamPlayer.new()
		player.bus = "SFX"
		add_child(player)
		sfx_players.append(player)

func play(sound_name: String):
	if not SOUNDS.has(sound_name):
		push_error("Sound not found: " + sound_name)
		return
	
	# Get next available player (round-robin)
	var player = sfx_players[current_player_index]
	current_player_index = (current_player_index + 1) % max_players
	
	# Load and play the sound
	player.stream = load(SOUNDS[sound_name])
	player.play()

func play_hover():
	play("hover")

func play_click():
	play("click")
