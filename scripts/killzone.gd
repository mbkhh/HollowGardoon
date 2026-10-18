extends Area2D

@onready var timer: Timer = $Timer
@onready var explosion_sound: AudioStreamPlayer2D = $ExplosionSound

const ExplosionScene := preload("res://scenes/Effects/explosion.tscn")
func _on_body_entered(body: Node2D) -> void:
	explosion_sound.play()
	if body is Rocket:
		print('you died!')
		
		var explosion := ExplosionScene.instantiate()
		get_tree().current_scene.add_child(explosion)
		explosion.global_position = body.global_position
		
		Engine.time_scale = 0.5
		body.queue_free()
		timer.start()
		 # Replace with function body.


func _on_timer_timeout() -> void:
	Engine.time_scale = 1.0
	get_tree().reload_current_scene() # Replace with function body.
