# scenes/game/Game.gd
extends Node2D

# Основная игровая сцена

@onready var map = $Map
@onready var units_container = $Units
@onready var buildings_container = $Buildings
@onready var ui = $UI

var selected_unit = null

func _ready():
	# Инициализация игрового мира
	initialize_world()
	
	# Подключение сигналов
	connect_signals()
	
	# Создаем тестовых юнитов
	for i in range(10):
		var unit = preload("res://scenes/units/LizardUnit.tscn").instantiate()
		unit.global_position = Vector2(
			randf_range(100, 500),
			randf_range(100, 500)
		)
		add_child(unit)

func initialize_world():
	# Инициализация карты
	if map:
		map.generate_map()
	
	# Создание начальных юнитов в зависимости от расы
	spawn_initial_units()

func connect_signals():
	# Подключение сигналов EventBus
	EventBus.connect("unit_selected", Callable(self, "_on_unit_selected"))
	EventBus.connect("unit_died", Callable(self, "_on_unit_died"))
	EventBus.connect("building_constructed", Callable(self, "_on_building_constructed"))

func spawn_initial_units():
	# Создание начальных юнитов
	var unit_scene = preload("res://scenes/units/BaseUnit.tscn")
	
	for i in range(5):
		var unit = unit_scene.instantiate()
		unit.race = GameManager.current_race
		unit.global_position = Vector2(100 + i * 50, 100)
		units_container.add_child(unit)

func _process(delta):
	# Обновление систем
	update_systems(delta)

func update_systems(delta):
	# Обновление потребностей юнитов
	var needs_system = get_node("/root/NeedsSystem")
	for unit in units_container.get_children():
		if unit is BaseUnit:
			needs_system.update_needs(unit, delta)
	
	# Обновление зданий
	var production_system = get_node("/root/ProductionSystem")
	for building in buildings_container.get_children():
		if building is BaseBuilding:
			if building.current_state == 1:  # CONSTRUCTING
				# Обновление строительства
				pass
			elif building.current_state == 2:  # OPERATIONAL
				# Обновление производства
				production_system.process_production(building, delta)

func _on_unit_selected(unit):
	selected_unit = unit
	# Обновление UI для выбранного юнита
	ui.update_unit_info(unit)

func _on_unit_died(unit):
	if selected_unit == unit:
		selected_unit = null
		ui.clear_unit_info()

func _on_building_constructed(building):
	# Обновление UI при постройке здания
	ui.show_notification("Здание построено: " + building.building_name)

func _input(event):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			handle_left_click(event.position)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			handle_right_click(event.position)

func handle_left_click(position):
	# Проверка клика по юниту
	var space_state = get_world_2d().direct_space_state
	var parameters = PhysicsPointQueryParameters2D.new()
	parameters.position = position
	var result = space_state.intersect_point(parameters)
	
	for intersection in result:
		if intersection.collider is BaseUnit:
			EventBus.emit_signal("unit_selected", intersection.collider)
			return
	
	# Если не кликнули по юниту, снимаем выделение
	if selected_unit:
		EventBus.emit_signal("unit_selected", null)

func handle_right_click(position):
	if selected_unit:
		# Отправка выделенного юнита к точке
		selected_unit.move_to(position)