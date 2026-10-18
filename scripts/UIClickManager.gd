extends Node

var ui_player: AudioStreamPlayer

func _ready() -> void:
	# Create a global audio player for UI clicks
	ui_player = AudioStreamPlayer.new()
	ui_player.bus = "SFX"  # or "UI" if you have a separate bus
	ui_player.stream = preload("res://assets/sounds/click-tick.wav")
	add_child(ui_player)

	# Automatically connect to every button that appears
	get_tree().node_added.connect(_on_node_added)


func _on_node_added(node: Node) -> void:
	# If this node is a Button, hook into its pressed signal
	if node is Button:
		var btn: Button = node as Button
		if not btn.pressed.is_connected(_on_button_pressed):
			btn.pressed.connect(_on_button_pressed)


func _on_button_pressed() -> void:
	# Play the click sound each time any button is pressed
	if ui_player != null:
		ui_player.play()
