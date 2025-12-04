# scenes/buildings/BaseBuilding.gd
extends StaticBody2D

class_name BaseBuilding

# Импортируем константы
const Constants = preload("res://scripts/utils/Constants.gd")

# Основные параметры
var building_name: String = ""
var building_type: String = ""
var race: String = ""

# Состояние
var current_state: Constants.BuildingState = Constants.BuildingState.BLUEPRINT

# Здоровье
var health: float = 100.0
var max_health: float = 100.0

# Строительство
var construction_progress: float = 0.0
var required_resources: Dictionary = {}
var delivered_resources: Dictionary = {}

# Производство (если применимо)
var production_queue: Array = []
var production_progress: float = 0.0
var production_speed: float = 1.0

# Рабочие
var assigned_workers: Array = []
var max_workers: int = 1

signal construction_completed()
signal production_completed(item)
signal destroyed()

func _ready():
	add_to_group("buildings")

func _process(delta):
	match current_state:
		Constants.BuildingState.CONSTRUCTING:
			_process_construction(delta)
		Constants.BuildingState.OPERATIONAL:
			_process_operation(delta)
		Constants.BuildingState.DAMAGED:
			_process_damaged(delta)

func _process_construction(delta):
	if _has_all_resources():
		construction_progress += delta * 10 * assigned_workers.size()
		if construction_progress >= 100:
			complete_construction()

func _process_operation(delta):
	if not production_queue.is_empty():
		production_progress += delta * production_speed * assigned_workers.size()
		if production_progress >= 100:
			complete_production()

func _process_damaged(delta):
	# Логика для поврежденного здания
	pass

func deliver_resource(resource_name: String, amount: int):
	if not delivered_resources.has(resource_name):
		delivered_resources[resource_name] = 0
	delivered_resources[resource_name] += amount

func _has_all_resources() -> bool:
	for resource in required_resources:
		if delivered_resources.get(resource, 0) < required_resources[resource]:
			return false
	return true

func complete_construction():
	current_state = Constants.BuildingState.OPERATIONAL
	construction_progress = 100
	emit_signal("construction_completed")

func add_to_production_queue(item):
	production_queue.append(item)

func complete_production():
	var item = production_queue.pop_front()
	production_progress = 0
	emit_signal("production_completed", item)

func assign_worker(worker):
	if assigned_workers.size() < max_workers:
		assigned_workers.append(worker)

func remove_worker(worker):
	assigned_workers.erase(worker)

func take_damage(amount: float):
	health -= amount
	if health <= 0:
		destroy()
	elif health < max_health * 0.5:
		current_state = Constants.BuildingState.DAMAGED

func destroy():
	current_state = Constants.BuildingState.DESTROYED
	emit_signal("destroyed")
	queue_free()