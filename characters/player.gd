extends CharacterBody2D

enum{
	move,
	idle,
	attack_1,
	attack_2,
	attack_3,
	block,
	death,
	hurt,
	jump
}
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
const SPEED = 120.0
const JUMP_VELOCITY = -400.0

@onready var anim = $AnimatedSprite2D
@onready var anim_player = $AnimationPlayer
@onready var hitbox = $AttackDirection/damagebox/HitBox


var damage_amount = 20
var health = 100
var current_health = 100
var state = move
var run_speed = 1
var combo = false
var cooldown = false
var player_pos


func _ready():
	Signals.health_changed.emit(current_health)
	Signals.connect("enemy_attack", Callable (self, "_on_damage_received"))
	hitbox.get_node("CollisionShape2D").set_deferred("disabled", true)

func _physics_process(delta):
	match state:
		move:
			move_state()
		attack_1:
			attack1_state()
		attack_2:
			attack2_state()
		attack_3:
			attack3_state()			
		block:
			block_state()
		hurt:
			hurt_state()
		jump:
			jump_state()			
	# Add the gravity.
	
	if not is_on_floor():
		velocity.y += gravity * delta
		
	move_and_slide()

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		state = jump
	
	player_pos = self.position
	Signals.player_position_update.emit(player_pos)

func move_state():
		var direction = Input.get_axis("left", "right")
		if direction:
			velocity.x = direction * SPEED * run_speed
			if velocity.y == 0:
				if run_speed == 1:
					anim_player.play("walk")
				else:
					anim_player.play("run")
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)				
			if velocity.y == 0:
				anim_player.play("idle")
		if direction == -1:
			anim.flip_h = true
			hitbox.position.x = -abs(hitbox.position.x)
		elif direction == 1:
			anim.flip_h = false
			hitbox.position.x = abs(hitbox.position.x)
			
		if Input.is_action_pressed("run"):
			run_speed = 2
		else:
			run_speed = 1
		if Input.is_action_pressed("block"):
			if velocity.x == 0:
				state = block
		if Input.is_action_just_pressed("attack") and not cooldown:
			state = attack_1	
func block_state():
	velocity.x = 0
	anim_player.play("block")
	if Input.is_action_just_released("block"):
		state = move
func attack1_state():
	if Input.is_action_just_pressed("attack") and combo:
		state = attack_2
	velocity.x = 0
	anim_player.play("attack_1")
	await anim_player.animation_finished
	attack_freeze()
	state = move			
func attack2_state():
	if Input.is_action_just_pressed("attack") and combo:
		state = attack_3 
	anim_player.play("attack_2")
	await anim_player.animation_finished
	state = move
func attack3_state():
	anim_player.play("attack_3")
	await anim_player.animation_finished
	state = move 
func combo1():
	combo = true
	await anim_player.animation_finished
	combo = false
func combo1_state():
	if Input.is_action_just_pressed("attack") and combo:
		state = combo2
	anim.play("attack_2")
	await anim_player.animation_finished
	state = move	
func combo2():
	combo = true
	await anim_player.animation_finished
	combo = false
func combo2_state():
	if $AnimatedSprite2D.flip_h:
		velocity.x = -30
	else:
		velocity.x = 30
	anim.play("attack_3")
	await anim_player.animation_finished
	state = move	
func attack_freeze():
	cooldown = true
	await get_tree().create_timer(0.5).timeout
	cooldown = false
func death_state():
	velocity.x = 0
	if anim_player.current_animation != "death":
		anim.play("death")
		await anim_player.animation_finished
		get_tree().change_scene_to_file("res://scenes/menu.tscn")
func hurt_state():
	velocity.x = 0
func jump_state():
	if velocity.y < 0:
		if anim_player.current_animation != "jump":
			anim_player.play("jump")

	elif velocity.y > 0:
		if anim_player.current_animation != "fall":
			anim_player.play("fall")

	if is_on_floor():
		state = move
func _on_damage_received(enemy_damage):
	# Если мы уже мертвы или уже проигрываем анимацию урона - игнорируем новые удары
	if state == death or state == hurt: 
		return

	health -= enemy_damage
	print(health)

	if health <= 0:
		health = 0
		die() # Вызываем смерть ОДИН РАЗ
	else:
		take_hit() # Вызываем реакцию на урон ОДИН РАЗ
# Функция смерти (запускается один раз)
func die():
	state = death
	# ОТКЛЮЧАЕМ физику! Персонаж замирает, _physics_process больше не выполняется
	set_physics_process(false) 
	velocity = Vector2.ZERO # Полностью останавливаем

	anim_player.play("death")
	await anim_player.animation_finished
	
	get_tree().change_scene_to_file("res://scenes/menu.tscn")
# Функция получения урона (запускается один раз)
func take_hit():
	state = hurt
	anim_player.play("hurt")
	await anim_player.animation_finished
	
	# После того как анимация проигралась до конца, возвращаемся в движение
	# Проверяем, не убили ли нас, пока проигрывалась анимация
	if state != death: 
		state = move
func _on_hit_box_area_entered(area):
	# Проверяем, есть ли у области, в которую мы попали, принадлежность к врагу
	# Например, если у хартбокса врага есть метод take_damage
	if area.has_method("take_damage"):
		area.take_damage(damage_amount)
		

func take_damage(amount):
	current_health -= amount
 
	if current_health < 0:
		current_health = 0
  
 # Отправляем сигнал
	Signals.health_changed.emit(current_health)

# 2. Функция для теста по кнопке
#func _input(event):
#		take_damage(15) # Вот теперь движок найдет эту команду!
