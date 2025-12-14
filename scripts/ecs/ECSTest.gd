# scripts/ecs/ECSTest.gd
extends Node2D

## Тестовая сцена для проверки ECS
## Создает несколько юнитов и зданий для тестирования

@onready var ecs_world = get_node("/root/ECSWorld")

func _ready():
	print("=== ECS Test Scene ===")
	test_create_units()
	test_create_building()
	print_ecs_stats()

func test_create_units():
	print("\n[Test] Creating test units...")
	
	# Создаем 3 тестовых юнита
	for i in range(3):
		var unit = create_test_unit(Vector2(100 + i * 100, 100), "lizard")
		print("  Created unit %d at position %v" % [unit.entity_id, unit.global_position])

func test_create_building():
	print("\n[Test] Creating test building...")
	
	var building = create_test_building(Vector2(400, 400), "workshop")
	print("  Created building %d at position %v" % [building.entity_id, building.global_position])

func create_test_unit(pos: Vector2, race: String) -> UnitNode:
	var unit_scene = preload("res://scenes/units/TestUnit.tscn")
	var unit = unit_scene.instantiate()
	unit.global_position = pos
	unit.unit_race = race
	unit.unit_name = "Test Unit"
	add_child(unit)
	return unit

func create_test_building(pos: Vector2, btype: String) -> BuildingNode:
	var building_scene = preload("res://scenes/buildings/TestBuilding.tscn")
	var building = building_scene.instantiate()
	building.global_position = pos
	building.building_type = btype
	add_child(building)
	return building

func print_ecs_stats():
	print("\n[ECS Stats]")
	if ecs_world:
		ecs_world.print_debug_info()

func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_F1:
				print("\n=== Manual ECS Stats ===")
				print_ecs_stats()
			KEY_F2:
				test_unit_movement()
			KEY_F3:
				test_building_production()

func test_unit_movement():
	print("\n[Test] Testing unit movement...")
	var units = get_tree().get_nodes_in_group("units")
	if units.size() > 0:
		var unit = units[0]
		if unit is UnitNode:
			unit.move_to(Vector2(500, 500))
			print("  Unit %d moving to (500, 500)" % unit.entity_id)

func test_building_production():
	print("\n[Test] Testing building production...")
	var buildings = get_tree().get_nodes_in_group("buildings")
	if buildings.size() > 0:
		var building = buildings[0]
		if building is BuildingNode:
			building.add_to_production("test_item")
			print("  Building %d started production" % building.entity_id)