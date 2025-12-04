# scripts/systems/ObjectPool.gd
extends Node

# Система повторного использования объектов

var pool: Dictionary = {}  # scene_path: [objects]

func get_object(scene_path: String) -> Node:
	if not pool.has(scene_path):
		pool[scene_path] = []
	
	var object_pool = pool[scene_path]
	if object_pool.is_empty():
		# Создаем новый объект
		return _create_new_object(scene_path)
	else:
		# Берем объект из пула
		var obj = object_pool.pop_back()
		_activate_object(obj)
		return obj

func return_object(obj: Node, scene_path: String):
	if not pool.has(scene_path):
		pool[scene_path] = []
	
	_deactivate_object(obj)
	pool[scene_path].append(obj)

func _create_new_object(scene_path: String) -> Node:
	var scene = load(scene_path)
	if scene:
		var obj = scene.instantiate()
		return obj
	return null

func _activate_object(obj: Node):
	if obj:
		obj.show()
		# Активируем обработку
		if obj.has_method("activate"):
			obj.call("activate")

func _deactivate_object(obj: Node):
	if obj:
		obj.hide()
		# Деактивируем обработку
		if obj.has_method("deactivate"):
			obj.call("deactivate")
		
		# Отключаем от сцены, но не удаляем
		if obj.get_parent():
			obj.get_parent().remove_child(obj)

func preload_objects(scene_path: String, count: int):
	if not pool.has(scene_path):
		pool[scene_path] = []
	
	var scene = load(scene_path)
	if not scene:
		return
	
	for i in range(count):
		var obj = scene.instantiate()
		_deactivate_object(obj)
		pool[scene_path].append(obj)

func clear_pool(scene_path: String = ""):
	if scene_path == "":
		# Очищаем все пулы
		for path in pool.keys():
			for obj in pool[path]:
				if is_instance_valid(obj):
					obj.queue_free()
		pool.clear()
	else:
		# Очищаем конкретный пул
		if pool.has(scene_path):
			for obj in pool[scene_path]:
				if is_instance_valid(obj):
					obj.queue_free()
			pool.erase(scene_path)

func get_pool_size(scene_path: String) -> int:
	if pool.has(scene_path):
		return pool[scene_path].size()
	return 0

func get_total_objects() -> int:
	var total = 0
	for path in pool.keys():
		total += pool[path].size()
	return total