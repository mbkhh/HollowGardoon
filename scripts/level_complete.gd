extends Control

@export_file("*.tscn") var main_menu_scene: String

@export var empty_star_texture: Texture2D        # black / empty
@export var previous_star_texture: Texture2D     # blurred / low color
@export var current_star_texture: Texture2D      # bright

var star_icons: Array[TextureRect] = []

@onready var xp_label: Label = $PanelContainer/XpLabel

var _next_level_scene: String = ""
var _prev_stars: int = 0
var _stars_earned: int = 0
var _xp_gained: int = 0


func _ready() -> void:
	# Make this UI work even when the game is paused
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false

	star_icons = [
		$PanelContainer/Star0 as TextureRect,
		$PanelContainer/Star1 as TextureRect,
		$PanelContainer/Star2 as TextureRect,
	]

	# Start with all empty
	for icon in star_icons:
		icon.texture = empty_star_texture


func show_results(prev_stars: int, stars_earned: int, xp_gained: int, next_level_scene: String) -> void:
	_prev_stars = prev_stars
	_stars_earned = stars_earned
	_xp_gained = xp_gained
	_next_level_scene = next_level_scene

	visible = true
	get_tree().paused = true

	# Text like: "XP +30 (Total: 120)"
	xp_label.text = "Crystal +%d (Total: %d)" % [xp_gained, SaveManager.xp]

	# Base state: previous best as blurred, rest empty
	for icon in star_icons:
		icon.texture = empty_star_texture

	var capped_prev: int = min(prev_stars, star_icons.size())
	for i in range(capped_prev):
		star_icons[i].texture = previous_star_texture

	# Animate stars from this run
	animate_new_stars(prev_stars, stars_earned)


func animate_new_stars(prev_stars: int, stars_earned: int) -> void:
	var total_slots: int = star_icons.size()
	var max_new: int = min(stars_earned, total_slots)

	for i in range(max_new):
		var idx: int = i
		if idx >= total_slots:
			break
		# Optional tiny delay between stars:
		var delay := create_tween()
		delay.tween_interval(0.2)
		await delay.finished
		
		var icon: TextureRect = star_icons[idx]
		icon.texture = current_star_texture
		icon.scale = Vector2.ZERO
	
		var tween: Tween = create_tween()
		tween.tween_property(icon, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		await tween.finished
		

func _on_next_button_pressed() -> void:
	get_tree().paused = false
	if _next_level_scene != "":
		get_tree().change_scene_to_file(_next_level_scene)


func _on_repeat_button_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _on_menu_button_pressed() -> void:
	get_tree().paused = false
	if main_menu_scene != "":
		get_tree().change_scene_to_file(main_menu_scene)
