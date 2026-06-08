extends CharacterBody2D

enum {
	idle,
	run,
	attack1,
	attack2,
	hurt,
	death
}

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

const SPEED = 110.0         
const CHASE_RANGE = 350.0  
const ATTACK_RANGE = 50.0   

var health = 150 

@onready var anim = $AnimatedSprite2D
@onready var anim_player = $AnimationPlayer
@onready var hitbox = $DamageBox/HitBox 

var state = idle 
var player_pos = Vector2.ZERO
var can_attack = true 

func _ready():
	Signals.connect("player_position_update", Callable(self, "_on_player_position_update"))
	hitbox.get_node("CollisionShape2D").set_deferred("disabled", true)
	anim_player.play("Idle")

func _on_player_position_update(pos):
	player_pos = pos

func _physics_process(delta):
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
			velocity.x = 0 

	move_and_slide()


func idle_state():
	velocity.x = move_toward(velocity.x, 0, SPEED) 
	anim_player.play("Idle")

	var distance = global_position.distance_to(player_pos)
	if distance <= ATTACK_RANGE:
		start_attack()
	elif distance < CHASE_RANGE:
		state = run

func run_state():
	anim_player.play("Run")

	var direction = sign(player_pos.x - global_position.x)
	velocity.x = direction * SPEED

	if direction < 0: 
		anim.flip_h = true 
		$DamageBox.scale.x = -1
	elif direction > 0: 
		anim.flip_h = false
		$DamageBox.scale.x = 1 

	var distance = global_position.distance_to(player_pos)
	if distance <= ATTACK_RANGE:
		start_attack()
	elif distance > CHASE_RANGE:
		state = idle

func attack_state():
	velocity.x = move_toward(velocity.x, 0, SPEED) 

func hurt_state():
	velocity.x = move_toward(velocity.x, 0, SPEED)


func start_attack():
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

	
func _on_hit_box_area_entered(area):
	if state == death or can_attack == false:
		return

	var target = area
	while target != null:
		if target.has_method("take_damage"):
			target.take_damage(10) 
			return
		target = target.get_parent()
