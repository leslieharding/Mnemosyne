extends Node

# Sound effect paths - change sounds here in one place
const SOUNDS = {
	#basic default navigation
	"click": "res://Assets/SoundEffects/default_click.wav",
	"hover": "res://Assets/SoundEffects/default_on_hover.wav",
	
	# In Battle Navigation Sounds
	
	"on_card_click": "res://Assets/SoundEffects/on_card_click.wav",
	
	# Dialogue tones
	"mnemosyne_default": "res://Assets/SoundEffects/mnemosyne_default.wav",
	"mnemosyne_happy": "res://Assets/SoundEffects/mnemosyne_happy.wav",
	"mnemosyne_funny": "res://Assets/SoundEffects/mnemosyne_funny.wav",
	"mnemosyne_angry": "res://Assets/SoundEffects/mnemosyne_angry.wav",
	"mnemosyne_sad": "res://Assets/SoundEffects/mnemosyne_sad.wav",
	"chiron_default": "res://Assets/SoundEffects/chiron_default.wav",
	"chiron_happy": "res://Assets/SoundEffects/chiron_happy.wav",
	"chiron_funny": "res://Assets/SoundEffects/chiron_funny.wav",
	"chiron_angry": "res://Assets/SoundEffects/chiron_angry.wav",
	"chiron_sad": "res://Assets/SoundEffects/chiron_sad.wav",
	"chronos_default": "res://Assets/SoundEffects/chronos_default.wav",
	"chronos_happy": "res://Assets/SoundEffects/chronos_happy.wav",
	"chronos_funny": "res://Assets/SoundEffects/chronos_funny.wav",
	"chronos_angry": "res://Assets/SoundEffects/chronos_angry.wav",
	"chronos_sad": "res://Assets/SoundEffects/chronos_sad.wav",
	"odin_default": "res://Assets/SoundEffects/odin_default.wav",
	"odin_happy": "res://Assets/SoundEffects/odin_happy.wav",
	"odin_funny": "res://Assets/SoundEffects/odin_funny.wav",
	"odin_angry": "res://Assets/SoundEffects/odin_angry.wav",
	"odin_sad": "res://Assets/SoundEffects/odin_sad.wav",
	
	
	# Run Map Actions
	"battle_entered": "res://Assets/SoundEffects/battle_entered.wav",
	
	# Dialogue actions
	"dialogue_complete": "res://Assets/SoundEffects/dialogue_complete.wav",
	"dialogue_skip": "res://Assets/SoundEffects/dialogue_skip.wav",
	
	# God Mod Select Sounds
	"apollo_hover": "res://Assets/SoundEffects/apollo_hover.wav",
	"artemis_hover": "res://Assets/SoundEffects/artemis_hover.wav",
	"hermes_hover": "res://Assets/SoundEffects/hermes_hover.wav",
	"demeter_hover": "res://Assets/SoundEffects/demeter_hover.wav",
	
	#Memory Journal Navigation
	"light_page_turn": "res://Assets/SoundEffects/light_page_turn.wav",
	"heavy_page_turn": "res://Assets/SoundEffects/heavy_page_turn.wav",
	"memory_journal_close": "res://Assets/SoundEffects/memory_journal_close.wav",
	"memory_journal_open": "res://Assets/SoundEffects/memory_journal_open.wav",
	
	#Deck Selection Screen Navigation
	"deck_sun_unlocked": "res://Assets/SoundEffects/deck_sun_unlocked.wav",
	"deck_music_unlocked": "res://Assets/SoundEffects/deck_music_unlocked.wav",
	"deck_prophecy_unlocked": "res://Assets/SoundEffects/deck_prophecy_unlocked.wav",
	"deck_locked": "res://Assets/SoundEffects/deck_locked.wav",
	"run_start": "res://Assets/SoundEffects/run_start.wav",
	
}

