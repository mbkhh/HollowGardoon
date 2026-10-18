extends Node

const MIN_DB: float = -30.0  # quieter limit
const MAX_DB: float = 0.0    # full volume

var music_volume: float = 1.0   # 0.0–1.0
var sfx_volume: float = 1.0     # 0.0–1.0


func _ready() -> void:
	_apply_music_volume()
	_apply_sfx_volume()


func set_music_volume(value: float) -> void:
	music_volume = clamp(value, 0.0, 1.0)
	_apply_music_volume()


func set_sfx_volume(value: float) -> void:
	sfx_volume = clamp(value, 0.0, 1.0)
	_apply_sfx_volume()



func _apply_music_volume() -> void:
	var idx: int = AudioServer.get_bus_index("Music")
	if music_volume <= 0.0:
		AudioServer.set_bus_mute(idx, true)
	else:
		AudioServer.set_bus_mute(idx, false)
		var db: float = lerp(MIN_DB, MAX_DB, music_volume)
		AudioServer.set_bus_volume_db(idx, db)
		
func _apply_sfx_volume() -> void:
	var idx: int = AudioServer.get_bus_index("SFX")
	if sfx_volume <= 0.0:
		AudioServer.set_bus_mute(idx, true)
	else:
		AudioServer.set_bus_mute(idx, false)
		var db: float = lerp(MIN_DB, MAX_DB, sfx_volume)
		AudioServer.set_bus_volume_db(idx, db)
