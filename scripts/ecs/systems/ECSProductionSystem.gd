# scripts/ecs/systems/ECSProductionSystem.gd
class_name ECSProductionSystem
extends Node

## Система производства
## Обрабатывает производство предметов в зданиях

const BuildingComponent = preload("res://scripts/ecs/components/BuildingComponent.gd")
const ProductionComponent = preload("res://scripts/ecs/components/ProductionComponent.gd")
const WorkersComponent = preload("res://scripts/ecs/components/WorkersComponent.gd")

func get_required_components() -> Array:
	return [
		"res://scripts/ecs/components/BuildingComponent.gd",
		"res://scripts/ecs/components/ProductionComponent.gd",
		"res://scripts/ecs/components/WorkersComponent.gd"
	]

func process(delta: float, world) -> void:
	var entities = world.query(get_required_components())
	process_entities(delta, world, entities)

func process_entities(delta: float, world, entities: Array) -> void:
	for entity_id in entities:
		var building = world.get_component(entity_id, "res://scripts/ecs/components/BuildingComponent.gd")
		var production = world.get_component(entity_id, "res://scripts/ecs/components/ProductionComponent.gd")
		var workers = world.get_component(entity_id, "res://scripts/ecs/components/WorkersComponent.gd")
		
		# Производство работает только в операционном состоянии
		if not building.is_operational():
			continue
		
		# Нужны рабочие
		if workers.get_worker_count() == 0:
			continue
		
		# Нужен рецепт в очереди
		if not production.has_production():
			continue
		
		# Прогресс производства
		var speed_modifier = workers.get_efficiency() * production.production_speed
		production.production_progress += delta * 10 * speed_modifier
		
		# Завершение производства
		if production.production_progress >= 100:
			complete_production(entity_id, production, world)

func complete_production(entity_id: int, production, world) -> void:
	var recipe = production.complete_current()
	
	# Создаем произведенный предмет
	EventBus.emit_signal("production_completed", entity_id, recipe)
	
	print("[ECSProductionSystem] Entity %d completed production: %s" % [entity_id, recipe])