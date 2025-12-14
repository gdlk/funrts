# scripts/ecs/components/PathComponent.gd
class_name PathComponent
extends RefCounted

## Компонент пути движения
## Хранит путь и текущую позицию на пути

var path: Array = []  # Array of Vector2
var current_index: int = 0
var target_position: Vector2 = Vector2.ZERO

func _init():
	pass

func set_path(new_path: Array) -> void:
	path = new_path.duplicate()
	current_index = 0

func has_path() -> bool:
	return not path.is_empty() and current_index < path.size()

func get_next_point() -> Vector2:
	if has_path():
		return path[current_index]
	return Vector2.ZERO

func advance() -> void:
	current_index += 1

func clear() -> void:
	path.clear()
	current_index = 0
	target_position = Vector2.ZERO

func get_remaining_distance() -> float:
	if not has_path():
		return 0.0
	
	var distance = 0.0
	for i in range(current_index, path.size() - 1):
		distance += path[i].distance_to(path[i + 1])
	return distance

func get_progress() -> float:
	if path.is_empty():
		return 1.0
	return float(current_index) / float(path.size())