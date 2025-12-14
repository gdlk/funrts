# scripts/ecs/systems/ECSAISystem.gd
class_name ECSAISystem
extends Node

## Система искусственного интеллекта
## Назначает задачи юнитам на основе их потребностей и приоритетов

const TaskComponent = preload("res://scripts/ecs/components/TaskComponent.gd")
const NeedsComponent = preload("res://scripts/ecs/components/NeedsComponent.gd")

func get_required_components() -> Array:
	return [
		"res://scripts/ecs/components/TaskComponent.gd",
		"res://scripts/ecs/components/NeedsComponent.gd"
	]

func process(delta: float, world) -> void:
	var entities = world.query(get_required_components())
	process_entities(delta, world, entities)

func process_entities(delta: float, world, entities: Array) -> void:
	for entity_id in entities:
		var task = world.get_component(entity_id, "res://scripts/ecs/components/TaskComponent.gd")
		var needs = world.get_component(entity_id, "res://scripts/ecs/components/NeedsComponent.gd")
		
		# Если нет задачи - ищем новую
		if task.is_idle():
			assign_new_task(entity_id, task, needs, world)

func assign_new_task(entity_id: int, task, needs, world) -> void:
	# Приоритет критическим потребностям
	if needs.hunger < 50:
		task.set_task(TaskComponent.TaskType.EAT)
		return
	
	if needs.rest < 50:
		task.set_task(TaskComponent.TaskType.SLEEP)
		return
	
	if needs.social < 30:
		task.set_task(TaskComponent.TaskType.SOCIALIZE)
		return
	
	# Запрашиваем рабочую задачу у TaskManager
	EventBus.emit_signal("request_task_for_unit", entity_id)