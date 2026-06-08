extends Control

@onready var health_bar = $HealthBar

func _ready():
 health_bar.value = Global.player_health

 Signals.health_changed.connect(_on_health_changed)

func _on_health_changed(new_health):
 var tween = create_tween()
 tween.tween_property(health_bar, "value", new_health, 0.3).set_trans(Tween.TRANS_SINE)
