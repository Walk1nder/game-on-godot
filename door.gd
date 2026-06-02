extends StaticBody2D

func open():
	visible = false

func _on_lever_lever_activated():
	open()
	$CollisionShape2D.disabled = false
	$CollisionShape2D2.disabled = true
