@tool
extends AnimatableBody2D
class_name Moon

# --- REFERENCES ---
@onready var gravity_well: Area2D = $GravityWell
@onready var orbit_path_line: Line2D = $GravityWell/OrbitPath # Rocket's path around Moon
@onready var moon_path_line: Line2D = $MoonPath # Moon's path around Planet
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

# --- CONFIGURATION ---
@export_category("Orbit Settings")
@export var parent_planet: Planet: # Drag your Planet node here in Inspector
	set(value):
		parent_planet = value
		_update_position()

@export var orbit_distance: float = 300.0: # Distance from Planet
	set(value):
		orbit_distance = value
		_update_position()
		_draw_paths()

@export var start_angle_degrees: float = 0.0:
	set(value):
		start_angle_degrees = value
		current_angle = deg_to_rad(start_angle_degrees)
		_update_position()

@export var angular_speed: float = 0.5 # Speed of moon around planet (radians/sec)
@export var clockwise: bool = true

@export_category("Moon Physics")
@export var radius: float = 25.0: # Size of the moon
	set(value):
		radius = value
		_update_mass()
		_update_shapes()

@export var density: float = 0.005: # Lower density than planets (Requirement 1)
	set(value):
		density = value
		_update_mass()

# --- READ-ONLY PROPERTIES ---
var _mass: float = 0.0
var _rocket_orbit_radius: float = 0.0
var current_angle: float = 0.0

@export var mass: float:
	get: return _mass

@export var orbit_radius: float: # Used by Rocket to know where to sit
	get: return _rocket_orbit_radius

func _ready():
	current_angle = deg_to_rad(start_angle_degrees)
	_update_mass()
	_update_shapes()
	_draw_paths()
	
	# Ensure visual paths are setup correctly
	if moon_path_line:
		moon_path_line.top_level = true # Detach from moon rotation/position to draw cleanly

func _process(delta):
	if Engine.is_editor_hint():
		# Keep visuals updated in editor when dragging parent or changing values
		_update_position()
		_draw_paths()
		# Fix sprite scale preview
		if sprite: sprite.scale = Vector2.ONE * 2 * radius/370 

func _physics_process(delta):
	if Engine.is_editor_hint(): return
	
	# --- ORBITAL MOVEMENT LOGIC ---
	if is_instance_valid(parent_planet):
		var direction = 1 if clockwise else -1
		current_angle += angular_speed * direction * delta
		
		# Wrap angle to keep numbers small
		current_angle = fmod(current_angle, TAU)
		
		_update_position()
		
		# --- ANIMATIONS & EFFECTS ---
		# TODO: Add Camera Shake if rocket hits moon
		# TODO: Add sound effect when passing close to something
		# if sprite: sprite.rotation += delta * 0.1 # Example idle rotation

func _update_position():
	if not is_instance_valid(parent_planet): return
	
	# Calculate position based on Polar Coordinates (Angle + Distance)
	var offset = Vector2(cos(current_angle), sin(current_angle)) * orbit_distance
	global_position = parent_planet.global_position + offset
	
	# Keep the Moon Path Visual centered on the planet
	if moon_path_line:
		moon_path_line.global_position = parent_planet.global_position

func _update_mass():
	# Mass calculation (Area * Density)
	_mass = radius * density * radius 

func _update_shapes():
	# 1. Update Rocket Orbit Radius (Gravity Well)
	# We set this smaller relative to size than planets to prevent intersection
	_rocket_orbit_radius = radius + 25.0 
	
	# 2. Update Physical Collision
	if collision_shape and collision_shape.shape is CircleShape2D:
		collision_shape.shape.radius = radius
	
	# 3. Update Gravity Well Sensor
	if gravity_well:
		var gravity_shape = gravity_well.get_child(0) as CollisionShape2D
		if gravity_shape and gravity_shape.shape is CircleShape2D:
			gravity_shape.shape.radius = _rocket_orbit_radius

	# 4. Update Sprite
	if sprite:
		sprite.scale = Vector2.ONE * 2 * radius/300 
	
	_draw_paths()

func _draw_paths():
	if not Engine.is_editor_hint(): 
		if orbit_path_line: orbit_path_line.visible = false
		if moon_path_line: moon_path_line.visible = false # Keep moon path visible in game?
		return

	# --- DRAW 1: Orbit Path (Where Rocket orbits Moon) ---
	if orbit_path_line:
		orbit_path_line.visible = true
		var points = PackedVector2Array()
		var segments = 32
		for i in range(segments + 1):
			var angle = (TAU / segments) * i
			points.append(Vector2(cos(angle), sin(angle)) * _rocket_orbit_radius)
		orbit_path_line.points = points

	# --- DRAW 2: Moon Path (Where Moon orbits Planet) ---
	if moon_path_line:
		moon_path_line.visible = true
		var points = PackedVector2Array()
		var segments = 64
		for i in range(segments + 1):
			var angle = (TAU / segments) * i
			# Draw circle with radius = orbit_distance
			points.append(Vector2(cos(angle), sin(angle)) * orbit_distance)
		moon_path_line.points = points

# --- SIGNALS (Connected via Editor or Code) ---
# Connect GravityWell body_entered signal to this function
func _on_gravity_well_body_entered(body):
	if Engine.is_editor_hint(): return
	if body.has_method("enter_orbit"):
		print("I tried to catch it")
		body.enter_orbit(self)

# Connect GravityWell body_exited signal to this function
func _on_gravity_well_body_exited(body):
	if Engine.is_editor_hint(): return
	if body.has_method("exit_orbit"):
		body.exit_orbit(self)
