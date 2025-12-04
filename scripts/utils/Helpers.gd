# scripts/utils/Helpers.gd
extends Node

# Вспомогательные функции

static func get_random_name(race: String) -> String:
	var names = []
	
	match race:
		"lizards":
			names = ["Грок", "Зара", "Торн", "Лира", "Крок", "Скаль", "Веном", "Салам", "Рипт", "Гекс"]
		"canids":
			names = ["Вольф", "Фенр", "Лупус", "Койот", "Джекал", "Хаунт", "Снейк", "Роар", "Фанг", "Клоз"]
		"rus":
			names = ["Гир", "Шестер", "Порш", "Вал", "Шпон", "Картер", "Ремень", "Фланец", "Маховик", "Турбин"]
		_:
			names = ["Юнит", "Солдат", "Рабочий", "Боец", "Житель", "Горожанин", "Персонаж", "Существо", "Обитатель", "Житель"]
	
	return names[randi() % names.size()]

static func clamp_vector(vector: Vector2, min_x: float, max_x: float, min_y: float, max_y: float) -> Vector2:
	return Vector2(
		clamp(vector.x, min_x, max_x),
		clamp(vector.y, min_y, max_y)
	)

static func get_direction_from_positions(from: Vector2, to: Vector2) -> Vector2:
	return (to - from).normalized()

static func get_distance_squared(pos1: Vector2, pos2: Vector2) -> float:
	return pos1.distance_squared_to(pos2)

static func lerp_color(color1: Color, color2: Color, t: float) -> Color:
	return Color(
		lerp(color1.r, color2.r, t),
		lerp(color1.g, color2.g, t),
		lerp(color1.b, color2.b, t),
		lerp(color1.a, color2.a, t)
	)

static func get_chunk_key(position: Vector2, chunk_size: int) -> Vector2i:
	return Vector2i(
		int(position.x / chunk_size),
		int(position.y / chunk_size)
	)

static func is_position_in_map(position: Vector2, map_width: int, map_height: int) -> bool:
	return position.x >= 0 and position.x < map_width and position.y >= 0 and position.y < map_height

static func get_resource_icon(resource_name: String) -> String:
	match resource_name:
		"wood":
			return "res://assets/sprites/ui/wood_icon.png"
		"stone":
			return "res://assets/sprites/ui/stone_icon.png"
		"food":
			return "res://assets/sprites/ui/food_icon.png"
		"metal":
			return "res://assets/sprites/ui/metal_icon.png"
		"steam":
			return "res://assets/sprites/ui/steam_icon.png"
		_:
			return "res://assets/sprites/ui/default_resource_icon.png"