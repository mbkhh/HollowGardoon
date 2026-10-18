extends Camera2D
class_name FollowCamera2D

@export_node_path("Node2D") var target_path: NodePath
@export var lock_y_to_start: bool = true
@export var fixed_y: float = 0.0
@export var min_x: float = -100000.0
@export var max_x: float =  0.0

# 0 → no follow, 1 → snap to target immediately.
# Values like 0.05–0.15 feel nice and smooth.
@export_range(0.0, 1.0, 0.01)
var lerp_factor: float = 0.08

# When rocket is orbiting, follow its planet (so camera stays stable)
@export var follow_planet_when_orbiting: bool = true

var _target: Node2D = null


func _ready() -> void:
	make_current()

	if target_path != NodePath():
		_target = get_node(target_path) as Node2D

	if lock_y_to_start:
		fixed_y = global_position.y


func _process(delta: float) -> void:
	if _target == null or not is_instance_valid(_target):
		return

	# --- Decide what point we track ---
	var target_global_pos: Vector2 = _target.global_position

	# If rocket is orbiting, optionally follow the planet instead of rocket
	if follow_planet_when_orbiting and _target.has_method("is_orbiting") and _target.is_orbiting():
		# your Rocket.gd has `orbiting_planet` var
		if "orbiting_planet" in _target and is_instance_valid(_target.orbiting_planet):
			target_global_pos = _target.orbiting_planet.global_position

	# --- Follow only on X, with clamping ---
	var target_x: float = clamp(target_global_pos.x, min_x, max_x)
	var desired_pos: Vector2 = Vector2(target_x, fixed_y)

	# --- Smooth follow ---
	var t: float = clamp(lerp_factor, 0.0, 1.0)
	global_position = global_position.lerp(desired_pos, t)
