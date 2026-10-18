extends Node2D

const ROCKET_COSTS := {
	"default": 0,
	"ship1": 150,
	"ship2": 350,
	"ship3": 500,
}

@onready var xp_label: Label = $MarginContainer/VBoxContainer/HBoxContainer/XPLabel
@onready var click_sound: AudioStreamPlayer2D = $ClickSound

# Panels dictionary: rocket id -> panel node
@onready var panels: Dictionary = {
	"default": $RocketShip1Panel,
	"ship1": $RocketShip2Panel,
	"ship2": $RocketShip3Panel,
	"ship3": $RocketShip4Panel,
}


func _ready() -> void:
	_update_ui()


func _update_ui() -> void:
	xp_label.text = "%d" % SaveManager.xp

	for name in panels.keys():
		var panel: Control = panels[name] as Control

		# Figure out the button name for this rocket
		var button_name: String
		if name == "default":
			button_name = "Button1"
		elif name == "ship1":
			button_name = "Button2"
		elif name == "ship2":
			button_name = "Button3"
		elif name == "ship3":
			button_name = "Button4"
		else:
			button_name = "Button1"  # fallback

		var button: Button = panel.get_node(button_name) as Button
		var price_label: Label = panel.get_node("Label") as Label

		var owned: bool = SaveManager.is_rocket_owned(name)
		var equipped: bool = (SaveManager.equipped_rocket == name)
		var cost: int = int(ROCKET_COSTS.get(name, 0))

		if price_label != null:
			if name == "default":
				price_label.text = "Owned (default)"
			else:
				price_label.text = "Cost: %d" % cost

		if equipped:
			button.text = "Equipped"
			button.disabled = true
		elif owned:
			button.text = "Equip"
			button.disabled = false
		else:
			button.text = "Buy"
			button.disabled = not SaveManager.can_afford(cost)


func _on_rocket_button_pressed(name: String) -> void:
	var owned: bool = SaveManager.is_rocket_owned(name)
	var cost: int = int(ROCKET_COSTS.get(name, 0))

	if not owned:
		var success: bool = SaveManager.buy_rocket(name, cost)
		if not success:
			# Optional: show popup "Not enough XP"
			return
	click_sound.play()
	# Now equip it
	SaveManager.equip_rocket(name)
	_update_ui()


func _on_button_1_pressed() -> void:
	click_sound.play()
	_on_rocket_button_pressed("default")


func _on_button_2_pressed() -> void:
	click_sound.play()
	_on_rocket_button_pressed("ship1")


func _on_button_3_pressed() -> void:
	click_sound.play()
	_on_rocket_button_pressed("ship2")


func _on_button_4_pressed() -> void:
	click_sound.play()
	_on_rocket_button_pressed("ship3")


func _on_back_pressed() -> void:
	click_sound.play()
	get_tree().change_scene_to_file("res://scenes/game.tscn")


func _on_setting_pressed() -> void:
	click_sound.play()
	get_tree().change_scene_to_file("res://scenes/settings.tscn")
