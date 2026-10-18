extends Node2D
## An opening to the left of the level. Gameplay stays frozen until the
## camera returns to the authored follow camera and Space has been released.
signal finished
const SEEN_KEY: StringName = &"hollow_gardoon_level_1_story_seen"

@export_node_path("Camera2D") var gameplay_camera_path: NodePath = ^"../FollowCamera2D"
@export_range(0.1, 4.0, 0.05) var pan_duration: float = 1.25
@export var play_once_per_session: bool = true
@export_multiline var story_text: String = "[font_size=32]جهان نابود نشد...\nاز درون تهی شد.[/font_size]\n\nسیاره‌ها هنوز می‌چرخند. گرانش هنوز تو را به سوی خود می‌کشد. اما خورشیدها دیگر زندگی نمی‌بخشند؛ آن‌ها هر چیزی را می‌بلعند.\n\nدر دوردست، نشانه‌ای هنوز می‌درخشد.\nمسافر، اگر صدای مرا می‌شنوی...\n[b]مسیر را دنبال کن. شاید هنوز چیزی باقی مانده باشد.[/b]"

enum Phase { READING, PANNING, RELEASING, DONE }
var phase: Phase = Phase.READING
var _active := false
var _accept_ready := false
var _was_paused := false
var _hidden_layers: Dictionary = {}
var _pan: Tween
@onready var intro_camera: Camera2D = $IntroCamera
@onready var story: RichTextLabel = $Card/Margin/Content/Story
@onready var prompt: Label = $Card/Margin/Content/Prompt
@onready var gameplay_camera: Camera2D = get_node(gameplay_camera_path)

func _ready() -> void:
	if play_once_per_session and get_tree().get_meta(SEEN_KEY, false):
		gameplay_camera.make_current()
		queue_free()
		return
	story.text = story_text
	# Only the existing gameplay HUDs are temporarily hidden. Their layout,
	# visibility and controls are restored before the first gameplay frame.
	for path in [^"../CanvasLayer", ^"../Rocket/CanvasLayer"]:
		var layer := get_node_or_null(path) as CanvasLayer
		if layer:
			_hidden_layers[layer] = layer.visible
			layer.hide()
	_fit_camera()
	intro_camera.make_current()
	intro_camera.force_update_scroll()
	_active = true
	# The parent level sets paused=false in its own _ready(), which runs last.
	# Defer until that initialization finishes, before physics starts.
	call_deferred("_begin")

func _begin() -> void:
	_was_paused = get_tree().paused
	get_tree().paused = true

func _fit_camera() -> void:
	var view := get_viewport_rect().size
	intro_camera.zoom = Vector2.ONE * minf(view.x / 1152.0, view.y / 648.0)

func _process(_delta: float) -> void:
	if phase == Phase.READING:
		_fit_camera()
		if not Input.is_physical_key_pressed(KEY_SPACE):
			_accept_ready = true
	elif phase == Phase.RELEASING and not Input.is_physical_key_pressed(KEY_SPACE):
		_finish()

func _input(event: InputEvent) -> void:
	if not _active:
		return
	# Consume both the press and release, including other gameplay/pause input.
	get_viewport().set_input_as_handled()
	if event is InputEventKey and event.pressed and not event.echo:
		if phase == Phase.READING and _accept_ready and event.physical_keycode == KEY_SPACE:
			_pan_to_level()

func _pan_to_level() -> void:
	phase = Phase.PANNING
	prompt.text = "سفر آغاز می‌شود..."
	_pan = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_pan.set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	_pan.tween_property(intro_camera, "global_position", gameplay_camera.global_position, pan_duration)
	_pan.tween_property(intro_camera, "zoom", gameplay_camera.zoom, pan_duration)
	_pan.chain().tween_callback(_arrived)

func _arrived() -> void:
	phase = Phase.RELEASING
	if not Input.is_physical_key_pressed(KEY_SPACE):
		_finish()

func _finish() -> void:
	phase = Phase.DONE
	gameplay_camera.make_current()
	gameplay_camera.force_update_scroll()
	for layer in _hidden_layers:
		if is_instance_valid(layer):
			layer.visible = _hidden_layers[layer]
	_active = false
	if play_once_per_session:
		get_tree().set_meta(SEEN_KEY, true)
	get_tree().paused = _was_paused
	finished.emit()
	queue_free()

func _exit_tree() -> void:
	# Switching away during the opening must not leave the next scene paused.
	if _active:
		get_tree().paused = _was_paused
