# Руководство по реализации Фазы 3.1: Базовые механики

**Версия:** 1.0  
**Дата:** 02.12.2024  
**Статус:** В разработке

---

## Содержание

1. [Обзор](#обзор)
2. [Неделя 1-2: Карта и навигация](#неделя-1-2-карта-и-навигация)
3. [Неделя 3-4: Юниты](#неделя-3-4-юниты)
4. [Интеграция и тестирование](#интеграция-и-тестирование)
5. [Критерии приемки](#критерии-приемки)

---

## Обзор

### Цель фазы
Реализовать базовые механики игры: визуальную карту с навигацией и полнофункциональную систему управления юнитами.

### Ожидаемый результат
- Процедурно генерируемая карта с визуальным отображением
- Камера с полным управлением (перемещение, зум)
- Юниты с движением, выделением и управлением
- Стабильная производительность (60 FPS с 50+ юнитами)

### Зависимости
- Godot 4.x
- Существующие системы: PathfindingSystem, EventBus, GameManager

---

## Неделя 1-2: Карта и навигация

### 1. Визуальный рендеринг карты

#### 1.1 Создание тайлсета

**Цель:** Создать базовый тайлсет для отображения различных типов местности.

**Технические требования:**
- Размер тайла: 32x32 пикселя
- Типы местности: вода, равнина, лес, горы
- Формат: PNG с прозрачностью
- Цветовая палитра: согласованная с общим стилем игры

**Структура файлов:**
```
assets/
  tiles/
    terrain_tileset.png      # Основной тайлсет
    terrain_tileset.tres     # Ресурс TileSet
```

**Пример создания тайлсета в коде:**
```gdscript
# Создание TileSet программно (если нужно)
var tileset = TileSet.new()

# Добавление источника атласа
var atlas_source = TileSetAtlasSource.new()
atlas_source.texture = preload("res://assets/tiles/terrain_tileset.png")
atlas_source.texture_region_size = Vector2i(32, 32)

# Добавление тайлов
for terrain_type in range(4):
    var coords = Vector2i(terrain_type, 0)
    atlas_source.create_tile(coords)
    
tileset.add_source(atlas_source)
```

**Цветовая схема (временная, для прототипа):**
- Вода: #4A90E2 (синий)
- Равнина: #7ED321 (зеленый)
- Лес: #417505 (темно-зеленый)
- Горы: #8B7355 (коричневый)

---

#### 1.2 Настройка TileMap

**Цель:** Интегрировать TileMap с процедурной генерацией карты.

**Изменения в Map.gd:**
```gdscript
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

func _ready():
    map_width = Constants.MAP_WIDTH
    map_height = Constants.MAP_HEIGHT
    tile_size = Constants.TILE_SIZE
    setup_tilemap()
    generate_map()

func setup_tilemap():
    # Настройка TileMap
    tilemap.tile_set = preload("res://assets/tiles/terrain_tileset.tres")
    
    # Создание слоев
    tilemap.add_layer(LAYER_TERRAIN)
    tilemap.add_layer(LAYER_RESOURCES)
    tilemap.add_layer(LAYER_OVERLAY)
    
    # Настройка слоев
    tilemap.set_layer_name(LAYER_TERRAIN, "Terrain")
    tilemap.set_layer_name(LAYER_RESOURCES, "Resources")
    tilemap.set_layer_name(LAYER_OVERLAY, "Overlay")

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

func create_tile(x: int, y: int) -> Dictionary:
    # Простая генерация с шумом Перлина
    var noise = FastNoiseLite.new()
    noise.seed = randi()
    noise.frequency = 0.05  # Частота шума
    var value = noise.get_noise_2d(x, y)
    
    var tile = {
        "position": Vector2(x, y),
        "terrain_type": _get_terrain_from_noise(value),
        "resources": [],
        "walkable": true,
        "building": null
    }
    
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
```

---

#### 1.3 Система чанков

**Цель:** Оптимизировать рендеринг больших карт через систему чанков.

**Создание ChunkManager (улучшенная версия):**
```gdscript
# scripts/systems/ChunkManager.gd
extends Node

const CHUNK_SIZE = 32  # Размер чанка в тайлах
const RENDER_DISTANCE = 2  # Расстояние рендеринга в чанках

var active_chunks: Dictionary = {}  # Активные чанки
var chunk_pool: Array = []  # Пул неиспользуемых чанков

signal chunk_loaded(chunk_pos: Vector2i)
signal chunk_unloaded(chunk_pos: Vector2i)

func get_chunk_position(world_pos: Vector2) -> Vector2i:
    return Vector2i(
        int(world_pos.x / (CHUNK_SIZE * Constants.TILE_SIZE)),
        int(world_pos.y / (CHUNK_SIZE * Constants.TILE_SIZE))
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
    return {
        "position": chunk_pos,
        "tiles": [],
        "entities": []
    }
```

---

### 2. Система камеры

#### 2.1 Создание Camera2D с управлением

**Цель:** Реализовать полнофункциональную камеру с перемещением и зумом.

**Создание CameraController:**
```gdscript
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
    target_zoom = zoom
    
    # Получаем границы карты
    var map = get_tree().get_first_node_in_group("map")
    if map:
        map_bounds = Rect2(
            0, 0,
            map.map_width * map.tile_size,
            map.map_height * map.tile_size
        )

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
    if smooth:
        var tween = create_tween()
        tween.tween_property(self, "position", target_position, 0.5)
        tween.set_ease(Tween.EASE_OUT)
        tween.set_trans(Tween.TRANS_CUBIC)
    else:
        position = target_position
```

**Добавление в project.godot (Input Map):**
```
[input]

camera_up={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":0,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":87,"key_label":0,"unicode":0,"echo":false,"script":null)
]
}

camera_down={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":0,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":83,"key_label":0,"unicode":0,"echo":false,"script":null)
]
}

camera_left={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":0,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":65,"key_label":0,"unicode":0,"echo":false,"script":null)
]
}

camera_right={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":0,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":68,"key_label":0,"unicode":0,"echo":false,"script":null)
]
}
```

---

### 3. Оптимизация рендеринга

#### 3.1 Viewport и Canvas настройки

**Изменения в project.godot:**
```
[display]

window/size/viewport_width=1920
window/size/viewport_height=1080
window/size/mode=2
window/stretch/mode="canvas_items"
window/stretch/aspect="expand"

[rendering]

renderer/rendering_method="gl_compatibility"
renderer/rendering_method.mobile="gl_compatibility"
textures/canvas_textures/default_texture_filter=0
2d/snap/snap_2d_transforms_to_pixel=true
2d/snap/snap_2d_vertices_to_pixel=true
```

#### 3.2 Culling система

**Создание VisibilityManager:**
```gdscript
# scripts/systems/VisibilityManager.gd
extends Node

var camera: Camera2D
var visible_rect: Rect2

func _ready():
    camera = get_tree().get_first_node_in_group("camera")

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
    visible_rect = visible_rect.grow(100)

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
```

---

## Неделя 3-4: Юниты

### 1. Улучшение движения юнитов

#### 1.1 Визуализация пути

**Добавление в BaseUnit.gd:**
```gdscript
# Визуализация пути
var path_line: Line2D

func _ready():
    add_to_group("units")
    unit_name = Helpers.get_random_name(race)
    setup_path_visualization()

func setup_path_visualization():
    path_line = Line2D.new()
    path_line.width = 2.0
    path_line.default_color = Color(0.2, 0.8, 0.2, 0.5)
    path_line.z_index = -1
    add_child(path_line)

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
    current_state = 1  # MOVING
    
    # Обновляем визуализацию пути
    update_path_visualization()

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

func _process_moving(delta):
    if path.is_empty():
        current_state = 0  # IDLE
        path_line.clear_points()
        return
    
    var target = path[path_index]
    var direction = (target - global_position).normalized()
    
    # Сглаживание движения
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
            current_state = 0  # IDLE
            path_line.clear_points()
            if current_task:
                start_working()
```

#### 1.2 Избегание столкновений

**Добавление в BaseUnit.gd:**
```gdscript
# Параметры избегания столкновений
@export var avoidance_radius: float = 50.0
@export var avoidance_force: float = 100.0

func _process_moving(delta):
    if path.is_empty():
        current_state = 0
        path_line.clear_points()
        return
    
    var target = path[path_index]
    var direction = (target - global_position).normalized()
    
    # Добавляем силу избегания
    var avoidance = calculate_avoidance_force()
    direction = (direction + avoidance).normalized()
    
    var distance_to_target = global_position.distance_to(target)
    var speed = 100 * work_speed_modifier
    
    if distance_to_target < 50:
        speed *= distance_to_target / 50.0
    
    velocity = direction * speed
    move_and_slide()
    
    update_path_visualization()
    
    if global_position.distance_to(target) < 5:
        path_index += 1
        if path_index >= path.size():
            path.clear()
            current_state = 0
            path_line.clear_points()
            if current_task:
                start_working()

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
```

---

### 2. Система выделения

#### 2.1 Выделение рамкой (Box Selection)

**Создание SelectionManager:**
```gdscript
# scripts/systems/SelectionManager.gd
extends Node

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
    
    # Добавляем рамку
    var border = StyleBoxFlat.new()
    border.border_color = Color(0.2, 0.8, 0.2, 0.8)
    border.border_width_left = 2
    border.border_width_right = 2
    border.border_width_top = 2
    border.border_width_bottom = 2
    selection_box.add_theme_stylebox_override("panel", border)
    
    get_tree().root.add_child(selection_box)

func _input(event):
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
        if event.pressed:
            start_box_selection(event.position)
        else:
            end_box_selection(event.position)
    
    elif event is InputEventMouseMotion and is_box_selecting:
        update_box_selection(event.position)

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
        var screen_pos = camera.get_screen_center_position() + \
                        (unit.global_position - camera.global_position) * camera.zoom
        
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
        unit.set_selected(false)
    selected_units.clear()
    emit_signal("selection_changed", selected_units)

func select_single_unit(unit: BaseUnit):
    clear_selection()
    add_to_selection(unit)
    emit_signal("selection_changed", selected_units)
```

#### 2.2 Визуальные индикаторы выделения

**Добавление в BaseUnit.gd:**
```gdscript
# Индикатор выделения
var selection_indicator: Sprite2D
var is_selected: bool = false

func _ready():
    add_to_group("units")