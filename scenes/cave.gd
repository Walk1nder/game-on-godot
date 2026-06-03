extends Node2D

func _ready():
	$player/Camera2D.limit_left = 0
	$player/Camera2D.limit_top = -1000
	$player/Camera2D.limit_right = 8000
	$player/Camera2D.limit_bottom = 5000
