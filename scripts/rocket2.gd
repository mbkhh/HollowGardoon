# Rocket.gd
extends RigidBody2D
class_name Rocket

# --- EXPORT VARIABLES ---
@export var launch_impulse: float = 500.0
@export var gravitational_constant: float = 600000.0
@export var base_orbiting_speed: float = 2.3 # Radians per second
@export var damping_coffactor: float = 0.3
#Reza: change of animation:
@export_enum("default","ship1","ship2","ship3") var SelectedType: String = "default"
var clockwize = -1;
var charge_time: float = 0.0
@export var max_charge_time: float = 7 # Limits how fast/strong it can get
@onready var charge_bar: ProgressBar = $ProgressBar
@onready var fire: AnimatedSprite2D = $AnimatedSprite2D/AnimatedSprite2D
@onready var reverse_button: Button = $CanvasLayer/ReverseButton
@onready var cancel_button: Button = $CanvasLayer/CancelButton
@onready var orbit_effect: AnimatedSprite2D = $OrbitEffects
@onready var orbit_sound: AudioStreamPlayer2D = $orbitSound
@onready var engine_sound: AudioStreamPlayer2D = $EngineSound


var is_charging: bool = false
var is_touch_on_cancel_button: bool = false

# --- STATE MANAGEMENT ---
# Using an enum makes the rocket's state clear and prevents bugs.
enum State { TRAVELING, ORBITING }
var current_state: State = State.TRAVELING

enum Gravity { REAL, LINEAR, SOFTENED }
@export var current_gravity: Gravity = Gravity.SOFTENED
@export var softening_factor = 100

@export var max_pitch_scale: float = 1.0 # Pitch when charge is 0%
@export var min_pitch_scale: float = 0.2 # Pitch when charge is 100%

# --- PHYSICS & NODE REFERENCES ---
var planets: Array[Node]
var whiteholes: Array[Node] # <--- NEW: Array to hold whitehole nodes
var moons: Array[Node] # <--- Add this variable
var orbiting_planet: Node = null # The planet we are currently orbiting.

func _ready():
	# Find all planets in the "planets" group.
	planets = get_tree().get_nodes_in_group("planets")
	# remove integrated physics and will do physics process instead
	# <--- NEW: Find all whiteholes so we can calculate their gravity later
	whiteholes = get_tree().get_nodes_in_group("whiteholes")
	moons = get_tree().get_nodes_in_group("moons") # <--- Add this line
	# Sync the UI bar max value to our script variable
	if charge_bar:
		charge_bar.max_value = max_charge_time
		charge_bar.value = 0
		charge_bar.visible = false # Hide it initially
	
	SelectedType = SaveManager.get_equipped_rocket()
	$AnimatedSprite2D.animation = SelectedType
	
	
	#Reza: fire
	fire.play()
	fire.scale.x = 0
	reverse_button.pressed.connect(flip)
	# These signals detect when a touch enters or leaves the button's area
	cancel_button.mouse_entered.connect(_on_cancel_button_mouse_entered)
	cancel_button.mouse_exited.connect(_on_cancel_button_mouse_exited)
	cancel_button.visible = false
	engine_sound.stream.loop = true
	
# This function is called by the player's input to launch the rocket.
func launch():
	# We can only launch if we are currently orbiting a planet.
	if current_state != State.ORBITING or orbiting_planet == null:
		return
	engine_sound.stop()
	engine_sound.pitch_scale = min_pitch_scale # Reset pitch to default
	# When we launch, we switch to the traveling state.
	current_state = State.TRAVELING
	
	# --- Calculate Launch Direction ---
	# Calculate dynamic impulse based on charge time
	var dynamic_impulse = (launch_impulse + (launch_impulse * charge_time) * 0.3 ) 
	# The direction is tangent to the orbit circle at our current position.
	# 1. Vector from planet to rocket.
	var planet_to_rocket = global_position - orbiting_planet.global_position
	# 2. Get the perpendicular vector (the tangent). This gives us the direction of orbital motion.
	var launch_direction = planet_to_rocket.orthogonal()
	
	# apply_central_impulse gives an instantaneous "kick".
	# We add our launch impulse to the existing velocity to make it feel like a boost.
	apply_central_impulse(launch_direction.normalized() * dynamic_impulse * -1 * clockwize)
	
	# We are no longer orbiting any specific planet.
	orbiting_planet = null
	
	if charge_bar:
		charge_bar.visible = false
		#Reza: fire
		fire.scale.x=0

# <--- NEW SECTION START: Physics State Management for Teleportation --->
var state_buffer_reset: bool = false
var preserved_velocity: Vector2 = Vector2.ZERO

# This function is called by Whitehole.gd
func teleport(target_position: Vector2):
	print("Teleporting Rocket!")
	
	var current_speed = linear_velocity.length()
	var direction = linear_velocity.normalized()
	
	# Prevent zero vector errors
	if direction == Vector2.ZERO: direction = Vector2.UP
	
	# Safely move the RigidBody using PhysicsServer
	PhysicsServer2D.body_set_state(
		get_rid(),
		PhysicsServer2D.BODY_STATE_TRANSFORM,
		Transform2D(rotation, target_position)
	)
	
	# Force immediate position update as fallback
	global_position = target_position 
	
	# Flag the physics engine to reset velocity on the next frame
	state_buffer_reset = true 
	preserved_velocity = direction * current_speed
	
