extends Node2D
## Local to level 15: crossing the invisible end line begins an uninterruptible
## voyage. Only the final planet can detect the rocket during this sequence.
signal started
signal arrived
enum Phase { PLAYING, FLYING, ARRIVING, COMPLETE }

@export_node_path("RigidBody2D") var rocket_path: NodePath = ^"../Rocket"
@export_node_path("Node2D") var goal_path: NodePath = ^"../goal planet/Planet8"
@export_node_path("Camera2D") var camera_path: NodePath = ^"../FollowCamera2D"
@export_range(3.0, 40.0, 0.5) var flight_duration: float = 18.0
@export_range(1.0, 15.0, 0.5) var darken_duration: float = 6.0
@export_range(0.0, 5.0, 0.1) var arrival_hold: float = 1.4

var phase: Phase = Phase.PLAYING
var elapsed := 0.0
var darkness := 0.0
var _hold_elapsed := 0.0
var _from := Vector2.ZERO
var _entry := Vector2.ZERO
var _previous := Vector2.ZERO
var _queued := false
var _actor_pairs: Array = []
var _glows: Array = []
@onready var rocket: RigidBody2D = get_node(rocket_path)
@onready var goal: Node2D = get_node(goal_path)
@onready var camera: Camera2D = get_node(camera_path)
@onready var fade: ColorRect = $Darkness/Shade
@onready var actors: Node2D = $Actors/Visuals

func _ready() -> void:
	_previous = rocket.global_position
	$Trigger.body_entered.connect(_on_trigger_body_entered)
	# This child readies before LevelController connects its result handler.
	goal.goal_reached.connect(_on_goal_reached)
	set_process_input(false)
	$Darkness.hide()
	$Actors.hide()
	process_physics_priority = 20
	process_priority = 20

func can_finish() -> bool:
	return phase == Phase.COMPLETE

func _on_trigger_body_entered(body: Node2D) -> void:
	if body == rocket and phase == Phase.PLAYING and not _queued:
		_queued = true
		call_deferred("_begin")

func _begin() -> void:
	if phase != Phase.PLAYING or not is_instance_valid(rocket):
		return
	phase = Phase.FLYING
	_from = rocket.global_position
	_entry = goal.global_position - Vector2(goal.orbit_radius - 3, 0)
	set_process_input(true)
	# Stop every polling/event-based control and neutralize pending charges.
	rocket.set_physics_process(false)
	rocket.set_process_unhandled_input(false)
	rocket._cancel_charge()
	rocket.orbit_sound.stop()
	rocket.orbit_effect.hide()
	# Orbit reversal can leave the skin flipped. Face its nose into the voyage.
	rocket.get_node("AnimatedSprite2D").flip_v = false
	rocket.get_node("AnimatedSprite2D").flip_h = false
	# Charging/reversing changes the flame's offset and flip. Reset its full
	# local pose as well, otherwise a previous orbit can leave it at the nose.
	rocket.fire.position = Vector2(0, 370)
	rocket.fire.rotation = PI * 0.5
	rocket.fire.scale = Vector2(0.45, 1.2)
	rocket.fire.flip_h = false
	rocket.fire.flip_v = false
	rocket.current_state = rocket.State.TRAVELING
	rocket.orbiting_planet = null
	rocket.state_buffer_reset = false
	rocket.linear_velocity = Vector2.ZERO
	rocket.angular_velocity = 0
	rocket.freeze_mode = RigidBody2D.FREEZE_MODE_KINEMATIC
	rocket.freeze = true
	rocket.collision_layer = 32
	rocket.collision_mask = 0
	# Wormholes, lethal planets and the old level boundaries use other layers.
	# The final well still reports a real arrival while the body is tweened.
	goal.get_node("GravityWell").collision_mask |= 32
	goal.set_physics_process(false)
	goal.rotation = 0
	camera.set_process(false)
	for path in [^"CanvasLayer", ^"Rocket/CanvasLayer"]:
		var hud := get_parent().get_node_or_null(path) as CanvasLayer
		if hud:
			hud.hide()
	_copy_actor(rocket.get_node("AnimatedSprite2D"), 90)
	_copy_actor(goal.get_node("AnimatedSprite2D"), goal.radius * 4)
	_copy_actor(goal.get_node("Flag"))
	$Darkness.show()
	$Actors.show()
	_update_visuals()
	started.emit()

func _input(_event: InputEvent) -> void:
	if phase in [Phase.FLYING, Phase.ARRIVING]:
		get_viewport().set_input_as_handled()

