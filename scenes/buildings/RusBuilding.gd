# scenes/buildings/RusBuilding.gd
extends BaseBuilding

# Специализированный класс для зданий русов

# Уникальные характеристики зданий русов
var steam_pressure: float = 100.0
var max_steam_pressure: float = 100.0
var automation_level: int = 1
var conveyor_connections: Array = []
var efficiency_rating: float = 1.0

func _ready():
	race = "rus"
	steam_pressure = 100.0
	max_steam_pressure = 100.0
	automation_level = 1
	efficiency_rating = 1.0
	
	# Вызов родительского _ready()
	super._ready()

func _process(delta):
	# Вызов родительского _process()
	super._process(delta)
	
	# Уникальная логика зданий русов
	if current_state == Constants.BuildingState.OPERATIONAL:
		_manage_steam(delta)
		_update_automation(delta)

func _process_operation(delta):
	# Специфическая логика работы для зданий русов
	if not production_queue.is_empty():
		var steam_bonus = steam_pressure / max_steam_pressure
		var automation_bonus = 1.0 + (automation_level * 0.3)
		var efficiency_bonus = efficiency_rating
		
		production_progress += delta * production_speed * assigned_workers.size() * steam_bonus * automation_bonus * efficiency_bonus
		if production_progress >= 100:
			complete_production()

func _manage_steam(delta: float):
	# Управление паром в здании
	steam_pressure = min(max_steam_pressure, steam_pressure + 10 * delta)
	
	# Потребление пара для работы
	if current_state == Constants.BuildingState.OPERATIONAL and assigned_workers.size() > 0:
		steam_pressure = max(0, steam_pressure - 5 * assigned_workers.size() * delta)

func _update_automation(delta: float):
	# Обновление автоматизации
	if automation_level >= 3:
		_manage_conveyor_system(delta)

func _manage_conveyor_system(delta: float):
	# Управление конвейерной системой
	for connection in conveyor_connections:
		if connection.active:
			connection.transfer_items(delta)

func connect_to_conveyor(other_building):
	# Подключение к конвейеру другого здания
	var connection = {
		"target": other_building,
		"active": true,
		"transfer_rate": 10.0 * automation_level
	}
	conveyor_connections.append(connection)

func upgrade_automation():
	# Улучшение автоматизации
	automation_level += 1
	
	match automation_level:
		2:
			production_speed *= 1.2
			max_workers += 2
		3:
			# Разблокировка конвейерной системы
			efficiency_rating *= 1.3
		4:
			# Продвинутая автоматизация
			max_steam_pressure += 50
		5:
			# Совершенная автоматизация
			production_speed *= 1.5
			max_workers += 3

func generate_steam(amount: float):
	# Генерация пара
	steam_pressure = min(max_steam_pressure, steam_pressure + amount)

func repair_with_steam():
	# Ремонт с помощью пара
	if steam_pressure > 30:
		health = min(max_health, health + 20)
		steam_pressure -= 20
		return true
	return false

func optimize_production():
	# Оптимизация производства
	if steam_pressure > 50:
		efficiency_rating = min(2.0, efficiency_rating + 0.1)
		steam_pressure -= 30
		return true
	return false

func collective_work():
	# Коллективная работа
	var nearby_rus_buildings = _get_nearby_rus_buildings()
	if nearby_rus_buildings.size() >= 2:
		# Бонус к эффективности при работе в группе
		var group_bonus = 1.0 + (nearby_rus_buildings.size() * 0.1)
		for building in nearby_rus_buildings:
			building.efficiency_rating *= group_bonus

func _get_nearby_rus_buildings() -> Array:
	# Получение ближайших зданий русов
	var buildings = []
	for building in get_tree().get_nodes_in_group("buildings"):
		if building.race == "rus" and building != self:
			if global_position.distance_to(building.global_position) <= 100:
				buildings.append(building)
	return buildings

func take_damage(amount: float):
	# Здания русов получают сопротивление при высоком давлении пара
	var damage = amount
	if steam_pressure > max_steam_pressure * 0.7:
		damage *= 0.8  # 20% сопротивление
	
	super.take_damage(damage)

func emergency_steam_release():
	# Аварийный сброс пара
	if steam_pressure > max_steam_pressure * 0.9:
		steam_pressure *= 0.5
		# Урон окружающим юнитам
		var nearby_units = _get_nearby_units()
		for unit in nearby_units:
			unit.take_damage(15)
		return true
	return false

func _get_nearby_units() -> Array:
	# Получение ближайших юнитов
	var units = []
	for unit in get_tree().get_nodes_in_group("units"):
		if global_position.distance_to(unit.global_position) <= 50:
			units.append(unit)
	return units

func get_steam_efficiency() -> float:
	# Получение эффективности пара
	return steam_pressure / max_steam_pressure

func get_automation_bonus() -> float:
	# Получение бонуса от автоматизации
	return 1.0 + (automation_level * 0.3)

func calibrate_machines():
	# Калибровка машин
	if steam_pressure > 20:
		efficiency_rating = min(2.0, efficiency_rating + 0.05)
		steam_pressure -= 10
		return true
	return false

func overclock_machines():
	# Разгон машин
	if steam_pressure > 40 and efficiency_rating > 1.5:
		production_speed *= 1.5
		steam_pressure -= 30
		
		# Эффект длится 30 секунд
		await get_tree().create_timer(30.0).timeout
		production_speed /= 1.5
		
		return true
	return false

func connect_power_grid():
	# Подключение к энергосети
	var nearby_engine_rooms = _get_nearby_engine_rooms()
	if not nearby_engine_rooms.is_empty():
		# Получение бонуса от энергосети
		max_steam_pressure += 50
		efficiency_rating *= 1.2

func _get_nearby_engine_rooms() -> Array:
	# Получение ближайших машинных отделений
	var engine_rooms = []
	for building in get_tree().get_nodes_in_group("buildings"):
		if building.building_type == "engine_room" and global_position.distance_to(building.global_position) <= 150:
			engine_rooms.append(building)
	return engine_rooms

func get_overall_efficiency() -> float:
	# Получение общей эффективности
	var steam_bonus = get_steam_efficiency()
	var automation_bonus = get_automation_bonus()
	var health_bonus = health / max_health
	
	return steam_bonus * automation_bonus * health_bonus * efficiency_rating