# scripts/data/BuildingData.gd
extends Node

# Система данных для зданий

class BuildingTemplate:
	var id: String
	var name: String
	var race: String
	var building_type: String
	var required_resources: Dictionary
	var construction_time: float
	var max_workers: int
	var production_recipes: Array
	var sprite: String
	var description: String
	
	func _init(data: Dictionary):
		id = data.get("id", "")
		name = data.get("name", "")
		race = data.get("race", "")
		building_type = data.get("building_type", "")
		required_resources = data.get("required_resources", {})
		construction_time = data.get("construction_time", 10.0)
		max_workers = data.get("max_workers", 1)
		production_recipes = data.get("production_recipes", [])
		sprite = data.get("sprite", "")
		description = data.get("description", "")

var building_templates: Dictionary = {}

func _ready():
	load_building_templates()

func load_building_templates():
	# В реальной игре здесь будет загрузка из JSON файлов
	# Пока создаем шаблоны вручную для демонстрации
	
	# Ящеры
	var lizard_nest_data = {
		"id": "lizard_nest",
		"name": "Гнездо ящеров",
		"race": "lizards",
		"building_type": "housing",
		"required_resources": {
			"wood": 20,
			"stone": 10
		},
		"construction_time": 15.0,
		"max_workers": 0,
		"production_recipes": [],
		"sprite": "res://assets/sprites/lizards/nest.png",
		"description": "Жилище для ящеров, способствует быстрому восстановлению здоровья."
	}
	
	var lizard_bioreactor_data = {
		"id": "lizard_bioreactor",
		"name": "Биореактор",
		"race": "lizards",
		"building_type": "production",
		"required_resources": {
			"wood": 50,
			"stone": 30,
			"food": 20
		},
		"construction_time": 30.0,
		"max_workers": 3,
		"production_recipes": ["spores", "mutagens"],
		"sprite": "res://assets/sprites/lizards/bioreactor.png",
		"description": "Центр производства биологических ресурсов и мутагенов."
	}
	
	var lizard_lab_data = {
		"id": "lizard_lab",
		"name": "Биолаборатория",
		"race": "lizards",
		"building_type": "research",
		"required_resources": {
			"wood": 40,
			"stone": 25,
			"food": 15
		},
		"construction_time": 25.0,
		"max_workers": 2,
		"production_recipes": [],
		"sprite": "res://assets/sprites/lizards/lab.png",
		"description": "Лаборатория для исследований и разработок новых мутаций."
	}
	
	# Песиголовцы
	var canid_den_data = {
		"id": "canid_den",
		"name": "Логово песиголовцев",
		"race": "canids",
		"building_type": "housing",
		"required_resources": {
			"wood": 15,
			"stone": 15
		},
		"construction_time": 12.0,
		"max_workers": 0,
		"production_recipes": [],
		"sprite": "res://assets/sprites/canids/den.png",
		"description": "Уютное логово для членов стаи."
	}
	
	var canid_hunting_lodge_data = {
		"id": "canid_hunting_lodge",
		"name": "Охотничий домик",
		"race": "canids",
		"building_type": "production",
		"required_resources": {
			"wood": 30,
			"stone": 20
		},
		"construction_time": 20.0,
		"max_workers": 2,
		"production_recipes": ["food", "fur"],
		"sprite": "res://assets/sprites/canids/hunting_lodge.png",
		"description": "Место для подготовки охоты и переработки трофеев."
	}
	
	var canid_pack_house_data = {
		"id": "canid_pack_house",
		"name": "Дом стаи",
		"race": "canids",
		"building_type": "command",
		"required_resources": {
			"wood": 60,
			"stone": 40
		},
		"construction_time": 40.0,
		"max_workers": 1,
		"production_recipes": [],
		"sprite": "res://assets/sprites/canids/pack_house.png",
		"description": "Центр управления стаей, повышает боевые характеристики воинов."
	}
	
	# Русы
	var rus_house_data = {
		"id": "rus_house",
		"name": "Дом русов",
		"race": "rus",
		"building_type": "housing",
		"required_resources": {
			"wood": 25,
			"stone": 20,
			"metal": 10
		},
		"construction_time": 18.0,
		"max_workers": 0,
		"production_recipes": [],
		"sprite": "res://assets/sprites/rus/house.png",
		"description": "Прочное жилище с паровым отоплением."
	}
	
	var rus_workshop_data = {
		"id": "rus_workshop",
		"name": "Мастерская",
		"race": "rus",
		"building_type": "production",
		"required_resources": {
			"wood": 40,
			"stone": 30,
			"metal": 20
		},
		"construction_time": 25.0,
		"max_workers": 4,
		"production_recipes": ["tools", "parts", "steam"],
		"sprite": "res://assets/sprites/rus/workshop.png",
		"description": "Производственное здание для создания инструментов и запчастей."
	}
	
	var rus_engine_room_data = {
		"id": "rus_engine_room",
		"name": "Машинное отделение",
		"race": "rus",
		"building_type": "utility",
		"required_resources": {
			"wood": 50,
			"stone": 40,
			"metal": 30
		},
		"construction_time": 35.0,
		"max_workers": 2,
		"production_recipes": ["steam", "power"],
		"sprite": "res://assets/sprites/rus/engine_room.png",
		"description": "Генератор пара для питания других зданий."
	}
	
	# Создание шаблонов
	building_templates["lizard_nest"] = BuildingTemplate.new(lizard_nest_data)
	building_templates["lizard_bioreactor"] = BuildingTemplate.new(lizard_bioreactor_data)
	building_templates["lizard_lab"] = BuildingTemplate.new(lizard_lab_data)
	building_templates["canid_den"] = BuildingTemplate.new(canid_den_data)
	building_templates["canid_hunting_lodge"] = BuildingTemplate.new(canid_hunting_lodge_data)
	building_templates["canid_pack_house"] = BuildingTemplate.new(canid_pack_house_data)
	building_templates["rus_house"] = BuildingTemplate.new(rus_house_data)
	building_templates["rus_workshop"] = BuildingTemplate.new(rus_workshop_data)
	building_templates["rus_engine_room"] = BuildingTemplate.new(rus_engine_room_data)

func get_building_template(template_id: String) -> BuildingTemplate:
	return building_templates.get(template_id, null)

func create_building_from_template(template_id: String) -> BaseBuilding:
	var template = get_building_template(template_id)
	if not template:
		return null
	
	# В реальной игре здесь будет инстанцирование сцены
	# Пока возвращаем null, так как это демонстрационный код
	return null

func get_templates_for_race(race: String) -> Array:
	var templates = []
	for template in building_templates.values():
		if template.race == race:
			templates.append(template)
	return templates

func get_templates_by_type(building_type: String) -> Array:
	var templates = []
	for template in building_templates.values():
		if template.building_type == building_type:
			templates.append(template)
	return templates