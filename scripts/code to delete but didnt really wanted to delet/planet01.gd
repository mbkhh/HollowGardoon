# Planet.gd
extends StaticBody2D
class_name Planet1

var _mass: float = 0.0
var _orbit_radius: float = 0.0
@export var radius: float = 50.0:
	set(value):
		radius = value
		# Recalculate mass whenever the radius is changed.
		_update_mass()
		_update_orbit_radius()
		_update_shapes()

@export var density: float = 1:
	set(value):
		density = value
		# Recalculate mass whenever the density is changed.
		_update_mass()

## The mass of the planet, used for gravity calculations by the rocket.
## This is now a read-only property, calculated automatically.
@export var mass: float:
	get:
		# We just return the pre-calculated mass.
		# A getter makes it visible in the inspector but not editable (read-only).
		return _mass
#@export var radius: float = 50.0
#@export var density: float = 5.0
### The mass of the planet, used for gravity calculations by the rocket.
#@export var mass: float = radius * radius * radius * density
## The radius at which the rocket will orbit this planet.
@export var orbit_radius: float:
	get:
		# We just return the pre-calculated mass.
		# A getter makes it visible in the inspector but not editable (read-only).
		return _orbit_radius


# Node references
@onready var gravity_well: Area2D = $GravityWell
@onready var orbit_path: Line2D = $GravityWell/OrbitPath
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var sprite: Sprite2D = $Sprite2D

func _ready():
	# Connect the signals from the Area2D.
	# they are already connect but if in case we needed to change anything
	# gravity_well.body_entered.connect(_on_gravity_well_body_entered)
	# gravity_well.body_exited.connect(_on_gravity_well_body_exited)
	
	# Configure the size of the Area2D's collision shape to match the orbit_radius.
	# This ensures the detection area matches our desired orbit distance.
	# We assume the shape is the first child (index 0).
	_update_mass()
	_update_orbit_radius()
	_update_shapes()

# This function is called automatically when the rocket enters the GravityWell Area2D.
func _on_gravity_well_body_entered(body: Node2D):
	# We check if the body that entered has the `enter_orbit` function.
	# This is a good way to ensure we're only interacting with the rocket.
	if body.has_method("enter_orbit"):
		# We tell the rocket to start orbiting this planet.
		body.enter_orbit(self)

# This function is called automatically when the rocket leaves the GravityWell Area2D.
func _on_gravity_well_body_exited(body: Node2D):
	if body.has_method("exit_orbit"):
		# If the rocket somehow leaves the orbit area (e.g., launched away),
		# we tell it to stop orbiting this specific planet.
		body.exit_orbit(self)

# Helper function to draw a circle for the orbit path.
func _draw_orbit_path():
	var points = PackedVector2Array()
	var segments = 64 # The number of line segments to use for the circle. More segments = smoother circle.
	
	for i in range(segments + 1):
		var angle = (2.0 * PI / segments) * i
		var point = Vector2(cos(angle), sin(angle)) * orbit_radius
		points.append(point)
	
	orbit_path.points = points

func _update_mass():
	# The calculation is now done here.
	_mass = radius * radius * density

func _update_orbit_radius():
	# The calculation is now done here.
	_orbit_radius = (radius + 20) * 1.25

func _update_shapes():
	# --- Update the Planet's Main Body ---
	# First, check if the node and its shape resource actually exist to prevent errors.
	if collision_shape and collision_shape.shape is CircleShape2D:
		# Access the shape resource and set its radius property.
		collision_shape.shape.radius = radius
	
	# --- Update the Gravity Well Area ---
	# We can reuse the logic from your _ready() function here.
	var gravity_shape = gravity_well.get_child(0) as CollisionShape2D
	if gravity_shape and gravity_shape.shape is CircleShape2D:
		gravity_shape.shape.radius = orbit_radius
	
	if sprite:
		sprite.scale = Vector2(1, 1)* radius/ 32
	# --- Update the Visual Orbit Path ---
	# It also makes sense to update the drawn line here.
	_draw_orbit_path()
