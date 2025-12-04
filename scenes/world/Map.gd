# scenes/world/Map.gd
extends Node2D

class_name Map

const Constants = preload("res://scripts/utils/Constants.gd")

var map_width: int = 128
var map_height: int = 128
var tile_size: int = 32

# Двумерный массив тайлов
var tiles: Array = []

# TileMap для отрисовки
@onready var tilemap: TileMap = $TileMap

# Слои TileMap
const LAYER_TERRAIN = 0
const LAYER_RESOURCES = 1
const LAYER_OVERLAY = 2

# Шум для генерации (создаем один раз)
var noise: FastNoiseLite

func _ready():
	add_to_group("map")
	map_width = Constants.MAP_WIDTH
	map_height = Constants.MAP_HEIGHT
	tile_size = Constants.TILE_SIZE
	setup_noise()
	setup_tilemap()
	generate_map()
	
	# Убедимся, что TileMap настроен правильно
	configure_tilemap()

func setup_noise():
	noise = FastNoiseLite.new()
	noise.seed = randi()
	noise.frequency = 0.05  # Частота шума для плавных переходов

func setup_tilemap():
	# Проверяем, есть ли TileMap
	if not tilemap:
		push_error("TileMap не найден! Добавьте TileMap как дочерний узел Map.")
		return
	
	# Создаем слои если их нет
	while tilemap.get_layers_count() < 3:
		tilemap.add_layer(-1)
	
	# Настройка слоев
	tilemap.set_layer_name(LAYER_TERRAIN, "Terrain")
	tilemap.set_layer_name(LAYER_RESOURCES, "Resources")
	tilemap.set_layer_name(LAYER_OVERLAY, "Overlay")
	
	# Загружаем тайлсет
	var tileset = load("res://assets/tiles/terrain_tileset.tres")
	if tileset:
		tilemap.tile_set = tileset
	else:
		push_warning("Тайлсет не найден! Создайте тайлсет вручную.")

func configure_tilemap():
	# Убедимся, что TileMap настроен правильно
	if tilemap and tilemap.tile_set:
		tilemap.cell_size = Vector2i(tile_size, tile_size)

func generate_map():
	tiles.clear()
	
	# Создание двумерного массива
	for x in range(map_width):
		tiles.append([])
		for y in range(map_height):
			var tile = create_tile(x, y)
			tiles[x].append(tile)
			
			# Отрисовка тайла
			render_tile(x, y, tile)

func render_tile(x: int, y: int, tile: Dictionary):
	if not tilemap:
		return
		
	var tile_coords = Vector2i(x, y)
	var atlas_coords = get_atlas_coords_for_terrain(tile.terrain_type)
	
	# Устанавливаем тайл на слое местности
	tilemap.set_cell(LAYER_TERRAIN, tile_coords, 0, atlas_coords)
	
	# Добавляем ресурсы, если есть
	if tile.resources.size() > 0:
		var resource_atlas = get_atlas_coords_for_resource(tile.resources[0])
		tilemap.set_cell(LAYER_RESOURCES, tile_coords, 0, resource_atlas)

func get_atlas_coords_for_terrain(terrain_type: int) -> Vector2i:
	# Маппинг типа местности на координаты в атласе
	match terrain_type:
		Constants.TERRAIN_WATER:
			return Vector2i(0, 0)
		Constants.TERRAIN_PLAIN:
			return Vector2i(1, 0)
		Constants.TERRAIN_FOREST:
			return Vector2i(2, 0)
		Constants.TERRAIN_MOUNTAIN:
			return Vector2i(3, 0)
	return Vector2i(0, 0)

func get_atlas_coords_for_resource(resource_type: int) -> Vector2i:
	# Пока используем те же координаты, позже добавим отдельные спрайты
	match resource_type:
		Constants.RESOURCE_WOOD:
			return Vector2i(2, 0)  # Лес
		Constants.RESOURCE_STONE:
			return Vector2i(3, 0)  # Горы
		_:
			return Vector2i(0, 0)

func create_tile(x: int, y: int) -> Dictionary:
	# Генерация с шумом Перлина
	var value = noise.get_noise_2d(x, y)
	
	var tile = {
		"position": Vector2(x, y),
		"terrain_type": _get_terrain_from_noise(value),
		"resources": [],
		"walkable": true,
		"building": null
	}
	
	# Вода не проходима
	if tile.terrain_type == Constants.TERRAIN_WATER:
		tile.walkable = false
	
	# Добавляем ресурсы на некоторые тайлы
	if tile.terrain_type == Constants.TERRAIN_FOREST and randf() < 0.3:
		tile.resources.append(Constants.RESOURCE_WOOD)
	elif tile.terrain_type == Constants.TERRAIN_MOUNTAIN and randf() < 0.2:
		tile.resources.append(Constants.RESOURCE_STONE)
	
	return tile

func _get_terrain_from_noise(value: float) -> int:
	if value < -0.3:
		return Constants.TERRAIN_WATER
	elif value < 0.0:
		return Constants.TERRAIN_PLAIN
	elif value < 0.3:
		return Constants.TERRAIN_FOREST
	else:
		return Constants.TERRAIN_MOUNTAIN

func get_tile(x: int, y: int):
	if x >= 0 and x < map_width and y >= 0 and y < map_height:
		return tiles[x][y]
	return null

func is_walkable(x: int, y: int) -> bool:
	var tile = get_tile(x, y)
	return tile != null and tile.walkable and tile.building == null

func get_tile_position_from_world(world_position: Vector2) -> Vector2i:
	return Vector2i(
		int(world_position.x / tile_size),
		int(world_position.y / tile_size)
	)

func get_world_position_from_tile(tile_x: int, tile_y: int) -> Vector2:
	return Vector2(
		tile_x * tile_size + tile_size / 2,
		tile_y * tile_size + tile_size / 2
	)
