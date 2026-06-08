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
@export var hotbar_grid: Control 
@export var expanded_inventory: Control
@export var chest_ui: Control
@export var max_health: int = 100
@export var health_bar: TextureProgressBar
@onready var light = $PointLight2D

var active_chest: Area2D = null
var damage_amount = 10
var health: float = 100
var current_health: float = 50
var state = move
var run_speed = 1
var combo = false
var cooldown = false
var player_pos
var inventory: Array = []
var ui_slots: Array = []

func _ready():
	add_to_group("dynamic_lights")
	light.visible = false
	current_health = Global.player_health
 
	Signals.health_changed.emit(current_health)
 
	Signals.connect("enemy_attack", Callable(self, "_on_damage_received"))
 
	hitbox.get_node("CollisionShape2D").set_deferred("disabled", true)
	
	for i in range(24):
		inventory.append(null)

	if hotbar_grid and expanded_inventory:
		ui_slots.append_array(hotbar_grid.get_children())
		ui_slots.append_array(expanded_inventory.get_children())


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
	
	if not is_on_floor():
		velocity.y += gravity * delta
		
	move_and_slide()

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		state = jump
	
	player_pos = self.position
	Signals.player_position_update.emit(player_pos)
	
	for slot in inventory:
		if slot != null and slot["item"].passive_heal_per_sec > 0:
			heal(slot["item"].passive_heal_per_sec * delta)

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
	await get_tree().create_timer(1).timeout
	cooldown = false
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

	if state == death or state == hurt: 
		return

func take_hit():
	state = hurt
	anim_player.play("hurt")
	await anim_player.animation_finished
	
	if state != death: 
		state = move
func _on_hit_box_area_entered(area):
	var target = area
	while target != null:
		if target.has_method("take_damage"):
			target.take_damage(damage_amount)
			return
		target = target.get_parent()

func take_damage(damage):
	if state == death:
		return 
	current_health -= damage
	Global.player_health = current_health 
	Signals.health_changed.emit(current_health)

	if current_health <= 0:
		death_state()
	else:
		state = hurt
		anim_player.play("hurt")
		await anim_player.animation_finished
  
		if state != death: 
			state = move


func death_state():
	state = death
 
	set_physics_process(false) 
	velocity = Vector2.ZERO 
 
	anim_player.play("death")
 
	await anim_player.animation_finished
 

	get_tree().change_scene_to_file("res://scenes/menu.tscn")
	
func add_item_to_inventory(item: ItemData, amount: int = 1) -> bool:
	for i in range(inventory.size()):
		if inventory[i] != null and inventory[i]["item"] == item:
			if inventory[i]["amount"] < item.max_stack:
				inventory[i]["amount"] += amount
				update_ui_slot(i) 
				return true
	for i in range(inventory.size()):
		if inventory[i] == null:
			inventory[i] = {"item": item, "amount": amount} 
			update_ui_slot(i) 
			return true
	return false

func use_item(slot_index: int):
	if inventory[slot_index] == null:
		return
  
	var item_data = inventory[slot_index]["item"]
	if item_data.resource_path.find("health_potion") != -1:
		var was_healed = heal(20) 
		if was_healed: 
			consume_item(slot_index)

	elif item_data.resource_path.find("apple") != -1:
		var was_healed = heal(10) 
		if was_healed:
			consume_item(slot_index)


func consume_item(slot_index: int):
	inventory[slot_index]["amount"] -= 1
	if inventory[slot_index]["amount"] <= 0:
		inventory[slot_index] = null
  
	update_inventory_ui()

func heal(amount: float) -> bool:
	if current_health >= max_health:
		return false 

	current_health += amount

	if current_health > max_health:
		current_health = max_health

	if health_bar:
		health_bar.value = current_health

	Signals.health_changed.emit(current_health)

	Global.player_health = current_health

	return true 


func update_ui_slot(index: int):
	if ui_slots.size() > index:
		var slot_ui = ui_slots[index] 

		if inventory[index] != null:
			slot_ui.update_slot(inventory[index]["item"], inventory[index]["amount"])
		else:
			slot_ui.update_slot(null, 0)


func swap_items(drag_data: Dictionary, drop_data: Dictionary):
	var from_idx = drag_data["from_index"]
	var from_chest = drag_data["is_chest"]

	var to_idx = drop_data["to_index"]
	var to_chest = drop_data["is_chest"]

	if from_idx == to_idx and from_chest == to_chest:
		return

	var source_array = active_chest.inventory if from_chest else inventory
	var target_array = active_chest.inventory if to_chest else inventory

	var item_source = source_array[from_idx]
	var item_target = target_array[to_idx]

	source_array[from_idx] = item_target
	target_array[to_idx] = item_source

	update_inventory_ui() 

	if active_chest:
		active_chest.update_chest_ui()
	
func update_inventory_ui():
	for i in range(inventory.size()):
		update_ui_slot(i)
func turn_light_on():
	light.visible = true

func turn_light_off():
	light.visible = false
