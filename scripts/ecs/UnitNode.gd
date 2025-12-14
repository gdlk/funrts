# scripts/ecs/UnitNode.gd
class_name UnitNode
extends CharacterBody2D

## Гибридный класс юнита: Godot Node + ECS Entity
## Node отвечает за визуализацию и физику
## ECS Entity отвечает за логику симуляции

# ECS
var entity_id: int = -1
var ecs_world: Node

# Визуальные компоненты
@onready var sprite: Sprite2D = $Sprite2D
@onready var health_bar: ProgressBar = $HealthBar
@onready var selection_indicator: Sprite2D = $SelectionIndicator
@onready var path_line: Line2D = $PathLine

# Параметры юнита (для инициализации)
@export var unit_race: String = "lizard"
@export var unit_name: String = ""
@export var max_health: float = 100.0

func _ready():
	ecs_world = get_node_or_null("/root/ECSWorld")
	if not ecs_world:
		push_error("[UnitNode] ECSWorld not found!")
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
	
	# VelocityComponent
	var velocity = load("res://scripts/ecs/components/VelocityComponent.gd").new(100.0)
	ecs_world.add_component(entity_id, velocity)
	
	# NeedsComponent
	var needs = load("res://scripts/ecs/components/NeedsComponent.gd").new()
	ecs_world.add_component(entity_id, needs)
	
	# SkillsComponent
	var skills = load("res://scripts/ecs/components/SkillsComponent.gd").new()
	ecs_world.add_component(entity_id, skills)
	
	# StatsComponent
	var stats = load("res://scripts/ecs/components/StatsComponent.gd").new()
	ecs_world.add_component(entity_id, stats)
	
	# TaskComponent
	var task = load("res://scripts/ecs/components/TaskComponent.gd").new()
	ecs_world.add_component(entity_id, task)
	
	# PathComponent
	var path = load("res://scripts/ecs/components/PathComponent.gd").new()
	ecs_world.add_component(entity_id, path)
	
	# RaceComponent
	var race = load("res://scripts/ecs/components/RaceComponent.gd").new()
	match unit_race:
		"lizard": race.race = race.Race.LIZARD
		"canid": race.race = race.Race.CANID
		"rus": race.race = race.Race.RUS
	ecs_world.add_component(entity_id, race)
	
	# Добавляем расовые компоненты
	add_race_specific_components()

func add_race_specific_components() -> void:
	match unit_race:
		"lizard":
			var bio = load("res://scripts/ecs/components/LizardBioComponent.gd").new()
			ecs_world.add_component(entity_id, bio)
		"canid":
			var pack = load("res://scripts/ecs/components/CanidPackComponent.gd").new()
			ecs_world.add_component(entity_id, pack)
		"rus":
			var mech = load("res://scripts/ecs/components/RusMechanicalComponent.gd").new()
			ecs_world.add_component(entity_id, mech)

func setup_visuals() -> void:
	# Настройка визуальных компонентов
	if not health_bar:
		health_bar = ProgressBar.new()
		health_bar.position = Vector2(-20, -40)
		health_bar.size = Vector2(40, 5)
		add_child(health_bar)
	
	if not selection_indicator:
		selection_indicator = Sprite2D.new()
		selection_indicator.visible = false
		add_child(selection_indicator)
	
	if not path_line:
		path_line = Line2D.new()
		path_line.width = 2.0
		path_line.default_color = Color(0.2, 0.8, 0.2, 0.5)
		path_line.z_index = -1
		add_child(path_line)

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
	
	# Обновляем здоровье
	var health = ecs_world.get_component(entity_id, "res://scripts/ecs/components/HealthComponent.gd")
	if health and health_bar:
		health_bar.value = health.get_health_percentage() * 100
		health_bar.visible = health.is_damaged()
	
	# Обновляем путь
	var path = ecs_world.get_component(entity_id, "res://scripts/ecs/components/PathComponent.gd")
	if path and path_line:
		update_path_visualization(path)

func update_path_visualization(path_comp) -> void:
	path_line.clear_points()
	
	if not path_comp.has_path():
		return
	
	# Добавляем текущую позицию
	path_line.add_point(Vector2.ZERO)
	
	# Добавляем точки пути относительно юнита
	for i in range(path_comp.current_index, path_comp.path.size()):
		var point = path_comp.path[i] - global_position
		path_line.add_point(point)

func set_selected(selected: bool) -> void:
	if selection_indicator:
		selection_indicator.visible = selected

# Команды для юнита

func move_to(target_position: Vector2) -> void:
	if entity_id < 0:
		return
	
	# Получаем путь от PathfindingSystem
	var pathfinding = get_node("/root/PathfindingSystem")
	var tile_size = 32  # TODO: взять из Constants
	var path_points = pathfinding.find_path(
		global_position / tile_size,
		target_position / tile_size
	)
	
	# Конвертируем в мировые координаты
	var world_path = []
	for point in path_points:
		world_path.append(point * tile_size)
	
	# Устанавливаем путь в PathComponent
	var path = ecs_world.get_component(entity_id, "res://scripts/ecs/components/PathComponent.gd")
	if path:
		path.set_path(world_path)
		path.target_position = target_position

func get_unit_info() -> Dictionary:
	if entity_id < 0:
		return {}
	
	var info = {
		"entity_id": entity_id,
		"name": unit_name,
		"race": unit_race
	}
	
	# Добавляем данные из компонентов
	var health = ecs_world.get_component(entity_id, "res://scripts/ecs/components/HealthComponent.gd")
	if health:
		info["health"] = health.current
		info["max_health"] = health.maximum
	
	var needs = ecs_world.get_component(entity_id, "res://scripts/ecs/components/NeedsComponent.gd")
	if needs:
		info["mood"] = needs.get_mood()
		info["hunger"] = needs.hunger
		info["rest"] = needs.rest
	
	var task = ecs_world.get_component(entity_id, "res://scripts/ecs/components/TaskComponent.gd")
	if task:
		info["current_task"] = task.get_task_name()
	
	return info