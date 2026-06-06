extends Resource
class_name ItemData

@export var item_name: String = "Зелье здоровья"
@export var icon: Texture2D       # Сюда ты потом закинешь свой спрайт пузырька
@export var heal_amount: int = 20 # Сколько ХП восстанавливает
@export var max_stack: int = 1 # Сколько штук может лежать в одной ячейке

@export_category("Активные свойства (Зелья)")
@export var is_consumable: bool = true # Тратится ли предмет при использовании?


@export_category("Пассивные свойства (Амулеты)")
@export var passive_heal_per_sec: float = 0.0 # Лечение в секунду, пока лежит в инвентаре
