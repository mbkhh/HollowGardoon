extends CanvasLayer
## Instanced only after the final goal has recorded its normal level result.
@export_multiline var story_text: String = "تو از میان جهان‌های خالی عبور کردی.\nاز مدارهایی که راه را گم کرده بودند؛ از خورشیدهایی که هر چیزی را به درون خود می‌کشیدند.\nپرچم‌ها تو را به اینجا رساندند.\nبه آخرین پناهگاه.\nبه آخرین جرقه.\nجهان هنوز توخالی است...\nاما حالا می‌دانی که در دل تاریکی، چیزی باقی مانده است.\n\n[b]و گاهی، یک جرقه برای آغاز دوباره کافی است.[/b]"
var _accept_ready := false
var _space_armed := false
var _leaving := false
@onready var screen: Control = $Screen
@onready var card: PanelContainer = $Screen/Card
@onready var story: RichTextLabel = $Screen/Card/Margin/Content/Story

func _ready() -> void:
	story.text = story_text
	for path in [^"CanvasLayer", ^"Rocket/CanvasLayer"]:
		var hud := get_parent().get_node_or_null(path) as CanvasLayer
		if hud:
			hud.hide()
	get_tree().paused = true
	screen.resized.connect(_fit_card)
	_fit_card()

func _fit_card() -> void:
	var view := screen.size
	card.scale = Vector2.ONE * minf(view.x / 1152.0, view.y / 648.0)
	card.position = (view - card.size * card.scale) * 0.5

func _process(_delta: float) -> void:
	if not Input.is_physical_key_pressed(KEY_SPACE):
		_accept_ready = true

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.physical_keycode == KEY_SPACE:
		get_viewport().set_input_as_handled()
		if event.pressed and not event.echo and _accept_ready:
			_space_armed = true
		elif not event.pressed and _space_armed:
			_on_main_menu_pressed()

func _on_main_menu_pressed() -> void:
	_leave("res://scenes/game.tscn")

func _on_level_select_pressed() -> void:
	_leave("res://scenes/level_select.tscn")

func _leave(scene_path: String) -> void:
	if _leaving:
		return
	_leaving = true
	get_tree().paused = false
	get_tree().change_scene_to_file(scene_path)

func _exit_tree() -> void:
	get_tree().paused = false
