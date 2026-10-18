extends "res://tests/test_ending_judge.gd"

func until(predicate: Callable, message: String, limit: int = 1600) -> void:
	for i in range(limit):
		if predicate.call():
			return
		await frames(1)
	check(false, "Timeout: " + message)

func launch_at_line(level: Node, speed: float = 1000) -> void:
	var rocket = level.get_node("Rocket")
	var flight = level.get_node("FinalFlight")
	rocket.current_state = rocket.State.TRAVELING
	rocket.orbiting_planet = null
	rocket.teleport(flight.global_position - Vector2(120,0))
	rocket.preserved_velocity = Vector2(speed,0)
	await until(func(): return flight.phase == flight.Phase.FLYING, "crossing end line", 60)

func _run() -> void:
	var saves = root.get_node("SaveManager")
	saves.set_script(load("res://tests/memory_save_manager.gd"))
	saves._init_default_data()
	await open_scene("res://scenes/Levels/level_15.tscn")
	var level = current_scene
	var flight = level.get_node("FinalFlight")
	var rocket = level.get_node("Rocket")
	var goal = level.get_node("goal planet/Planet8")
	check(goal.global_position.x - flight.global_position.x > 9000, "Flag planet is far beyond playable level")
	check(flight.global_position.x > level.get_node("wormwholes/Whitehole9").global_position.x + 200, "End line is beyond final ordinary obstacles")
	check(flight.phase == flight.Phase.PLAYING and rocket.is_physics_processing() and not rocket.freeze, "Normal play is untouched before trigger")
	check(not flight.get_node("Darkness").visible and not flight.get_node("Actors").visible, "No cinematic overlay during normal play")
	check(flight.get_node("Trigger/EndLine").shape.size.y > 1700, "Invisible line spans full playable height")
	var other := Node2D.new()
	flight._on_trigger_body_entered(other)
	other.free()
	check(flight.phase == flight.Phase.PLAYING, "Only rocket can activate line")
	# Even a remote/early goal event cannot skip the final voyage.
	goal.goal_reached.emit(rocket)
	check(not level.level_finished and saves.save_calls == 0, "Premature goal signal cannot skip voyage or save rewards")
	level.stars_collected = 2
	# Reproduce a charged reverse orbit: the old negative flame offset used
	# to survive the cinematic's skin reset and put exhaust at the nose.
	rocket.clockwize = 1
	rocket.get_node("AnimatedSprite2D").flip_v = true
	rocket.fire.position.y = -1050
	rocket.fire.flip_h = true
	await launch_at_line(level)
	check(rocket.freeze and not rocket.is_physics_processing(), "Autopilot owns movement instead of gravity/polling input")
	check(not rocket.is_processing_unhandled_input(), "Rocket's event controls are disabled")
	check(rocket.collision_layer == 32 and rocket.collision_mask == 0, "Cinematic flight cannot hit hazards or wormholes")
	check(not level.get_node("CanvasLayer").visible and not rocket.get_node("CanvasLayer").visible, "Cinematic hides pause and rocket buttons")
	var direction = rocket.clockwize
	await key(KEY_SPACE, true)
	await key(KEY_Z, true)
	await key(KEY_X, true)
	await key(KEY_ESCAPE, true)
	var mouse := InputEventMouseButton.new()
	mouse.button_index = MOUSE_BUTTON_LEFT
	mouse.pressed = true
	Input.parse_input_event(mouse)
	var touch := InputEventScreenTouch.new()
	touch.index = 0
	touch.pressed = true
	Input.parse_input_event(touch)
	await frames(10)
	check(not paused and not level.pause_menu.visible, "Escape cannot interrupt cinematic")
	check(not rocket.is_charging and rocket.charge_time == 0 and rocket.clockwize == direction, "Keyboard, mouse and touch cannot steer, charge or reverse")
	await key(KEY_Z, false)
	await key(KEY_X, false)
	await key(KEY_ESCAPE, false)
	mouse.pressed = false
	Input.parse_input_event(mouse)
	touch.pressed = false
	Input.parse_input_event(touch)
	await until(func(): return flight.elapsed >= 3, "gradual fade")
	var skin: AnimatedSprite2D = rocket.get_node("AnimatedSprite2D")
	check((rocket.fire.global_position - skin.global_position).dot(-skin.global_transform.y.normalized()) < -10, "Reversed-orbit flame is behind rocket's nose")
	var copy: Node2D = flight._actor_pairs[0][1]
	var copied_fire: Node2D = copy.get_node("AnimatedSprite2D")
	check((copied_fire.global_position - copy.global_position).dot(-copy.global_transform.y.normalized()) < -10, "Rendered cinematic flame stays behind rocket")
	check(flight.darkness > 0.1 and flight.darkness < 0.9, "Background fades gradually before becoming black")
	check(rocket.global_position.x > flight.global_position.x + 300, "Autopilot travels through world")
	check(not level.has_node("StoryEnding") and saves.save_calls == 0, "Text and rewards wait for arrival")
	await until(func(): return flight.elapsed >= flight.darken_duration + 0.2, "full darkness")
	check(is_equal_approx(flight.darkness, 1), "Background reaches full black")
	check(goal.global_position.x - rocket.global_position.x > 4000 and flight.phase == flight.Phase.FLYING, "Long flight continues after full darkness")
	check(flight._actor_pairs.size() == 3 and flight._glows.size() == 2, "Rocket, goal and flag remain visible above black, with soft glows")
	await until(func(): return flight.phase == flight.Phase.ARRIVING, "actual final planet arrival")
	check(is_zero_approx(rocket.fire.scale.x), "Flame extinguishes on final arrival")
	check(goal.get_node("GravityWell").overlaps_body(rocket), "Actual goal area detects the cinematic rocket")
	check(rocket.global_position.distance_to(goal.global_position) <= goal.orbit_radius + 1, "Rocket reaches planet's orbit")
	check(not level.has_node("StoryEnding") and not level.level_finished, "Arrival shot precedes ending text")
	await until(func(): return level.has_node("StoryEnding"), "ending after arrival hold")
	check(paused and flight.phase == flight.Phase.COMPLETE, "Ending appears only after voyage and arrival")
	check(saves.get_level_stars("level_15") == 2 and saves.xp == 20, "Final result records once after arrival")
	check(is_equal_approx(Engine.time_scale, 1), "Safe voyage does not trigger death slow motion")
	var writes: int = saves.save_calls
	goal.goal_reached.emit(rocket)
	check(saves.save_calls == writes, "Duplicate final arrival cannot duplicate rewards")
	# Space held during flight must not dismiss the story on its first release.
	await key(KEY_SPACE, false)
	await frames(4)
	check(current_scene == level and level.has_node("StoryEnding"), "Held flight input cannot dismiss ending")
	await key(KEY_SPACE, true)
	await key(KEY_SPACE, false)
	await frames(4)
	check(not paused and current_scene.scene_file_path.ends_with("game.tscn"), "Ending exits cleanly to main menu")
	# Swept crossing catches a high-speed launch through the thin trigger.
	await open_scene("res://scenes/Levels/level_15.tscn")
	level = current_scene
	flight = level.get_node("FinalFlight")
	await launch_at_line(level, 18000)
	check(flight.phase == flight.Phase.FLYING, "Very fast crossing still starts autopilot")
	reload_current_scene()
	await frames(5)
	flight = current_scene.get_node("FinalFlight")
	check(flight.phase == flight.Phase.PLAYING and flight.darkness == 0 and not flight.get_node("Darkness").visible, "Reload resets cinematic, fade and input")
	check(not current_scene.get_node("Rocket").freeze and current_scene.get_node("Rocket").is_physics_processing(), "Reload restores normal rocket")
	await open_scene("res://scenes/Levels/level_14.tscn")
	check(not current_scene.has_node("FinalFlight") and current_scene.final_flight_path.is_empty(), "Other levels have no cinematic changes")
	current_scene.free()
	current_scene = null
	await frames(3)
	print("FINAL_FLIGHT_QA_RESULT: ", checks, " checks; ", failures.size(), " failures")
	quit(0 if failures.is_empty() else 1)
