# scenes/units/BaseUnit.gd
extends CharacterBody2D

class_name BaseUnit

# Импортируем константы и вспомогательные функции
const Constants = preload("res://scripts/utils/Constants.gd")
const Helpers = preload("res://scripts/utils/Helpers.gd")

# Основные характеристики
var unit_name: String = ""
var race: String = ""
var health: float = 100.0
var max_health: float = 100.0

# Характеристики
var strength: int = 5
var agility: int = 5
var intelligence: int = 5
var endurance: int = 5

# Навыки (0-100)
var skills: Dictionary = {
	"mining": 0,
	"building": 0,
	"combat": 0,
	"crafting": 0
}

# Потребности (0-100)
var needs: Dictionary = {
	"hunger": 100,
	"rest": 100,
	"comfort": 50,
	"social": 50
}

# Настроение (-100 до +100)
var mood: float = 0.0
# Модификаторы
var work_speed_modifier: float = 1.0
var attack_range: float = float(Constants.TILE_SIZE)


# Текущее состояние
var current_state: Constants.UnitState = Constants.UnitState.IDLE

# Текущая задача
var current_task = null

# Путь движения
var path: Array = []
var path_index: int = 0

# Визуализация пути
var path_line: Line2D

# Параметры избегания столкновений
@export var avoidance_radius: float = 50.0
@export var avoidance_force: float = 100.0

# Индикатор выделения
var selection_indicator: Sprite2D
var is_selected: bool = false

signal task_completed()
signal died()
signal selected_changed(is_selected: bool)

func _ready():
	add_to_group("units")
	unit_name = Helpers.get_random_name(race)
	setup_path_visualization()
	setup_selection_indicator()

func _process(delta):
	match current_state:
		Constants.UnitState.IDLE:
			_process_idle(delta)
		Constants.UnitState.MOVING:
			_process_moving(delta)
		Constants.UnitState.WORKING:
			_process_working(delta)
		Constants.UnitState.FIGHTING:
			_process_fighting(delta)
		Constants.UnitState.SLEEPING:
			_process_sleeping(delta)
		Constants.UnitState.EATING:
			_process_eating(delta)

func _process_idle(delta):
	# Ищем задачу или удовлетворяем потребности
	if needs["hunger"] < 30:
		find_food()
	elif needs["rest"] < 30:
		find_bed()
	else:
		request_task()

func _process_moving(delta):
	if path.is_empty():
		current_state = Constants.UnitState.IDLE
		path_line.clear_points()
		return
	
	var target = path[path_index]
	var direction = (target - global_position).normalized()
	
	# Добавляем силу избегания
	var avoidance = calculate_avoidance_force()
	direction = (direction + avoidance).normalized()
	
	var distance_to_target = global_position.distance_to(target)
	var speed = 100 * work_speed_modifier
	
	# Замедление при приближении к точке
	if distance_to_target < 50:
		speed *= distance_to_target / 50.0
	
	velocity = direction * speed
	move_and_slide()
	
	# Обновляем визуализацию
	update_path_visualization()
	
	if global_position.distance_to(target) < 5:
		path_index += 1
		if path_index >= path.size():
			path.clear()
			current_state = Constants.UnitState.IDLE
			path_line.clear_points()
			if current_task:
				start_working()

func move_to(target_position: Vector2):
	var pathfinding = get_node("/root/PathfindingSystem")
	path = pathfinding.find_path(
		global_position / Constants.TILE_SIZE,
		target_position / Constants.TILE_SIZE
	)
	
	# Конвертируем путь в мировые координаты
	var world_path = []
	for point in path:
		world_path.append(point * Constants.TILE_SIZE)
	
	path = world_path
	path_index = 0
	current_state = Constants.UnitState.MOVING
	
	# Обновляем визуализацию пути
	update_path_visualization()

func take_damage(amount: float):
	health -= amount
	if health <= 0:
		die()

func die():
	emit_signal("died")
	queue_free()

func _process_working(delta):
	pass

func _process_fighting(delta):
	pass

func _process_sleeping(delta):
	needs["rest"] = min(100, needs["rest"] + 20 * delta)
	if needs["rest"] >= 100:
		current_state = Constants.UnitState.IDLE

func _process_eating(delta):
	needs["hunger"] = min(100, needs["hunger"] + 30 * delta)
	if needs["hunger"] >= 100:
		current_state = Constants.UnitState.IDLE

func find_food():
	# Логика поиска еды
	pass

func find_bed():
	# Логика поиска кровати
	pass

func request_task():
	# Запрос задачи у системы управления задачами
	pass

func start_working():
	current_state = Constants.UnitState.WORKING

# Визуализация пути
func setup_path_visualization():
	path_line = Line2D.new()
	path_line.width = 2.0
	path_line.default_color = Color(0.2, 0.8, 0.2, 0.5)
	path_line.z_index = -1
	add_child(path_line)

func update_path_visualization():
	path_line.clear_points()
	
	if path.is_empty():
		return
	
	# Добавляем текущую позицию
	path_line.add_point(Vector2.ZERO)
	
	# Добавляем точки пути относительно юнита
	for i in range(path_index, path.size()):
		var point = path[i] - global_position
		path_line.add_point(point)

# Избегание столкновений
func calculate_avoidance_force() -> Vector2:
	var avoidance = Vector2.ZERO
	var nearby_units = get_tree().get_nodes_in_group("units")
	
	for unit in nearby_units:
		if unit == self or not unit is BaseUnit:
			continue
		
		var distance = global_position.distance_to(unit.global_position)
		if distance < avoidance_radius and distance > 0:
			var away = (global_position - unit.global_position).normalized()
			var force = (1.0 - distance / avoidance_radius) * avoidance_force
			avoidance += away * force
	
	return avoidance.normalized() if avoidance.length() > 0 else Vector2.ZERO

# Система выделения
func setup_selection_indicator():
	selection_indicator = Sprite2D.new()
	selection_indicator.modulate = Color(0.2, 0.8, 0.2, 0.5)
	selection_indicator.z_index = -2
	selection_indicator.visible = false
	add_child(selection_indicator)
	
	# Создаем простой круг для индикатора
	var image = Image.create(64, 64, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	
	# Рисуем круг
	for x in range(64):
		for y in range(64):
			var dx = x - 32
			var dy = y - 32
			var dist = sqrt(dx * dx + dy * dy)
			if dist > 28 and dist < 32:
				image.set_pixel(x, y, Color(0.2, 0.8, 0.2, 0.8))
	
	var texture = ImageTexture.create_from_image(image)
	selection_indicator.texture = texture

func set_selected(selected: bool):
	is_selected = selected
	selection_indicator.visible = selected
	emit_signal("selected_changed", selected)

func get_selected() -> bool:
	return is_selected