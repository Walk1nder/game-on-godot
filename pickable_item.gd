extends Area2D

@export var item_data: ItemData 

func _ready():
	if item_data and item_data.icon:
		$Sprite2D.texture = item_data.icon

func _on_body_entered(body):
	if body.name == "Player": 
		if body.add_item_to_inventory(item_data): 
			queue_free() 
