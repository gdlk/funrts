# scripts/data/UnitData.gd
extends Node

# Система данных для юнитов

class UnitTemplate:
	var id: String
	var name: String
	var race: String
	var base_stats: Dictionary
	var skills: Dictionary
	var sprite: String
	var description: String
	
	func _init(data: Dictionary):
		id = data.get("id", "")
		name = data.get("name", "")
		race = data.get("race", "")
		base_stats = data.get("base_stats", {})
		skills = data.get("skills", {})
		sprite = data.get("sprite", "")
		description = data.get("description", "")

var unit_templates: Dictionary = {}

func _ready():
	load_unit_templates()

func load_unit_templates():
	# В реальной игре здесь будет загрузка из JSON файлов
	# Пока создаем шаблоны вручную для демонстрации
	
	# Ящеры
	var lizard_worker_data = {
		"id": "lizard_worker",
		"name": "Ящер-рабочий",
		"race": "lizards",
		"base_stats": {
			"health": 100,
			"strength": 5,
			"agility": 4,
			"intelligence": 3,
			"endurance": 6
		},
		"skills": {
			"mining": 10,
			"building": 15,
			"combat": 5,
			"crafting": 8
		},
		"sprite": "res://assets/sprites/lizards/worker.png",
		"description": "Основной рабочий ящеров, специализирующийся на добыче ресурсов и строительстве."
	}
	
	var lizard_warrior_data = {
		"id": "lizard_warrior",
		"name": "Ящер-воин",
		"race": "lizards",
		"base_stats": {
			"health": 120,
			"strength": 8,
			"agility": 5,
			"intelligence": 2,
			"endurance": 7
		},
		"skills": {
			"mining": 5,
			"building": 5,
			"combat": 20,
			"crafting": 5
		},
		"sprite": "res://assets/sprites/lizards/warrior.png",
		"description": "Боевая единица ящеров с высокой выносливостью и силой."
	}
	
	var lizard_scientist_data = {
		"id": "lizard_scientist",
		"name": "Ящер-ученый",
		"race": "lizards",
		"base_stats": {
			"health": 80,
			"strength": 2,
			"agility": 3,
			"intelligence": 10,
			"endurance": 4
		},
		"skills": {
			"mining": 5,
			"building": 8,
			"combat": 2,
			"crafting": 15
		},
		"sprite": "res://assets/sprites/lizards/scientist.png",
		"description": "Исследователь и изобретатель, специализирующийся на биотехнологиях."
	}
	
	# Песиголовцы
	var canid_worker_data = {
		"id": "canid_worker",
		"name": "Песиголовец-рабочий",
		"race": "canids",
		"base_stats": {
			"health": 90,
			"strength": 4,
			"agility": 7,
			"intelligence": 4,
			"endurance": 5
		},
		"skills": {
			"mining": 8,
			"building": 10,
			"combat": 8,
			"crafting": 10
		},
		"sprite": "res://assets/sprites/canids/worker.png",
		"description": "Быстрый и универсальный рабочий песиголовцев."
	}
	
	var canid_warrior_data = {
		"id": "canid_warrior",
		"name": "Песиголовец-воин",
		"race": "canids",
		"base_stats": {
			"health": 100,
			"strength": 6,
			"agility": 9,
			"intelligence": 3,
			"endurance": 6
		},
		"skills": {
			"mining": 3,
			"building": 3,
			"combat": 25,
			"crafting": 5
		},
		"sprite": "res://assets/sprites/canids/warrior.png",
		"description": "Быстрый и смертоносный воин, использующий скоростную тактику."
	}
	
	var canid_alpha_data = {
		"id": "canid_alpha",
		"name": "Альфа-песиголовец",
		"race": "canids",
		"base_stats": {
			"health": 150,
			"strength": 10,
			"agility": 6,
			"intelligence": 7,
			"endurance": 8
		},
		"skills": {
			"mining": 5,
			"building": 12,
			"combat": 30,
			"crafting": 8
		},
		"sprite": "res://assets/sprites/canids/alpha.png",
		"description": "Лидер стаи, обладающий повышенными боевыми и управленческими способностями."
	}
	
	# Русы
	var rus_worker_data = {
		"id": "rus_worker",
		"name": "Рус-рабочий",
		"race": "rus",
		"base_stats": {
			"health": 110,
			"strength": 6,
			"agility": 3,
			"intelligence": 6,
			"endurance": 8
		},
		"skills": {
			"mining": 12,
			"building": 20,
			"combat": 6,
			"crafting": 18
		},
		"sprite": "res://assets/sprites/rus/worker.png",
		"description": "Инженер и строитель, специализирующийся на механизации производства."
	}
	
	var rus_engineer_data = {
		"id": "rus_engineer",
		"name": "Рус-инженер",
		"race": "rus",
		"base_stats": {
			"health": 95,
			"strength": 3,
			"agility": 4,
			"intelligence": 9,
			"endurance": 5
		},
		"skills": {
			"mining": 8,
			"building": 25,
			"combat": 3,
			"crafting": 30
		},
		"sprite": "res://assets/sprites/rus/engineer.png",
		"description": "Специалист по сложным механизмам и автоматизации."
	}
	
	var rus_guard_data = {
		"id": "rus_guard",
		"name": "Рус-страж",
		"race": "rus",
		"base_stats": {
			"health": 130,
			"strength": 7,
			"agility": 4,
			"intelligence": 5,
			"endurance": 9
		},
		"skills": {
			"mining": 5,
			"building": 10,
			"combat": 15,
			"crafting": 12
		},
		"sprite": "res://assets/sprites/rus/guard.png",
		"description": "Защитник поселения, использующий паровые механизмы в бою."
	}
	
	# Создание шаблонов
	unit_templates["lizard_worker"] = UnitTemplate.new(lizard_worker_data)
	unit_templates["lizard_warrior"] = UnitTemplate.new(lizard_warrior_data)
	unit_templates["lizard_scientist"] = UnitTemplate.new(lizard_scientist_data)
	unit_templates["canid_worker"] = UnitTemplate.new(canid_worker_data)
	unit_templates["canid_warrior"] = UnitTemplate.new(canid_warrior_data)
	unit_templates["canid_alpha"] = UnitTemplate.new(canid_alpha_data)
	unit_templates["rus_worker"] = UnitTemplate.new(rus_worker_data)
	unit_templates["rus_engineer"] = UnitTemplate.new(rus_engineer_data)
	unit_templates["rus_guard"] = UnitTemplate.new(rus_guard_data)

func get_unit_template(template_id: String) -> UnitTemplate:
	return unit_templates.get(template_id, null)

func create_unit_from_template(template_id: String) -> BaseUnit:
	var template = get_unit_template(template_id)
	if not template:
		return null
	
	# В реальной игре здесь будет инстанцирование сцены
	# Пока возвращаем null, так как это демонстрационный код
	return null

func get_templates_for_race(race: String) -> Array:
	var templates = []
	for template in unit_templates.values():
		if template.race == race:
			templates.append(template)
	return templates