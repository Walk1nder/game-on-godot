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
	print("🚀🚀🚀 СКРИПТ ИГРОКА ЖИВ И РАБОТАЕТ! 🚀🚀🚀")
	add_to_group("dynamic_lights")
	light.visible = false
 # 1. СНАЧАЛА забираем сохраненное здоровье с прошлой локации
	current_health = Global.player_health
 
 # 2. ТОЛЬКО ПОТОМ отправляем сигнал, чтобы хелсбар обновился до нужного значения
	Signals.health_changed.emit(current_health)
 
 # 3. Подключаем сигнал атаки врага
	Signals.connect("enemy_attack", Callable(self, "_on_damage_received"))
 
 # 4. Отключаем хитбокс (чтобы не получать случайный урон в начале)
	hitbox.get_node("CollisionShape2D").set_deferred("disabled", true)
	
# При старте заполняем массив инвентаря 24-мя пустотами (null)
	for i in range(24):
		inventory.append(null)

	# Собираем все визуальные ячейки в один единый список, чтобы с ними было удобно работать
	if hotbar_grid and expanded_inventory:
		ui_slots.append_array(hotbar_grid.get_children())
		ui_slots.append_array(expanded_inventory.get_children())
	else:
		print("ОШИБКА: Ты забыл привязать hotbar_grid или expanded_inventory в Инспекторе!")


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
	
	# Проверяем все предметы в инвентаре на наличие пассивного лечения
	for slot in inventory:
		if slot != null and slot["item"].passive_heal_per_sec > 0:
			# delta - это время между кадрами. Умножение на delta делает лечение плавным
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

	# Если мы уже мертвы или уже проигрываем анимацию урона - игнорируем новые удары
	if state == death or state == hurt: 
		return

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
	print("⚔️ Меч игрока коснулся зоны: ", area.name)
	var target = area
 
 # Идем вверх по ветке гриба, пока не найдем главный скрипт с take_damage
	while target != null:
		if target.has_method("take_damage"):
			print("✅ Нашли take_damage у: ", target.name, "! Бьем!")
			target.take_damage(damage_amount) # Твоя переменная урона
			return
		target = target.get_parent()

func take_damage(damage):
	print("--- НАЧАЛО TAKE_DAMAGE ---")
	print("Текущее состояние (state) перед уроном: ", state)

 # 1. Защита: если игрок уже мертв, игнорируем дальнейший урон
	if state == death:
		return 

 # 2. Отнимаем ХП (используем твою переменную current_health)
	current_health -= damage
	print("Получен урон! Текущее ХП: ", current_health) 

 # 3. Сохраняем новое ХП в склад (чтобы перенести на другую локацию)
	Global.player_health = current_health 
 
 # 4. Кричим на всю игру: "ХП изменилось!" (чтобы хелсбар обновился)
	Signals.health_changed.emit(current_health)

 # 5. Проверяем состояние: умер или просто ранен?
	if current_health <= 0:
		death_state()
	else:
		state = hurt
		anim_player.play("hurt")
		await anim_player.animation_finished
  
  # Если пока проигрывалась анимация боли игрок не умер, возвращаем ему движение
		if state != death: 
			state = move


func death_state():
	state = death
 
 # Отключаем физику (твой отличный кусок кода)
	set_physics_process(false) 
	velocity = Vector2.ZERO 
 
 # Проигрываем смерть через AnimationPlayer
	anim_player.play("death")
 
 # Ждем окончания
	await anim_player.animation_finished
 
 # Переходим в меню
	get_tree().change_scene_to_file("res://scenes/menu.tscn")
	
# Функция добавления предмета в инвентарь
func add_item_to_inventory(item: ItemData, amount: int = 1) -> bool:
	# 1. Сначала ищем, есть ли такой предмет, чтобы добавить количество
	for i in range(inventory.size()):
		if inventory[i] != null and inventory[i]["item"] == item:
			if inventory[i]["amount"] < item.max_stack:
				inventory[i]["amount"] += amount
				update_ui_slot(i) # Обновляем картинку в интерфейсе
				return true
	# 2. Если нет, ищем первую пустую ячейку
	for i in range(inventory.size()):
		if inventory[i] == null:
			# Кладем в ячейку словарь: сам предмет и его количество
			inventory[i] = {"item": item, "amount": amount} 
			update_ui_slot(i) # Обновляем картинку в интерфейсе
			return true
	print("Инвентарь полон!")
	return false

