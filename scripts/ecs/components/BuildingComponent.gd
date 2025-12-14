# scripts/ecs/components/BuildingComponent.gd
class_name BuildingComponent
extends RefCounted

## Компонент здания
## Управляет состоянием и типом здания

enum State {
	BLUEPRINT,      # Чертеж, еще не начато строительство
	CONSTRUCTING,   # В процессе строительства
	OPERATIONAL,    # Работает нормально
	DAMAGED,        # Повреждено, требует ремонта
	DESTROYED       # Уничтожено
}

var building_type: String = ""
var building_name: String = ""
var race: String = ""
var state: State = State.BLUEPRINT
var construction_progress: float = 0.0

# Требуемые ресурсы для строительства
var required_resources: Dictionary = {}
var delivered_resources: Dictionary = {}

func _init(btype: String = "", bname: String = ""):
	building_type = btype
	building_name = bname

func is_operational() -> bool:
	return state == State.OPERATIONAL

func is_constructing() -> bool:
	return state == State.CONSTRUCTING

func has_all_resources() -> bool:
	for resource in required_resources:
		if delivered_resources.get(resource, 0) < required_resources[resource]:
			return false
	return true

func deliver_resource(resource_name: String, amount: int) -> void:
	if not delivered_resources.has(resource_name):
		delivered_resources[resource_name] = 0
	delivered_resources[resource_name] += amount

func get_construction_percentage() -> float:
	return construction_progress