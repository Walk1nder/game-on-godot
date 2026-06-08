extends CharacterBody2D

enum {
	sleep,
	wake_up,
	idle_air,
	run,     
	attack1,
	attack2,
	hurt,
	death
}

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var can_attack = true

const SPEED = 90.0       
const WAKE_RANGE = 300.0   
const CHASE_RANGE = 350.0 
const ATTACK_RANGE = 45.0 

var health = 60 

@onready var anim = $AnimatedSprite2D
@onready var anim_player = $AnimationPlayer
@onready var hitbox = $DamageBox/HitBox 

var state = sleep 
var player_pos = Vector2.ZERO

func _ready():
	Signals.connect("player_position_update", Callable(self, "_on_player_position_update"))
	hitbox.get_node("CollisionShape2D").set_deferred("disabled", true)
	anim_player.play("Sleep") 

func _on_player_position_update(pos):
	player_pos = pos

func _physics_process(delta):
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


func sleep_state():
	velocity = Vector2.ZERO
	var distance = global_position.distance_to(player_pos)
	if distance <= WAKE_RANGE:
		start_wake_up()

func wake_up_state():
	velocity = Vector2.ZERO

func idle_air_state():
	anim_player.play("Idle_air") 

	velocity = velocity.move_toward(Vector2.ZERO, SPEED * 0.05) 

	var distance = global_position.distance_to(player_pos)
	if distance <= ATTACK_RANGE:
		start_attack()
	elif distance < CHASE_RANGE:
		state = run

func run_state():
	anim_player.play("Run")

	var direction = global_position.direction_to(player_pos)
	velocity = direction * SPEED

	if direction.x < 0:
		anim.flip_h = false
		$DamageBox.scale.x = 1
	elif direction.x > 0:
		anim.flip_h = true
		$DamageBox.scale.x = -1

	var distance = global_position.distance_to(player_pos)
	if distance <= ATTACK_RANGE:
		start_attack()
	elif distance > CHASE_RANGE:
		state = idle_air

func attack_state():
	velocity = Vector2.ZERO 

func hurt_state():
	velocity = Vector2.ZERO 


func start_wake_up():
	state = wake_up
	anim_player.play("WakeUp")
	await anim_player.animation_finished
	if state != death:
		state = run 

func start_attack():
	if randi() % 2 == 0:
		state = attack1
		anim_player.play("Attack1")
	else:
		state = attack2
		anim_player.play("Attack2")

	await anim_player.animation_finished
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
	$CollisionShape2D.set_deferred("disabled", true)
	hitbox.get_node("CollisionShape2D").set_deferred("disabled", true)

func _on_hit_box_area_entered(area):
	if state == death or can_attack == false:
		return

	var target = area
	while target != null:
		if target.has_method("take_damage"):
			target.take_damage(10) 
			return
		target = target.get_parent()
func take_damage(damage):
	if state == death:
		return

	health -= damage
 
	if health <= 0:
		start_death() 
  
		await anim_player.animation_finished
  
		var tween = create_tween()
		tween.tween_property(self, "modulate:a", 0.0, 1.5) 
  
		await tween.finished 
		queue_free()
	else:
		start_hurt()
