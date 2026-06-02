extends Control

# Получаем ссылку на наш узел
@onready var health_bar = $HealthBar

func _ready():
 # 1. МГНОВЕННО ставим сохраненное ХП при загрузке локации.
 # Без анимации, чтобы не казалось, что мы получаем урон при входе.
 health_bar.value = Global.player_health

 # 2. Подключаемся к сигналу из глобального скрипта Signals
 Signals.health_changed.connect(_on_health_changed)

# Эта функция сработает, когда игрок получит урон в процессе игры
func _on_health_changed(new_health):
 # Создаем плавную анимацию (Tween) изменения полоски
 var tween = create_tween()
 # Меняем свойство "value" у health_bar до значения new_health за 0.3 секунды
 tween.tween_property(health_bar, "value", new_health, 0.3).set_trans(Tween.TRANS_SINE)
