# scripts/ecs/BuildingNode.gd
class_name BuildingNode
extends StaticBody2D

## Гибридный класс здания: Godot Node + ECS Entity
## Node отвечает за визуализацию и коллизии
## ECS Entity отвечает за логику производства и строительства

# ECS
var entity_id: int = -1
var ecs_world: Node

# Визуальные компоненты
@onready var sprite: Sprite2D = $Sprite2D
@onready var progress_bar: ProgressBar = $ProgressBar

# Параметры здания (для инициализации)
@export var building_type: String = ""
@export var building_race: String = "lizard"
@export var max_health: float = 200.0
@export var max_workers: int = 2

func _ready():
	ecs_world = get_node_or_null("/root/ECSWorld")
	if not ecs_world:
		push_error("[BuildingNode] ECSWorld not found!")
		return
	
	create_ecs_entity()
	setup_visuals()

func _exit_tree():
	# Уничтожаем ECS entity при удалении Node
	if entity_id >= 0 and ecs_world:
		ecs_world.destroy_entity(entity_id)

func create_ecs_entity() -> void:
	# Создаем entity
	var entity = ecs_world.create_entity()
	entity_id = entity.id
	
	# TransformComponent
	var transform = load("res://scripts/ecs/components/TransformComponent.gd").new()
	transform.position = global_position
	transform.node_ref = self
	ecs_world.add_component(entity_id, transform)
	
	# HealthComponent
	var health = load("res://scripts/ecs/components/HealthComponent.gd").new(max_health)
	ecs_world.add_component(entity_id, health)
	
	# BuildingComponent
	var building = load("res://scripts/ecs/components/BuildingComponent.gd").new(building_type)
	building.race = building_race
	ecs_world.add_component(entity_id, building)
	
	# ProductionComponent
	var production = load("res://scripts/ecs/components/ProductionComponent.gd").new()
	ecs_world.add_component(entity_id, production)
	
	# WorkersComponent
	var workers = load("res://scripts/ecs/components/WorkersComponent.gd").new(max_workers)
	ecs_world.add_component(entity_id, workers)
	
	# RaceComponent
	var race = load("res://scripts/ecs/components/RaceComponent.gd").new()
	match building_race:
		"lizard": race.race = race.Race.LIZARD
		"canid": race.race = race.Race.CANID
		"rus": race.race = race.Race.RUS
	ecs_world.add_component(entity_id, race)

func setup_visuals() -> void:
	# Настройка визуальных компонентов
	if not progress_bar:
		progress_bar = ProgressBar.new()
		progress_bar.position = Vector2(-30, -50)
		progress_bar.size = Vector2(60, 8)
		progress_bar.visible = false
		add_child(progress_bar)

func _process(delta):
	sync_from_ecs()
	update_visuals()

func sync_from_ecs() -> void:
	if entity_id < 0 or not ecs_world:
		return
	
	# Синхронизируем позицию из ECS
	var transform = ecs_world.get_component(entity_id, "res://scripts/ecs/components/TransformComponent.gd")
	if transform:
		global_position = transform.position

func update_visuals() -> void:
	if entity_id < 0 or not ecs_world:
		return
	
	var building = ecs_world.get_component(entity_id, "res://scripts/ecs/components/BuildingComponent.gd")
	if not building:
		return
	
	# Обновляем визуал в зависимости от состояния
	match building.state:
		building.State.BLUEPRINT:
			if sprite:
				sprite.modulate = Color(1, 1, 1, 0.5)
			if progress_bar:
				progress_bar.visible = false
		
		building.State.CONSTRUCTING:
			if sprite:
				sprite.modulate = Color(1, 1, 1, 0.7)
			if progress_bar:
				progress_bar.visible = true
				progress_bar.value = building.construction_progress
		
		building.State.OPERATIONAL:
			if sprite:
				sprite.modulate = Color(1, 1, 1, 1)
			if progress_bar:
				progress_bar.visible = false
			update_production_visual()
		
		building.State.DAMAGED:
			if sprite:
				sprite.modulate = Color(1, 0.5, 0.5, 1)
		
		building.State.DESTROYED:
			queue_free()

func update_production_visual() -> void:
	var production = ecs_world.get_component(entity_id, "res://scripts/ecs/components/ProductionComponent.gd")
	if production and production.has_production() and progress_bar:
		progress_bar.visible = true
		progress_bar.value = production.production_progress

# Команды для здания

func start_construction() -> void:
	if entity_id < 0:
		return
	
	var building = ecs_world.get_component(entity_id, "res://scripts/ecs/components/BuildingComponent.gd")
	if building:
		building.state = building.State.CONSTRUCTING

func add_to_production(recipe: String) -> void:
	if entity_id < 0:
		return
	
	var production = ecs_world.get_component(entity_id, "res://scripts/ecs/components/ProductionComponent.gd")
	if production:
		production.add_to_queue(recipe)

func assign_worker(worker_entity_id: int) -> bool:
	if entity_id < 0:
		return false
	
	var workers = ecs_world.get_component(entity_id, "res://scripts/ecs/components/WorkersComponent.gd")
	if workers:
		return workers.assign_worker(worker_entity_id)
	return false

func get_building_info() -> Dictionary:
	if entity_id < 0:
		return {}
	
	var info = {
		"entity_id": entity_id,
		"type": building_type,
		"race": building_race
	}
	
	var building = ecs_world.get_component(entity_id, "res://scripts/ecs/components/BuildingComponent.gd")
	if building:
		info["state"] = building.state
		info["construction_progress"] = building.construction_progress
	
	var workers = ecs_world.get_component(entity_id, "res://scripts/ecs/components/WorkersComponent.gd")
	if workers:
		info["workers"] = workers.get_worker_count()
		info["max_workers"] = workers.max_workers
	
	var production = ecs_world.get_component(entity_id, "res://scripts/ecs/components/ProductionComponent.gd")
	if production:
		info["production_queue"] = production.get_queue_size()
		info["current_recipe"] = production.current_recipe
	
	return info