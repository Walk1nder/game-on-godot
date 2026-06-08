extends Node2D

@export var platform: Node2D

@onready var sprite: Sprite2D = $Sprite2D
@onready var anchor: Node2D = $Anchor

func _process(_delta):
	if platform == null:
		return

	var length = platform.global_position.y - anchor.global_position.y
	length = max(length, 0)

	sprite.scale.y = length / sprite.texture.get_height()

	sprite.global_position = anchor.global_position
