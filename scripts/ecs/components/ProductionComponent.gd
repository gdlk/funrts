# scripts/ecs/components/ProductionComponent.gd
class_name ProductionComponent
extends RefCounted

## Компонент производства
## Управляет очередью производства и прогрессом

var production_queue: Array = []  # Array of recipe names/IDs
var current_recipe: String = ""
var production_progress: float = 0.0
var production_speed: float = 1.0

func _init(speed: float = 1.0):
	production_speed = speed

func add_to_queue(recipe: String) -> void:
	production_queue.append(recipe)
	if current_recipe == "":
		start_next_recipe()

func start_next_recipe() -> void:
	if production_queue.is_empty():
		current_recipe = ""
		production_progress = 0.0
		return
	
	current_recipe = production_queue[0]
	production_progress = 0.0

func complete_current() -> String:
	var completed = current_recipe
	production_queue.pop_front()
	start_next_recipe()
	return completed

func has_production() -> bool:
	return not production_queue.is_empty()

func get_queue_size() -> int:
	return production_queue.size()

func clear_queue() -> void:
	production_queue.clear()
	current_recipe = ""
	production_progress = 0.0