# Music paths
const MUSIC = {
	"menu_theme": "res://Assets/Music/menu_theme.ogg",
	"battle_theme": "res://Assets/Music/battle_theme.ogg",
}


# Audio players pool
var sfx_players: Array[AudioStreamPlayer] = []
var max_players = 8
var current_player_index = 0

# Dedicated music player
var music_player: AudioStreamPlayer

# Hover sound tracking
var card_hover_player: AudioStreamPlayer = null
var card_hover_sound_playing: bool = false
var god_hover_player: AudioStreamPlayer = null
var god_hover_fade_tween: Tween = null

func _ready():
	# Create a pool of AudioStreamPlayer nodes
	for i in range(max_players):
		var player = AudioStreamPlayer.new()
		player.bus = "Sounds"
		add_child(player)
		sfx_players.append(player)
	
	# Create dedicated card hover player
	card_hover_player = AudioStreamPlayer.new()
	card_hover_player.bus = "Sounds"
	add_child(card_hover_player)
	card_hover_player.finished.connect(_on_card_hover_finished)
	
	
	# Create dedicated god hover player
	god_hover_player = AudioStreamPlayer.new()
	god_hover_player.bus = "Sounds"
	add_child(god_hover_player)
	
	
	# Create music player
	music_player = AudioStreamPlayer.new()
	music_player.bus = "Music"
	add_child(music_player)	

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


# Music functions
func play_music(music_name: String, fade_duration: float = 0.0):
	if not MUSIC.has(music_name):
		push_error("Music not found: " + music_name)
		return
	
	music_player.stream = load(MUSIC[music_name])
	music_player.play()

func stop_music(fade_duration: float = 0.0):
	music_player.stop()


func play_dialogue_tone(tone: String):
	var sound_key = "dialogue_" + tone
	play(sound_key)

func play_dialogue_complete():
	play("dialogue_complete")

func play_dialogue_skip():
	play("dialogue_skip")


func play_on_card_click():
	play("on_card_click")	

func _on_card_hover_finished():
	card_hover_sound_playing = false

func play_god_hover(god_name: String):
	var sound_key = god_name.to_lower() + "_hover"
	
	# Check if this sound exists
	if not SOUNDS.has(sound_key):
		push_error("God hover sound not found: " + sound_key)
		return
	
	# If fade tween exists, we need to check if we're in grace period or actually fading
	if god_hover_fade_tween:
		# Check current volume - if it's still at 0db, we're in grace period
		if god_hover_player.volume_db >= -1:
			print("In grace period - cancelling fade, keeping sound")
			god_hover_fade_tween.kill()
			god_hover_fade_tween = null
			return  # Keep the existing sound playing
		else:
			# Volume has started changing - we're fading out, need fresh start
			print("Fade in progress - stopping and restarting")
			god_hover_fade_tween.kill()
			god_hover_fade_tween = null
			god_hover_player.stop()
			god_hover_player.volume_db = 0
			god_hover_player.stream = load(SOUNDS[sound_key])
			god_hover_player.play()
			return
	
	# Only restart if not currently playing
	if not god_hover_player.playing:
		print("Starting new god hover sound")
		god_hover_player.stream = load(SOUNDS[sound_key])
		god_hover_player.volume_db = 0
		god_hover_player.play()
	else:
		print("God hover already playing, keeping it")

func stop_god_hover_with_fade(delay: float = 0.8, fade_duration: float = 1.3):
	if not god_hover_player or not god_hover_player.playing:
		return
	
	# Kill any existing fade tween
	if god_hover_fade_tween:
		god_hover_fade_tween.kill()
	
	# Create fade-out sequence
	god_hover_fade_tween = create_tween()
	god_hover_fade_tween.tween_interval(delay)
	god_hover_fade_tween.tween_property(god_hover_player, "volume_db", -80, fade_duration)
	god_hover_fade_tween.tween_callback(func(): 
		god_hover_player.stop()
		god_hover_player.volume_db = 0
	)
