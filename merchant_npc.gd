extends Node2D

var player_inside := false

func _ready():
	$AnimatedSprite2D.play("idle")

func _process(delta):
	if player_inside and Input.is_action_just_pressed("interact"):
		$"../player".open_dialog()
		$"../Interface/DialogUI/Label".text = "Я — гранит, что научился говорить. Стоял веками, пока трещины не стали словами. Я не помню, кто меня вырезал… но помню, как мир менялся вокруг. Теперь я торгую тем, что пережило время. 
	И иногда — тем, что ему не должно было пережить"

func _on_area_2d_body_entered(body: Node2D) -> void:
		if body.is_in_group("player"):
			player_inside = true
			$Label.show()


func _on_area_2d_body_exited(body: Node2D) -> void:
		if body.is_in_group("player"):
			player_inside = false
			$Label.hide()	
