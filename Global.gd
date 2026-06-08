extends Node

var player_health: int = 100
var player_max_health: int = 100
func _input(event):
 if event.is_action_pressed("toggle_fullscreen"):
  if get_window().mode == Window.MODE_WINDOWED:
   get_window().mode = Window.MODE_FULLSCREEN
  else:
   # Возвращаем в окно
   get_window().mode = Window.MODE_WINDOWED
