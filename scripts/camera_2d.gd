extends Camera2D

@export var zoom_speed: float = 0.1
@export var min_zoom: float = 0.5
@export var max_zoom: float = 3.0
@export var zoom_smoothness: float = 10.0

var target_zoom: Vector2

func _ready():
	zoom = Vector2(1.0, 1.0)
	target_zoom = zoom

func _input(event):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			target_zoom *= (1.0 + zoom_speed)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			target_zoom *= (1.0 - zoom_speed)
		
		# Clamp target zoom
		target_zoom.x = clamp(target_zoom.x, min_zoom, max_zoom)
		target_zoom.y = clamp(target_zoom.y, min_zoom, max_zoom)

func _process(delta):
	# Smooth interpolation
	zoom = zoom.lerp(target_zoom, zoom_smoothness * delta)
