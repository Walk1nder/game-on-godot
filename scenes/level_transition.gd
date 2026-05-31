extends Area2D

@export var next_scene_path: String = ""

func _on_body_entered(body):
	# Дополнительная проверка, что в зону вошел именно игрок
	if body.name == "player": # Убедись, что твой узел персонажа называется именно "Player"
		TransitionScreen.transition_to(next_scene_path)
