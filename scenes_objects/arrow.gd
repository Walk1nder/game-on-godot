extends Area2D

@export var speed: float = 400.0 
@export var damage: int = 20   
var direction: Vector2 = Vector2.RIGHT 


func _physics_process(delta):
	position += direction * speed * delta

func _on_body_entered(body):
	if body.has_method("take_damage"):
		body.take_damage(damage)
		queue_free() 
	elif body is TileMap: 
		queue_free()

func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free()

func _on_hit_box_area_entered(area: Area2D) -> void:
	Signals.emit_signal("enemy_attack", damage)
