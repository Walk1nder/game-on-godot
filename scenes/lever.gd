extends Node2D

var player_in_range = false
var activated = false

func _ready():
	$Label.hide()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = true
		$Label.show()
		print("Кто-то вошёл:", body.name)


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = false
		$Label.hide()
		print("Кто-то вышел:", body.name)
		
func _process(delta):
	if activated:
		return
		
	if player_in_range and Input.is_action_just_pressed("interact"):
		activate_lever()
		
func activate_lever():
	activated = true
	self.monitoring = false
	$AnimatedSprite2D.play("default")
	$Label.hide()
	lever_activated.emit()
	
signal lever_activated
