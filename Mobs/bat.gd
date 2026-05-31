extends CharacterBody2D


enum {
	sleep,
	wake_up,
	idle_air,
	run,      # В данном случае это будет полет/преследование
	attack1,
	attack2,
	hurt,
	death
}

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var can_attack = true

const SPEED = 90.0         # Мышь обычно быстрее и проворнее гриба
const WAKE_RANGE = 300.0   # Дистанция, на которой мышь просыпается
const CHASE_RANGE = 350.0  # Дистанция, пока мышь преследует (если игрок убежит дальше, она отстанет)
const ATTACK_RANGE = 45.0  # Дистанция удара

var health = 60 # Здоровья поменьше, чем у гриба

@onready var anim = $AnimatedSprite2D
@onready var anim_player = $AnimationPlayer
@onready var hitbox = $DamageBox/HitBox 

var state = sleep # Мышь по умолчанию начинает на уровне в спящем состоянии
var player_pos = Vector2.ZERO

func _ready():
	Signals.connect("player_position_update", Callable(self, "_on_player_position_update"))
	hitbox.get_node("CollisionShape2D").set_deferred("disabled", true)
	anim_player.play("Sleep") # Запускаем анимацию сна сразу

func _on_player_position_update(pos):
	player_pos = pos

func _physics_process(delta):
	# Если мышь мертва, она падает на землю (включаем гравитацию только для трупа)
	#if state == death:
	#	if not is_on_floor():
	#		velocity.y += gravity * delta
	#	move_and_slide()
	#	return

	# Для остальных состояний гравитации нет, так как она летает!

	match state:
		sleep:
			sleep_state()
		wake_up:
			wake_up_state()
		idle_air:
			idle_air_state()
		run:
			run_state()
		attack1, attack2:
			attack_state()
		hurt:
			hurt_state()

	move_and_slide()

# --- СОСТОЯНИЯ ---

func sleep_state():
	velocity = Vector2.ZERO
	# Спит, пока игрок не подойдет достаточно близко
	var distance = global_position.distance_to(player_pos)
	if distance <= WAKE_RANGE:
		start_wake_up()

func wake_up_state():
	velocity = Vector2.ZERO
	# Висит на месте и проигрывает анимацию (см. триггеры)

func idle_air_state():
	anim_player.play("Idle_air") # Проверь точное название своей анимации в плеере!

	# Плавное замедление в воздухе
	velocity = velocity.move_toward(Vector2.ZERO, SPEED * 0.05) 

	var distance = global_position.distance_to(player_pos)
	if distance <= ATTACK_RANGE:
		start_attack()
	elif distance < CHASE_RANGE:
		state = run

func run_state():
	anim_player.play("Run")

	# ВАЖНО: Мышь летает, поэтому определяем направление по обеим осям (X и Y)
	var direction = global_position.direction_to(player_pos)
	velocity = direction * SPEED

	# Поворачиваем мышь в сторону игрока (по оси X)
	if direction.x < 0:
		anim.flip_h = false
		$DamageBox.scale.x = 1
	elif direction.x > 0:
		anim.flip_h = true
		$DamageBox.scale.x = -1

	# Проверяем, нужно ли бить или остановиться
	var distance = global_position.distance_to(player_pos)
	if distance <= ATTACK_RANGE:
		start_attack()
	elif distance > CHASE_RANGE:
		state = idle_air

func attack_state():
	velocity = Vector2.ZERO # Во время атаки мышь зависает в воздухе

func hurt_state():
	velocity = Vector2.ZERO # Во время получения урона замирает

# --- ТРИГГЕРЫ (Запуск анимаций и таймеров) ---

func start_wake_up():
	state = wake_up
	anim_player.play("WakeUp")
	await anim_player.animation_finished
	if state != death:
		state = run # Сразу после пробуждения летит атаковать

func start_attack():
	# Рандомно выбираем между двумя атаками (0 или 1)
	if randi() % 2 == 0:
		state = attack1
		anim_player.play("Attack1")
	else:
		state = attack2
		anim_player.play("Attack2")

	await anim_player.animation_finished

	# Небольшая пауза после укуса/удара
	await get_tree().create_timer(0.3).timeout 

	if state != death and state != hurt: 
		state = idle_air

func start_hurt():
	state = hurt
	anim_player.stop() 
	anim_player.play("Hurt")
	await anim_player.animation_finished
	if state != death:
		state = idle_air

func start_death():
	state = death
	anim_player.play("Death")
	# Отключаем коллизии, чтобы игрок не толкал мышь
	$CollisionShape2D.set_deferred("disabled", true)
	hitbox.get_node("CollisionShape2D").set_deferred("disabled", true)

func _on_hit_box_area_entered(area):
	if state == death or can_attack == false:
		return

	var target = area
	while target != null:
		if target.has_method("take_damage"):
			target.take_damage(10) # Урон от мыши
			return
		target = target.get_parent()
func take_damage(damage):
 # Защита: если мышь УЖЕ умирает, новые удары по ней не проходят
	if state == death:
		return

	health -= damage
	print("🦇 Ай! Летучая мышь получила урон! Осталось ХП: ", health)
 
	if health <= 0:
  # Переключаем состояние и играем анимацию смерти
		start_death() 
  
  # Ждем, пока проиграется анимация смерти
		await anim_player.animation_finished
		print("🦇 Летучая мышь умерла! Начинаем плавно исчезать...")
  
  # --- ТУТ НАЧИНАЕТСЯ ПЛАВНОЕ ИСЧЕЗНОВЕНИЕ ---
		var tween = create_tween()
  # Меняем прозрачность (modulate:a) до 0.0 за 1.5 секунды
		tween.tween_property(self, "modulate:a", 0.0, 1.5) 
  
		await tween.finished 
  # Теперь полностью удаляем:
		queue_free()
	else:
  # ЕСЛИ МЫШЬ ВЫЖИЛА: вызываем нашу функцию боли
		start_hurt()
