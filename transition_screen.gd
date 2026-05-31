extends CanvasLayer


@onready var anim_player = $AnimationPlayer

# Эта функция будет вызываться из любого места игры
func transition_to(target_scene_path: String):
 # 1. Запускаем анимацию затемнения
 anim_player.play("fade_to_black")
 
 # Ждем окончания анимации (пока экран полностью не почернеет)
 await anim_player.animation_finished
 
 # 2. Меняем сцену (игрок этого не видит, так как экран черный)
 get_tree().change_scene_to_file(target_scene_path)
 
 # 3. Делаем ИСКУССТВЕННУЮ ПАУЗУ (ту самую "мини-загрузку")
 # Ждем 1.5 секунды (можешь поменять время)
 await get_tree().create_timer(1.5).timeout
 
 # 4. Запускаем анимацию в обратном порядке, чтобы экран снова стал прозрачным
 anim_player.play_backwards("fade_to_black")