func is_orbiting() -> bool:
	return current_state == State.ORBITING

# Native Godot function to safely modify RigidBody state
func _integrate_forces(state):
	if state_buffer_reset:
		state.linear_velocity = preserved_velocity
		state_buffer_reset = false
# <--- NEW SECTION END --->

# This function is called by the Planet's signal when we enter its gravity well.
func enter_orbit(planet: Node):
	# If we are already orbiting something, or the planet is invalid, do nothing.
	if current_state == State.ORBITING or not is_instance_valid(planet):
		return
	# <--- NEW: Safety check. 
	# Since Whiteholes also have gravity, we ensure we only enter orbit mode for actual Planets.
	if not (planet is Planet or planet is Moon): return 
	
	print("Entering orbit around: ", planet.name)
	# --- ADDED CODE: Automatically determine orbit direction ---
	# We determine the orbital direction (clockwise or counter-clockwise) based on
	# the rocket's velocity as it enters the orbit zone.
	# 1. Get the vector from the planet's center to the rocket.
	var planet_to_rocket = global_position - planet.global_position
	
	# 2. Use the 2D cross product of the position and velocity vectors.
	# The sign of the result tells us the direction of angular motion.
	var orbital_direction_sign = sign(planet_to_rocket.cross(linear_velocity))

	# If the cross product is 0, the rocket is moving directly toward or away from
	# the planet. In this case, there's no initial orbital direction, so we
	# keep the current 'clockwize' setting.
	if orbital_direction_sign != 0:
		# The 'clockwize' variable is -1 for clockwise and 1 for counter-clockwise.
		# A positive cross product corresponds to counter-clockwise motion.
		# If the required direction doesn't match our current state, we flip.
		if orbital_direction_sign != clockwize:
			flip()
	# --- END OF ADDED CODE ---
	charge_time = 0.0
	current_state = State.ORBITING
	orbiting_planet = planet
	
	if charge_bar:
		charge_bar.value = 0.0
		#Reza: change it so the change bar won't show
		charge_bar.visible = false
	# Immediately snap the rocket to the correct orbit distance.
	# This ensures a perfect circular orbit from the start.
	var direction_to_rocket = (global_position - orbiting_planet.global_position).normalized()
	global_position = orbiting_planet.global_position + direction_to_rocket * orbiting_planet.orbit_radius
	
	# Stop all previous motion to begin a stable orbit.
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	rotation = 0.0
	reverse_button.visible = true
	orbit_effect.play()
	orbit_sound.play()


# This function is called by the Planet's signal if we leave its gravity well.
func exit_orbit(planet: Node):
	# We only care if we are exiting the planet we thought we were orbiting.
	if orbiting_planet == planet:
		print("Exiting orbit of: ", planet.name)
		current_state = State.TRAVELING
		orbiting_planet = null


# --- CORE PHYSICS LOGIC ---

func _unhandled_input(event: InputEvent):
	# This is how the player will launch the rocket.
	# "ui_accept" is Spacebar, Enter, or the main gamepad button by default.
	# We only care about touch controls when orbiting.
	if current_state != State.ORBITING:
		return
	# This is how the player will launch the rocket.
	# "ui_accept" is Spacebar, Enter, or the main gamepad button by default.
	if event.is_action_pressed("reverse"):
		flip()
	if event.is_action_released("ui_accept") and not Input.is_action_pressed("cancel"):
		launch()
		_cancel_charge()
	# This logic specifically targets screen touches.
	if event is InputEventScreenTouch:
		# If the user just touched the screen (and not on a button)...
		if event.is_pressed():
			is_charging = true
			cancel_button.visible = true # Show the cancel button.
			is_touch_on_cancel_button = false # Reset the cancel flag.
		
		# If the user just released their finger from the screen...
		elif event.is_released():
			if not is_charging: return # Ignore if we weren't charging.
			
			# Check if the finger was released over the cancel button.
			if is_touch_on_cancel_button:
				_cancel_charge() # Cancel the action.
			else:
				launch() # Otherwise, launch the rocket.
				reverse_button.visible = false

			# Clean up state regardless of outcome.
			is_charging = false
			cancel_button.visible = false
			


func flip():
	clockwize = clockwize * -1
	$AnimatedSprite2D.flip_v = !$AnimatedSprite2D.flip_v
	fire.flip_h = !fire.flip_h 

func _physics_process(delta: float):
	# The state machine determines what physics to apply.
	match current_state:
		State.TRAVELING:
			apply_gravity_forces()
			linear_damp = damping_coffactor
			# Check if we are moving fast enough to calculate a valid angle
			if linear_velocity.length_squared() > 0.05: # for better feel in direction changes
				rotation = linear_velocity.angle() + deg_to_rad(90 * clockwize * -1)
		State.ORBITING:
			perform_orbit(delta)

