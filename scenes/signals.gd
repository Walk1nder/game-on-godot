# signals.gd (предполагаемый скрипт для твоего AutoLoad "Signals")
extends Node

# Объявляем сигнал player_position_update
# Указываем, что он будет передавать один аргумент типа Vector2
signal player_position_update(position: Vector2)

# Здесь могут быть другие глобальные сигналы
# signal another_signal()
signal enemy_attack (enemy_damage)

signal health_changed(new_health)
var player_health: int = 100
var player_max_health: int = 100
