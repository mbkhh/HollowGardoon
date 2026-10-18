extends Node2D


func _ready() -> void:
	# Init sliders from current values
	pass

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/game.tscn")


func _on_rich_text_label_meta_clicked(meta: Variant) -> void:
	OS.shell_open(str(meta))
