# scripts/ecs/systems/ECSMovementSystem.gd
class_name ECSMovementSystem
extends Node

## Система движения
## Обрабатывает перемещение сущностей по пути

const TransformComponent = preload("res://scripts/ecs/components/TransformComponent.gd")
const VelocityComponent = preload("res://scripts/ecs/components/VelocityComponent.gd")
const PathComponent = preload("res://scripts/ecs/components/PathComponent.gd")

func get_required_components() -> Array:
	return [
		"res://scripts/ecs/components/TransformComponent.gd",
		"res://scripts/ecs/components/VelocityComponent.gd",
		"res://scripts/ecs/components/PathComponent.gd"
	]

func process(delta: float, world) -> void:
	var entities = world.query(get_required_components())
	process_entities(delta, world, entities)

func process_entities(delta: float, world, entities: Array) -> void:
	for entity_id in entities:
		var transform = world.get_component(entity_id, "res://scripts/ecs/components/TransformComponent.gd")
		var velocity = world.get_component(entity_id, "res://scripts/ecs/components/VelocityComponent.gd")
		var path = world.get_component(entity_id, "res://scripts/ecs/components/PathComponent.gd")
		
		if not path.has_path():
			# Применяем трение если нет пути
			velocity.apply_friction(delta)
			continue
		
		# Движение к следующей точке пути
		var target = path.get_next_point()
		var direction = (target - transform.position).normalized()
		
		# Ускорение к цели
		var desired_velocity = direction * velocity.max_speed
		var steering = desired_velocity - velocity.velocity
		velocity.velocity += steering * velocity.acceleration * delta
		
		# Ограничиваем скорость
		velocity.limit_speed()
		
		# Обновляем позицию
		transform.position += velocity.velocity * delta
		
		# Синхронизируем с Node если есть
		if transform.node_ref:
			transform.node_ref.global_position = transform.position
		
		# Проверяем достижение точки
		if transform.position.distance_to(target) < 5:
			path.advance()
			if not path.has_path():
				velocity.velocity = Vector2.ZERO
				EventBus.emit_signal("unit_reached_destination", entity_id)