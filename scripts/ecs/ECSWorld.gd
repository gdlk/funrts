# scripts/ecs/ECSWorld.gd
extends Node

## Менеджер ECS мира
## Управляет всеми сущностями, компонентами и системами
## Автозагружается как синглтон

# Preload базовых классов
const Entity = preload("res://scripts/ecs/Entity.gd")
const Component = preload("res://scripts/ecs/Component.gd")
const System = preload("res://scripts/ecs/System.gd")

# Хранилище всех сущностей
var entities: Dictionary = {}  # {entity_id: Entity}
var next_entity_id: int = 0

# Хранилище компонентов по типам
# {component_type_path: {entity_id: component}}
var components: Dictionary = {}

# Системы обработки
var systems: Array = []

# Кэш запросов для оптимизации
var entity_queries: Dictionary = {}  # {query_key: [entity_ids]}

# Статистика для отладки
var stats: Dictionary = {
	"entity_count": 0,
	"component_count": 0,
	"system_count": 0
}

func _ready():
	print("[ECSWorld] Initializing ECS World...")
	setup_systems()
	print("[ECSWorld] ECS World initialized with %d systems" % systems.size())

func _process(delta: float):
	# Обрабатываем все системы последовательно
	for system in systems:
		system.process(delta, self)

# === Entity Management ===

## Создает новую сущность и возвращает её
func create_entity() -> Entity:
	var entity = Entity.new(next_entity_id)
	entities[next_entity_id] = entity
	next_entity_id += 1
	stats.entity_count = entities.size()
	return entity

## Уничтожает сущность и все её компоненты
func destroy_entity(entity_id: int) -> void:
	if not entities.has(entity_id):
		push_warning("[ECSWorld] Trying to destroy non-existent entity: %d" % entity_id)
		return
	
	# Удаляем все компоненты этой сущности
	for component_type in components:
		if components[component_type].has(entity_id):
			components[component_type].erase(entity_id)
	
	# Удаляем саму сущность
	entities.erase(entity_id)
	
	# Очищаем кэш запросов
	entity_queries.clear()
	
	stats.entity_count = entities.size()
	_update_component_count()

## Проверяет существование сущности
func has_entity(entity_id: int) -> bool:
	return entities.has(entity_id)

## Получает сущность по ID
func get_entity(entity_id: int) -> Entity:
	return entities.get(entity_id)

# === Component Management ===

## Добавляет компонент к сущности
func add_component(entity_id: int, component: Component) -> void:
	if not entities.has(entity_id):
		push_error("[ECSWorld] Cannot add component to non-existent entity: %d" % entity_id)
		return
	
	var component_type = component.get_script().get_path()
	
	if not components.has(component_type):
		components[component_type] = {}
	
	components[component_type][entity_id] = component
	
	# Очищаем кэш запросов
	entity_queries.clear()
	
	_update_component_count()

## Получает компонент сущности по типу
func get_component(entity_id: int, component_type: String):
	if not components.has(component_type):
		return null
	return components[component_type].get(entity_id)

## Проверяет наличие компонента у сущности
func has_component(entity_id: int, component_type: String) -> bool:
	return components.has(component_type) and components[component_type].has(entity_id)

## Удаляет компонент у сущности
func remove_component(entity_id: int, component_type: String) -> void:
	if components.has(component_type):
		components[component_type].erase(entity_id)
		entity_queries.clear()
		_update_component_count()

## Получает все компоненты сущности
func get_all_components(entity_id: int) -> Array:
	var result = []
	for component_type in components:
		if components[component_type].has(entity_id):
			result.append(components[component_type][entity_id])
	return result

# === Query System ===

## Находит все сущности с указанными компонентами
## component_types: Array of String (пути к скриптам компонентов)
func query(component_types: Array) -> Array:
	if component_types.is_empty():
		return []
	
	# Создаем ключ для кэша
	var cache_key = "_".join(component_types)
	
	# Проверяем кэш
	if entity_queries.has(cache_key):
		return entity_queries[cache_key]
	
	var result = []
	
	# Находим все entity с нужными компонентами
	for entity_id in entities:
		var has_all = true
		for comp_type in component_types:
			if not has_component(entity_id, comp_type):
				has_all = false
				break
		
		if has_all:
			result.append(entity_id)
	
	# Кэшируем результат
	entity_queries[cache_key] = result
	return result

# === System Management ===

## Настраивает все системы
## Порядок важен! Системы выполняются последовательно
func setup_systems() -> void:
	# Загружаем системы
	var ECSNeedsSystem = load("res://scripts/ecs/systems/ECSNeedsSystem.gd")
	var ECSMovementSystem = load("res://scripts/ecs/systems/ECSMovementSystem.gd")
	var ECSProductionSystem = load("res://scripts/ecs/systems/ECSProductionSystem.gd")
	var ECSAISystem = load("res://scripts/ecs/systems/ECSAISystem.gd")
	
	# Добавляем системы в правильном порядке
	add_system(ECSNeedsSystem.new())
	add_system(ECSAISystem.new())
	add_system(ECSMovementSystem.new())
	add_system(ECSProductionSystem.new())

## Добавляет систему в мир
func add_system(system: Node) -> void:
	systems.append(system)
	add_child(system)
	stats.system_count = systems.size()
	print("[ECSWorld] Added system: %s" % system)

## Удаляет систему из мира
func remove_system(system: Node) -> void:
	var index = systems.find(system)
	if index >= 0:
		systems.remove_at(index)
		system.queue_free()
		stats.system_count = systems.size()

# === Debug & Utilities ===

## Получает статистику ECS мира
func get_stats() -> Dictionary:
	return stats.duplicate()

## Выводит информацию о мире в консоль
func print_debug_info() -> void:
	print("=== ECS World Debug Info ===")
	print("Entities: %d" % stats.entity_count)
	print("Components: %d" % stats.component_count)
	print("Systems: %d" % stats.system_count)
	print("Component types: %d" % components.size())
	for comp_type in components:
		print("  - %s: %d instances" % [comp_type.get_file().get_basename(), components[comp_type].size()])
	print("===========================")

## Очищает весь мир (для тестов или перезапуска)
func clear() -> void:
	# Удаляем все системы
	for system in systems:
		system.queue_free()
	systems.clear()
	
	# Очищаем все данные
	entities.clear()
	components.clear()
	entity_queries.clear()
	next_entity_id = 0
	
	stats.entity_count = 0
	stats.component_count = 0
	stats.system_count = 0
	
	print("[ECSWorld] World cleared")

# === Private Methods ===

func _update_component_count() -> void:
	var count = 0
	for component_type in components:
		count += components[component_type].size()
	stats.component_count = count