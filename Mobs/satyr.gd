extends CharacterBody2D

enum {
	idle,
	run,
	attack1,
	attack2,
	hurt,
	death
}

# Получаем гравитацию из настроек проекта
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

const SPEED = 110.0         # Скорость бега Сатира
const CHASE_RANGE = 350.0   # Дистанция, на которой он видит игрока и бежит к нему
const ATTACK_RANGE = 50.0   # Дистанция удара вблизи (для атаки 1)

var health = 150 # Сатир крепкий парень

@onready var anim = $AnimatedSprite2D
@onready var anim_player = $AnimationPlayer
@onready var hitbox = $DamageBox/HitBox 

var state = idle # Сатир сразу стоит и ждет (сна больше нет)
var player_pos = Vector2.ZERO
var can_attack = true 

func _ready():
	Signals.connect("player_position_update", Callable(self, "_on_player_position_update"))
	hitbox.get_node("CollisionShape2D").set_deferred("disabled", true)
	anim_player.play("Idle")

func _on_player_position_update(pos):
	player_pos = pos

func _physics_process(delta):
	# ВАЖНО: Сатир ходит по земле, поэтому гравитация работает ВСЕГДА, если он не на полу
	if not is_on_floor():
		velocity.y += gravity * delta

	match state:
		idle:
			idle_state()
		run:
			run_state()
		attack1, attack2:
			attack_state()
		hurt:
			hurt_state()
		death:
			velocity.x = 0 # Труп просто лежит на месте

	move_and_slide()

# --- СОСТОЯНИЯ ---

func idle_state():
	velocity.x = move_toward(velocity.x, 0, SPEED) # Останавливаемся
	anim_player.play("Idle")

	var distance = global_position.distance_to(player_pos)
	if distance <= ATTACK_RANGE:
		start_attack()
	elif distance < CHASE_RANGE:
		state = run

func run_state():
	anim_player.play("Run")

	# Сатир ходит по полу, поэтому нам нужно направление ТОЛЬКО по оси X
	var direction = sign(player_pos.x - global_position.x)
	velocity.x = direction * SPEED

	# Поворачиваем Сатира в сторону игрока
	if direction < 0: # Игрок слева
		anim.flip_h = true # Отражаем спрайт
		$DamageBox.scale.x = -1 # Отражаем хитбокс
	elif direction > 0: # Игрок справа
		anim.flip_h = false # Возвращаем спрайт в норму
		$DamageBox.scale.x = 1 # Возвращаем хитбокс в норму

	# Проверяем дистанцию
	var distance = global_position.distance_to(player_pos)
	if distance <= ATTACK_RANGE:
		start_attack()
	elif distance > CHASE_RANGE:
		state = idle

func attack_state():
	velocity.x = move_toward(velocity.x, 0, SPEED) # Во время атаки стоит на месте

func hurt_state():
	velocity.x = move_toward(velocity.x, 0, SPEED) # При получении урона останавливается

# --- ТРИГГЕРЫ (Запуск анимаций) ---

func start_attack():
	# Рандомно выбираем между двумя атаками
	if randi() % 2 == 0:
		state = attack1
		anim_player.play("Attack1")
	else:
		state = attack2
		anim_player.play("Attack2")

	await anim_player.animation_finished

	if state != death and state != hurt: 
		state = idle

func take_damage(damage):
	if state == death:
		return

	health -= damage
	print("Сатир получил урон! ХП: ", health)

	if health <= 0:
		state = death
		anim_player.play("Death")
		await anim_player.animation_finished
		queue_free()
	else:
		state = hurt
		anim_player.stop() 
		anim_player.play("Hurt")
		await anim_player.animation_finished
		if state != death:
			state = idle

# --- ЭТУ ФУНКЦИЮ НУЖНО ВЫЗВАТЬ ИЗ ANIMATION PLAYER ---
func cast_magic():
	print("ПИУ! Сатир выстрелил лучом!")
	# Сюда добавим код спавна луча, когда ты его создашь
	
func _on_hit_box_area_entered(area):
	if state == death or can_attack == false:
		return

	var target = area
	while target != null:
		if target.has_method("take_damage"):
			target.take_damage(10) # Урон от мыши
			return
		target = target.get_parent()
