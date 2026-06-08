extends CharacterBody2D

enum {
	IDLE,
	CHASE,
	DEATH 
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

var health: int = 120

func _ready():
	animPlayer.play("idle")
	Signals.player_position_update.connect(Callable(self, "_on_player_position_update"))
	

func _physics_process(_delta):
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

func fire_arrow():
	if arrow_scene and target_player:
		var arrow = arrow_scene.instantiate()
		arrow.global_position = shoot_point.global_position
		var direction_to_player = shoot_point.global_position.direction_to(target_player.global_position)
		arrow.direction = direction_to_player
		arrow.rotation = direction_to_player.angle() 
		get_tree().current_scene.add_child(arrow)

func _on_detection_area_body_entered(body):
	if body.is_in_group("player"): 
		player_in_range = true
		target_player = body
		state = CHASE

func _on_detection_area_body_exited(body):
	if body.is_in_group("player"):
		player_in_range = false
		target_player = null
		state = IDLE

func _on_animation_player_animation_finished(anim_name):
	if state == DEATH:
		return

	if anim_name == "attack":
		is_attacking = false
		cooldown_timer.start() 

		if not player_in_range:
			animPlayer.play("idle") 
	elif anim_name == "hurt":
		is_attacking = false 
		if player_in_range:
			animPlayer.play("idle") 
		else:
			animPlayer.play("idle")

func chase_state(): 
	if player:
		direction = (player - self.position).normalized()
		if direction.x < 0:
			sprite.flip_h = true
		else:
			sprite.flip_h = false


func take_damage(damage_amount):
	if state == DEATH:
		return
	health -= damage_amount
	if health <= 0:
		health = 0
		die()
	else:
		animPlayer.stop()
		animPlayer.play("hurt")
func die():
	state = DEATH
	set_physics_process(false) 
	cooldown_timer.stop() 
	is_attacking = false 
	
	animPlayer.play("death") 
	await animPlayer.animation_finished 
	
	queue_free() 


func _on_hurt_box_area_entered(area):
	var attacker = area.owner
	if attacker != null and "damage_amount" in attacker:
		take_damage(attacker.damage_amount)
	
