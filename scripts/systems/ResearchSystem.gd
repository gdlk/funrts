# scripts/systems/ResearchSystem.gd
extends Node

# Система исследований и технологий

class Technology:
	var id: String
	var name: String
	var description: String
	var race: String  # "" для общих технологий
	var level: int = 1
	var max_level: int = 5
	var research_time: float = 0.0
	var required_resources: Dictionary = {}
	var required_technologies: Array = []
	var unlocked_buildings: Array = []
	var unlocked_units: Array = []
	var bonuses: Dictionary = {}
	var is_researched: bool = false
	var research_progress: float = 0.0
	
	func _init(data: Dictionary):
		id = data.get("id", "")
		name = data.get("name", "")
		description = data.get("description", "")
		race = data.get("race", "")
		level = data.get("level", 1)
		max_level = data.get("max_level", 5)
		research_time = data.get("research_time", 60.0)
		required_resources = data.get("required_resources", {})
		required_technologies = data.get("required_technologies", [])
		unlocked_buildings = data.get("unlocked_buildings", [])
		unlocked_units = data.get("unlocked_units", [])
		bonuses = data.get("bonuses", {})

var technologies: Dictionary = {}
var research_queue: Array = []
var completed_research: Array = []

func _ready():
	load_technologies()

func load_technologies():
	# Загрузка технологий для всех рас
	
	# Общие технологии
	var basic_construction_data = {
		"id": "basic_construction",
		"name": "Основы строительства",
		"description": "Позволяет строить базовые здания.",
		"race": "",
		"level": 1,
		"max_level": 3,
		"research_time": 30.0,
		"required_resources": {"wood": 50, "stone": 30},
		"unlocked_buildings": ["basic_house", "storage"],
		"bonuses": {"building_speed": 1.1}
	}
	
	var resource_processing_data = {
		"id": "resource_processing",
		"name": "Переработка ресурсов",
		"description": "Улучшает эффективность переработки ресурсов.",
		"race": "",
		"level": 1,
		"max_level": 5,
		"research_time": 60.0,
		"required_resources": {"wood": 100, "stone": 50},
		"required_technologies": ["basic_construction"],
		"bonuses": {"resource_efficiency": 1.2}
	}
	
	# Технологии ящеров
	var bioreactor_efficiency_data = {
		"id": "bioreactor_efficiency",
		"name": "Эффективность биореактора",
		"description": "Увеличивает производство спор в биореакторах.",
		"race": "lizards",
		"level": 1,
		"max_level": 5,
		"research_time": 90.0,
		"required_resources": {"spores": 100},
		"required_technologies": ["basic_construction"],
		"bonuses": {"spore_production": 1.3}
	}
	
	var advanced_mutations_data = {
		"id": "advanced_mutations",
		"name": "Продвинутые мутации",
		"description": "Открывает доступ к мощным мутациям.",
		"race": "lizards",
		"level": 1,
		"max_level": 3,
		"research_time": 120.0,
		"required_resources": {"spores": 200, "mutagens": 50},
		"required_technologies": ["bioreactor_efficiency"],
		"unlocked_buildings": ["advanced_lab"],
		"unlocked_units": ["mutant_warrior"]
	}
	
	var terraforming_data = {
		"id": "terraforming",
		"name": "Терраформирование",
		"description": "Позволяет изменять местность для улучшения производства.",
		"race": "lizards",
		"level": 1,
		"max_level": 3,
		"research_time": 150.0,
		"required_resources": {"spores": 300, "mutagens": 100},
		"required_technologies": ["advanced_mutations"],
		"bonuses": {"tile_fertility": 1.5}
	}
	
	# Технологии песиголовцев
	var pack_tactics_data = {
		"id": "pack_tactics",
		"name": "Тактика стаи",
		"description": "Улучшает боевую эффективность стай.",
		"race": "canids",
		"level": 1,
		"max_level": 5,
		"research_time": 80.0,
		"required_resources": {"food": 150},
		"required_technologies": ["basic_construction"],
		"bonuses": {"pack_damage": 1.2}
	}
	
	var territorial_expansion_data = {
		"id": "territorial_expansion",
		"name": "Расширение территории",
		"description": "Увеличивает радиус влияния территории.",
		"race": "canids",
		"level": 1,
		"max_level": 3,
		"research_time": 100.0,
		"required_resources": {"food": 200, "fur": 100},
		"required_technologies": ["pack_tactics"],
		"bonuses": {"territory_radius": 1.3}
	}
	
	var advanced_howling_data = {
		"id": "advanced_howling",
		"name": "Продвинутый вой",
		"description": "Улучшает эффекты от воя песиголовцев.",
		"race": "canids",
		"level": 1,
		"max_level": 3,
		"research_time": 110.0,
		"required_resources": {"food": 250, "fur": 150},
		"required_technologies": ["territorial_expansion"],
		"bonuses": {"howl_effect": 1.4}
	}
	
	# Технологии русов
	var steam_engine_data = {
		"id": "steam_engine",
		"name": "Паровой двигатель",
		"description": "Основа паровых технологий русов.",
		"race": "rus",
		"level": 1,
		"max_level": 5,
		"research_time": 100.0,
		"required_resources": {"metal": 100, "wood": 150},
		"required_technologies": ["basic_construction"],
		"unlocked_buildings": ["engine_room"],
		"bonuses": {"steam_efficiency": 1.2}
	}
	
	var automation_data = {
		"id": "automation",
		"name": "Автоматизация",
		"description": "Позволяет создавать автоматизированные производственные линии.",
		"race": "rus",
		"level": 1,
		"max_level": 5,
		"research_time": 140.0,
		"required_resources": {"metal": 200, "parts": 100},
		"required_technologies": ["steam_engine"],
		"unlocked_buildings": ["automated_workshop"],
		"bonuses": {"production_speed": 1.3}
	}
	
	var conveyor_system_data = {
		"id": "conveyor_system",
		"name": "Конвейерная система",
		"description": "Соединяет здания для автоматической передачи ресурсов.",
		"race": "rus",
		"level": 1,
		"max_level": 3,
		"research_time": 180.0,
		"required_resources": {"metal": 300, "parts": 200, "tools": 100},
		"required_technologies": ["automation"],
		"bonuses": {"resource_transfer": 1.5}
	}
	
	# Создание технологий
	technologies["basic_construction"] = Technology.new(basic_construction_data)
	technologies["resource_processing"] = Technology.new(resource_processing_data)
	technologies["bioreactor_efficiency"] = Technology.new(bioreactor_efficiency_data)
	technologies["advanced_mutations"] = Technology.new(advanced_mutations_data)
	technologies["terraforming"] = Technology.new(terraforming_data)
	technologies["pack_tactics"] = Technology.new(pack_tactics_data)
	technologies["territorial_expansion"] = Technology.new(territorial_expansion_data)
	technologies["advanced_howling"] = Technology.new(advanced_howling_data)
	technologies["steam_engine"] = Technology.new(steam_engine_data)
	technologies["automation"] = Technology.new(automation_data)
	technologies["conveyor_system"] = Technology.new(conveyor_system_data)

