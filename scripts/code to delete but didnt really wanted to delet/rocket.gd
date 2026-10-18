
extends RigidBody2D

# You can adjust these values in the Inspector tab in the Godot editor.
@export var launch_speed: float = 400.0
@export var gravitational_constant: float = 5000.0
@export var orbiting_speed: float = 100.0
@export var orbiting_distance: float = 100.0

# A list to hold all nodes that can exert gravity (i.e., planets, stars).
var planets: Array[Node]

# A variable to track the planet we are most influenced by (optional, but useful).
var current_planet: Node

# A boolean flag to determine if physics forces should be calculated.
var is_launched: bool = false


func _ready():
	# In Godot, it's best to use "groups" to organize similar nodes.
	# Go to your planet scenes/nodes, select the "Node" tab -> "Groups" -> and add them to a group named "planets".
	# This line will then automatically find all nodes in that group when the game starts.
	planets = get_tree().get_nodes_in_group("planets")
	
	# We set custom_integrator to true so that the _integrate_forces function is called.
	# This is the correct place to apply custom physics like gravity every frame.
	custom_integrator = true


# This function is the heart of our physics simulation.
# It is called automatically by the physics engine before it moves the body.
# 'state' gives us access to the body's current state (like velocity, position)
# and allows us to add forces.
func _integrate_forces(state: PhysicsDirectBodyState2D):
	# If the rocket hasn't been launched, we don't do any calculations.
	if not is_launched:
		orbit(state)
		pass
	# This calls the function to calculate and apply forces.
	calculate_and_apply_forces(state)
	
	# following lines are here for debug purpose and will be removed
	if current_planet == null:
		is_launched = true
		return
	if (current_planet.global_position - self.global_position).length() <= orbiting_distance:
		is_launched = false


# This function calculates all the gravitational forces and applies them.
func calculate_and_apply_forces(state: PhysicsDirectBodyState2D):
	var closest_planet = null
	var min_dist_sq = INF  # INF represents infinity.
	# We loop through every planet we found in the _ready() function.
	for planet in planets:
		# We need to make sure the planet script has a 'mass' variable.
		if not planet.has("mass"):
			print_debug("Warning: Planet %s is missing a 'mass' property." % planet.name)
			continue
		
		# --- find closest planet ---
		var dist_sq = self.global_position.distance_squared_to(planet.global_position)
		if dist_sq < min_dist_sq:
			min_dist_sq = dist_sq
			closest_planet = planet
		
		# --- Calculate Gravitational Force ---
		# 1. Get the direction vector from the rocket to the planet.
		var direction_vector = planet.global_position - self.global_position
		
		# 2. Get the squared distance. Using length_squared() is much faster
		#    than using length() because it avoids a square root calculation.
		var distance_squared = direction_vector.length_squared()
		
		# Avoid division by zero if the rocket is exactly at the planet's center.
		if distance_squared < 1.0:
			continue
			
		# 3. Calculate the magnitude of the force using Newton's law of universal gravitation:
		#    F = G * (m1 * m2) / r^2
		#    Here, self.mass is the built-in mass of the RigidBody2D.
		var force_magnitude = (gravitational_constant * self.mass * planet.mass) / distance_squared
		
		# 4. Create the final force vector by combining the direction and magnitude.
		#    We normalize the direction vector to get a unit vector (length of 1)
		#    and then multiply by the calculated force magnitude.
		var force_vector = direction_vector.normalized() * force_magnitude
		
		# 5. Apply the calculated force to the rocket.
		#    This force is added to any other forces acting on the body for this physics frame.
		state.apply_central_force(force_vector)
	current_planet = closest_planet


## Call this function to launch the rocket.
## Pass it a normalized direction vector, e.g., Vector2.UP.
func launch(direction: Vector2):
	if is_launched:
		return
	
	# This activates the force calculations in _integrate_forces.
	is_launched = true
	
	# Clears any existing motion.
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	
	# apply_central_impulse gives the body an instantaneous "kick".
	# It's perfect for launching projectiles, jumping, etc.
	apply_central_impulse(direction.normalized() * launch_speed)

## todo add effects
func orbit(state: PhysicsDirectBodyState2D):
	# updates the speed of the rocket based on the plannet it is orbiting
	# following lines are here for debug purpose and will be removed

	if current_planet == null:
		is_launched = true
		return
	
	# Zero out physics engine's influence to take full control.
	state.linear_velocity = Vector2.ZERO
	state.angular_velocity = 0.0
	
	# Calculate position relative to the planet.
	var offset = position - current_planet.global_position
	
	# Calculate the new angle by advancing the old one with orbit_speed.
	var angle = offset.angle() + orbiting_speed * state.step
	
	# Set new position using the new angle and radius.
	var new_transform = state.transform
	new_transform.origin = current_planet.global_position + Vector2.from_angle(angle) * offset.length()
	state.transform = new_transform

	# Point the body in the direction of travel (tangent to the orbit circle).
	rotation = angle + PI / 2.0


# not useful
### it is calculate to check weather or not we can orbit a planet
### can be used to check condition distance_from_current_planet < orbiting_limit_of_the_same_planet
#func find_closest_planet() -> Node2D:
	#var closest_planet = null
	#var min_dist_sq = INF  # INF represents infinity.
	#
	#for planet in planets:
		#var dist_sq = self.global_position.distance_squared_to(planet.global_position)
		#if dist_sq < min_dist_sq:
			#min_dist_sq = dist_sq
			#closest_planet = planet
			#
	#current_planet = closest_planet
	#return closest_planet
