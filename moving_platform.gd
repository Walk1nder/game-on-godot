extends AnimatableBody2D

@export var move_distance := 300.0
@export var speed := 100.0
@export var wait_time := 1.0


var start_pos: Vector2
var end_pos: Vector2
var target: Vector2
var waiting := false

func _ready():
	start_pos = global_position
	end_pos = start_pos + Vector2(move_distance, 0)
	target = end_pos
	$Timer.wait_time = wait_time
	
func _physics_process(delta):
	if waiting:
		return

	global_position = global_position.move_toward(target, speed * delta)

	if global_position.distance_to(target) < 1:
		waiting = true
		$Timer.start()

func _on_timer_timeout():
	waiting = false

	if target == end_pos:
		target = start_pos
	else:
		target = end_pos
