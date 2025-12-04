# scripts/systems/CameraController.gd
extends Camera2D

class_name CameraController

# Параметры движения
@export var move_speed: float = 500.0
@export var edge_scroll_margin: float = 20.0
@export var edge_scroll_speed: float = 400.0

# Параметры зума
@export var zoom_min: float = 0.5
@export var zoom_max: float = 3.0
@export var zoom_speed: float = 0.1
@export var zoom_smooth: float = 10.0

# Параметры перетаскивания
var is_dragging: bool = false
var drag_start_position: Vector2
var drag_start_camera_position: Vector2

# Границы карты
var map_bounds: Rect2

# Целевой зум для плавного перехода
var target_zoom: Vector2

func _ready():
	add_to_group("camera")
	target_zoom = zoom
	
	# Получаем границы карты
	call_deferred("setup_map_bounds")

func setup_map_bounds():
	var map = get_tree().get_first_node_in_group("map")
	if map:
		map_bounds = Rect2(
			0, 0,
			map.map_width * map.tile_size,
			map.map_height * map.tile_size
		)
	else:
		# Границы по умолчанию
		map_bounds = Rect2(0, 0, 4096, 4096)

func _process(delta):
	handle_keyboard_movement(delta)
	handle_edge_scrolling(delta)
	handle_zoom(delta)
	apply_camera_limits()

func _input(event):
	# Зум колесиком мыши
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom_in()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom_out()
		
		# Перетаскивание средней кнопкой
		elif event.button_index == MOUSE_BUTTON_MIDDLE:
			if event.pressed:
				start_drag(event.position)
			else:
				stop_drag()
	
	# Перетаскивание
	elif event is InputEventMouseMotion and is_dragging:
		update_drag(event.position)

func handle_keyboard_movement(delta):
	var direction = Vector2.ZERO
	
	# WASD или стрелки
	if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D):
		direction.x += 1
	if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A):
		direction.x -= 1
	if Input.is_action_pressed("ui_down") or Input.is_key_pressed(KEY_S):
		direction.y += 1
	if Input.is_action_pressed("ui_up") or Input.is_key_pressed(KEY_W):
		direction.y -= 1
	
	if direction != Vector2.ZERO:
		direction = direction.normalized()
		position += direction * move_speed * delta / zoom.x

func handle_edge_scrolling(delta):
	var mouse_pos = get_viewport().get_mouse_position()
	var viewport_size = get_viewport_rect().size
	var direction = Vector2.ZERO
	
	# Проверяем края экрана
	if mouse_pos.x < edge_scroll_margin:
		direction.x -= 1
	elif mouse_pos.x > viewport_size.x - edge_scroll_margin:
		direction.x += 1
	
	if mouse_pos.y < edge_scroll_margin:
		direction.y -= 1
	elif mouse_pos.y > viewport_size.y - edge_scroll_margin:
		direction.y += 1
	
	if direction != Vector2.ZERO:
		direction = direction.normalized()
		position += direction * edge_scroll_speed * delta / zoom.x

func handle_zoom(delta):
	# Плавный переход к целевому зуму
	zoom = zoom.lerp(target_zoom, zoom_smooth * delta)

func zoom_in():
	target_zoom = (target_zoom * (1.0 + zoom_speed)).clamp(
		Vector2(zoom_min, zoom_min),
		Vector2(zoom_max, zoom_max)
	)

func zoom_out():
	target_zoom = (target_zoom * (1.0 - zoom_speed)).clamp(
		Vector2(zoom_min, zoom_min),
		Vector2(zoom_max, zoom_max)
	)

func start_drag(mouse_position: Vector2):
	is_dragging = true
	drag_start_position = mouse_position
	drag_start_camera_position = position

func stop_drag():
	is_dragging = false

func update_drag(mouse_position: Vector2):
	var delta = (drag_start_position - mouse_position) / zoom.x
	position = drag_start_camera_position + delta

func apply_camera_limits():
	# Ограничиваем камеру границами карты
	var viewport_size = get_viewport_rect().size / zoom
	
	position.x = clamp(
		position.x,
		viewport_size.x / 2,
		map_bounds.size.x - viewport_size.x / 2
	)
	position.y = clamp(
		position.y,
		viewport_size.y / 2,
		map_bounds.size.y - viewport_size.y / 2
	)

func focus_on_position(target_position: Vector2, smooth: bool = true):
	"""Фокусирует камеру на указанной позиции"""
	if smooth:
		var tween = create_tween()
		tween.tween_property(self, "position", target_position, 0.5)
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_CUBIC)
	else:
		position = target_position

func get_visible_rect() -> Rect2:
	"""Возвращает видимую область в мировых координатах"""
	var viewport_size = get_viewport_rect().size / zoom
	return Rect2(
		position - viewport_size / 2,
		viewport_size
	)