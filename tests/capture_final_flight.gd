extends "res://tests/test_ending_judge.gd"

func capture(name_text: String) -> void:
	await RenderingServer.frame_post_draw
	print("FLIGHT_CAPTURE ", name_text, ": ", root.get_texture().get_image().save_png("res://.godot/final-flight-validation/" + name_text + ".png"))

func _run() -> void:
	var saves = root.get_node("SaveManager")
	saves.set_script(load("res://tests/memory_save_manager.gd"))
	saves._init_default_data()
	await open_scene("res://scenes/Levels/level_15.tscn")
	var level = current_scene
	var rocket = level.get_node("Rocket")
	var flight = level.get_node("FinalFlight")
	var camera = level.get_node("FollowCamera2D")
	if "--reversed-exhaust" in OS.get_cmdline_user_args():
		rocket.clockwize = 1
		rocket.get_node("AnimatedSprite2D").flip_v = true
		rocket.fire.position.y = -1050
		rocket.fire.flip_h = true
	rocket.current_state = rocket.State.TRAVELING
	rocket.orbiting_planet = null
	rocket.teleport(flight.global_position - Vector2(140,0))
	rocket.preserved_velocity = Vector2(1000,0)
	camera.global_position = flight.global_position - Vector2(180,0)
	camera.force_update_scroll()
	for shot in [[0.8,"handoff"],[3.0,"darkening"],[7.0,"void"],[16.0,"approach"]]:
		for i in range(1500):
			if flight.elapsed >= float(shot[0]):
				break
			await frames(1)
		await capture(shot[1])
	for i in range(400):
		if flight.phase == flight.Phase.ARRIVING:
			break
		await frames(1)
	await frames(15)
	await capture("arrival")
	for i in range(400):
		if level.has_node("StoryEnding"):
			break
		await frames(1)
	await frames(5)
	await capture("ending")
	level.free()
	current_scene = null
	await frames(3)
	quit()
