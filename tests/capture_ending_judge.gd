extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func frames(count: int) -> void:
	for i in range(count):
		await process_frame

func capture(name_text: String) -> void:
	await RenderingServer.frame_post_draw
	print("ENDING_CAPTURE: ", root.get_texture().get_image().save_png("res://.godot/ending-validation/" + name_text + ".png"))

func _run() -> void:
	var saves = root.get_node("SaveManager")
	saves.set_script(load("res://tests/memory_save_manager.gd"))
	saves._init_default_data()
	var menu = load("res://scenes/game.tscn").instantiate()
	root.add_child(menu)
	current_scene = menu
	await frames(12)
	await capture("main-menu")
	menu.get_node("Buttons/GameJamJudges").pressed.emit()
	await frames(12)
	await capture("judge-levels")
	current_scene.grid.get_child(14).pressed.emit()
	await frames(10)
	var level = current_scene
	var goal = level.get_node("goal planet/Planet8")
	var rocket = level.get_node("Rocket")
	rocket.current_state = rocket.State.TRAVELING
	rocket.orbiting_planet = null
	rocket.teleport(goal.global_position + Vector2(goal.orbit_radius-3,0))
	for i in range(120):
		if level.has_node("StoryEnding"):
			break
		await frames(1)
	await frames(12)
	var ending = level.get_node("StoryEnding")
	print("ENDING_LAYOUT: content=",ending.story.get_content_height(), " available=",ending.story.size)
	await capture("ending")
	root.size = Vector2i(800,600)
	await frames(6)
	await capture("ending-small")
	level.free()
	current_scene = null
	await frames(3)
	quit()
