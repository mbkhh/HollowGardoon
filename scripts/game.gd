extends Node2D

@onready var game: Node2D = $"."
@onready var start: Button = $Buttons/Start
@onready var exit: Button = $Buttons/Exit
@onready var click_sound: AudioStreamPlayer2D = $ClickSound


func _on_button_button_down() -> void:
	print("hello world!!") # Replace with function body.
	SaveManager.judge_mode = false
	
	get_tree().change_scene_to_file("res://scenes/level_select.tscn")


func _on_button_2_button_down() -> void:
	
	print("Exit") # Replace with function body.
	get_tree().quit()

func _ready() -> void:
	$background/Planet.rotate_delta = 0.001
	$background/Planet2.rotate_delta = 0.001

func _process(delta: float) -> void:
	$Buttons/Setting.rotation -= 0.001


func _on_shop_pressed() -> void:
	
	get_tree().change_scene_to_file("res://scenes/shop.tscn")


func _on_setting_pressed() -> void:
	
	get_tree().change_scene_to_file("res://scenes/settings.tscn")


func _on_about_us_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/about us.tscn")

func _on_game_jam_judges_pressed() -> void:
	SaveManager.judge_mode = true
	get_tree().change_scene_to_file("res://scenes/level_select.tscn")
