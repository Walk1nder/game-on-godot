extends Control


@onready var dialog_sentence = false

func _on_btn_shop_pressed():
	$TextureRect.visible = true

func _on_btn_dialog_pressed():
	dialog_sentence = true
	$Label.show()
	$DialogWindow/VBoxContainer.hide()

func _on_btn_back_pressed():
	var player = get_tree().get_first_node_in_group("player")
	player.close_dialog()
	hide()


func _on_gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if dialog_sentence:
				$Label.hide()
				$DialogWindow/VBoxContainer.show()
				
			
			
