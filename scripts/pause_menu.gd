extends Control
@onready var resumes: Button = $Resumes
@onready var repeat_button: Button = $RepeatButton
@onready var menu_button: Button = $MenuButton

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false   # make sure it's hidden at start

func open() -> void:
	visible = true

func close() -> void:
	visible = false


func _on_repeat_button_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _on_menu_button_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/game.tscn")


func _on_resumes_pressed() -> void:
	print("resume")
	get_tree().paused = false; # Replace with function body.
	close()
