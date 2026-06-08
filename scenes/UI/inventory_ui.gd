extends MarginContainer

@onready var expanded_inventory = $VBoxContainer/ExpandedInventory

func _ready():
	expanded_inventory.hide()
	expanded_inventory.modulate.a = 0.0

func _input(event):
	if event.is_action_pressed("inventory"):
		var tween = get_tree().create_tween()

		if expanded_inventory.visible:
			tween.tween_property(expanded_inventory, "modulate:a", 0.0, 0.2)
			tween.tween_callback(expanded_inventory.hide)
		else:
			expanded_inventory.show()
			tween.tween_property(expanded_inventory, "modulate:a", 1.0, 0.2)
