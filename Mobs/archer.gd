extends CharacterBody2D

enum {
	IDLE,
	CHASE,
	DEATH # 1. Добавили новое состояние смерти
}

@export var arrow_scene: PackedScene 
@onready var cooldown_timer = $AttackCooldown
@onready var animPlayer = $AnimationPlayer
@onready var shoot_point = $ShootPoint
@onready var sprite = $AnimatedSprite2D

var target_player: Node2D = null
var facing_right = true
var player_in_range = false
var is_attacking = false   
var player: Vector2         
var direction: Vector2      

var state: int = IDLE       

# 2. Добавили здоровье лучнику
var health: int = 100 # Можешь изменить значение

func _ready():
	animPlayer.play("idle")
	print("Лучник появился, запущен idle")
	Signals.player_position_update.connect(Callable(self, "_on_player_position_update"))
	

func _physics_process(_delta):
	# 3. Если мертв - выходим из функции, чтобы он перестал ходить и стрелять
	if state == DEATH:
		return

	if player_in_range and not is_attacking and cooldown_timer.is_stopped():
		start_attack()
		
	match state:
		IDLE:
			if player_in_range and target_player:
				state = CHASE
		CHASE:
			chase_state()
			if not player_in_range:
				state = IDLE
			
func _on_player_position_update(player_pos):
	player = player_pos

func start_attack():
	is_attacking = true
	animPlayer.play("attack") 
	print("Начата анимация атаки!")

func fire_arrow():
	if arrow_scene and target_player:
		var arrow = arrow_scene.instantiate()
		arrow.global_position = shoot_point.global_position
		var direction_to_player = shoot_point.global_position.direction_to(target_player.global_position)
		arrow.direction = direction_to_player
		arrow.rotation = direction_to_player.angle() 
		get_tree().current_scene.add_child(arrow)

func _on_detection_area_body_entered(body):
	print("В зону вошел: ", body.name)
	if body.is_in_group("player"): 
		player_in_range = true
		target_player = body
		print("Это игрок! Начинаем стрельбу.")
		state = CHASE

func _on_detection_area_body_exited(body):
	if body.is_in_group("player"):
		player_in_range = false
		target_player = null
		print("Игрок ушел из зоны!")
		state = IDLE

func _on_animation_player_animation_finished(anim_name):
	# Не запускаем таймеры и не меняем состояния, если лучник уже умирает
	if state == DEATH:
		return

	if anim_name == "attack":
		is_attacking = false
		cooldown_timer.start() 
		print("Анимация атаки закончилась")

		if not player_in_range:
			animPlayer.play("idle") 
			print("Возвращаемся в idle")
	elif anim_name == "hurt":
		is_attacking = false # Сбрасываем атаку, если его ударили во время выстрела
		if player_in_range:
			animPlayer.play("idle") # Возвращаем в стойку
		else:
			animPlayer.play("idle")

func chase_state(): 
	if player:
		direction = (player - self.position).normalized()
		if direction.x < 0:
			sprite.flip_h = true
		else:
			sprite.flip_h = false


# 4. Функция получения урона (вызовешь её через сигнал HurtBox)
func take_damage(damage_amount):
	# Если уже мертв - игнорируем новые удары
	if state == DEATH:
		return
	health -= damage_amount
	print("Лучник получил урон! Осталось: ", health)
	if health <= 0:
		health = 0
		die()
	else:
		animPlayer.stop()
		animPlayer.play("hurt")
# 5. Функция смерти
func die():
	state = DEATH
	set_physics_process(false) # Останавливаем движение навсегда
	cooldown_timer.stop() # Останавливаем таймер, чтобы он не выстрелил из могилы
	is_attacking = false # Прерываем атаку
	
	animPlayer.play("death") # Запускаем анимацию смерти
	await animPlayer.animation_finished # Ждем конца анимации
	
	queue_free() # Удаляем лучника с уровня (здесь это безопасно, так как мы не меняем сцену)


func _on_hurt_box_area_entered(area):
	print("Что-то коснулось лучника: ", area.name)
# area.owner — это главный узел сцены (твоего Игрока), на котором висит скрипт Игрока
	var attacker = area.owner
  
  # Проверяем, существует ли attacker и есть ли внутри его скрипта переменная 'damage_amount'
	if attacker != null and "damage_amount" in attacker:
	# Берем урон прямо из скрипта твоего Игрока!
		take_damage(attacker.damage_amount)
	
  # Резервная проверка (если структура сцены чуть другая, сработает по слову damagebox или hitbox)
	elif "damagebox" in str(area.name).to_lower() or "hitbox" in str(area.name).to_lower():
		take_damage(20)
#pfgfpf
