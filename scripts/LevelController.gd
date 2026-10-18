# LevelController.gd
extends Node2D

# How many stars collected in this run (0–3)
var stars_collected: int = 0
var prev_stars: int = 0

@onready var hud := $CanvasLayer/StarHUD   # adjust this path to your HUD node
@onready var pause_menu: Control = $CanvasLayer/PauseMenu
var level_finished := false
@onready var puase_btn: Button = $CanvasLayer/PuaseBtn
@onready var level_complete: Control = $CanvasLayer/LevelComplete

@export var level_id: String = "level_1"
@export_file("*.tscn") var next_level_scene: String   # set this in the editor
@export var ending_scene: PackedScene # Optional story ending, used by level 15.
@export_node_path("Node") var final_flight_path: NodePath


func _ready() -> void:
	# Connect to all stars in this level
	prev_stars = SaveManager.get_level_stars(level_id)
	hud.reset_stars()
	hud.show_previous_stars(prev_stars)
	for star in get_tree().get_nodes_in_group("stars"):
		star.collected.connect(_on_star_collected)

	# Connect to goal planet(s)
	for planet in get_tree().get_nodes_in_group("planets"):
		if planet is Planet:
			var p: Planet = planet
			if planet.is_goal_planet :
				print("this is goal planet")
				planet.goal_reached.connect(_on_goal_reached)
	get_tree().paused = false
	pause_menu.visible = false
	

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"): # or your custom "pause" action
		_toggle_pause()
		
func _toggle_pause() -> void:
	var tree: SceneTree = get_tree()
	tree.paused = not tree.paused

	if tree.paused:
		pause_menu.call("open")
	else:
		pause_menu.call("close")

func _on_star_collected(index: int) -> void:
	# We don't care about *which* star (index), only the count.
	if level_finished:
		return

	if stars_collected >= 3:
		return  # already full
	WinSfx.play_star()
	stars_collected += 1
	print("collected, total:", stars_collected)

	# Light stars in order: first pickup -> icon 0, second -> icon 1, ...
	hud.set_star_glowing(stars_collected - 1)


func _on_goal_reached(body: Node2D) -> void:
	if level_finished:
		return
	if not final_flight_path.is_empty() and not get_node(final_flight_path).can_finish():
		return
	level_finished = true
	WinSfx.play_win()
	var stars_earned := stars_collected  # directly use the count

	# Save result – SaveManager is your autoload
	SaveManager.set_level_result(level_id, stars_earned)

	if ending_scene:
		var ending := ending_scene.instantiate()
		ending.name = "StoryEnding"
		# Goal signals originate in physics; add the UI once that step finishes.
		call_deferred("add_child", ending)
		return

	# Go to next level (no intermediate screen)
	var xp_gained: int = stars_earned * 10

	# Show level complete screen (prev_stars = previous best; stars_earned = this run)
	level_complete.call("show_results", prev_stars, stars_earned, xp_gained, next_level_scene)



func _on_puase_btn_pressed() -> void:
	_toggle_pause()
