# scenes/units/CanidUnit.gd
extends BaseUnit

# Специализированный класс для песиголовцев

# Уникальные характеристики песиголовцев
var pack_id: int = -1
var pack_rank: int = 0  # 0 - Омега, 1 - Бета, 2 - Альфа
var territory_markers: Array = []
var howl_cooldown: float = 0.0

# Уникальные навыки песиголовцев
var pack_tactics: int = 0
var scent_tracking: int = 0
var territorial_instinct: int = 0

func _ready():
	race = "canids"
	pack_tactics = 15
	scent_tracking = 10
	territorial_instinct = 8
	
	# Вызов родительского _ready()
	super._ready()

func _process(delta):
	# Вызов родительского _process()
	super._process(delta)
	
	# Уникальная логика песиголовцев
	if howl_cooldown > 0:
		howl_cooldown -= delta
	
	if current_state == Constants.UnitState.IDLE:
		_check_pack_status()
		_maintain_territory()

func _process_working(delta):
	# Специфическая логика работы для песиголовцев
	if current_task and current_task.type == "hunting":
		# Охота более эффективна в стае
		var pack_bonus = 1.0
		if pack_id != -1:
			var pack_size = _get_pack_size()
			pack_bonus = 1.0 + (pack_size * 0.1)
		
		# Увеличение эффективности охоты
		current_task.efficiency *= pack_bonus
	elif current_task and current_task.type == "territory_marking":
		# Разметка территории
		_mark_territory()

func _process_fighting(delta):
	# Боевая логика песиголовцев
	if current_task and current_task.type == "combat":
		# Бонус в бою при наличии стаи
		if pack_id != -1:
			var nearby_allies = _get_nearby_pack_members(100)
			if nearby_allies.size() > 2:
				# Стая дает бонус к урону
				current_task.damage_multiplier *= 1.2

func _check_pack_status():
	# Проверка статуса в стае
	if pack_id == -1:
		_try_join_pack()
	else:
		_maintain_pack_hierarchy()

func _try_join_pack():
	# Попытка присоединиться к стае
	var nearby_canids = _get_nearby_canids(80)
	for canid in nearby_canids:
		if canid.pack_id != -1 and canid.pack_rank >= 1:  # Только Альфы и Беты могут принимать
			join_pack(canid.pack_id, 0)  # Присоединяемся как Омега
			return

func join_pack(new_pack_id: int, rank: int):
	pack_id = new_pack_id
	pack_rank = rank
	
	# Бонусы от стаи
	match rank:
		0:  # Омега
			work_speed_modifier *= 0.8
		1:  # Бета
			strength += 2
			work_speed_modifier *= 1.1
		2:  # Альфа
			strength += 4
			agility += 2
			max_health += 30

func _maintain_pack_hierarchy():
	# Поддержание иерархии в стае
	if pack_rank == 2:  # Альфа
		_lead_pack()
	elif pack_rank == 1:  # Бета
		_assist_alpha()
	else:  # Омега
		_follow_leaders()

func _lead_pack():
	# Лидирование стаей
	var pack_members = _get_pack_members()
	for member in pack_members:
		if member != self:
			# Альфа дает бонусы стае
			member.work_speed_modifier = 1.1

func _assist_alpha():
	# Помощь альфе
	pass

func _follow_leaders():
	# Следование за лидерами
	pass

func _get_nearby_canids(radius: float) -> Array:
	# Получение ближайших песиголовцев
	var canids = []
	for unit in get_tree().get_nodes_in_group("units"):
		if unit != self and unit.race == "canids":
			if global_position.distance_to(unit.global_position) <= radius:
				canids.append(unit)
	return canids

func _get_pack_members() -> Array:
	# Получение членов своей стаи
	if pack_id == -1:
		return []
	
	var members = []
	for unit in get_tree().get_nodes_in_group("units"):
		if unit.race == "canids" and unit.pack_id == pack_id:
			members.append(unit)
	return members

func _get_pack_size() -> int:
	return _get_pack_members().size()

func _maintain_territory():
	# Поддержание территории
	if territory_markers.is_empty():
		_place_territory_marker()

func _place_territory_marker():
	# Размещение метки территории
	var marker = {
		"position": global_position,
		"strength": 100,
		"timestamp": Time.get_ticks_msec()
	}
	territory_markers.append(marker)

func _mark_territory():
	# Активная разметка территории
	var nearby_markers = _get_nearby_markers(50)
	for marker in nearby_markers:
		marker.strength = min(100, marker.strength + 10)

func _get_nearby_markers(radius: float) -> Array:
	# Получение ближайших меток
	var markers = []
	for marker in territory_markers:
		if global_position.distance_to(marker.position) <= radius:
			markers.append(marker)
	return markers

func howl():
	# Вой песиголовцев
	if howl_cooldown <= 0:
		howl_cooldown = 30.0  # 30 секунд перезарядки
		
		# Эффекты от воя
		var nearby_allies = _get_nearby_pack_members(150)
		for ally in nearby_allies:
			ally.morale += 10
			ally.work_speed_modifier *= 1.1
			# Временный эффект
			await get_tree().create_timer(10.0).timeout
			ally.work_speed_modifier /= 1.1

func _get_nearby_pack_members(radius: float) -> Array:
	# Получение ближайших членов стаи
	if pack_id == -1:
		return []
	
	var members = []
	for unit in get_tree().get_nodes_in_group("units"):
		if unit.race == "canids" and unit.pack_id == pack_id:
			if global_position.distance_to(unit.global_position) <= radius:
				members.append(unit)
	return members

func take_damage(amount: float):
	# Песиголовцы получают меньше урона в стае
	var damage = amount
	var pack_bonus = 1.0
	
	if pack_id != -1:
		var pack_size = _get_pack_size()
		pack_bonus = 1.0 - (pack_size * 0.05)  # До 50% снижения урона в большой стае
		damage *= max(0.5, pack_bonus)  # Минимум 50% урона
	
	super.take_damage(damage)

func die():
	# При смерти песиголовца стая теряет мораль
	if pack_id != -1:
		var pack_members = _get_pack_members()
		for member in pack_members:
			if member != self:
				member.morale -= 5
	
	super.die()

func reproduce():
	# Быстрое размножение песиголовцев
	# В реальной реализации здесь будет создание нового юнита
	pass

func get_pack_bonus() -> float:
	# Получение бонуса от стаи
	if pack_id == -1:
		return 1.0
	
	var pack_size = _get_pack_size()
	return 1.0 + (pack_size * 0.1)  # 10% бонус за каждого члена стаи