@tool
extends Area2D
class_name Whitehole

# --- REFERENCES ---
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var sprite: Sprite2D = $Sprite2D
# Optional visualizer for editor
@onready var debug_line: Line2D = get_node_or_null("Line2D") 

# --- EXPORTED PROPERTIES ---
@export_group("Settings")
@export var linked_whitehole: Whitehole # Drag the OTHER whitehole here in the inspector

#Reza: for planet rotating
var rotate_delta

@export var radius: float = 60.0:
	set(value):
		radius = value
		_update_shape()
		_update_mass()
		queue_redraw() # Force editor redraw

# Controls how strong the gravity is compared to a planet of the same size
@export_range(0.0, 1.0) var gravity_strength_factor: float = 0.2: 
	set(value):
		gravity_strength_factor = value
		_update_mass()

# --- PUBLIC PROPERTIES FOR PHYSICS ---
# We expose 'mass' so the Rocket script can treat this like a Planet for gravity calculations
var mass: float = 0.0

# To prevent infinite teleport loops (ping-ponging)
var teleport_cooldown: float = 0.0 

func _ready():
	# Unique resources for instances
	if collision_shape and collision_shape.shape:
		collision_shape.shape = collision_shape.shape.duplicate()
	#Reza: rotation
	rotate_delta = randf_range(0.01,0.05)
	
	_update_shape()
	_update_mass()
	
	# Connect signal via code to ensure it exists
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)


func _process(delta):
	if teleport_cooldown > 0:
		teleport_cooldown -= delta
	
	#Reza: rotate
	$Sprite2D.rotation += rotate_delta


	

func _update_shape():
	if is_instance_valid(collision_shape) and collision_shape.shape is CircleShape2D:
		collision_shape.shape.radius = radius
	
	# Visual update
	if is_instance_valid(sprite):
		# Assuming sprite is roughly 100x100, scale it to match radius
		# Adjust '100.0' to your actual texture size
		var texture_size = 900.0 
		if sprite.texture:
			texture_size = sprite.texture.get_width()
		sprite.scale = Vector2.ONE * (radius * 2.0) / texture_size

func _update_mass():
	# We use a similar formula to Planet, but multiply by the weakness factor
	# This ensures the gravity logic in Rocket feels consistent but weaker.
	var fake_density = 0.006 # Base density
	mass = (radius * fake_density * radius) * gravity_strength_factor

# --- TELEPORTATION LOGIC ---
func _on_body_entered(body: Node2D):
	if Engine.is_editor_hint(): return
	if teleport_cooldown > 0: return
	
	if body.has_method("teleport") and is_instance_valid(linked_whitehole):
		
		# TODO: SECTION FOR SOUND EFFECTS
		# AudioManager.play_sfx("warp_sound")
		
		# TODO: SECTION FOR CAMERA SHAKE
		# Camera.shake(intensity=5.0)
		
		# TODO: SECTION FOR ANIMATION
		# Create a tween to shrink the rocket before teleporting?
		
		linked_whitehole.teleport_cooldown = 1.2 
		
		var exit_pos = linked_whitehole.global_position
		
		# Calculate boost direction based on whitehole's rotation
		var boost_direction = Vector2.RIGHT.rotated(linked_whitehole.rotation)
		var boost_speed = 500.0  # Adjust this value as needed
		
		# Teleport the rocket
		body.teleport(exit_pos)
		
		# Apply boost velocity
		if body.has_method("set_velocity") or "velocity" in body:
			body.velocity = boost_direction * boost_speed

# --- EDITOR VISUALIZATION ---
func _draw():
	if Engine.is_editor_hint():
		# Draw a visual circle in the editor to see the "Event Horizon"
		draw_circle(Vector2.ZERO, radius, Color(0.5, 0.0, 1.0, 0.3))
		draw_circle(Vector2.ZERO, radius, Color(1.0, 1.0, 1.0, 0.8), false, 2.0)
		
		# Draw line to linked whitehole if it exists
		if is_instance_valid(linked_whitehole):
			draw_line(Vector2.ZERO, to_local(linked_whitehole.global_position), Color.CYAN, 2.0, true)
