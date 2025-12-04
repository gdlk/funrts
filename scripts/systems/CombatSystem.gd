# scripts/systems/CombatSystem.gd
extends Node

# Система боя и взаимодействия юнитов

func process_combat(attacker, target, delta: float):
	if not _is_valid_target(attacker, target):
		return
	
	# Проверяем расстояние до цели
	if attacker.global_position.distance_to(target.global_position) <= attacker.attack_range:
		# Атакуем
		_attack(attacker, target)
	else:
		# Двигаемся к цели
		_move_to_target(attacker, target)

func _is_valid_target(attacker, target) -> bool:
	# Проверка валидности цели
	if not target or not is_instance_valid(target):
		return false
	
	if not target.is_in_group("units") and not target.is_in_group("buildings"):
		return false
	
	# Проверка принадлежности к вражеской фракции
	return attacker.race != target.race

func _attack(attacker, target):
	# Расчет урона
	var damage = attacker.strength + randf_range(-1, 1)
	
	# Применение урона
	target.take_damage(damage)
	
	# Эмитируем сигнал атаки
	EventBus.emit_signal("unit_attacked", attacker, target, damage)

func _move_to_target(attacker, target):
	# Движение к цели с использованием pathfinding
	var pathfinding = get_node("/root/PathfindingSystem")
	var path = pathfinding.find_path(attacker.global_position, target.global_position)
	
	if not path.is_empty():
		attacker.move_to(path[0])

func calculate_damage(attacker, target) -> float:
	# Расчет урона с учетом характеристик
	var base_damage = attacker.strength
	var defense = target.endurance * 0.5
	var damage = max(1, base_damage - defense)
	
	# Случайный фактор
	damage *= randf_range(0.8, 1.2)
	
	return damage

func is_alive(unit) -> bool:
	return unit.health > 0

func get_distance(unit1, unit2) -> float:
	return unit1.global_position.distance_to(unit2.global_position)
