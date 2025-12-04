# scripts/systems/SelectionManager.gd
extends Node

# Менеджер выделения юнитов

var selected_units: Array = []
var is_box_selecting: bool = false
var box_start: Vector2
var box_end: Vector2

# Визуализация рамки выделения
var selection_box: ColorRect

signal selection_changed(units: Array)

func _ready():
	setup_selection_box()

func setup_selection_box():
	selection_box = ColorRect.new()
	selection_box.color = Color(0.2, 0.8, 0.2, 0.2)
	selection_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	selection_box.visible = false
	
	# Создаем стиль с рамкой
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.8, 0.2, 0.2)
	style.border_color = Color(0.2, 0.8, 0.2, 0.8)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	
	# Добавляем в корень сцены
	get_tree().root.add_child.call_deferred(selection_box)

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			start_box_selection(event.position)
		else:
			end_box_selection(event.position)
	
	elif event is InputEventMouseMotion and is_box_selecting:
		update_box_selection(event.position)
	
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		move_selected_units_to(event.position)

func start_box_selection(position: Vector2):
	# Если не зажат Shift, очищаем выделение
	if not Input.is_key_pressed(KEY_SHIFT):
		clear_selection()
	
	is_box_selecting = true
	box_start = position
	box_end = position
	selection_box.visible = true
	update_selection_box_visual()

func update_box_selection(position: Vector2):
	box_end = position
	update_selection_box_visual()

func end_box_selection(position: Vector2):
	box_end = position
	is_box_selecting = false
	selection_box.visible = false
	
	# Выделяем юнитов в рамке
	select_units_in_box()

func update_selection_box_visual():
	var rect = get_selection_rect()
	selection_box.position = rect.position
	selection_box.size = rect.size

func get_selection_rect() -> Rect2:
	var min_x = min(box_start.x, box_end.x)
	var min_y = min(box_start.y, box_end.y)
	var max_x = max(box_start.x, box_end.x)
	var max_y = max(box_start.y, box_end.y)
	
	return Rect2(min_x, min_y, max_x - min_x, max_y - min_y)

func select_units_in_box():
	var camera = get_tree().get_first_node_in_group("camera")
	if not camera:
		return
	
	var rect = get_selection_rect()
	var units = get_tree().get_nodes_in_group("units")
	
	for unit in units:
		if not unit is BaseUnit:
			continue
		
		# Конвертируем мировую позицию в экранную
		var viewport = get_viewport()
		var screen_pos = viewport.get_camera_2d().get_screen_center_position() + \
						(unit.global_position - viewport.get_camera_2d().global_position) * viewport.get_camera_2d().zoom
		
		if rect.has_point(screen_pos):
			add_to_selection(unit)
	
	emit_signal("selection_changed", selected_units)

func add_to_selection(unit: BaseUnit):
	if not unit in selected_units:
		selected_units.append(unit)
		unit.set_selected(true)

func remove_from_selection(unit: BaseUnit):
	if unit in selected_units:
		selected_units.erase(unit)
		unit.set_selected(false)

func clear_selection():
	for unit in selected_units:
		if is_instance_valid(unit):
			unit.set_selected(false)
	selected_units.clear()
	emit_signal("selection_changed", selected_units)

func select_single_unit(unit: BaseUnit):
	clear_selection()
	add_to_selection(unit)
	emit_signal("selection_changed", selected_units)

func get_selected_units() -> Array:
	return selected_units

func has_selection() -> bool:
	return selected_units.size() > 0

func move_selected_units_to(target_position: Vector2):
	"""Перемещает всех выделенных юнитов к целевой позиции"""
	for unit in selected_units:
		if is_instance_valid(unit):
			unit.move_to(target_position)