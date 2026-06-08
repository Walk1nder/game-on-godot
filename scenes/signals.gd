extends Node

signal player_position_update(position: Vector2)

signal enemy_attack (enemy_damage)

signal health_changed(new_health)
var player_health: int = 100
var player_max_health: int = 100
