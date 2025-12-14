# scripts/ecs/systems/ECSNeedsSystem.gd
class_name ECSNeedsSystem
extends Node

## Система обработки потребностей юнитов
## Обновляет голод, отдых, комфорт и социализацию
## Влияет на настроение и эффективность работы

const System = preload("res://scripts/ecs/System.gd")
const NeedsComponent = preload("res://scripts/ecs/components/NeedsComponent.gd")
const TaskComponent = preload("res://scripts/ecs/components/TaskComponent.gd")

func get_required_components() -> Array:
	return [
		"res://scripts/ecs/components/NeedsComponent.gd"
	]

func process(delta: float, world) -> void:
	var entities = world.query(get_required_components())
	process_entities(delta, world, entities)

func process_entities(delta: float, world, entities: Array) -> void:
	for entity_id in entities:
		var needs = world.get_component(entity_id, "res://scripts/ecs/components/NeedsComponent.gd")
		
		# Уменьшаем потребности со временем
		needs.hunger = max(0, needs.hunger - needs.hunger_decay * delta)
		needs.rest = max(0, needs.rest - needs.rest_decay * delta)
		needs.comfort = max(0, needs.comfort - needs.comfort_decay * delta)
		needs.social = max(0, needs.social - needs.social_decay * delta)
		
		# Проверяем критические потребности и назначаем задачи
		check_critical_needs(entity_id, needs, world)

func check_critical_needs(entity_id: int, needs, world) -> void:
	var task = world.get_component(entity_id, "res://scripts/ecs/components/TaskComponent.gd")
	if not task:
		return
	
	# Приоритет: голод > отдых > остальное
	if needs.hunger < 30 and task.current_task != TaskComponent.TaskType.EAT:
		task.set_task(TaskComponent.TaskType.EAT)
		EventBus.emit_signal("unit_needs_food", entity_id)
	
	elif needs.rest < 30 and task.current_task != TaskComponent.TaskType.SLEEP:
		task.set_task(TaskComponent.TaskType.SLEEP)
		EventBus.emit_signal("unit_needs_rest", entity_id)
	
	elif needs.social < 20 and task.is_idle():
		task.set_task(TaskComponent.TaskType.SOCIALIZE)