extends Control


@export var empty_star_texture: Texture2D        # dark / empty
@export var previous_star_texture: Texture2D     # blurred / low color
@export var current_star_texture: Texture2D 

@onready var star_icons := [
	$HBoxContainer/Star0,
	$HBoxContainer/Star1,
	$HBoxContainer/Star2,
]

func reset_stars() -> void:
	# Set all to empty at start
	for icon in star_icons:
		icon.texture = empty_star_texture
		

func show_previous_stars(count: int) -> void:
	# Show stars that were collected before (blurred)
	var capped: int = min(count, star_icons.size())
	for i in range(capped):
		star_icons[i].texture = previous_star_texture


func set_star_glowing(index: int) -> void:
	# Used when collecting during this run
	if index < 0 or index >= star_icons.size():
		return
	star_icons[index].texture = current_star_texture
