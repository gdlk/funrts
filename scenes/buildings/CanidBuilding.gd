# scenes/buildings/CanidBuilding.gd
extends BaseBuilding

# Специализированный класс для зданий песиголовцев

# Уникальные характеристики зданий песиголовцев
var pack_influence_radius: float = 100.0
var territory_strength: float = 100.0
var max_territory_strength: float = 100.0
var howl_amplifiers: int = 0

func _ready():
	race = "canids"
	pack_influence_radius = 100.0
	territory_strength = 100.0
	max_territory_strength = 100.0
	howl_amplifiers = 1
	
	# Вызов родительского _ready()
	super._ready()

func _process(delta):
	# Вызов родительского _process()
	super._process(delta)
	
	# Уникальная логика зданий песиголовцев
	if current_state == Constants.BuildingState.OPERATIONAL:
		_maintain_territory(delta)
		_amplify_howls(delta)

func _process_operation(delta):
	# Специфическая логика работы для зданий песиголовцев
	if not production_queue.is_empty():
		production_progress += delta * production_speed * assigned_workers.size() * _get_pack_bonus()
		if production_progress >= 100:
			complete_production()

func _get_pack_bonus() -> float:
	# Бонус от стаи и территории
	var pack_bonus = 1.0
	var territory_bonus = territory_strength / max_territory_strength
	return pack_bonus + (territory_bonus * 0.5)

func _maintain_territory(delta: float):
	# Поддержание территории
	territory_strength = min(max_territory_strength, territory_strength + 10 * delta)
	
	# Влияние на юнитов в радиусе
	var nearby_units = _get_nearby_units()
	for unit in nearby_units:
		if unit.race == "canids":
			# Союзники получают бонусы
			unit.morale = min(100, unit.morale + 5 * delta)
		else:
			# Враги получают дебаффы
			unit.work_speed_modifier *= 0.9

func _amplify_howls(delta: float):
	# Усиление воя песиголовцев
	if howl_amplifiers > 0:
		var nearby_canids = _get_nearby_canids()
		for canid in nearby_canids:
			if canid.howl_cooldown > 0:
				canid.howl_cooldown = max(0, canid.howl_cooldown - 5 * delta)

func _get_nearby_units() -> Array:
	# Получение юнитов в радиусе влияния
	var units = []
	for unit in get_tree().get_nodes_in_group("units"):
		if global_position.distance_to(unit.global_position) <= pack_influence_radius:
			units.append(unit)
	return units

func _get_nearby_canids() -> Array:
	# Получение песиголовцев в радиусе влияния
	var canids = []
	for unit in get_tree().get_nodes_in_group("units"):
		if unit.race == "canids" and global_position.distance_to(unit.global_position) <= pack_influence_radius:
			canids.append(unit)
	return canids

func mark_territory():
	# Разметка территории
	territory_strength = max_territory_strength
	
	# Создание визуальных маркеров территории
	EventBus.emit_signal("territory_marked", global_position, pack_influence_radius)

func upgrade_territory():
	# Улучшение территории
	max_territory_strength += 50
	pack_influence_radius += 30
	territory_strength = max_territory_strength

func add_howl_amplifier():
	# Добавление усилителя воя
	howl_amplifiers += 1

func call_to_arms():
	# Призыв к оружию
	var nearby_canids = _get_nearby_canids()
	for canid in nearby_canids:
		canid.current_state = Constants.UnitState.FIGHTING
		# Назначаем задачу атаки ближайшего врага
		canid.request_combat_task()

func organize_hunt():
	# Организация охоты
	var hunt_party = []
	var nearby_canids = _get_nearby_canids()
	
	# Формируем охотничью группу
	for i in range(min(5, nearby_canids.size())):
		var canid = nearby_canids[i]
		if canid.current_state == Constants.UnitState.IDLE:
			hunt_party.append(canid)
			canid.current_state = Constants.UnitState.WORKING
			canid.request_hunt_task()
	
	if not hunt_party.is_empty():
		EventBus.emit_signal("hunt_organized", hunt_party)
		return true
	return false

func establish_pack_hierarchy():
	# Установление иерархии в стае
	var nearby_canids = _get_nearby_canids()
	if nearby_canids.size() < 3:
		return
	
	# Определяем Альфу (самый сильный)
	var alpha = nearby_canids[0]
	for canid in nearby_canids:
		if canid.strength > alpha.strength:
			alpha = canid
	
	# Назначаем Альфу
	alpha.pack_rank = 2
	alpha.join_pack(hash(str(global_position)), 2)
	
	# Определяем Бету (второй по силе)
	var beta = null
	for canid in nearby_canids:
		if canid != alpha and (not beta or canid.strength > beta.strength):
			beta = canid
	
	if beta:
		beta.pack_rank = 1
		beta.join_pack(hash(str(global_position)), 1)
	
	# Остальные становятся Омегами
	for canid in nearby_canids:
		if canid != alpha and canid != beta:
			canid.pack_rank = 0
			canid.join_pack(hash(str(global_position)), 0)

func take_damage(amount: float):
	# Здания песиголовцев теряют силу территории при повреждении
	var damage = amount
	territory_strength = max(0, territory_strength - damage * 2)
	
	super.take_damage(damage)

func repair_territory():
	# Ремонт территории
	if ResourceManager.get_resource("food") > 20:
		territory_strength = min(max_territory_strength, territory_strength + 50)
		ResourceManager.remove_resource("food", 20)
		return true
	return false

func get_territory_influence() -> float:
	# Получение силы влияния территории
	return territory_strength / max_territory_strength

func get_pack_efficiency() -> float:
	# Получение эффективности стаи
	var nearby_canids = _get_nearby_canids()
	if nearby_canids.is_empty():
		return 1.0
	
	var total_morale = 0.0
	for canid in nearby_canids:
		total_morale += canid.morale
	
	return 1.0 + (total_morale / nearby_canids.size() / 100.0)

func call_pack_meeting():
	# Созыв собрания стаи
	var nearby_canids = _get_nearby_canids()
	for canid in nearby_canids:
		canid.current_state = Constants.UnitState.IDLE
		canid.move_to(global_position)
	
	# Бонус к морали для всех участников
	await get_tree().create_timer(5.0).timeout
	for canid in nearby_canids:
		canid.morale = min(100, canid.morale + 20)
	
	EventBus.emit_signal("pack_meeting_held", nearby_canids.size())