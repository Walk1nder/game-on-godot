@tool
extends TextureButton

@export var slot_index: int = 0 
@export var is_chest_slot: bool = false

@onready var icon_rect: TextureRect = $ItemIcon
@onready var hotkey_label: Label = $HotkeyLabel
@onready var amount_label: Label = $AmountLabel

# Обрати внимание на двоеточие в конце этой строки!
@export var custom_background: Texture2D:
	set(value):
		custom_background = value
  # Мгновенно обновляем картинку прямо в редакторе!
		if has_node("SlotBackground"):
			$SlotBackground.texture = value

# ДОБАВИЛИ: Теперь ячейка запоминает, что в ней лежит
var current_item: ItemData = null
var current_amount: int = 0

func _ready():
 # На всякий случай обновляем фон при старте игры
	if custom_background != null and has_node("SlotBackground"):
		$SlotBackground.texture = custom_background
	
	if not is_chest_slot and slot_index <= 5:
		hotkey_label.text = str(slot_index + 1)
		hotkey_label.show()
	else:
		hotkey_label.hide()

func update_slot(item_data, amount: int):
	current_item = item_data
	current_amount = amount

	if item_data != null:
		icon_rect.texture = item_data.icon
		icon_rect.show()
		if amount > 1:
			amount_label.text = str(amount)
			amount_label.show()
		else:
			amount_label.hide()
	else:
		icon_rect.texture = null
		icon_rect.hide()
		amount_label.hide()

# --- СИСТЕМА DRAG & DROP (ПЕРЕТАСКИВАНИЕ) ---

# 1. Захват предмета (срабатывает, когда зажимаешь левую кнопку мыши)
func _get_drag_data(at_position):
	if current_item == null:
		return null # Если ячейка пуста, перетаскивать нечего

	# Создаем "призрачную" картинку предмета, которая будет летать за мышкой
	var preview_texture = TextureRect.new()
	preview_texture.texture = current_item.icon
	preview_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview_texture.custom_minimum_size = Vector2(40, 40) # Размер картинки под курсором

	var preview = Control.new()
	preview.add_child(preview_texture)
	# Центрируем картинку по курсору
	preview_texture.position = -preview_texture.custom_minimum_size / 2 

	set_drag_preview(preview)

	# Упаковываем данные о том, ОТКУДА мы тащим предмет
	var drag_data = {
		"from_index": slot_index,
		"is_chest": is_chest_slot
	}
	return drag_data

# 2. Проверка: можно ли бросить сюда? (срабатывает, когда мышь нависает над этой ячейкой)
func _can_drop_data(at_position, data):
	# Разрешаем бросать, только если данные пришли из другой ячейки
	return typeof(data) == TYPE_DICTIONARY and data.has("from_index")

# 3. Бросок предмета (срабатывает, когда отпускаешь левую кнопку мыши)
func _drop_data(at_position, data):
	var player = get_tree().get_first_node_in_group("player")
	if player:
		# Упаковываем данные о том, КУДА бросили предмет
		var drop_data = {
			"to_index": slot_index,
			"is_chest": is_chest_slot
		}
		# Говорим игроку поменять предметы местами
		player.swap_items(data, drop_data)

# --- ИСПОЛЬЗОВАНИЕ ПРЕДМЕТА НА ПРАВЫЙ КЛИК ---
func _gui_input(event):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_RIGHT: # Правая кнопка мыши
			var player = get_tree().get_first_node_in_group("player")
			if player and not is_chest_slot:
				player.use_item(slot_index)
