# scripts/systems/VisibilityManager.gd
extends Node

# Менеджер видимости для оптимизации рендеринга

var camera: Camera2D
var visible_rect: Rect2
var buffer_size: float = 100.0  # Буфер для плавности

func _ready():
	# Ждем пока камера будет готова
	call_deferred("setup_camera")

func setup_camera():
	camera = get_tree().get_first_node_in_group("camera")
	if not camera:
		push_warning("VisibilityManager: Камера не найдена!")

func _process(_delta):
	if camera:
		update_visible_rect()
		update_entity_visibility()

func update_visible_rect():
	var viewport_size = get_viewport().get_visible_rect().size
	var camera_pos = camera.get_screen_center_position()
	var zoom_factor = camera.zoom.x
	
	visible_rect = Rect2(
		camera_pos - (viewport_size / (2.0 * zoom_factor)),
		viewport_size / zoom_factor
	)
	
	# Добавляем буфер для плавности
	visible_rect = visible_rect.grow(buffer_size)

func update_entity_visibility():
	# Обновляем видимость юнитов
	for unit in get_tree().get_nodes_in_group("units"):
		if unit is Node2D:
			unit.visible = is_in_visible_rect(unit.global_position)
	
	# Обновляем видимость зданий
	for building in get_tree().get_nodes_in_group("buildings"):
		if building is Node2D:
			building.visible = is_in_visible_rect(building.global_position)

func is_in_visible_rect(position: Vector2) -> bool:
	return visible_rect.has_point(position)

func get_visible_rect() -> Rect2:
	return visible_rect

func is_rect_visible(rect: Rect2) -> bool:
	"""Проверяет, видим ли прямоугольник"""
	return visible_rect.intersects(rect)