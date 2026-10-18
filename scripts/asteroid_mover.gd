@tool
extends PathFollow2D

# --- CONFIGURATION ---
@export var speed: float = 100.0 # Pixels per second
@export var start_delay: float = 0.0 # How long to wait before the very first launch
@export var respawn_delay: float = 1.0 # How long to wait after finishing path before restarting

# NEW: Variable Radius Property
@export var radius: float = 50.0:
	set(value):
		radius = value
		print("Setter called with radius:", radius)
		# IMPORTANT: Only call _update_shapes if we're already in the tree
		# and the shapes have been made unique
		if is_inside_tree():
			call_deferred("_update_shapes")

# --- NODE REFERENCES ---
@onready var collision_shape: CollisionShape2D = $killzone/CollisionShape2D
@onready var sprite: AnimatedSprite2D = $killzone/AnimatedSprite2D

# --- STATE ---
var is_active: bool = false
var current_wait_time: float = 0.0

func _ready():
	# Make all shapes unique to this instance FIRST
	_make_resources_unique()
	
	# THEN update shapes with current radius
	_update_shapes()
	
	# Ensure we start at the beginning
	progress_ratio = 0.0
	
	#Reza: picking random sprites:
	
	var sprite_types = Array($killzone/AnimatedSprite2D.sprite_frames.get_animation_names())
	$killzone/AnimatedSprite2D.animation = sprite_types.pick_random()
	
	# Safety check to prevent this from running in the editor
	if not Engine.is_editor_hint():
		set_physics_process(false)
		
		# Create a one-shot timer for the initial delay
		if start_delay > 0:
			await get_tree().create_timer(start_delay).timeout
		
		# Start moving
		is_active = true
		set_physics_process(true)

func _physics_process(delta: float):
	if not is_active:
		return

	# Move along the path
	progress += speed * delta

	# Check if we reached the end of the path
	if progress_ratio >= 1.0:
		_handle_respawn()

func _handle_respawn():
	# Stop moving
	is_active = false
	
	# Reset position to start immediately
	progress_ratio = 0.0
	
	# Wait for the respawn delay
	if respawn_delay > 0:
		await get_tree().create_timer(respawn_delay).timeout
	
	# Start moving again
	is_active = true

# --- HELPER FUNCTIONS ---
func _make_resources_unique():
	"""Ensures the collision shape is unique to this asteroid instance."""
	if collision_shape and collision_shape.shape:
		collision_shape.shape = collision_shape.shape.duplicate()

func _update_shapes():
	"""Updates the collision shape and sprite scale based on the radius."""
	print("_update_shapes called with radius:", radius)
	
	# Get nodes directly - works in both editor and runtime
	var collision_shape_d: CollisionShape2D = get_node_or_null("killzone/CollisionShape2D")
	if is_instance_valid(collision_shape_d) and collision_shape_d.shape is CircleShape2D:
		collision_shape_d.shape.radius = radius
		print("Updated collision shape radius to:", radius)

	# Update the sprite's scale
	#Reza: changed some to fit AnimatedSprite2D
	var sprite_d: AnimatedSprite2D = get_node_or_null("killzone/AnimatedSprite2D")
	if is_instance_valid(sprite_d):
		var base_sprite_size = 200.0 
		sprite_d.scale = Vector2.ONE * (radius * 2) / base_sprite_size
		print("Updated sprite scale to:", sprite_d.scale)
