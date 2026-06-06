extends Area2D

# Сколько ячеек в этом сундуке? (Должно совпадать с количеством ячеек в ChestUI)
@export var chest_size: int = 9 

@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D

var inventory: Array = []
var player_in_zone: bool = false
var is_open: bool = false

func _ready():
	$Label.hide()
	anim_sprite.play("closed")
	# Создаем пустые ячейки для сундука
	for i in range(chest_size):
		inventory.append(null)
		
	var health_potion = preload("res://health_potion.tres") 
	inventory[0] = {"item": health_potion, "amount": 2}

	# --- ТУТ МОЖНО ДОБАВИТЬ СТАРТОВЫЙ ЛУТ ---
	# Например, если хочешь, чтобы сундук не был пустым изначально:
	# inventory[0] = {"item": preload("res://Items/potion.tres"), "amount": 2}

func _unhandled_input(event):
	if event.is_action_pressed("interact") and player_in_zone:
		var player = get_tree().get_first_node_in_group("player")
		if player:
			if not is_open:
				open_chest(player)
			else:
				close_chest(player)

func open_chest(player):
	is_open = true
	anim_sprite.play("open") # Анимация открытия
	player.active_chest = self # Говорим игроку "я твой открытый сундук"

	# Показываем UI сундука и обновляем его
	if player.chest_ui:
		player.chest_ui.show()
		update_chest_ui()

func close_chest(player):
	is_open = false
	anim_sprite.play("closed") # Анимация закрытия
	player.active_chest = null # Игрок больше не смотрит в сундук

	if player.chest_ui:
		player.chest_ui.hide()

# Функция добавления предмета В СУНДУК (похожа на add_item_to_inventory у игрока)
func add_item_to_chest(item_data, amount: int) -> bool:
	# Ищем пустую ячейку (стаки здесь пока опустим для простоты, или сделай как у игрока)
	for i in range(chest_size):
		if inventory[i] == null:
			inventory[i] = {"item": item_data, "amount": amount}
			return true
	return false # Сундук полон

# Обновление картинок в ChestUI
func update_chest_ui():
	var player = get_tree().get_first_node_in_group("player")
	if player and player.chest_ui:
		var chest_slots = player.chest_ui.get_children()
		for i in range(chest_size):
			if i < chest_slots.size():
				if inventory[i] != null:
					chest_slots[i].update_slot(inventory[i]["item"], inventory[i]["amount"])
				else:
					chest_slots[i].update_slot(null, 0)

# --- СИГНАЛЫ ЗОНЫ ---
func _on_body_entered(body):
	if body.is_in_group("player"):
		player_in_zone = true
		$Label.show()
		print("Кто-то вошёл:", body.name)

func _on_body_exited(body):
	if body.is_in_group("player"):
		player_in_zone = false
		$Label.hide()
		print("Кто-то вышел:", body.name)
		# Если игрок убежал от сундука, закрываем его автоматически!
		if is_open:
			close_chest(body)
