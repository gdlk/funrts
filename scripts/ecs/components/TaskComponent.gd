# scripts/ecs/components/TaskComponent.gd
class_name TaskComponent
extends RefCounted

## Компонент текущей задачи юнита
## Управляет тем, что юнит делает в данный момент

enum TaskType {
	NONE,
	IDLE,
	MOVE,
	GATHER,
	BUILD,
	CRAFT,
	FIGHT,
	EAT,
	SLEEP,
	SOCIALIZE
}

var current_task: TaskType = TaskType.IDLE
var task_target: int = -1  # Entity ID цели задачи
var task_position: Vector2 = Vector2.ZERO
var task_progress: float = 0.0
var task_data: Dictionary = {}  # Дополнительные данные задачи

func _init():
	pass

func set_task(task_type: TaskType, target: int = -1, position: Vector2 = Vector2.ZERO) -> void:
	current_task = task_type
	task_target = target
	task_position = position
	task_progress = 0.0
	task_data.clear()

func clear_task() -> void:
	current_task = TaskType.IDLE
	task_target = -1
	task_position = Vector2.ZERO
	task_progress = 0.0
	task_data.clear()

func is_idle() -> bool:
	return current_task == TaskType.IDLE or current_task == TaskType.NONE

func has_target() -> bool:
	return task_target >= 0

func get_task_name() -> String:
	match current_task:
		TaskType.NONE: return "None"
		TaskType.IDLE: return "Idle"
		TaskType.MOVE: return "Moving"
		TaskType.GATHER: return "Gathering"
		TaskType.BUILD: return "Building"
		TaskType.CRAFT: return "Crafting"
		TaskType.FIGHT: return "Fighting"
		TaskType.EAT: return "Eating"
		TaskType.SLEEP: return "Sleeping"
		TaskType.SOCIALIZE: return "Socializing"
	return "Unknown"