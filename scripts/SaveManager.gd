extends Node

const SAVE_PATH := "user://savegame.cfg"
const TOTAL_LEVELS := 15 # change to your real number of levels

var xp: int = 0
var level_data: Dictionary = {}

const ROCKET_TYPES: Array[String] = ["default", "ship1", "ship2", "ship3"]

var rocket_owned: Dictionary = {}
var equipped_rocket: String = "default"

func _ready() -> void:
	print("Save file: "+OS.get_user_data_dir())
	_init_default_data()
	load_game()


func _init_default_data() -> void:
	# If save file doesn't exist, we start with default values
	level_data.clear()

	for i in range(TOTAL_LEVELS):
		var level_id := "level_%d" % (i + 1)  # level_1, level_2, ...
		level_data[level_id] = {
			"completed": false,
			"stars": 0
		}

	xp = 0
	rocket_owned.clear()
	for t in ROCKET_TYPES:
		rocket_owned[t] = false
	rocket_owned["default"] = true   # player starts with default
	equipped_rocket = "default"


func save_game() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("player", "xp", xp)
	cfg.set_value("player", "equipped_rocket", equipped_rocket)

	for t in ROCKET_TYPES:
		cfg.set_value("rocket", t + "_owned", rocket_owned.get(t, false))
		
	for level_id in level_data.keys():
		var section := "level_%s" % level_id  # e.g. level_level_1 (optional)
		# Or just use level_id directly as section, if you want:
		section = level_id
		cfg.set_value(section, "completed", level_data[level_id]["completed"])
		cfg.set_value(section, "stars", level_data[level_id]["stars"])

	var err := cfg.save(SAVE_PATH)
	if err != OK:
		push_error("Failed to save game: %s" % err)


func load_game() -> void:
	var cfg := ConfigFile.new()
	var err := cfg.load(SAVE_PATH)

	if err != OK:
		# No file yet → keep defaults
		return

	xp = int(cfg.get_value("player", "xp", 0))

	equipped_rocket = String(cfg.get_value("player", "equipped_rocket", "default"))

	# Load rockets
	rocket_owned.clear()
	for t in ROCKET_TYPES:
		var owned := bool(cfg.get_value("rocket", t + "_owned", t == "default"))
		rocket_owned[t] = owned

	for i in range(TOTAL_LEVELS):
		var level_id := "level_%d" % (i + 1)
		if cfg.has_section(level_id):
			level_data[level_id]["completed"] = bool(cfg.get_value(level_id, "completed", false))
			level_data[level_id]["stars"] = int(cfg.get_value(level_id, "stars", 0))


# ---------- Helper methods ----------

func set_level_result(level_id: String, stars_earned: int) -> void:
	stars_earned = clamp(stars_earned, 0, 3)

	if not level_data.has(level_id):
		return

	# Explicit type so the compiler is happy
	var prev_stars: int = int(level_data[level_id]["stars"])

	level_data[level_id]["completed"] = true
	# Only keep best star result
	level_data[level_id]["stars"] = max(prev_stars, stars_earned)

	# Example: add XP based on stars (customize this)
	var gained_xp: int = stars_earned * 10
	add_xp(gained_xp)

	# Optionally unlock the next level
	var parts := level_id.split("_")
	if parts.size() >= 2:
		var num := int(parts[1])
		var next_level_id := "level_%d" % (num + 1)
		if level_data.has(next_level_id):
			# put your unlock logic here later if you want
			pass

	save_game()



func add_xp(amount: int) -> void:
	xp = max(xp + amount, 0)
	save_game()


func get_level_stars(level_id: String) -> int:
	if level_data.has(level_id):
		return level_data[level_id]["stars"]
	return 0


func is_level_completed(level_id: String) -> bool:
	if level_data.has(level_id):
		return level_data[level_id]["completed"]
	return false
	
#----------------------------------------------
func is_rocket_owned(name: String) -> bool:
	return rocket_owned.get(name, false)


func can_afford(cost: int) -> bool:
	return xp >= cost


func buy_rocket(name: String, cost: int) -> bool:
	if not ROCKET_TYPES.has(name):
		return false
	if is_rocket_owned(name):
		return true
	if not can_afford(cost):
		return false

	xp -= cost
	rocket_owned[name] = true
	save_game()
	return true


func equip_rocket(name: String) -> void:
	if not is_rocket_owned(name):
		return
	equipped_rocket = name
	save_game()


func get_equipped_rocket() -> String:
	return equipped_rocket
