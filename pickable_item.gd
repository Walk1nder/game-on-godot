extends Area2D

@export var item_data: ItemData # Сюда мы положим наш health_potion.tres

func _ready():
	# Автоматически ставим картинку из ресурса, чтобы не делать это вручную
	if item_data and item_data.icon:
		$Sprite2D.texture = item_data.icon

# Эта функция сработает, когда кто-то войдет в зону Area2D
func _on_body_entered(body):
	if body.name == "Player": # Проверяем, что это именно игрок
		if body.add_item_to_inventory(item_data): # Пытаемся дать предмет игроку
			queue_free() # Если игрок забрал предмет, удаляем его со сцены
