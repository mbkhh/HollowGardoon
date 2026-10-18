extends SceneTree

const LEVEL_PATH := "res://scenes/Levels/level_1.tscn"
const SEEN_KEY := &"hollow_gardoon_level_1_story_seen"
var failures: Array[String] = []
var checks := 0
var handoff: Dictionary = {}

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error("STORY_QA: " + message)

func frames(count: int) -> void:
	for i in range(count):
		await process_frame

func key(code: Key, pressed: bool, echo: bool = false) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.pressed = pressed
	event.echo = echo
	Input.parse_input_event(event)
	await frames(2)

func load_level(with_intro: bool = true) -> Node2D:
	var level := load(LEVEL_PATH).instantiate() as Node2D
	if not with_intro:
		level.get_node("StoryOpening").free()
	root.add_child(level)
	current_scene = level
	return level

func _run() -> void:
	# Capture the original ready-state with the added opening removed.
	# None of the authored gameplay nodes or scripts are changed.
	var baseline := load_level(false)
	var initial_transform: Transform2D = baseline.get_node("Rocket").global_transform
	var initial_velocity: Vector2 = baseline.get_node("Rocket").linear_velocity
	var camera_transform: Transform2D = baseline.get_node("FollowCamera2D").global_transform
	var layers := [baseline.get_node("CanvasLayer").visible, baseline.get_node("Rocket/CanvasLayer").visible]
	baseline.free()
	current_scene = null
	var level := load_level()
	await frames(8)
	var intro = level.get_node("StoryOpening")
	var rocket = level.get_node("Rocket")
	var planet = level.get_node("planets/Planet6")
	var planet_transform: Transform2D = planet.global_transform
	check(paused, "Level is paused while reading")
	check(root.get_camera_2d() == intro.intro_camera, "Opening owns the camera")
	check(intro.intro_camera.global_position.x < -500, "Story sits to the left of the original level")
	check(not level.get_node("CanvasLayer").visible and not rocket.get_node("CanvasLayer").visible, "Gameplay HUDs hidden while reading")
	check(rocket.global_transform.is_equal_approx(initial_transform), "Rocket begins at authored transform")
	check(intro.story.text_direction == Control.TEXT_DIRECTION_RTL and intro.story.language == "fa", "Persian text explicitly uses RTL shaping")
	check(intro.story.get_theme_font("normal_font").has_char("ژ".unicode_at(0)), "Existing font supports Persian")
	print("STORY_TEST_LAYOUT: content=", intro.story.get_content_height(), " available=", intro.story.size, " viewport=", root.size)
	check(intro.story.get_content_height() <= intro.story.size.y + 1, "Entire story fits without scrolling")
	check(intro.story.get_parsed_text().ends_with("مسیر را دنبال کن. شاید هنوز چیزی باقی مانده باشد."), "Final emphasized sentence is present")
	await frames(90)
	check(rocket.global_transform.is_equal_approx(initial_transform) and rocket.linear_velocity.is_equal_approx(initial_velocity), "Reading does not advance rocket physics")
	check(planet.global_transform.is_equal_approx(planet_transform), "Reading does not advance planet rotation")
	await key(KEY_ESCAPE, true)
	await key(KEY_ESCAPE, false)
	await key(KEY_Z, true)
	await key(KEY_Z, false)
	await key(KEY_ENTER, true)
	await key(KEY_ENTER, false)
	check(intro.phase == intro.Phase.READING and not level.pause_menu.visible, "Other keys do not start gameplay or open pause menu")
	check(rocket.charge_time == 0 and not rocket.is_charging, "Input is blocked while reading")
	intro.finished.connect(func():
		handoff = {"transform":rocket.global_transform, "velocity":rocket.linear_velocity, "charge":rocket.charge_time, "camera":root.get_camera_2d()}
	)
	await key(KEY_SPACE, true)
	check(intro.phase == intro.Phase.PANNING and paused, "Fresh Space starts camera pan with world frozen")
	await frames(35)
	check(intro.intro_camera.global_position.x > -1152 and intro.intro_camera.global_position.x < camera_transform.origin.x, "Camera actually travels between story and level")
	await key(KEY_SPACE, true, true)
	await frames(65)
	check(intro.phase == intro.Phase.RELEASING and paused, "Held Space cannot start charging after pan")
	check(rocket.charge_time == 0 and rocket.global_transform.is_equal_approx(initial_transform), "World remains unchanged through pan")
	await key(KEY_SPACE, false)
	await frames(2)
	check(not paused and not is_instance_valid(intro), "Space release restores play and removes intro")
	check(handoff.transform.is_equal_approx(initial_transform) and handoff.velocity.is_equal_approx(initial_velocity), "Exact original rocket state at handoff")
	check(handoff.charge == 0, "Opening keypress does not charge or launch rocket")
	check(handoff.camera == level.get_node("FollowCamera2D"), "Original follow camera restored")
	check(level.get_node("CanvasLayer").visible == layers[0] and rocket.get_node("CanvasLayer").visible == layers[1], "Original HUD visibility restored")
	await frames(10)
	check(not rocket.global_transform.is_equal_approx(initial_transform), "Original gameplay physics resumes")
	await key(KEY_ESCAPE, true)
	await key(KEY_ESCAPE, false)
	check(paused and level.pause_menu.visible, "Existing pause menu still works after opening")
	level.pause_menu._on_resumes_pressed()
	check(not paused and not level.pause_menu.visible, "Existing resume still works")
	# Death/repeat uses reload_current_scene(). It must not replay the story.
	reload_current_scene()
	await frames(5)
	level = current_scene
	check(not paused and not level.has_node("StoryOpening"), "Retry goes straight into level 1")
	check(root.get_camera_2d() == level.get_node("FollowCamera2D"), "Retry uses original camera")
	check(level.get_node("CanvasLayer").visible == layers[0], "Retry leaves authored HUD enabled")
	level.free()
	current_scene = null
	# Another level never has the opening and keeps its normal startup.
	var next_level = load("res://scenes/Levels/level_2.tscn").instantiate()
	root.add_child(next_level)
	current_scene = next_level
	check(not paused and not next_level.has_node("StoryOpening"), "Level 2 startup is unchanged")
	next_level.free()
	current_scene = null
	# Starting a fresh session shows the story again; changing scenes early
	# must not leave any global pause behind.
	remove_meta(SEEN_KEY)
	level = load_level()
	await frames(4)
	check(paused and level.has_node("StoryOpening"), "Fresh session shows story")
	level.free()
	current_scene = null
	check(not paused, "Leaving opening early cleans up global pause")
	print("STORY_QA_RESULT: ", checks, " checks; ", failures.size(), " failures")
	quit(0 if failures.is_empty() else 1)
