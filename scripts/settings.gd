extends Node2D

@onready var music_slider: HSlider = $MusicSlider
@onready var sfx_slider: HSlider = $SfxSlider

func _ready() -> void:
	# Init sliders from current values
	music_slider.value = AudioManager.music_volume
	sfx_slider.value = AudioManager.sfx_volume

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/game.tscn")

func _on_sfx_slider_value_changed(value: float) -> void:
	AudioManager.set_sfx_volume(value)


func _on_music_slider_value_changed(value: float) -> void:
	AudioManager.set_music_volume(value)
