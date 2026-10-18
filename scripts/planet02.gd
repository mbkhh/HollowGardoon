@tool
extends StaticBody2D
class_name Planet

@onready var gravity_well: Area2D = $GravityWell
@onready var orbit_path: Line2D = $GravityWell/OrbitPath
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var collision_shape_killzone: CollisionShape2D = $killzone/CollisionShape2D
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

signal goal_reached(body: Node2D)

@export var is_goal_planet: bool = false
@onready var flag: Sprite2D = $Flag
#Reza: enum for types:
#var planetType := Array($AnimatedSprite2D.sprite_frames.get_animation_names())
@export_enum("planet01","planet02","planet03","planet04","planet05","planet06","planet07","planet08","planet09","planet10") var SelectedType: String = "planet01"
#Reza: for planet rotating
var rotate_delta
func _physics_process(delta: float) -> void:
	rotation += rotate_delta
	

# --- Private backing fields ---
var _mass: float = 0.0
var _orbit_radius: float = 0.0

# --- Exported Properties with Setters ---
@export var radius: float = 50.0:
	set(value):
		if radius == value:
			return
		
		radius = value
		print("of course you are sane")
		_update_mass()
		_update_orbit_radius()
		_update_shapes()

@export var density: float = 0.01:
	set(value):
		if density == value:
			return
		
		density = value
		_update_mass()
		_update_shapes()

# --- Read-Only Exported Properties ---
@export var mass: float:
	get:
		return _mass

@export var orbit_radius: float:
	get:
		return _orbit_radius


func _ready():
	# Make all shapes unique to this instance
	_make_resources_unique()
	
	#Reza: for changing sprites
	$AnimatedSprite2D.animation = SelectedType
	
	#Reza: for planet Rotating
	var randd = randi_range(-1,1)
	while (randd ==0):
		randd = randi_range(-1,1)
	rotate_delta = randf_range(0.0001,0.005) * randd
	
	# Initial setup for both editor and game.
	_update_mass()
	_update_orbit_radius()
	_update_shapes()
	if is_instance_valid(flag):
		flag.visible = is_goal_planet

func _make_resources_unique():
	"""Ensures each planet instance has its own unique collision shapes"""
	if collision_shape and collision_shape.shape:
		collision_shape.shape = collision_shape.shape.duplicate()
	
	
	if is_instance_valid(collision_shape_killzone) and collision_shape_killzone.shape:
		collision_shape_killzone.shape = collision_shape_killzone.shape.duplicate(true)
	
	if gravity_well:
		var gravity_shape = gravity_well.get_child(0) as CollisionShape2D
		if gravity_shape and gravity_shape.shape:
			gravity_shape.shape = gravity_shape.shape.duplicate()
			

func _update_shapes():
	print("Updating planet shapes...")
	# --- Update the Planet's Main Body ---
	
	var collision_shape_d: CollisionShape2D = get_node_or_null("CollisionShape2D")
	if is_instance_valid(collision_shape_d) and collision_shape_d.shape is CircleShape2D:
		collision_shape_d.shape.radius = radius
		print(collision_shape_d.shape.radius)
		
	var collision_shape_killerzone_d: CollisionShape2D = get_node_or_null("killzone/CollisionShape2D")
	if is_instance_valid(collision_shape_killerzone_d) and collision_shape_killerzone_d.shape is CircleShape2D:
		collision_shape_killerzone_d.shape.radius = radius
		print(collision_shape_killerzone_d.shape.radius)
	
	# --- Update the Gravity Well Area ---
	var gravity_well_d: Area2D = get_node_or_null("GravityWell")
	if is_instance_valid(gravity_well_d):
		var gravity_shape = gravity_well_d.get_child(0) as CollisionShape2D
		if is_instance_valid(gravity_shape) and gravity_shape.shape is CircleShape2D:
			gravity_shape.shape.radius = _orbit_radius

		# --- Update the Visual Orbit Path ---
		var orbit_path_d: Line2D = gravity_well_d.get_node_or_null("OrbitPath")
		if is_instance_valid(orbit_path_d):
			_draw_orbit_path(orbit_path_d)
	
	# --- Update the Sprite Size ---
	#Reza: changes for new sprites
	var sprite_d: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D")
	if is_instance_valid(sprite_d):
		sprite_d.scale = Vector2.ONE * 2 * radius/300 #(this needs to be the size of the sprits) 
	

func _draw_orbit_path(orbit_path_d: Line2D):
	if Engine.is_editor_hint():
		orbit_path_d.visible = true
		var points = PackedVector2Array()
		var segments = 64
		
		for i in range(segments + 1):
			var angle = (2.0 * PI / segments) * i
			var point = Vector2(cos(angle), sin(angle)) * _orbit_radius
			points.append(point)
		
		orbit_path_d.points = points
	else:
		orbit_path_d.visible = false

func _update_mass():
	_mass = radius * density * (radius) 

func _update_orbit_radius():
	_orbit_radius = (radius + 20) * 1.25

func _on_gravity_well_body_entered(body: Node2D):
	if Engine.is_editor_hint():
		return
	if body.has_method("enter_orbit"):
		body.enter_orbit(self)
		
	if is_goal_planet and body.is_in_group("rocket"):
		goal_reached.emit(body)

func _on_gravity_well_body_exited(body: Node2D):
	if Engine.is_editor_hint():
		return
	if body.has_method("exit_orbit"):
		body.exit_orbit(self)
