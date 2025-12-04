# scenes/units/RusUnit.gd
extends BaseUnit

# Специализированный класс для русов

# Уникальные характеристики русов
var steam_pressure: float = 100.0
var max_steam_pressure: float = 100.0
var steam_efficiency: float = 1.0
var automation_level: int = 1

# Уникальные навыки русов
var engineering_skill: int = 0
var automation_skill: int = 0
var steam_handling: int = 0

func _ready():
	race = "rus"
	engineering_skill = 12
	automation_skill = 15
	steam_handling = 10
	steam_efficiency = 1.2  # Начальный бонус к эффективности пара
	
	# Вызов родительского _ready()
	super._ready()

func _process(delta):
	# Вызов родительского _process()
	super._process(delta)
	
	# Уникальная логика русов
	_manage_steam(delta)
	
	if current_state == Constants.UnitState.IDLE:
		_check_for_automation()

func _process_working(delta):
	# Специфическая логика работы для русов
	if current_task:
		# Работа более эффективна при высоком давлении пара
		var steam_bonus = steam_pressure / max_steam_pressure
		current_task.efficiency *= (1.0 + steam_bonus * 0.5)
		
		# Потребление пара при работе
		steam_pressure = max(0, steam_pressure - 5 * delta)
		
		# Генерация пара при работе на паровых установках
		if current_task.type == "steam_work":
			generate_steam(10 * delta)

func _manage_steam(delta: float):
	# Автоматическое управление паром
	steam_pressure = min(max_steam_pressure, steam_pressure + 5 * steam_efficiency * delta)
	
	# При низком давлении пара снижается эффективность
	if steam_pressure < max_steam_pressure * 0.3:
		work_speed_modifier = 0.7
	elif steam_pressure < max_steam_pressure * 0.6:
		work_speed_modifier = 0.9
	else:
		work_speed_modifier = 1.0

func generate_steam(amount: float):
	# Генерация пара
	steam_pressure = min(max_steam_pressure, steam_pressure + amount)

func _check_for_automation():
	# Проверка возможности автоматизации
	if automation_level >= 2:
		_manage_automated_tasks()

func _manage_automated_tasks():
	# Управление автоматизированными задачами
	var nearby_machines = _get_nearby_machines(100)
	for machine in nearby_machines:
		if machine.needs_maintenance():
			_automate_maintenance(machine)

func _get_nearby_machines(radius: float) -> Array:
	# Получение ближайших машин
	var machines = []
	for building in get_tree().get_nodes_in_group("buildings"):
		if global_position.distance_to(building.global_position) <= radius:
			machines.append(building)
	return machines

func _automate_maintenance(machine):
	# Автоматическое обслуживание машин
	if steam_pressure > 20:
		machine.perform_maintenance()
		steam_pressure -= 10

func connect_to_conveyor():
	# Подключение к конвейерной системе
	var nearby_conveyors = _get_nearby_conveyors(30)
	if not nearby_conveyors.is_empty():
		# Получение бонуса от конвейера
		work_speed_modifier *= 1.3
		steam_efficiency *= 1.1

func _get_nearby_conveyors(radius: float) -> Array:
	# Получение ближайших конвейеров
	# В реальной реализации здесь будет логика поиска конвейеров
	return []

func upgrade_automation():
	# Повышение уровня автоматизации
	automation_level += 1
	
	match automation_level:
		2:
			# Разблокировка базовой автоматизации
			steam_efficiency += 0.2
		3:
			# Продвинутая автоматизация
			work_speed_modifier *= 1.2
			max_steam_pressure += 50
		4:
			# Экспертная автоматизация
			steam_efficiency += 0.3
			# Возможность управлять несколькими машинами одновременно
		5:
			# Мастер автоматизации
			work_speed_modifier *= 1.3
			steam_efficiency *= 1.5

func take_damage(amount: float):
	# Русы получают бонус к защите при высоком уровне пара
	var damage = amount
	if steam_pressure > max_steam_pressure * 0.7:
		damage *= 0.8  # 20% сопротивление при высоком давлении пара
	
	super.take_damage(damage)

func die():
	# При смерти руса происходит выброс пара
	if steam_pressure > 50:
		_steam_explosion()
	
	super.die()

func _steam_explosion():
	# Выброс пара при смерти
	var nearby_units = _get_nearby_units(50)
	for unit in nearby_units:
		if unit.race == "rus":
			# Союзники получают бонус к пару
			unit.steam_pressure = min(unit.max_steam_pressure, unit.steam_pressure + 20)
		else:
			# Враги получают урон от пара
			unit.take_damage(10)

func _get_nearby_units(radius: float) -> Array:
	# Получение ближайших юнитов
	var units = []
	for unit in get_tree().get_nodes_in_group("units"):
		if unit != self:
			if global_position.distance_to(unit.global_position) <= radius:
				units.append(unit)
	return units

func collective_work():
	# Коллективный труд русов
	var nearby_rus = _get_nearby_rus(60)
	if nearby_rus.size() >= 3:
		# Бонус к работе в группе
		for rus in nearby_rus:
			rus.work_speed_modifier *= 1.2

func _get_nearby_rus(radius: float) -> Array:
	# Получение ближайших русов
	var rus_units = []
	for unit in get_tree().get_nodes_in_group("units"):
		if unit.race == "rus" and unit != self:
			if global_position.distance_to(unit.global_position) <= radius:
				rus_units.append(unit)
	return rus_units

func repair_machine(machine):
	# Ремонт машин с использованием пара
	if steam_pressure > 30:
		machine.repair(20)
		steam_pressure -= 20
		return true
	return false

func get_steam_bonus() -> float:
	# Получение бонуса от пара
	return steam_pressure / max_steam_pressure