# scripts/systems/TaskManager.gd
extends Node

# Система управления задачами для юнитов

class Task:
	var id: int
	var type: String
	var target_position: Vector2
	var target_object = null
	var priority: int  # 1-10, где 10 - наивысший приоритет
	var assigned_unit = null
	var progress: float = 0.0
	var required_time: float = 0.0
	var required_resources: Dictionary = {}
	var skills_required: Dictionary = {}
	var is_completed: bool = false
	var description: String = ""
	
	func _init(task_data: Dictionary):
		id = task_data.get("id", 0)
		type = task_data.get("type", "")
		target_position = task_data.get("target_position", Vector2.ZERO)
		target_object = task_data.get("target_object", null)
		priority = task_data.get("priority", 1)
		required_time = task_data.get("required_time", 10.0)
		required_resources = task_data.get("required_resources", {})
		skills_required = task_data.get("skills_required", {})
		description = task_data.get("description", "")

var tasks: Array = []
var task_counter: int = 0
var task_queue: Array = []  # Очередь задач по приоритетам

func _ready():
	initialize_task_types()

func initialize_task_types():
	# Инициализация типов задач
	pass

func create_task(task_data: Dictionary) -> Task:
	task_counter += 1
	task_data["id"] = task_counter
	
	var task = Task.new(task_data)
	tasks.append(task)
	
	# Добавление в очередь по приоритету
	_add_to_queue(task)
	
	return task

func _add_to_queue(task: Task):
	# Добавление задачи в очередь с учетом приоритета
	task_queue.append(task)
	_sort_queue_by_priority()

func _sort_queue_by_priority():
	# Сортировка очереди по приоритету (от высокого к низкому)
	task_queue.sort_custom(Callable(self, "_compare_priority"))

func _compare_priority(task_a: Task, task_b: Task) -> bool:
	return task_a.priority > task_b.priority

func assign_task(unit) -> Task:
	# Назначение задачи юниту
	if task_queue.is_empty():
		return null
	
	# Поиск подходящей задачи для юнита
	for i in range(task_queue.size()):
		var task = task_queue[i]
		if _is_task_suitable(unit, task):
			task_queue.remove_at(i)
			task.assigned_unit = unit
			return task
	
	return null

func _is_task_suitable(unit, task: Task) -> bool:
	# Проверка, подходит ли задача юниту
	
	# Проверка навыков
	for skill in task.skills_required:
		if not unit.skills.has(skill):
			return false
		if unit.skills[skill] < task.skills_required[skill]:
			return false
	
	# Проверка ресурсов (если юнит должен их иметь)
	for resource in task.required_resources:
		if ResourceManager.get_resource(resource) < task.required_resources[resource]:
			# Проверяем, может ли юнит получить ресурсы
			if not _can_acquire_resources(unit, resource, task.required_resources[resource]):
				return false
	
	# Проверка расы (если задача расовая)
	if task.type.begins_with(unit.race + "_"):
		return true
	
	# Общие задачи подходят всем
	if task.type in ["move", "gather", "build", "repair"]:
		return true
	
	return false

func _can_acquire_resources(unit, resource_name: String, amount: int) -> bool:
	# Проверка возможности получения ресурсов
	# В реальной реализации здесь будет логика поиска источника ресурсов
	return ResourceManager.get_resource(resource_name) >= amount

func complete_task(task: Task):
	# Завершение задачи
	task.is_completed = true
	
	# Удаление из списка активных задач
	tasks.erase(task)
	
	# Эмитирование сигнала
	EventBus.emit_signal("task_completed", task)

func cancel_task(task: Task):
	# Отмена задачи
	if task.assigned_unit:
		task.assigned_unit.current_task = null
	
	# Возвращение в очередь, если задача не завершена
	if not task.is_completed:
		task.assigned_unit = null
		task_queue.append(task)
		_sort_queue_by_priority()
	
	# Удаление из списка активных задач
	tasks.erase(task)

