extends Area2D

@export var star_index: int = 0  # 0,1,2 for each level

signal collected(star_index: int)

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("rocket"):
		return

	# Tell level or global manager
	collected.emit(star_index)

	# TODO: play animation / sound here
	queue_free()
