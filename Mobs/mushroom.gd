extends CharacterBody2D

enum {
	idle,
	run,
	attack,
	hurt,
	stun,
	death
}

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var can_attack = true
const SPEED = 70.0 # Гриб медленнее игрока
const CHASE_RANGE = 275.0 # Дистанция, с которой гриб замечает игрока
const ATTACK_RANGE = 45.0 # Дистанция удара гриба
var health = 100

@onready var anim = $AnimatedSprite2D
@onready var anim_player = $AnimationPlayer
# @onready var hitbox = $AttackDirection/damagebox/HitBox # Раскомментируй и настрой путь, если у гриба есть хитбокс
@onready var hitbox = $DamageBox/HitBox # Проверь, чтобы путь был правильным



var state = idle
var player_pos = Vector2.ZERO

func _ready():
	# Подписываемся на сигнал игрока, чтобы гриб знал его координаты
	Signals.connect("player_position_update", Callable(self, "_on_player_position_update"))
	hitbox.get_node("CollisionShape2D").set_deferred("disabled", true)

func _on_player_position_update(pos):
	player_pos = pos

func _physics_process(delta):
	# Если гриб мертв, он больше ничего не делает
	if state == death:
		return

	if not is_on_floor():
		velocity.y += gravity * delta

	match state:
		idle:
			idle_state()
		run:
			run_state()
		attack:
			attack_state()
		hurt:
			hurt_state()
		stun:
			stun_state()

	move_and_slide()

# --- СОСТОЯНИЯ ---

func idle_state():
	anim_player.play("Idle")
	velocity.x = move_toward(velocity.x, 0, SPEED)
 
	var distance = global_position.distance_to(player_pos)
 # Добавили проверку на атаку из состояния покоя!
	if distance <= ATTACK_RANGE:
		start_attack()
	elif distance < CHASE_RANGE:
		state = run

func run_state():
	anim_player.play("Run")

	# Определяем направление к игроку (1 вправо, -1 влево)
	var direction = sign(player_pos.x - global_position.x)
	velocity.x = direction * SPEED

	# Поворачиваем гриб в сторону игрока
	if direction < 0:
		anim.flip_h = false
		$DamageBox.scale.x = 1
	elif direction > 0:
		anim.flip_h = true
		$DamageBox.scale.x = -1

	# Проверяем, нужно ли бить или остановиться
	var distance = global_position.distance_to(player_pos)
	if distance <= ATTACK_RANGE:
		start_attack()
	elif distance > CHASE_RANGE:
		state = idle

func attack_state():
	velocity.x = 0 # Во время атаки гриб стоит на месте

func hurt_state():
	velocity.x = 0 # Во время получения урона отбрасываем или останавливаем

func stun_state():
	velocity.x = 0 # В стане гриб замирает

# --- ТРИГГЕРЫ (Запуск анимаций и таймеров) ---

func start_attack():
	state = attack
	anim_player.play("Attack")
	await anim_player.animation_finished
	await get_tree().create_timer(1.0).timeout 
	# Проверяем, не убили ли/не застанили ли гриба, пока он замахивался
	if state != death and state != stun: 
		state = idle
func start_hurt():
	state = hurt
	anim_player.stop() 
	anim_player.play("Hurt")
	await anim_player.animation_finished
	if state != death and state != stun:
		state = idle

func start_stun():
	state = stun
	anim_player.play("Stun")
	# ТОТ САМЫЙ ТАЙМЕР НА 2 СЕКУНДЫ
	await get_tree().create_timer(2.0).timeout 
	if state != death:
		state = idle

func start_death():
	state = death
	anim_player.play("death")
	# Отключаем коллизию гриба, чтобы игрок не толкал труп
	$CollisionShape2D.set_deferred("disabled", true)


func _on_hit_box_area_entered(area):
	 # Если атака на кулдауне - ничего не делаем
	if state == stun or state == death:
		return

	var target = area
	while target != null:
		if target.has_method("take_damage"):
			target.take_damage(15) # Урон по игроку
			return
		target = target.get_parent()
	if can_attack == false:
		return

	while target != null:
		if target.has_method("take_damage"):
			target.take_damage(15)
   
   # Включаем кулдаун!
			can_attack = false 
			print("Гриб ушел на перезарядку!")
   
   # Ждем 1.5 секунды (можешь поменять число)
			await get_tree().create_timer(1.5).timeout 
   
   # Снова разрешаем бить
			can_attack = true 
			print("Гриб снова готов атаковать!")
			return
   
		target = target.get_parent()
		
func take_damage(damage):
 # Защита: если гриб УЖЕ умирает/исчезает, новые удары по нему не проходят
	if state == death:
		return

	health -= damage
	print("🍄 Ай! Гриб получил урон! Осталось ХП: ", health)
 
	if health <= 0:
		state = death # Переключаем в состояние смерти
		anim_player.play("Death") # Играем анимацию смерти
  
  # Ждем, пока проиграется анимация смерти:
		await anim_player.animation_finished
		print("🍄 Гриб умер! Начинаем плавно исчезать...")
  
  # --- ТУТ НАЧИНАЕТСЯ ПЛАВНОЕ ИСЧЕЗНОВЕНИЕ ---
		var tween = create_tween()
  # Меняем прозрачность (modulate:a) до 0.0 за 1.5 секунды
		tween.tween_property(self, "modulate:a", 0.0, 1.5) 
  
  # Ждем эти 1.5 секунды, пока гриб тает:
		await tween.finished 
  
  # Теперь полностью удаляем:
		queue_free() 
  
	else:
  # Если выжил — уходит в стан! 
  # (Анимацию урона лучше проигрывать внутри start_stun, чтобы они не путались)
		print("🍄 Гриб оглушен!")
		start_stun()
func _on_hurt_box_area_entered(area):
	print("💥 Что-то коснулось Гриба: ", area.name)
 
 # Получаем главного владельца этого меча (скрипт Игрока)
	var attacker = area.owner
 
 # Проверяем, существует ли attacker и есть ли у него переменная 'damage_amount'
	if attacker != null and "damage_amount" in attacker:
		print("✅ Нас ударил Игрок! Урон: ", attacker.damage_amount)
		take_damage(attacker.damage_amount)
		return # Выходим, всё сработало
  
 # Резервная проверка (если owner не сработал, но по имени это HitBox)
	elif "hitbox" in str(area.name).to_lower() or "damagebox" in str(area.name).to_lower():
		print("⚠️ Сработала резервная проверка по имени узла!")
		take_damage(10) # Дефолтный урон
