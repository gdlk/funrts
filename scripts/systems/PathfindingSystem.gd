# scripts/systems/PathfindingSystem.gd
extends Node

# Импортируем константы
const Constants = preload("res://scripts/utils/Constants.gd")

# PathfindingSystem - автозагрузка

var astar: AStar2D = AStar2D.new()
var map_size: Vector2
var tile_size: int = Constants.TILE_SIZE

func initialize(map_width: int, map_height: int):
	map_size = Vector2(map_width, map_height)
	_build_astar_grid()

func _build_astar_grid():
	# Создаем узлы для каждого тайла
	for x in range(map_size.x):
		for y in range(map_size.y):
			var id = _get_point_id(x, y)
			astar.add_point(id, Vector2(x, y))
	
	# Соединяем соседние узлы
	for x in range(map_size.x):
		for y in range(map_size.y):
			var id = _get_point_id(x, y)
			# 4 направления (можно добавить диагонали)
			if x > 0:
				astar.connect_points(id, _get_point_id(x-1, y))
			if x < map_size.x - 1:
				astar.connect_points(id, _get_point_id(x+1, y))
			if y > 0:
				astar.connect_points(id, _get_point_id(x, y-1))
			if y < map_size.y - 1:
				astar.connect_points(id, _get_point_id(x, y+1))

func find_path(from: Vector2, to: Vector2) -> Array:
	var from_id = _get_point_id(int(from.x), int(from.y))
	var to_id = _get_point_id(int(to.x), int(to.y))
	return astar.get_point_path(from_id, to_id)

func _get_point_id(x: int, y: int) -> int:
	return x + y * int(map_size.x)

func set_point_disabled(x: int, y: int, disabled: bool):
	var id = _get_point_id(x, y)
	astar.set_point_disabled(id, disabled)