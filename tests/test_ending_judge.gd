extends SceneTree
var checks := 0
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error("ENDING_JUDGE_QA: " + message)

func frames(count: int) -> void:
	for i in range(count):
		await process_frame

func open_scene(path: String) -> void:
	if current_scene:
		current_scene.free()
		current_scene = null
	var scene = load(path).instantiate()
	root.add_child(scene)
	current_scene = scene
	await frames(4)

func key(code: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)
	await frames(2)

func reach_final_goal(level: Node) -> void:
	var rocket = level.get_node("Rocket")
	var flight = level.get_node("FinalFlight")
	rocket.current_state = rocket.State.TRAVELING
	rocket.orbiting_planet = null
	rocket.teleport(flight.global_position - Vector2(120,0))
	rocket.preserved_velocity = Vector2(1000,0)
	for i in range(1600):
		if level.has_node("StoryEnding"):
			break
		await frames(1)
	check(level.has_node("StoryEnding"), "Final flight reaches goal and shows final story")
	await frames(5)

func _run() -> void:
	# Keep the same autoload node/global reference, overriding only file I/O.
	var saves = root.get_node("SaveManager")
	saves.set_script(load("res://tests/memory_save_manager.gd"))
	saves._init_default_data()
	await open_scene("res://scenes/game.tscn")
	var menu = current_scene
	var button: Button = menu.get_node("Buttons/GameJamJudges")
	check(button.text.contains("Judges") and button.text.contains("15"), "Main-menu button explains the judge shortcut")
	check(not saves.judge_mode, "Normal startup keeps progression locks")
	button.pressed.emit()
	await frames(5)
	var select = current_scene
	check(select.scene_file_path == "res://scenes/level_select.tscn", "Judge button opens level select")
	check(saves.judge_mode and select.get_node("JudgeBanner").visible, "Level select clearly announces judge mode")
	check(select.grid.get_child_count() == 15, "All fifteen level choices are present")
	for i in range(15):
		check(not select.grid.get_child(i).disabled, "Judge can select level %d" % (i+1))
		check(ResourceLoader.exists(select._get_scene_path_for_level("level_%d" % (i+1))), "Level %d resolves to an existing scene" % (i+1))
	check(saves.xp == 0 and saves.save_calls == 0, "Judge access awards no currency and writes no save")
	check(not saves.is_level_completed("level_14") and saves.get_level_stars("level_15") == 0, "Unlock shortcut does not fake completion or stars")
	select.grid.get_child(14).pressed.emit()
	await frames(5)
	var level = current_scene
	check(level.level_id == "level_15" and not level.has_node("StoryEnding"), "Level 15 plays normally until its goal")
	level.stars_collected = 2
	await reach_final_goal(level)
	var ending = level.get_node("StoryEnding")
	check(level.level_finished and saves.is_level_completed("level_15"), "Final goal still records completion")
	check(saves.get_level_stars("level_15") == 2 and saves.xp == 20, "Final stars and reward are preserved")
	var writes: int = saves.save_calls
	level.get_node("goal planet/Planet8").goal_reached.emit(level.get_node("Rocket"))
	check(saves.save_calls == writes, "Repeated goal signal cannot award results twice")
	check(paused and not level.level_complete.visible, "Story replaces final completion popup and freezes play")
	check(not level.get_node("CanvasLayer").visible and not level.get_node("Rocket/CanvasLayer").visible, "Gameplay HUDs do not cover ending")
	check(ending.story.language == "fa" and ending.story.text_direction == Control.TEXT_DIRECTION_RTL, "Ending uses Persian RTL text")
	check(ending.story.get_content_height() <= ending.story.size.y + 1, "Complete ending fits without clipped text")
	var markup := RegEx.create_from_string("\\[[^\\]]+\\]")
	check(ending.story.get_parsed_text().strip_edges() == markup.sub(ending.story_text,"",true).strip_edges(), "Current authored ending text is preserved")
	var position: Vector2 = level.get_node("Rocket").global_position
	await frames(40)
	check(level.get_node("Rocket").global_position == position, "Reading the ending does not advance physics")
	ending.get_node("Screen/Card/Margin/Content/Actions/LevelSelect").pressed.emit()
	await frames(5)
	check(not paused and current_scene.scene_file_path.ends_with("level_select.tscn"), "Ending level-select button leaves pause cleanly")
	check(not current_scene.grid.get_child(14).disabled, "Judge can replay final level after ending")
	current_scene.grid.get_child(14).pressed.emit()
	await frames(5)
	level = current_scene
	await reach_final_goal(level)
	await key(KEY_SPACE, true)
	check(current_scene == level and paused, "Ending consumes Space press")
	await key(KEY_SPACE, false)
	await frames(4)
	check(not paused and current_scene.scene_file_path.ends_with("game.tscn"), "Space release returns to main menu")
	current_scene.get_node("Buttons/Start").button_down.emit()
	await frames(5)
	check(not saves.judge_mode and not current_scene.get_node("JudgeBanner").visible, "Normal Start leaves judge mode")
	check(not current_scene.grid.get_child(0).disabled and current_scene.grid.get_child(13).disabled, "Normal progression locks still work")
	check(saves.get_level_stars("level_15") == 2, "Review mode preserves earned stars on replay")
	# Non-final levels continue to use their existing win popup.
	await open_scene("res://scenes/Levels/level_2.tscn")
	level = current_scene
	level._on_goal_reached(level.get_node("Rocket"))
	check(level.level_complete.visible and not level.has_node("StoryEnding"), "Other levels retain normal completion UI")
	paused = false
	current_scene.free()
	current_scene = null
	await frames(3)
	print("ENDING_JUDGE_QA_RESULT: ", checks, " checks; ", failures.size(), " failures")
	quit(0 if failures.is_empty() else 1)
