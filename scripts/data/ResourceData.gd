# scripts/data/ResourceData.gd
extends Node

# Система данных для ресурсов

# Импортируем константы
const Constants = preload("res://scripts/utils/Constants.gd")

class ResourceTemplate:
	var id: String
	var name: String
	var description: String
	var icon: String
	var rarity: int  # 1-5, где 1 - обычный, 5 - редкий
	var spawn_locations: Array  # Массив типов местности
	var base_value: int  # Базовая стоимость в торговле
	
	func _init(data: Dictionary):
		id = data.get("id", "")
		name = data.get("name", "")
		description = data.get("description", "")
		icon = data.get("icon", "")
		rarity = data.get("rarity", 1)
		spawn_locations = data.get("spawn_locations", [])
		base_value = data.get("base_value", 1)

var resource_templates: Dictionary = {}

func _ready():
	load_resource_templates()

func load_resource_templates():
	# В реальной игре здесь будет загрузка из JSON файлов
	# Пока создаем шаблоны вручную для демонстрации
	
	var wood_data = {
		"id": "wood",
		"name": "Дерево",
		"description": "Основной строительный материал. Добывается в лесах.",
		"icon": "res://assets/sprites/ui/wood_icon.png",
		"rarity": 1,
		"spawn_locations": [Constants.TERRAIN_FOREST],
		"base_value": 1
	}
	
	var stone_data = {
		"id": "stone",
		"name": "Камень",
		"description": "Прочный строительный материал. Добывается в горах.",
		"icon": "res://assets/sprites/ui/stone_icon.png",
		"rarity": 1,
		"spawn_locations": [Constants.TERRAIN_MOUNTAIN],
		"base_value": 2
	}
	
	var food_data = {
		"id": "food",
		"name": "Еда",
		"description": "Необходима для выживания юнитов. Производится на фермах и в охотничьих домиках.",
		"icon": "res://assets/sprites/ui/food_icon.png",
		"rarity": 1,
		"spawn_locations": [Constants.TERRAIN_PLAIN, Constants.TERRAIN_FOREST],
		"base_value": 3
	}
	
	var metal_data = {
		"id": "metal",
		"name": "Металл",
		"description": "Ценный ресурс для создания инструментов и механизмов. Добывается в горах.",
		"icon": "res://assets/sprites/ui/metal_icon.png",
		"rarity": 3,
		"spawn_locations": [Constants.TERRAIN_MOUNTAIN],
		"base_value": 5
	}
	
	var steam_data = {
		"id": "steam",
		"name": "Пар",
		"description": "Энергетический ресурс русов. Производится в машинных отделениях.",
		"icon": "res://assets/sprites/ui/steam_icon.png",
		"rarity": 2,
		"spawn_locations": [],
		"base_value": 4
	}
	
	var spores_data = {
		"id": "spores",
		"name": "Споры",
		"description": "Биологический ресурс ящеров. Используется для мутаций и размножения.",
		"icon": "res://assets/sprites/ui/spores_icon.png",
		"rarity": 2,
		"spawn_locations": [],
		"base_value": 6
	}
	
	var mutagens_data = {
		"id": "mutagens",
		"name": "Мутагены",
		"description": "Редкий биологический ресурс ящеров. Используется для создания мутаций.",
		"icon": "res://assets/sprites/ui/mutagens_icon.png",
		"rarity": 4,
		"spawn_locations": [],
		"base_value": 15
	}
	
	var fur_data = {
		"id": "fur",
		"name": "Мех",
		"description": "Ресурс песиголовцев. Используется для создания теплой одежды.",
		"icon": "res://assets/sprites/ui/fur_icon.png",
		"rarity": 2,
		"spawn_locations": [],
		"base_value": 5
	}
	
	var tools_data = {
		"id": "tools",
		"name": "Инструменты",
		"description": "Производственный ресурс русов. Повышает эффективность работы.",
		"icon": "res://assets/sprites/ui/tools_icon.png",
		"rarity": 3,
		"spawn_locations": [],
		"base_value": 8
	}
	
	var parts_data = {
		"id": "parts",
		"name": "Запчасти",
		"description": "Ресурс русов для создания механизмов и автоматизации.",
		"icon": "res://assets/sprites/ui/parts_icon.png",
		"rarity": 3,
		"spawn_locations": [],
		"base_value": 10
	}
	
	# Создание шаблонов
	resource_templates["wood"] = ResourceTemplate.new(wood_data)
	resource_templates["stone"] = ResourceTemplate.new(stone_data)
	resource_templates["food"] = ResourceTemplate.new(food_data)
	resource_templates["metal"] = ResourceTemplate.new(metal_data)
	resource_templates["steam"] = ResourceTemplate.new(steam_data)
	resource_templates["spores"] = ResourceTemplate.new(spores_data)
	resource_templates["mutagens"] = ResourceTemplate.new(mutagens_data)
	resource_templates["fur"] = ResourceTemplate.new(fur_data)
	resource_templates["tools"] = ResourceTemplate.new(tools_data)
	resource_templates["parts"] = ResourceTemplate.new(parts_data)

func get_resource_template(template_id: String) -> ResourceTemplate:
	return resource_templates.get(template_id, null)

func get_all_resources() -> Array:
	return resource_templates.values()

func get_resources_by_rarity(min_rarity: int, max_rarity: int) -> Array:
	var resources = []
	for resource in resource_templates.values():
		if resource.rarity >= min_rarity and resource.rarity <= max_rarity:
			resources.append(resource)
	return resources

func get_resource_value(resource_id: String) -> int:
	var template = get_resource_template(resource_id)
	if template:
		return template.base_value
	return 0

func get_resource_icon(resource_id: String) -> String:
	var template = get_resource_template(resource_id)
	if template:
		return template.icon
	return ""