func update_task_progress(task: Task, delta: float):
	# Обновление прогресса задачи
	if task.assigned_unit:
		var efficiency = task.assigned_unit.work_speed_modifier
		task.progress += delta * efficiency
		if task.progress >= task.required_time:
			complete_task(task)

func get_tasks_for_unit(unit) -> Array:
	# Получение списка задач, подходящих юниту
	var suitable_tasks = []
	for task in task_queue:
		if _is_task_suitable(unit, task):
			suitable_tasks.append(task)
	return suitable_tasks

func get_tasks_by_type(type: String) -> Array:
	# Получение задач по типу
	var type_tasks = []
	for task in tasks:
		if task.type == type:
			type_tasks.append(task)
	return type_tasks

func get_tasks_by_priority(min_priority: int) -> Array:
	# Получение задач с минимальным приоритетом
	var priority_tasks = []
	for task in tasks:
		if task.priority >= min_priority:
			priority_tasks.append(task)
	return priority_tasks

func create_gather_task(resource_type: String, position: Vector2, amount: int) -> Task:
	# Создание задачи сбора ресурсов
	var task_data = {
		"type": "gather",
		"target_position": position,
		"priority": 3,
		"required_time": 20.0,
		"required_resources": {},
		"skills_required": {"mining": 5},
		"description": "Собрать " + str(amount) + " " + resource_type
	}
	
	var task = create_task(task_data)
	
	# Добавление специфических данных
	task.resource_type = resource_type
	task.amount = amount
	
	return task

func create_build_task(building_template, position: Vector2) -> Task:
	# Создание задачи строительства
	var task_data = {
		"type": "build",
		"target_position": position,
		"priority": 5,
		"required_time": 60.0,
		"required_resources": building_template.required_resources,
		"skills_required": {"building": 10},
		"description": "Построить " + building_template.name
	}
	
	var task = create_task(task_data)
	
	# Добавление специфических данных
	task.building_template = building_template
	
	return task

func create_repair_task(building) -> Task:
	# Создание задачи ремонта
	var task_data = {
		"type": "repair",
		"target_position": building.global_position,
		"target_object": building,
		"priority": 4,
		"required_time": 30.0,
		"required_resources": {"wood": 10, "stone": 5},
		"skills_required": {"building": 8},
		"description": "Починить " + building.building_name
	}
	
	var task = create_task(task_data)
	
	# Добавление специфических данных
	task.building = building
	
	return task

func create_combat_task(target) -> Task:
	# Создание боевой задачи
	var task_data = {
		"type": "combat",
		"target_position": target.global_position,
		"target_object": target,
		"priority": 8,
		"required_time": 0.0,  # Боевые задачи не имеют фиксированного времени
		"required_resources": {},
		"skills_required": {"combat": 5},
		"description": "Атаковать " + (target.unit_name if target.unit_name else "цель")
	}
	
	var task = create_task(task_data)
	
	# Добавление специфических данных
	task.target = target
	
	return task

func get_nearest_task(unit, task_type: String = "") -> Task:
	# Получение ближайшей задачи
	var suitable_tasks = task_queue.duplicate()
	if task_type != "":
		suitable_tasks = []
		for task in task_queue:
			if task.type == task_type:
				suitable_tasks.append(task)
	
	if suitable_tasks.is_empty():
		return null
	
	# Сортировка по расстоянию
	suitable_tasks.sort_custom(Callable(self, "_compare_distance").bind(unit))
	return suitable_tasks[0]

func _compare_distance(task_a: Task, task_b: Task, unit) -> bool:
	var dist_a = unit.global_position.distance_to(task_a.target_position)
	var dist_b = unit.global_position.distance_to(task_b.target_position)
	return dist_a < dist_b

func clear_completed_tasks():
	# Очистка завершенных задач
	var i = 0
	while i < tasks.size():
		if tasks[i].is_completed:
			tasks.remove_at(i)
		else:
			i += 1

func get_task_count() -> int:
	# Получение количества активных задач
	return tasks.size()

func get_queue_size() -> int:
	# Получение размера очереди
	return task_queue.size()