# Функция использования предмета из инвентаря
func use_item(slot_index: int):
 # Проверяем, есть ли что-то в этом слоте
	if inventory[slot_index] == null:
		return
  
	var item_data = inventory[slot_index]["item"]
	if item_data.resource_path.find("health_potion") != -1:
		var was_healed = heal(20) # Пытаемся вылечиться на 20 ХП
		if was_healed: # Тратим зелье ТОЛЬКО если вылечились
			consume_item(slot_index)

 # Проверка: если это яблоко
	elif item_data.resource_path.find("apple") != -1:
		var was_healed = heal(10) # Пытаемся вылечиться на 10 ХП
		if was_healed:
			consume_item(slot_index)
  
	else:
		print("Этот предмет нельзя использовать!")

# Функция уменьшения количества предметов после использования
func consume_item(slot_index: int):
	inventory[slot_index]["amount"] -= 1
 
 # Если предметы закончились (стало 0), полностью очищаем ячейку
	if inventory[slot_index]["amount"] <= 0:
		inventory[slot_index] = null
  
 # Обновляем интерфейс
	update_inventory_ui()

# Функция лечения
func heal(amount: float) -> bool:
	# Используем твою переменную max_health
	if current_health >= max_health:
		print("Здоровье и так полное! Предмет не потрачен.")
		return false # Возвращаем false (здоровье не прибавилось)

	current_health += amount

	# Не даем ХП стать больше максимума
	if current_health > max_health:
		current_health = max_health

	# 1. Обновляем полоску здоровья (HealthBar) напрямую
	if health_bar:
		health_bar.value = current_health

	# 2. Обновляем через сигнал (так как у тебя это работает в _ready)
	Signals.health_changed.emit(current_health)

	# 3. Сохраняем в Global, чтобы ХП не сбросилось при смене сцены
	Global.player_health = current_health

	print("Игрок вылечился! Текущее ХП: ", current_health)
	return true # Возвращаем true (предмет успешно использован)


# Функция для обновления одной конкретной ячейки
func update_ui_slot(index: int):
	if ui_slots.size() > index:
		var slot_ui = ui_slots[index] # Берем нужную ячейку

		if inventory[index] != null:
			slot_ui.update_slot(inventory[index]["item"], inventory[index]["amount"])
		else:
			slot_ui.update_slot(null, 0)


func swap_items(drag_data: Dictionary, drop_data: Dictionary):
	var from_idx = drag_data["from_index"]
	var from_chest = drag_data["is_chest"]

	var to_idx = drop_data["to_index"]
	var to_chest = drop_data["is_chest"]

	# Если мы бросили предмет в ту же самую ячейку - ничего не делаем
	if from_idx == to_idx and from_chest == to_chest:
		return

	# Получаем ссылки на массивы, с которыми будем работать
	var source_array = active_chest.inventory if from_chest else inventory
	var target_array = active_chest.inventory if to_chest else inventory

	# Берем предметы из массивов
	var item_source = source_array[from_idx]
	var item_target = target_array[to_idx]

	# Меняем их местами в массивах!
	source_array[from_idx] = item_target
	target_array[to_idx] = item_source

	# ОБНОВЛЯЕМ ИНТЕРФЕЙСЫ
	# Обновляем инвентарь игрока
	update_inventory_ui() 

	# Если открыт сундук, обновляем и его интерфейс
	if active_chest:
		active_chest.update_chest_ui()
	
func update_inventory_ui():
	for i in range(inventory.size()):
		update_ui_slot(i)
func turn_light_on():
	light.visible = true

func turn_light_off():
	light.visible = false
# 2. Функция для теста по кнопке
#func _input(event):
#		take_damage(15) # Вот теперь движок найдет эту команду!
