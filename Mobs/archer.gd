extends CharacterBody2D

# Перетаскиваем сцену стрелы (arrow.tscn) из файловой системы в это поле в Инспекторе
@export var arrow_scene: PackedScene 

@onready var animPlayer = $AnimationPlayer
@onready var shoot_point = $ShootPoint
@onready var sprite = $AnimatedSprite2D # Учтено твое название узла!

var facing_right = true
var player_in_range = false # Видит ли лучник игрока?
var is_attacking = false    # Атакует ли он прямо сейчас?

func _ready():
	# Принудительно запускаем idle при старте игры
	animPlayer.play("idle")
	print("Лучник появился, запущен idle")

func _physics_process(_delta):
	# Если игрок в зоне видимости и лучник сейчас НЕ атакует — начинаем атаку
	if player_in_range and not is_attacking:
		start_attack()

func start_attack():
	is_attacking = true
	animPlayer.play("attack") # Запускаем анимацию
	print("Начата анимация атаки!")

# Эта функция всё так же вызывается из AnimationPlayer (Call Method Track)
func fire_arrow():
	print("Функция fire_arrow вызвана!") # Проверка вызова
	if arrow_scene:
		var arrow = arrow_scene.instantiate()
		arrow.global_position = shoot_point.global_position

		if facing_right:
			arrow.direction = Vector2.RIGHT
			arrow.scale.x = 1
		else:
			arrow.direction = Vector2.LEFT
			arrow.scale.x = -1

		get_tree().current_scene.add_child(arrow)
		print("Стрела заспавнена!")
	else:
		print("ОШИБКА: В инспектор не добавлена сцена стрелы!")

# СИГНАЛ: Игрок вошел в зону видимости
func _on_detection_area_body_entered(body):
	print("В зону вошел: ", body.name) # Смотрим, кого вообще видит лучник
	
	# Надежная проверка: проверяем, состоит ли вошедший объект в группе "player"
	if body.is_in_group("player"): 
		player_in_range = true
		print("Это игрок! Начинаем стрельбу.")

# СИГНАЛ: Игрок вышел из зоны видимости
func _on_detection_area_body_exited(body):
	if body.is_in_group("player"):
		player_in_range = false
		print("Игрок ушел из зоны!")

# СИГНАЛ: Анимация завершилась
func _on_animation_player_animation_finished(anim_name):
	if anim_name == "attack":
		# Лучник закончил выстрел, снимаем флаг атаки
		is_attacking = false
		print("Анимация атаки закончилась")

		# Если игрок убежал, возвращаемся в покой
		if not player_in_range:
			animPlayer.play("idle") 
			print("Возвращаемся в idle")
