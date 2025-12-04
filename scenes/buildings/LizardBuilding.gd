# scenes/buildings/LizardBuilding.gd
extends BaseBuilding

# Специализированный класс для зданий ящеров

# Уникальные характеристики зданий ящеров
var bioreactor_level: int = 1
var mutation_chambers: Array = []
var symbiosis_chambers: int = 0
var terraforming_radius: float = 0.0

func _ready():
	race = "lizards"
	bioreactor_level = 1
	symbiosis_chambers = 1
	terraforming_radius = 50.0
	
	# Вызов родительского _ready()
	super._ready()

func _process(delta):
	# Вызов родительского _process()
	super._process(delta)
	
	# Уникальная логика зданий ящеров
	if current_state == Constants.BuildingState.OPERATIONAL:
		_generate_spores(delta)
		_manage_mutation_chambers(delta)

func _process_operation(delta):
	# Специфическая логика работы для зданий ящеров
	if not production_queue.is_empty():
		production_progress += delta * production_speed * assigned_workers.size() * _get_bioreactor_bonus()
		if production_progress >= 100:
			complete_production()

func _get_bioreactor_bonus() -> float:
	# Бонус от уровня биореактора
	return 1.0 + (bioreactor_level * 0.2)

func _generate_spores(delta: float):
	# Генерация спор в биореакторе
	if building_type == "bioreactor":
		var spore_production = 5.0 * bioreactor_level * assigned_workers.size() * delta
		ResourceManager.add_resource("spores", int(spore_production))

func _manage_mutation_chambers(delta: float):
	# Управление камерами мутаций
	for chamber in mutation_chambers:
		if chamber.active:
			chamber.progress += delta * 10
			if chamber.progress >= 100:
				_complete_mutation(chamber)

func _complete_mutation(chamber):
	# Завершение мутации
	chamber.progress = 0
	chamber.active = false
	
	# Создание мутировавшего юнита или улучшение существующего
	EventBus.emit_signal("mutation_completed", self, chamber.target_unit)

func add_mutation_chamber():
	# Добавление камеры мутаций
	var chamber = {
		"id": mutation_chambers.size(),
		"active": false,
		"progress": 0.0,
		"target_unit": null,
		"mutation_type": ""
	}
	mutation_chambers.append(chamber)

func activate_mutation_chamber(chamber_id: int, unit, mutation_type: String):
	# Активация камеры мутаций
	if chamber_id >= 0 and chamber_id < mutation_chambers.size():
		var chamber = mutation_chambers[chamber_id]
		chamber.active = true
		chamber.target_unit = unit
		chamber.mutation_type = mutation_type

func upgrade_bioreactor():
	# Улучшение биореактора
	bioreactor_level += 1
	
	match bioreactor_level:
		2:
			production_speed *= 1.3
			max_workers += 1
		3:
			# Разблокировка симбиотических камер
			symbiosis_chambers += 2
		4:
			# Улучшенная генерация спор
			_terraform_around_building()
		5:
			# Древний биореактор
			production_speed *= 1.5
			terraforming_radius *= 1.5

func _terraform_around_building():
	# Терраформирование вокруг здания
	var map = get_node("/root/Game/Map")
	if not map:
		return
	
	var building_tile = map.get_tile_position_from_world(global_position)
	var radius = int(terraforming_radius / Constants.TILE_SIZE)
	
	for x in range(building_tile.x - radius, building_tile.x + radius + 1):
		for y in range(building_tile.y - radius, building_tile.y + radius + 1):
			var tile = map.get_tile(x, y)
			if tile:
				var distance = Vector2(x, y).distance_to(Vector2(building_tile.x, building_tile.y))
				if distance <= radius:
					# Улучшение тайла
					tile.fertility += 0.05 * (bioreactor_level / 5.0)
					tile.resource_quality += 0.02 * (bioreactor_level / 5.0)

func create_symbiote(unit1, unit2):
	# Создание симбиотического существа
	if symbiosis_chambers > 0:
		# В реальной реализации здесь будет создание нового юнита-симбиота
		symbiosis_chambers -= 1
		EventBus.emit_signal("symbiosis_created", unit1, unit2)
		return true
	return false

func research_mutation(mutation_name: String) -> bool:
	# Исследование новой мутации
	var research_cost = {
		"basic": 100,
		"advanced": 300,
		"legendary": 1000
	}
	
	var cost = research_cost.get(mutation_name, 100)
	if ResourceManager.has_resource("spores", cost):
		ResourceManager.remove_resource("spores", cost)
		
		# В реальной реализации здесь будет добавление мутации в список доступных
		EventBus.emit_signal("mutation_researched", mutation_name)
		return true
	return false

func get_mutation_list() -> Array:
	# Получение списка доступных мутаций
	# В реальной реализации это будет загружаться из данных
	return ["regeneration", "strength", "speed", "intelligence", "armor"]

func produce_mutagen():
	# Производство мутагенов
	if building_type == "lab" and current_state == Constants.BuildingState.OPERATIONAL:
		if ResourceManager.has_resource("spores", 50):
			ResourceManager.remove_resource("spores", 50)
			ResourceManager.add_resource("mutagens", 5)
			return true
	return false

func take_damage(amount: float):
	# Здания ящеров имеют регенерацию при наличии спор
	var damage = amount
	if ResourceManager.get_resource("spores") > 10:
		damage *= 0.9  # 10% сопротивление
		ResourceManager.remove_resource("spores", 10)
	
	super.take_damage(damage)

func repair_with_biology():
	# Ремонт с помощью биологических ресурсов
	if ResourceManager.get_resource("spores") > 20:
		health = min(max_health, health + 30)
		ResourceManager.remove_resource("spores", 20)
		return true
	return false

func get_bioreactor_efficiency() -> float:
	# Получение эффективности биореактора
	return _get_bioreactor_bonus() * (health / max_health)