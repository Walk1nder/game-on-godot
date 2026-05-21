extends Area2D

@export var speed: float = 400.0 # Скорость полета
@export var damage: int = 20     # Урон
var direction: Vector2 = Vector2.RIGHT # Направление по умолчанию


func _physics_process(delta):
	# Двигаем стрелу каждый кадр
	position += direction * speed * delta

# Этот сигнал нужно подключить в узле Area2D во вкладке "Узлы" (Node) -> body_entered
func _on_body_entered(body):
	# Проверяем, является ли объект игроком (например, если у игрока есть метод take_damage)
	if body.has_method("take_damage"):
		body.take_damage(damage)
		queue_free() # Удаляем стрелу после попадания
	# Если стрела попала в стену (TileMap), тоже удаляем её
	elif body is TileMap: 
		queue_free()

# Если добавил VisibleOnScreenNotifier2D, подключи его сигнал screen_exited
func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free() # Удаляем стрелу, если она улетела за экран, чтобы не засорять память


func _on_hit_box_area_entered(area: Area2D) -> void:
	Signals.emit_signal("enemy_attack", damage)
