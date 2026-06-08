extends CanvasModulate

@export var day_color: Color = Color.WHITE
@export var night_color: Color = Color(0.15, 0.15, 0.25)
@export var day_length: float = 10.0 
@export var transition_time: float = 3.0 

var is_day = true
var timer: Timer

func _ready():
 self.color = day_color
 # При старте ставим фону дневной цвет
 get_tree().call_group("ParallaxBackground", "set_modulate", day_color)
 
 timer = Timer.new()
 timer.wait_time = day_length
 timer.one_shot = false
 timer.timeout.connect(_on_timer_timeout)
 add_child(timer)
 timer.start()

func _on_timer_timeout():
 is_day = !is_day
 var target_color = day_color if is_day else night_color
 
 var tween = create_tween()
 tween.set_parallel(true)
 
 # Затемняем основную сцену
 tween.tween_property(self, "color", target_color, transition_time)
 
 # Затемняем ВСЕ ноды в группе "background" (наш параллакс фон)
 var bgs = get_tree().get_nodes_in_group("ParallaxBackground")
 for bg in bgs:
  # У ParallaxBackground нет своего цвета, но мы затеняем его дочерние элементы
  tween.tween_property(bg, "modulate", target_color, transition_time)
 
 # Включаем/выключаем свет на игроке и мобах
 if is_day:
  get_tree().call_group("dynamic_lights", "turn_light_off")
 else:
  get_tree().call_group("dynamic_lights", "turn_light_on")
