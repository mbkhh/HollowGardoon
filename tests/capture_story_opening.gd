extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _capture(name_text: String) -> void:
	await RenderingServer.frame_post_draw
	print("STORY_CAPTURE: ", root.get_texture().get_image().save_png("res://.godot/intro-validation/" + name_text + ".png"))

func _run() -> void:
	var level = load("res://scenes/Levels/level_1.tscn").instantiate()
	root.add_child(level)
	current_scene = level
	for i in range(12):
		await process_frame
	var intro = level.get_node("StoryOpening")
	print("STORY_LAYOUT: content=", intro.story.get_content_height(), " available=", intro.story.size.y, " viewport=", root.size)
	await _capture("opening")
	root.size = Vector2i(800,600)
	for i in range(4):
		await process_frame
	await _capture("opening-small")
	root.size = Vector2i(1152,648)
	for i in range(4):
		await process_frame
	var event := InputEventKey.new()
	event.physical_keycode = KEY_SPACE
	event.pressed = true
	Input.parse_input_event(event)
	await create_timer(0.65, true).timeout
	await _capture("camera-pan")
	event = InputEventKey.new()
	event.physical_keycode = KEY_SPACE
	Input.parse_input_event(event)
	await create_timer(0.75, true).timeout
	await _capture("gameplay")
	level.free()
	current_scene = null
	quit()
