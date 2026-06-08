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
const SPEED = 70.0 
const CHASE_RANGE = 275.0 
const ATTACK_RANGE = 45.0 
var health = 100

@onready var anim = $AnimatedSprite2D
@onready var anim_player = $AnimationPlayer
@onready var hitbox = $DamageBox/HitBox 



var state = idle
var player_pos = Vector2.ZERO

func _ready():
	Signals.connect("player_position_update", Callable(self, "_on_player_position_update"))
	hitbox.get_node("CollisionShape2D").set_deferred("disabled", true)

func _on_player_position_update(pos):
	player_pos = pos

func _physics_process(delta):
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

func idle_state():
	anim_player.play("Idle")
	velocity.x = move_toward(velocity.x, 0, SPEED)
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
		anim.flip_h = false
		$DamageBox.scale.x = 1
	elif direction > 0:
		anim.flip_h = true
		$DamageBox.scale.x = -1

	var distance = global_position.distance_to(player_pos)
	if distance <= ATTACK_RANGE:
		start_attack()
	elif distance > CHASE_RANGE:
		state = idle

func attack_state():
	velocity.x = 0 

func hurt_state():
	velocity.x = 0 

func stun_state():
	velocity.x = 0 

func start_attack():
	state = attack
	anim_player.play("Attack")
	await anim_player.animation_finished
	await get_tree().create_timer(1.0).timeout 
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
	await get_tree().create_timer(2.0).timeout 
	if state != death:
		state = idle

func start_death():
	state = death
	anim_player.play("death")
	$CollisionShape2D.set_deferred("disabled", true)


func _on_hit_box_area_entered(area):

	if state == stun or state == death:
		return

	var target = area
	while target != null:
		if target.has_method("take_damage"):
			target.take_damage(15) 
			return
		target = target.get_parent()
	if can_attack == false:
		return

	while target != null:
		if target.has_method("take_damage"):
			target.take_damage(15)
			can_attack = false 
			
			await get_tree().create_timer(1.5).timeout 
			can_attack = true 
			return
		target = target.get_parent()
		
func take_damage(damage):
	if state == death:
		return

	health -= damage
 
	if health <= 0:
		state = death 
		anim_player.play("Death") 
		await anim_player.animation_finished
		var tween = create_tween()
		tween.tween_property(self, "modulate:a", 0.0, 1.5) 
  
		await tween.finished 
  
		queue_free() 
  
	else:
		start_stun()
func _on_hurt_box_area_entered(area):
 
	var attacker = area.owner
 
	if attacker != null and "damage_amount" in attacker:
		take_damage(attacker.damage_amount)
		return 
  
	elif "hitbox" in str(area.name).to_lower() or "damagebox" in str(area.name).to_lower():
		take_damage(10)
