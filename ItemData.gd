extends Resource
class_name ItemData

@export var item_name: String = "Зелье здоровья"
@export var icon: Texture2D       
@export var heal_amount: int = 20 
@export var max_stack: int = 1 

@export_category("Активные свойства (Зелья)")
@export var is_consumable: bool = true 

@export_category("Пассивные свойства (Амулеты)")
@export var passive_heal_per_sec: float = 0.0 
