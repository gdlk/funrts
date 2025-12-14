# scripts/ecs/EntityNode.gd
class_name EntityNode
extends Node2D

## Связующий слой между Godot Node и ECS Entity
## Этот класс синхронизирует визуальное представление (Node) с логикой (ECS)

# Ссылка на ECS entity
var entity_id: int = -1
var ecs_world: Node  # ECSWorld

func _ready():
	ecs_world = get_node_or_null("/root/ECSWorld")
	if not ecs_world:
		push_error("[EntityNode] ECSWorld not found! Make sure it's in autoload.")
		return
	
	# Создаем ECS entity при создании Node
	create_ecs_entity()

func _exit_tree():
	# Уничтожаем ECS entity при удалении Node
	if entity_id >= 0 and ecs_world:
		ecs_world.destroy_entity(entity_id)

## Создает ECS entity и базовые компоненты
## Переопределяется в подклассах для добавления специфичных компонентов
func create_ecs_entity() -> void:
	if not ecs_world:
		return
	
	var entity = ecs_world.create_entity()
	entity_id = entity.id
	
	# Добавляем базовый TransformComponent
	var transform_comp = load("res://scripts/ecs/components/TransformComponent.gd").new()
	transform_comp.position = global_position
	transform_comp.rotation = rotation
	transform_comp.scale = scale
	transform_comp.node_ref = self
	ecs_world.add_component(entity_id, transform_comp)

## Синхронизирует Node с ECS данными
## Вызывается каждый кадр
func sync_from_ecs() -> void:
	if entity_id < 0 or not ecs_world:
		return
	
	# Синхронизируем позицию из ECS
	var transform = ecs_world.get_component(entity_id, "res://scripts/ecs/components/TransformComponent.gd")
	if transform:
		global_position = transform.position
		rotation = transform.rotation
		scale = transform.scale

## Синхронизирует ECS с Node данными
## Используется когда Node изменяется напрямую (например, через редактор)
func sync_to_ecs() -> void:
	if entity_id < 0 or not ecs_world:
		return
	
	var transform = ecs_world.get_component(entity_id, "res://scripts/ecs/components/TransformComponent.gd")
	if transform:
		transform.position = global_position
		transform.rotation = rotation
		transform.scale = scale

## Получает компонент из ECS
func get_ecs_component(component_type: String):
	if entity_id < 0 or not ecs_world:
		return null
	return ecs_world.get_component(entity_id, component_type)

## Добавляет компонент в ECS
func add_ecs_component(component) -> void:
	if entity_id < 0 or not ecs_world:
		return
	ecs_world.add_component(entity_id, component)

## Проверяет наличие компонента
func has_ecs_component(component_type: String) -> bool:
	if entity_id < 0 or not ecs_world:
		return false
	return ecs_world.has_component(entity_id, component_type)