# This function is responsible for the gravity simulation when traveling between planets.
func apply_gravity_forces():
	var gravity_sources = planets + whiteholes + moons 
	for body in gravity_sources: # <--- CHANGED: Iterating over 'body' instead of 'planet'
		
		# <--- CHANGED: Check if instance is valid AND if it has a mass property. 
		# We removed "is Planet" check so it works for Whiteholes too.
		if not is_instance_valid(body) or not "mass" in body:
			continue
			
		var direction_vector = body.global_position - global_position # <--- CHANGED: 'planet' became 'body'
		var distance_squared = direction_vector.length_squared()
		
		if distance_squared < 1.0: # Avoid division by zero
			continue
		var force_magnitude = 0
		
		# <--- CHANGED: Logic remains the same, but we use 'body.mass'
		match current_gravity:
			Gravity.REAL:
				force_magnitude = (gravitational_constant * self.mass * body.mass) / distance_squared
			Gravity.LINEAR:
				var distance = sqrt(distance_squared)
				force_magnitude = (gravitational_constant * self.mass * body.mass) / distance
			Gravity.SOFTENED:
				force_magnitude = (gravitational_constant * self.mass * body.mass) / (distance_squared + softening_factor)
		
		var force_vector = direction_vector.normalized() * force_magnitude
		apply_central_force(force_vector)

# This function handles the perfect circular orbit.
func perform_orbit(delta: float):
	if not is_instance_valid(orbiting_planet):
		# If the planet we were orbiting gets destroyed, go back to traveling.
		current_state = State.TRAVELING
		return
		
	# This whole block now runs if the player is touching the screen.
	if is_charging:
		if not engine_sound.playing:
			engine_sound.play() # Start the engine sound if it's not already playing

		charge_time = min(charge_time + delta, max_charge_time)

		# Calculate the charge percentage (a value from 0.0 to 1.0)
		var charge_percent = charge_time / max_charge_time
		# Linearly interpolate the pitch based on the charge percentage
		engine_sound.pitch_scale = lerp(min_pitch_scale, max_pitch_scale, charge_percent)

		charge_time = min(charge_time + delta, max_charge_time)
		if charge_bar:
			charge_bar.visible = false # Make sure it reappears if we restart charging
			charge_bar.value = charge_time
			#Reza: some changes for fire:
		fire.scale.x = charge_time/2
		fire.position.y = clockwize * 300 * charge_time/2 * -1
	
	if Input.is_action_pressed("cancel"):
		charge_time = 0.0
		fire.scale.x = 0.0
		is_charging = false
		if charge_bar: charge_bar.visible = false
	elif Input.is_action_pressed("ui_accept"):
		charge_time = min(charge_time + delta, max_charge_time)
		is_charging = true
		if charge_bar:
			charge_bar.visible = false # Make sure it reappears if we restart charging
			charge_bar.value = charge_time
			#Reza: some changes for fire:
			fire.scale.x = charge_time/2
			fire.position.y = clockwize * 300 * charge_time/2 * -1
	
	# To ensure a stable orbit, we take direct control of the transform.
	# This overrides any lingering physics forces.
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	var current_orbit_speed = (base_orbiting_speed + (base_orbiting_speed * charge_time) * 0.5) / sqrt(orbiting_planet.orbit_radius/50.0)
	# 1. Calculate our current position relative to the planet.
	var offset = global_position - orbiting_planet.global_position
	
	# 2. Calculate the new angle by advancing the current angle over time.
	#    'state.step' is the delta time for the physics frame, ensuring smooth, frame-rate-independent motion.
	var new_angle = offset.angle() + current_orbit_speed * delta * clockwize
	
	# 3. Calculate the new position on the circle.
	var new_position = orbiting_planet.global_position + Vector2.from_angle(new_angle) * orbiting_planet.orbit_radius
	
	global_position = new_position

	# Point the rocket in the direction of travel (tangent to the orbit).
	rotation = new_angle 

func _cancel_charge():
	charge_time = 0.0
	fire.scale.x = 0.0
	engine_sound.stop()
	is_charging = false
	engine_sound.pitch_scale = min_pitch_scale # Reset pitch to default
	cancel_button.scale = Vector2.ONE * 0.5
	cancel_button.position = cancel_button.position + Vector2.ONE * 20
	if charge_bar:
		charge_bar.visible = false
		charge_bar.value = 0.0

func _on_cancel_button_mouse_entered():
	# This is triggered when the player's finger drags onto the button.
	if is_charging:
		is_touch_on_cancel_button = true
		cancel_button.position = cancel_button.position - Vector2.ONE * 20
		cancel_button.scale = Vector2.ONE * 0.8

func _on_cancel_button_mouse_exited():
	# This is triggered when the player's finger drags off the button.
	if is_charging:
		is_touch_on_cancel_button = false
		cancel_button.scale = Vector2.ONE * 0.5
		cancel_button.position = cancel_button.position + Vector2.ONE * 20
