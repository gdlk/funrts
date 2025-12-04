# scripts/data/EventData.gd
extends Node

# Система данных для событий

class EventTemplate:
	var id: String
	var name: String
	var description: String
	var event_type: String  # "random", "seasonal", "triggered"
	var frequency: float  # Вероятность в час (для случайных событий)
	var conditions: Dictionary  # Условия для запуска
	var effects: Dictionary  # Эффекты события
	var duration: float  # Длительность в секундах (0 для мгновенных)
	var sprite: String
	
	func _init(data: Dictionary):
		id = data.get("id", "")
		name = data.get("name", "")
		description = data.get("description", "")
		event_type = data.get("event_type", "random")
		frequency = data.get("frequency", 0.0)
		conditions = data.get("conditions", {})
		effects = data.get("effects", {})
		duration = data.get("duration", 0.0)
		sprite = data.get("sprite", "")

var event_templates: Dictionary = {}

func _ready():
	load_event_templates()

func load_event_templates():
	# В реальной игре здесь будет загрузка из JSON файлов
	# Пока создаем шаблоны вручную для демонстрации
	
	# Случайные события
	var resource_discovery_data = {
		"id": "resource_discovery",
		"name": "Находка ресурсов",
		"description": "Ваши юниты обнаружили дополнительные ресурсы!",
		"event_type": "random",
		"frequency": 0.5,
		"conditions": {},
		"effects": {
			"resource_bonus": {
				"wood": 50,
				"stone": 30
			}
		},
		"duration": 0.0,
		"sprite": "res://assets/sprites/events/resource_discovery.png"
	}
	
	var unit_injury_data = {
		"id": "unit_injury",
		"name": "Травма юнита",
		"description": "Один из ваших юнитов получил травму и не может работать!",
		"event_type": "random",
		"frequency": 0.2,
		"conditions": {},
		"effects": {
			"unit_injured": true
		},
		"duration": 120.0,
		"sprite": "res://assets/sprites/events/unit_injury.png"
	}
	
	var resource_shortage_data = {
		"id": "resource_shortage",
		"name": "Дефицит ресурсов",
		"description": "Из-за неудачного сезона сбора урожая возник дефицит еды!",
		"event_type": "random",
		"frequency": 0.3,
		"conditions": {},
		"effects": {
			"food_reduction": 0.5
		},
		"duration": 300.0,
		"sprite": "res://assets/sprites/events/resource_shortage.png"
	}
	
	# Сезонные события
	var harsh_winter_data = {
		"id": "harsh_winter",
		"name": "Суровая зима",
		"description": "Зима оказалась особенно суровой. Все потребности юнитов увеличены.",
		"event_type": "seasonal",
		"frequency": 0.0,
		"conditions": {
			"season": "winter"
		},
		"effects": {
			"needs_multiplier": 1.5
		},
		"duration": 0.0,
		"sprite": "res://assets/sprites/events/harsh_winter.png"
	}
	
	var bountiful_harvest_data = {
		"id": "bountiful_harvest",
		"name": "Богатый урожай",
		"description": "Весна принесла богатый урожай. Производство еды увеличено.",
		"event_type": "seasonal",
		"frequency": 0.0,
		"conditions": {
			"season": "spring"
		},
		"effects": {
			"food_production_bonus": 2.0
		},
		"duration": 0.0,
		"sprite": "res://assets/sprites/events/bountiful_harvest.png"
	}
	
	# Триггерные события
	var first_combat_data = {
		"id": "first_combat",
		"name": "Первый бой",
		"description": "Ваши юниты вступили в первый бой! Это важный момент в истории вашей колонии.",
		"event_type": "triggered",
		"frequency": 0.0,
		"conditions": {
			"first_combat": true
		},
		"effects": {
			"experience_bonus": 10
		},
		"duration": 0.0,
		"sprite": "res://assets/sprites/events/first_combat.png"
	}
	
	var building_constructed_data = {
		"id": "building_constructed",
		"name": "Новое здание",
		"description": "Вы построили свое первое специализированное здание!",
		"event_type": "triggered",
		"frequency": 0.0,
		"conditions": {
			"building_type": "production"
		},
		"effects": {
			"morale_bonus": 10
		},
		"duration": 0.0,
		"sprite": "res://assets/sprites/events/building_constructed.png"
	}
	
	# Создание шаблонов
	event_templates["resource_discovery"] = EventTemplate.new(resource_discovery_data)
	event_templates["unit_injury"] = EventTemplate.new(unit_injury_data)
	event_templates["resource_shortage"] = EventTemplate.new(resource_shortage_data)
	event_templates["harsh_winter"] = EventTemplate.new(harsh_winter_data)
	event_templates["bountiful_harvest"] = EventTemplate.new(bountiful_harvest_data)
	event_templates["first_combat"] = EventTemplate.new(first_combat_data)
	event_templates["building_constructed"] = EventTemplate.new(building_constructed_data)

func get_event_template(template_id: String) -> EventTemplate:
	return event_templates.get(template_id, null)

func get_random_events() -> Array:
	var events = []
	for event in event_templates.values():
		if event.event_type == "random":
			events.append(event)
	return events

func get_seasonal_events() -> Array:
	var events = []
	for event in event_templates.values():
		if event.event_type == "seasonal":
			events.append(event)
	return events

func get_triggered_events() -> Array:
	var events = []
	for event in event_templates.values():
		if event.event_type == "triggered":
			events.append(event)
	return events

func roll_for_random_event() -> EventTemplate:
	var random_events = get_random_events()
	if random_events.is_empty():
		return null
	
	# Простой рандомный выбор события
	var event = random_events[randi() % random_events.size()]
	
	# Проверка частоты (упрощенная реализация)
	if randf() < event.frequency / 100.0:
		return event
	
	return null