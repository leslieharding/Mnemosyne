extends Node

const SETTINGS_FILE = "user://settings.cfg"
const MASTER_BUS = 0
const SFX_BUS = 1
const MUSIC_BUS = 2

var master_volume: float = 80.0
var music_volume: float = 80.0
var sfx_volume: float = 80.0
var is_fullscreen: bool = false

func _ready():
	load_and_apply()

func load_and_apply():
	var config = ConfigFile.new()
	if config.load(SETTINGS_FILE) == OK:
		master_volume = config.get_value("audio", "master", 80.0)
		music_volume = config.get_value("audio", "music", 80.0)
		sfx_volume = config.get_value("audio", "sfx", 80.0)
		is_fullscreen = config.get_value("video", "fullscreen", false)
	apply_audio()
	apply_video()

func apply_audio():
	AudioServer.set_bus_volume_db(MASTER_BUS, _to_db(master_volume))
	AudioServer.set_bus_mute(MASTER_BUS, master_volume == 0)
	AudioServer.set_bus_volume_db(MUSIC_BUS, _to_db(music_volume))
	AudioServer.set_bus_mute(MUSIC_BUS, music_volume == 0)
	AudioServer.set_bus_volume_db(SFX_BUS, _to_db(sfx_volume))
	AudioServer.set_bus_mute(SFX_BUS, sfx_volume == 0)

func apply_video():
	if is_fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func set_master(value: float):
	master_volume = value
	AudioServer.set_bus_volume_db(MASTER_BUS, _to_db(value))
	AudioServer.set_bus_mute(MASTER_BUS, value == 0)
	save()

func set_music(value: float):
	music_volume = value
	AudioServer.set_bus_volume_db(MUSIC_BUS, _to_db(value))
	AudioServer.set_bus_mute(MUSIC_BUS, value == 0)
	save()

func set_sfx(value: float):
	sfx_volume = value
	AudioServer.set_bus_volume_db(SFX_BUS, _to_db(value))
	AudioServer.set_bus_mute(SFX_BUS, value == 0)
	save()

func set_fullscreen(value: bool):
	is_fullscreen = value
	apply_video()
	save()

func save():
	var config = ConfigFile.new()
	config.set_value("audio", "master", master_volume)
	config.set_value("audio", "music", music_volume)
	config.set_value("audio", "sfx", sfx_volume)
	config.set_value("video", "fullscreen", is_fullscreen)
	config.save(SETTINGS_FILE)

func _to_db(value: float) -> float:
	if value <= 0.0:
		return -80.0
	return linear_to_db(value / 100.0)
