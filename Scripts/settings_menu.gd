extends Control

# Audio Bus indices
const MASTER_BUS = 0
const MUSIC_BUS = 1
const SFX_BUS = 2
const VOICE_BUS = 3

# Common resolutions
var resolutions = [
	Vector2(1280, 720),
	Vector2(1366, 768),
	Vector2(1600, 900),
	Vector2(1920, 1080),
	Vector2(2560, 1440),
	Vector2(3840, 2160)
]

# References to UI nodes
@onready var master_slider = $SettingsContainer/TabContainer/Audio/MasterVolumeContainer/HSlider
@onready var music_slider = $SettingsContainer/TabContainer/Audio/MusicVolumeContainer2/HSlider
@onready var sfx_slider = $SettingsContainer/TabContainer/Audio/SFXVolumeContainer3/HSlider
@onready var voice_slider = $SettingsContainer/TabContainer/Audio/VoiceVolumeContainer4/HSlider

# Video settings UI references
@onready var resolution_dropdown = $SettingsContainer/TabContainer/Video/ResolutionContainer/OptionButton
@onready var fullscreen_checkbox = $SettingsContainer/TabContainer/Video/FullscreenToggleContainer/CheckBox
@onready var brightness_slider = $SettingsContainer/TabContainer/Video/BrightnessContainer/HSlider

func _ready():
	# Setup resolution dropdown
	_setup_resolution_dropdown()
	
	# Connect audio signals
	master_slider.value_changed.connect(_on_master_volume_changed)
	music_slider.value_changed.connect(_on_music_volume_changed)
	sfx_slider.value_changed.connect(_on_sfx_volume_changed)
	voice_slider.value_changed.connect(_on_voice_volume_changed)
	
	# Connect video signals
	resolution_dropdown.item_selected.connect(_on_resolution_selected)
	fullscreen_checkbox.toggled.connect(_on_fullscreen_toggled)
	brightness_slider.value_changed.connect(_on_brightness_changed)
	
	# Load saved settings
	load_settings()

func _setup_resolution_dropdown():
	resolution_dropdown.clear()
	for i in range(resolutions.size()):
		var res = resolutions[i]
		resolution_dropdown.add_item(str(res.x) + "×" + str(res.y))
	
	# Select current resolution if it exists in the list
	var current_res = Vector2(DisplayServer.window_get_size())
	for i in range(resolutions.size()):
		if resolutions[i] == current_res:
			resolution_dropdown.select(i)
			break

# Audio handling functions
func _on_master_volume_changed(value):
	var db = linear_to_db(value / 100.0)
	AudioServer.set_bus_volume_db(MASTER_BUS, db)
	save_settings()

func _on_music_volume_changed(value):
	var db = linear_to_db(value / 100.0)
	AudioServer.set_bus_volume_db(MUSIC_BUS, db)
	save_settings()

func _on_sfx_volume_changed(value):
	var db = linear_to_db(value / 100.0)
	AudioServer.set_bus_volume_db(SFX_BUS, db)
	save_settings()

func _on_voice_volume_changed(value):
	var db = linear_to_db(value / 100.0)
	AudioServer.set_bus_volume_db(VOICE_BUS, db)
	save_settings()

# Video handling functions
func _on_resolution_selected(index):
	if index >= 0 and index < resolutions.size():
		var new_resolution = resolutions[index]
		DisplayServer.window_set_size(new_resolution)
		# Center the window after changing resolution
		var screen_size = DisplayServer.screen_get_size()
		var window_size = DisplayServer.window_get_size()
		DisplayServer.window_set_position(
			Vector2i((screen_size.x - window_size.x) / 2, (screen_size.y - window_size.y) / 2)
		)
		save_settings()

func _on_fullscreen_toggled(button_pressed):
	if button_pressed:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	save_settings()

func _on_brightness_changed(value):
	# Apply brightness value to your game
	# This is typically done using a shader or post-processing effect
	# For this example, we'll just save the value
	save_settings()

# Save all settings
func save_settings():
	var config = ConfigFile.new()
	
	# Save audio settings
	config.set_value("audio", "master", master_slider.value)
	config.set_value("audio", "music", music_slider.value)
	config.set_value("audio", "sfx", sfx_slider.value)
	config.set_value("audio", "voice", voice_slider.value)
	
	# Save video settings
	config.set_value("video", "resolution_index", resolution_dropdown.selected)
	config.set_value("video", "fullscreen", fullscreen_checkbox.button_pressed)
	config.set_value("video", "brightness", brightness_slider.value)
	
	config.save("user://settings.cfg")

# Load all settings
func load_settings():
	var config = ConfigFile.new()
	var err = config.load("user://settings.cfg")
	
	if err == OK:
		# Load audio settings
		master_slider.value = config.get_value("audio", "master", 80)
		music_slider.value = config.get_value("audio", "music", 80)
		sfx_slider.value = config.get_value("audio", "sfx", 80)
		voice_slider.value = config.get_value("audio", "voice", 80)
		
		# Load video settings
		var res_index = config.get_value("video", "resolution_index", 3)  # Default to 1080p
		if res_index >= 0 and res_index < resolution_dropdown.item_count:
			resolution_dropdown.select(res_index)
			_on_resolution_selected(res_index)
		
		var is_fullscreen = config.get_value("video", "fullscreen", false)
		fullscreen_checkbox.button_pressed = is_fullscreen
		_on_fullscreen_toggled(is_fullscreen)
		
		brightness_slider.value = config.get_value("video", "brightness", 100)
		_on_brightness_changed(brightness_slider.value)


func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/MainMenu.tscn")
