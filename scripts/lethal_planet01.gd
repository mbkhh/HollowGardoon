@tool
extends RigidBody2D
class_name LethalPlanet

# --- Private backing fields ---
var _mass: float = 0.0

# --- Exported Properties with Setters ---
@export var radius: float = 50.0:
	set(value):
		if radius == value:
			return
		radius = value
		_update_mass()
		_update_shapes()

@export var density: float = 1.0:
	set(value):
		if density == value:
			return
		density = value
		_update_mass()

@export var planet_texture: Texture2D:
	set(value):
		planet_texture = value
		# Wait for the node to be ready before accessing children
		if is_inside_tree():
			var sprite_d: Sprite2D = get_node_or_null("Sprite2D")
			if is_instance_valid(sprite_d):
				sprite_d.texture = planet_texture

# New property to toggle gravity in the Inspector
@export var gravity_enabled: bool:
	set(value):
		if value:
			_update_mass()
		else:
			_update_mass()


# --- Node References ---
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var sprite: Sprite2D = $Sprite2D


func _ready():
	# Make all shapes unique to this instance to avoid issues in the editor
	_make_resources_unique()

	# Apply custom texture if set
	if planet_texture and sprite:
		sprite.texture = planet_texture

	# Initial setup for both editor and game.
	_update_mass()
	_update_shapes()



func _make_resources_unique():
	if collision_shape and collision_shape.shape:
		collision_shape.shape = collision_shape.shape.duplicate()


func _update_shapes():
	# --- Update the Planet's Main Collision Body ---
	if is_instance_valid(collision_shape) and collision_shape.shape is CircleShape2D:
		collision_shape.shape.radius = radius

	# --- Update the Sprite Size ---
	if is_instance_valid(sprite) and sprite.texture:
		# Scale the sprite so its visual size matches the physics radius
		var texture_width = sprite.texture.get_width()
		if texture_width > 0:
			sprite.scale = Vector2.ONE * 2 * radius / texture_width


func _update_mass():
	# Using the simplified mass calculation from your original script
	if gravity_enabled:
		_mass = radius * density * (radius * 500)
	else:
		_mass = 0
	self.mass = _mass


func _on_body_entered(body: Node2D):
	# Don't run this collision logic in the editor
	if Engine.is_editor_hint():
		return

	# A safe way to check if the body is the rocket is to see if it has a specific method.
	# We will add a "die()" function to your rocket script.
	if body.has_method("die"):
		print("Rocket collided with a killer planet. Initiating self-destruct!")
		body.die()