func start_research(tech_id: String) -> bool:
	# Начало исследования технологии
	var tech = technologies.get(tech_id, null)
	if not tech or tech.is_researched:
		return false
	
	# Проверка требований
	if not _check_requirements(tech):
		return false
	
	# Потребление ресурсов
	for resource in tech.required_resources:
		ResourceManager.remove_resource(resource, tech.required_resources[resource])
	
	# Добавление в очередь исследований
	research_queue.append(tech)
	
	# Эмитирование сигнала
	EventBus.emit_signal("research_started", tech)
	return true

func _check_requirements(tech: Technology) -> bool:
	# Проверка требований для исследования
	
	# Проверка наличия ресурсов
	for resource in tech.required_resources:
		if not ResourceManager.has_resource(resource, tech.required_resources[resource]):
			return false
	
	# Проверка изученных технологий
	for req_tech in tech.required_technologies:
		var required_tech = technologies.get(req_tech, null)
		if not required_tech or not required_tech.is_researched:
			return false
	
	# Проверка расы
	if tech.race != "" and tech.race != GameManager.current_race:
		return false
	
	return true

func update_research(delta: float):
	# Обновление процесса исследований
	for i in range(research_queue.size() - 1, -1, -1):
		var tech = research_queue[i]
		tech.research_progress += delta
		
		if tech.research_progress >= tech.research_time:
			complete_research(tech)
			research_queue.remove_at(i)

func complete_research(tech: Technology):
	# Завершение исследования
	tech.is_researched = true
	tech.research_progress = tech.research_time
	completed_research.append(tech)
	
	# Применение бонусов
	_apply_technology_bonuses(tech)
	
	# Эмитирование сигнала
	EventBus.emit_signal("research_completed", tech)

func _apply_technology_bonuses(tech: Technology):
	# Применение бонусов от технологии
	for bonus in tech.bonuses:
		# В реальной реализации здесь будет применение бонусов к соответствующим системам
		pass

func get_available_technologies() -> Array:
	# Получение доступных для исследования технологий
	var available = []
	for tech in technologies.values():
		if not tech.is_researched and _check_requirements(tech):
			available.append(tech)
	return available

func get_researched_technologies() -> Array:
	# Получение изученных технологий
	return completed_research.duplicate()

func get_technology(tech_id: String) -> Technology:
	# Получение технологии по ID
	return technologies.get(tech_id, null)

func get_research_progress(tech_id: String) -> float:
	# Получение прогресса исследования
	var tech = get_technology(tech_id)
	if tech:
		return tech.research_progress / tech.research_time
	return 0.0

func cancel_research(tech_id: String) -> bool:
	# Отмена исследования
	for i in range(research_queue.size()):
		var tech = research_queue[i]
		if tech.id == tech_id:
			# Возврат ресурсов (части)
			for resource in tech.required_resources:
				var refund = int(tech.required_resources[resource] * 0.5)
				ResourceManager.add_resource(resource, refund)
			
			research_queue.remove_at(i)
			EventBus.emit_signal("research_cancelled", tech)
			return true
	return false

func get_research_time(tech_id: String) -> float:
	# Получение времени исследования
	var tech = get_technology(tech_id)
	if tech:
		return tech.research_time
	return 0.0

func get_technology_cost(tech_id: String) -> Dictionary:
	# Получение стоимости исследования
	var tech = get_technology(tech_id)
	if tech:
		return tech.required_resources.duplicate()
	return {}

func has_technology(tech_id: String) -> bool:
	# Проверка, изучена ли технология
	var tech = get_technology(tech_id)
	return tech and tech.is_researched

func get_race_technologies(race: String) -> Array:
	# Получение технологий для конкретной расы
	var race_techs = []
	for tech in technologies.values():
		if tech.race == race or tech.race == "":
			race_techs.append(tech)
	return race_techs

func get_technology_tree(race: String = "") -> Array:
	# Получение дерева технологий
	var tree = []
	for tech in technologies.values():
		if race == "" or tech.race == race or tech.race == "":
			tree.append(tech)
	return tree