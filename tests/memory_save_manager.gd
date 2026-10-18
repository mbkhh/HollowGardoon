extends "res://scripts/SaveManager.gd"
## Test-only storage: exercise real result/progression code without disk writes.
var save_calls := 0

func save_game() -> void:
	save_calls += 1

func load_game() -> void:
	pass
