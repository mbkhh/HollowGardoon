extends Node

var player: AudioStreamPlayer
var player2: AudioStreamPlayer


func _ready() -> void:
	# Create an audio player for the win sound
	process_mode = Node.PROCESS_MODE_ALWAYS
	player = AudioStreamPlayer.new()
	player.bus = "SFX"  # or "Master" / your SFX bus name
	player.stream = preload("res://assets/sounds/Level-success.wav")  # <-- change path if needed
	add_child(player)
	
	player2 = AudioStreamPlayer.new()
	player2.bus = "SFX"  # or "Master" / your SFX bus name
	player2.stream = preload("res://assets/sounds/Star_beep-sytlized.wav")  # <-- change path if needed
	add_child(player2)

func play_star() -> void:
	if player2 == null:
		return
	if player2.playing:
		player2.stop()
	player2.play()
func play_win() -> void:
	if player == null:
		return

	if player.playing:
		player.stop()

	player.play()
