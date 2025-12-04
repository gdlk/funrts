# scripts/autoload/SaveSystem.gd
extends Node

const SAVE_PATH = "user://savegame.json"

func save_game():
	var save_data = {
		"version": "1.0",
		"timestamp": Time.get_unix_time_from_system(),
		"game_time": GameManager.game_time,
		"race": GameManager.current_race,
		"resources": ResourceManager.resources,
		"units": _serialize_units(),
		"buildings": _serialize_buildings(),
		"map": _serialize_map()
	}
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(save_data, "\t"))
	file.close()

func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	if parse_result != OK:
		return false
	
	var save_data = json.data
	_deserialize_game(save_data)
	return true

func _serialize_units() -> Array:
	var units_data = []
	for unit in get_tree().get_nodes_in_group("units"):
		units_data.append({
			"name": unit.unit_name,
			"race": unit.race,
			"position": [unit.global_position.x, unit.global_position.y],
			"health": unit.health,
			"needs": unit.needs,
			"skills": unit.skills,
			"mood": unit.mood
		})
	return units_data

func _serialize_buildings() -> Array:
	var buildings_data = []
	for building in get_tree().get_nodes_in_group("buildings"):
		buildings_data.append({
			"type": building.building_type,
			"position": [building.global_position.x, building.global_position.y],
			"state": building.current_state,
			"health": building.health
		})
	return buildings_data

func _serialize_map() -> Dictionary:
	# Сохраняем только измененные тайлы
	return {
		"seed": 12345,  # Для процедурной генерации
		"modified_tiles": []
	}

func _deserialize_game(data: Dictionary):
	# Восстанавливаем состояние игры
	GameManager.game_time = data.game_time
	GameManager.current_race = data.race
	ResourceManager.resources = data.resources
	# ... и т.д.