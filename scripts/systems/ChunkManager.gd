# scripts/systems/ChunkManager.gd
extends Node

# Менеджер чанков для оптимизации производительности

const Constants = preload("res://scripts/utils/Constants.gd")

const CHUNK_SIZE = 32  # Размер чанка в тайлах
const RENDER_DISTANCE = 2  # Расстояние рендеринга в чанках

var active_chunks: Dictionary = {}  # Активные чанки
var chunk_pool: Array = []  # Пул неиспользуемых чанков
var chunk_size_pixels: int

signal chunk_loaded(chunk_pos: Vector2i)
signal chunk_unloaded(chunk_pos: Vector2i)

func _ready():
	chunk_size_pixels = CHUNK_SIZE * Constants.TILE_SIZE

func get_chunk_position(world_pos: Vector2) -> Vector2i:
	return Vector2i(
		int(world_pos.x / chunk_size_pixels),
		int(world_pos.y / chunk_size_pixels)
	)

func update_visible_chunks(camera_position: Vector2):
	var camera_chunk = get_chunk_position(camera_position)
	var required_chunks = get_required_chunks(camera_chunk)
	
	# Выгружаем чанки вне зоны видимости
	var chunks_to_unload = []
	for chunk_pos in active_chunks.keys():
		if not chunk_pos in required_chunks:
			chunks_to_unload.append(chunk_pos)
	
	for chunk_pos in chunks_to_unload:
		unload_chunk(chunk_pos)
	
	# Загружаем новые чанки
	for chunk_pos in required_chunks:
		if not chunk_pos in active_chunks:
			load_chunk(chunk_pos)

func get_required_chunks(center_chunk: Vector2i) -> Array:
	var chunks = []
	for x in range(-RENDER_DISTANCE, RENDER_DISTANCE + 1):
		for y in range(-RENDER_DISTANCE, RENDER_DISTANCE + 1):
			chunks.append(center_chunk + Vector2i(x, y))
	return chunks

func load_chunk(chunk_pos: Vector2i):
	if chunk_pos in active_chunks:
		return
	
	var chunk = create_chunk(chunk_pos)
	active_chunks[chunk_pos] = chunk
	emit_signal("chunk_loaded", chunk_pos)

func unload_chunk(chunk_pos: Vector2i):
	if not chunk_pos in active_chunks:
		return
	
	var chunk = active_chunks[chunk_pos]
	chunk_pool.append(chunk)
	active_chunks.erase(chunk_pos)
	emit_signal("chunk_unloaded", chunk_pos)

func create_chunk(chunk_pos: Vector2i) -> Dictionary:
	# Переиспользуем чанк из пула если возможно
	if chunk_pool.size() > 0:
		var chunk = chunk_pool.pop_back()
		chunk.position = chunk_pos
		chunk.tiles.clear()
		chunk.entities.clear()
		return chunk
	
	return {
		"position": chunk_pos,
		"tiles": [],
		"entities": []
	}

func add_entity_to_chunk(entity, position: Vector2):
	var chunk_pos = get_chunk_position(position)
	if chunk_pos in active_chunks:
		var chunk = active_chunks[chunk_pos]
		if not entity in chunk.entities:
			chunk.entities.append(entity)

func remove_entity_from_chunk(entity, position: Vector2):
	var chunk_pos = get_chunk_position(position)
	if chunk_pos in active_chunks:
		var chunk = active_chunks[chunk_pos]
		chunk.entities.erase(entity)

func get_entities_in_chunk(chunk_pos: Vector2i) -> Array:
	if chunk_pos in active_chunks:
		return active_chunks[chunk_pos].entities
	return []

func get_nearby_entities(position: Vector2, radius: int) -> Array:
	var result = []
	var center_chunk = get_chunk_position(position)
	var chunk_radius = int(radius / chunk_size_pixels) + 1
	
	for x in range(-chunk_radius, chunk_radius + 1):
		for y in range(-chunk_radius, chunk_radius + 1):
			var chunk_pos = Vector2i(center_chunk.x + x, center_chunk.y + y)
			if chunk_pos in active_chunks:
				result.append_array(active_chunks[chunk_pos].entities)
	
	return result

func update_entity_chunk(entity, old_position: Vector2, new_position: Vector2):
	var old_chunk = get_chunk_position(old_position)
	var new_chunk = get_chunk_position(new_position)
	
	if old_chunk != new_chunk:
		remove_entity_from_chunk(entity, old_position)
		add_entity_to_chunk(entity, new_position)

func is_chunk_loaded(chunk_pos: Vector2i) -> bool:
	return chunk_pos in active_chunks

func get_active_chunk_count() -> int:
	return active_chunks.size()

func clear_all_chunks():
	active_chunks.clear()
	chunk_pool.clear()