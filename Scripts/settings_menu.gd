extends Control

@onready var master_slider = $SettingsContainer/MasterVolumeContainer/HSlider
@onready var music_slider = $SettingsContainer/MusicVolumeContainer/HSlider
@onready var sfx_slider = $SettingsContainer/SFXVolumeContainer/HSlider
@onready var fullscreen_checkbox = $SettingsContainer/FullscreenContainer/CheckBox

func _ready():
	master_slider.value = SettingsManagerAutoload.master_volume
	music_slider.value = SettingsManagerAutoload.music_volume
	sfx_slider.value = SettingsManagerAutoload.sfx_volume
	fullscreen_checkbox.button_pressed = SettingsManagerAutoload.is_fullscreen

	master_slider.value_changed.connect(_on_master_changed)
	music_slider.value_changed.connect(_on_music_changed)
	sfx_slider.value_changed.connect(_on_sfx_changed)
	fullscreen_checkbox.toggled.connect(_on_fullscreen_toggled)

func _on_master_changed(value: float):
	SettingsManagerAutoload.set_master(value)

func _on_music_changed(value: float):
	SettingsManagerAutoload.set_music(value)

func _on_sfx_changed(value: float):
	SettingsManagerAutoload.set_sfx(value)

func _on_fullscreen_toggled(pressed: bool):
	SettingsManagerAutoload.set_fullscreen(pressed)

func _on_back_button_pressed() -> void:
	SoundManagerAutoload.play_randomized('click')
	TransitionManagerAutoload.change_scene_to("res://Scenes/MainMenu.tscn")
