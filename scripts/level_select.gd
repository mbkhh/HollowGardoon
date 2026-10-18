extends Control

@onready var grid := $MarginContainer/VBoxContainer/GridContainer
@onready var xp_label: Label = $MarginContainer/VBoxContainer/HBoxContainer/XPLabel

var level_button_scene := preload("res://scenes/UI/level_button.tscn")

const TOTAL_LEVELS := SaveManager.TOTAL_LEVELS

func _ready() -> void:
	$JudgeBanner.visible = SaveManager.judge_mode
	_update_xp_label()
	_create_level_buttons()


func _update_xp_label() -> void:
	xp_label.text = "%d" % SaveManager.xp


func _create_level_buttons():
	for i in range(SaveManager.TOTAL_LEVELS):
		var level_number := i + 1
		var level_id := "level_%d" % level_number

		var button := level_button_scene.instantiate()

		# Assume these nodes exist in the scene:
		var label: Label = button.get_node("Label")
		var star_container: HBoxContainer = button.get_node("HBoxContainer")

		label.text = "Level %d" % level_number

		var unlocked := _is_level_unlocked(level_number)
		button.disabled = not unlocked

		var stars := SaveManager.get_level_stars(level_id)
		for j in range(3):
			var star_tex: TextureRect = star_container.get_child(j)
			star_tex.visible = j < stars

		button.pressed.connect(_on_level_button_pressed.bind(level_id))
		grid.add_child(button)


func _is_level_unlocked(level_number: int) -> bool:
	if SaveManager.judge_mode:
		return true
	# Simple logic:
	# - Level 1 always unlocked
	# - Level n unlocked if level n-1 is completed
	if level_number == 1:
		return true

	var prev_level_id := "level_%d" % (level_number - 1)
	return SaveManager.is_level_completed(prev_level_id)


func _on_level_button_pressed(level_id: String) -> void:
	# Map level_id to scene path
	var scene_path := _get_scene_path_for_level(level_id)

	if ResourceLoader.exists(scene_path):
		get_tree().change_scene_to_file(scene_path)
	else:
		push_error("Scene for %s not found: %s" % [level_id, scene_path])


func _get_scene_path_for_level(level_id: String) -> String:
	# You can define a mapping rule like:
	# res://levels/level_1.tscn, res://levels/level_2.tscn, ...
	return "res://scenes/Levels/%s.tscn" % level_id


#Reza: back button
func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/game.tscn")
