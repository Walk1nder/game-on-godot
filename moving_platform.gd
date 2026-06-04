@tool
extends AnimatableBody2D

@export var move_distance_x := 300.0
@export var move_distance_y := 0.0
@export var speed := 100.0
@export var wait_time := 1.0
@export var direction := 1.0

@export var platform_width := 96.0:
	set(value):
		platform_width = value
		update_platform()	
		
@export var platform_height := 16.0:
	set(value):
		platform_height = value
		update_platform()

var start_pos: Vector2
var end_pos: Vector2
var target: Vector2
var waiting := false

func update_platform():
	if not is_inside_tree():
		return	
		
	var sprite = $Sprite2D
	
	if sprite.texture:
		sprite.scale.x = platform_width / sprite.texture.get_width()
		sprite.scale.y = platform_height / sprite.texture.get_height()
		
	var shape = $CollisionShape2D.shape as RectangleShape2D
	shape.size = Vector2(platform_width, platform_height)

func _ready():
	
	if Engine.is_editor_hint():
		return	
		
	var sprite = $Sprite2D
	sprite.scale.x = platform_width / sprite.texture.get_width()
	sprite.scale.y = platform_height / sprite.texture.get_height()

	var shape = $CollisionShape2D.shape as RectangleShape2D
	shape.size = Vector2(platform_width, platform_height)
	
	start_pos = global_position
	if direction == 1:
		end_pos = start_pos + Vector2(move_distance_x, move_distance_y)
	else:
		end_pos = start_pos - Vector2(move_distance_x, move_distance_y)
	target = end_pos
	$Timer.wait_time = wait_time
	
func _physics_process(delta):
	if Engine.is_editor_hint():
		return	
	
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