func _physics_process(delta: float) -> void:
	if not is_instance_valid(rocket):
		return
	if phase == Phase.PLAYING:
		var at := rocket.global_position
		# Swept X crossing also catches a fast launch that skips the thin Area.
		if _previous.x < global_position.x and at.x >= global_position.x:
			_on_trigger_body_entered(rocket)
		_previous = at
		return
	if phase == Phase.FLYING:
		elapsed = minf(elapsed + delta, flight_duration)
		var t := elapsed / flight_duration
		var travel := smoothstep(0.0, 1.0, t)
		rocket.global_position.x = lerpf(_from.x, _entry.x, travel)
		rocket.global_position.y = lerpf(_from.y, _entry.y, smoothstep(0.0, 0.28, t))
		rocket.rotation = lerp_angle(rocket.rotation, PI * 0.5, 1 - exp(-3 * delta))
		darkness = smoothstep(0.0, darken_duration, elapsed)
		fade.material.set_shader_parameter("darkness", darkness)
		# Some physics backends do not monitor manually moved frozen bodies.
		# Only accept this fallback when the ship is physically inside the well.
		if elapsed >= flight_duration and rocket.global_position.distance_to(goal.global_position) < goal.orbit_radius:
			goal._on_gravity_well_body_entered(rocket)
	elif phase == Phase.ARRIVING:
		_hold_elapsed += delta
		if _hold_elapsed >= arrival_hold:
			phase = Phase.COMPLETE
			set_process_input(false)
			# Reuse the normal goal/results path after the arrival shot.
			goal.goal_reached.emit(rocket)
	if phase != Phase.PLAYING:
		var look_ahead := 240.0 if phase == Phase.FLYING else 120.0
		var desired := Vector2(rocket.global_position.x + look_ahead, goal.global_position.y)
		camera.global_position = camera.global_position.lerp(desired, 1 - exp(-4 * delta))
		camera.force_update_scroll()

func _on_goal_reached(body: Node2D) -> void:
	if phase != Phase.FLYING or body != rocket:
		return
	phase = Phase.ARRIVING
	rocket.rotation = PI * 0.5
	rocket.orbit_sound.stop()
	rocket.orbit_effect.hide()
	rocket._cancel_charge()
	arrived.emit()

func _process(_delta: float) -> void:
	if phase != Phase.PLAYING:
		_update_visuals()

func _copy_actor(source: Node2D, glow_size: float = 0) -> void:
	if glow_size > 0:
		var gradient := Gradient.new()
		gradient.offsets = PackedFloat32Array([0, 0.25, 1])
		gradient.colors = PackedColorArray([Color(0.55,0.8,1,0.35),Color(0.25,0.55,0.9,0.13),Color(0.1,0.3,0.6,0)])
		var texture := GradientTexture2D.new()
		texture.gradient = gradient
		texture.width = 128
		texture.height = 128
		texture.fill = GradientTexture2D.FILL_RADIAL
		texture.fill_from = Vector2(0.5,0.5)
		texture.fill_to = Vector2(0.5,1)
		var glow := Sprite2D.new()
		glow.texture = texture
		var blend := CanvasItemMaterial.new()
		blend.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		glow.material = blend
		actors.add_child(glow)
		_glows.append([source,glow,glow_size])
	var copy := source.duplicate() as Node2D
	actors.add_child(copy)
	_actor_pairs.append([source,copy])

func _update_visuals() -> void:
	# Draw only the ship, planet and flag above the blackening world. This
	# keeps the actual actors visible without exposing stars through a hole.
	var canvas := get_viewport().get_canvas_transform()
	for pair in _glows:
		var source: Node2D = pair[0]
		var glow: Sprite2D = pair[1]
		glow.position = canvas * source.global_position
		glow.scale = Vector2.ONE * float(pair[2]) / 128.0 * camera.zoom.x
		glow.modulate.a = darkness
	for pair in _actor_pairs:
		var source: Node2D = pair[0]
		var copy: Node2D = pair[1]
		copy.global_transform = canvas * source.global_transform
		_sync_sprite(source, copy)

func _sync_sprite(source: Node2D, copy: Node2D) -> void:
	if source is AnimatedSprite2D:
		copy.animation = source.animation
		copy.frame = source.frame
		copy.flip_h = source.flip_h
		copy.flip_v = source.flip_v
	for child in source.get_children():
		if child is Node2D and copy.has_node(NodePath(child.name)):
			var visual := copy.get_node(NodePath(child.name)) as Node2D
			visual.transform = child.transform
			visual.visible = child.visible
			_sync_sprite(child, visual)
