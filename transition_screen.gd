extends CanvasLayer


@onready var anim_player = $AnimationPlayer

func transition_to(target_scene_path: String):
 anim_player.play("fade_to_black")
 
 await anim_player.animation_finished
 
 get_tree().change_scene_to_file(target_scene_path)
 await get_tree().create_timer(1.5).timeout
 anim_player.play_backwards("fade_to_black")
