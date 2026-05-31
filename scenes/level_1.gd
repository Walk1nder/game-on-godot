extends Node2D

func _ready():

	$player/Camera2D.limit_left = 0
	$player/Camera2D.limit_top = 200
	$player/Camera2D.limit_right = 7850
	$player/Camera2D.limit_bottom = 700
