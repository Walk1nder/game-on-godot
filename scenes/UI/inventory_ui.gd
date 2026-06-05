extends MarginContainer

@onready var expanded_inventory = $VBoxContainer/ExpandedInventory

func _ready():
	# При старте скрываем и делаем прозрачным
	expanded_inventory.hide()
	expanded_inventory.modulate.a = 0.0

func _input(event):
	if event.is_action_pressed("inventory"):
		var tween = get_tree().create_tween()

		if expanded_inventory.visible:
			# Плавное исчезновение (анимация прозрачности от 1 к 0 за 0.2 секунды)
			tween.tween_property(expanded_inventory, "modulate:a", 0.0, 0.2)
			# Ждем конца анимации и скрываем полностью
			tween.tween_callback(expanded_inventory.hide)
		else:
			# Плавное появление
			expanded_inventory.show()
			tween.tween_property(expanded_inventory, "modulate:a", 1.0, 0.2)
