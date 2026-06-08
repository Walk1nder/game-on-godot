@tool
extends TextureButton

@export var slot_index: int = 0 
@export var is_chest_slot: bool = false

@onready var icon_rect: TextureRect = $ItemIcon
@onready var hotkey_label: Label = $HotkeyLabel
@onready var amount_label: Label = $AmountLabel

@export var custom_background: Texture2D:
	set(value):
		custom_background = value
		if has_node("SlotBackground"):
			$SlotBackground.texture = value

var current_item: ItemData = null
var current_amount: int = 0

func _ready():
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


func _get_drag_data(at_position):
	if current_item == null:
		return null 

	var preview_texture = TextureRect.new()
	preview_texture.texture = current_item.icon
	preview_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview_texture.custom_minimum_size = Vector2(40, 40) 

	var preview = Control.new()
	preview.add_child(preview_texture)
	preview_texture.position = -preview_texture.custom_minimum_size / 2 

	set_drag_preview(preview)

	var drag_data = {
		"from_index": slot_index,
		"is_chest": is_chest_slot
	}
	return drag_data

func _can_drop_data(at_position, data):
	return typeof(data) == TYPE_DICTIONARY and data.has("from_index")

func _drop_data(at_position, data):
	var player = get_tree().get_first_node_in_group("player")
	if player:
		var drop_data = {
			"to_index": slot_index,
			"is_chest": is_chest_slot
		}
		player.swap_items(data, drop_data)

func _gui_input(event):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_RIGHT: 
			var player = get_tree().get_first_node_in_group("player")
			if player and not is_chest_slot:
				player.use_item(slot_index)
