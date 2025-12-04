# Руководство по реализации Фазы 3.1: Базовые механики (Часть 2)

## Продолжение: Система выделения и UI

### 2.2 Визуальные индикаторы выделения (продолжение)

**Добавление в BaseUnit.gd:**
```gdscript
# Индикатор выделения
var selection_indicator: Sprite2D
var is_selected: bool = false
var health_bar: ProgressBar

func _ready():
    add_to_group("units")
    unit_name = Helpers.get_random_name(race)
    setup_path_visualization()
    setup_selection_indicator()
    setup_health_bar()

func setup_selection_indicator():
    # Создаем круг выделения
    selection_indicator = Sprite2D.new()
    selection_indicator.texture = create_selection_circle()
    selection_indicator.modulate = Color(0.2, 0.8, 0.2, 0.5)
    selection_indicator.z_index = -1
    selection_indicator.visible = false
    add_child(selection_indicator)

func create_selection_circle() -> Texture2D:
    # Создаем текстуру круга программно
    var size = 64
    var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
    
    var center = Vector2(size / 2, size / 2)
    var radius = size / 2 - 2
    
    for x in range(size):
        for y in range(size):
            var dist = Vector2(x, y).distance_to(center)
            if dist >= radius - 2 and dist <= radius:
                image.set_pixel(x, y, Color(1, 1, 1, 1))
    
    return ImageTexture.create_from_image(image)

func set_selected(selected: bool):
    is_selected = selected
    selection_indicator.visible = selected
    
    if selected:
        # Анимация появления
        var tween = create_tween()
        tween.tween_property(selection_indicator, "scale", Vector2(1.2, 1.2), 0.2)
        tween.tween_property(selection_indicator, "scale", Vector2(1.0, 1.0), 0.2)

func setup_health_bar():
    health_bar = ProgressBar.new()
    health_bar.size = Vector2(40, 4)
    health_bar.position = Vector2(-20, -30)
    health_bar.max_value = max_health
    health_bar.value = health
    health_bar.show_percentage = false
    
    # Стилизация
    var style = StyleBoxFlat.new()
    style.bg_color = Color(0.8, 0.2, 0.2)
    health_bar.add_theme_stylebox_override("fill", style)
    
    add_child(health_bar)

func take_damage(amount: float):
    health -= amount
    health_bar.value = health
    
    # Визуальная обратная связь
    flash_damage()
    
    if health <= 0:
        die()

func flash_damage():
    var tween = create_tween()
    tween.tween_property(self, "modulate", Color(1, 0.5, 0.5), 0.1)
    tween.tween_property(self, "modulate", Color(1, 1, 1), 0.1)
```

---

### 3. UI и обратная связь

#### 3.1 Панель информации о юните

**Создание UnitInfoPanel:**
```gdscript
# scenes/ui/UnitInfoPanel.gd
extends PanelContainer

@onready var unit_name_label = $VBox/NameLabel
@onready var health_label = $VBox/HealthLabel
@onready var state_label = $VBox/StateLabel
@onready var needs_container = $VBox/NeedsContainer
@onready var skills_container = $VBox/SkillsContainer

var current_unit: BaseUnit = null

func _ready():
    visible = false
    SelectionManager.connect("selection_changed", Callable(self, "_on_selection_changed"))

func _on_selection_changed(units: Array):
    if units.is_empty():
        hide_panel()
    else:
        show_unit_info(units[0])

func show_unit_info(unit: BaseUnit):
    current_unit = unit
    visible = true
    update_info()

func hide_panel():
    current_unit = null
    visible = false

func update_info():
    if not current_unit:
        return
    
    unit_name_label.text = current_unit.unit_name
    health_label.text = "HP: %d/%d" % [current_unit.health, current_unit.max_health]
    state_label.text = "State: " + get_state_name(current_unit.current_state)
    
    update_needs()
    update_skills()

func get_state_name(state: int) -> String:
    match state:
        0: return "Idle"
        1: return "Moving"
        2: return "Working"
        3: return "Fighting"
        4: return "Sleeping"
        5: return "Eating"
    return "Unknown"

func update_needs():
    # Очищаем контейнер
    for child in needs_container.get_children():
        child.queue_free()
    
    # Добавляем прогресс-бары для потребностей
    for need_name in current_unit.needs.keys():
        var need_bar = create_need_bar(need_name, current_unit.needs[need_name])
        needs_container.add_child(need_bar)

func create_need_bar(need_name: String, value: float) -> HBoxContainer:
    var container = HBoxContainer.new()
    
    var label = Label.new()
    label.text = need_name.capitalize() + ":"
    label.custom_minimum_size = Vector2(80, 0)
    container.add_child(label)
    
    var bar = ProgressBar.new()
    bar.max_value = 100
    bar.value = value
    bar.custom_minimum_size = Vector2(100, 20)
    container.add_child(bar)
    
    return container

func update_skills():
    # Аналогично update_needs
    for child in skills_container.get_children():
        child.queue_free()
    
    for skill_name in current_unit.skills.keys():
        var skill_bar = create_skill_bar(skill_name, current_unit.skills[skill_name])
        skills_container.add_child(skill_bar)

func create_skill_bar(skill_name: String, value: float) -> HBoxContainer:
    var container = HBoxContainer.new()
    
    var label = Label.new()
    label.text = skill_name.capitalize() + ":"
    label.custom_minimum_size = Vector2(80, 0)
    container.add_child(label)
    
    var bar = ProgressBar.new()
    bar.max_value = 100
    bar.value = value
    bar.custom_minimum_size = Vector2(100, 20)
    container.add_child(bar)
    
    return container

func _process(_delta):
    if current_unit and visible:
        update_info()
```

#### 3.2 Мини-карта

**Создание Minimap:**
```gdscript
# scenes/ui/Minimap.gd
extends SubViewportContainer

@onready var viewport: SubViewport = $SubViewport
@onready var minimap_camera: Camera2D = $SubViewport/MinimapCamera
@onready var main_camera: Camera2D

var map_size: Vector2
var minimap_size: Vector2 = Vector2(200, 200)
var zoom_factor: float = 0.1

func _ready():
    custom_minimum_size = minimap_size
    size = minimap_size
    
    # Настройка viewport
    viewport.size = minimap_size
    viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    
    # Получаем основную камеру
    main_camera = get_tree().get_first_node_in_group("camera")
    
    # Получаем размер карты
    var map = get_tree().get_first_node_in_group("map")
    if map:
        map_size = Vector2(map.map_width * map.tile_size, map.map_height * map.tile_size)
        
        # Настраиваем камеру мини-карты
        minimap_camera.position = map_size / 2
        minimap_camera.zoom = Vector2(zoom_factor, zoom_factor)

func _process(_delta):
    if main_camera:
        draw_camera_rect()

func draw_camera_rect():
    # Рисуем прямоугольник, показывающий область основной камеры
    queue_redraw()

func _draw():
    if not main_camera:
        return
    
    # Вычисляем позицию и размер прямоугольника камеры на мини-карте
    var viewport_size = get_viewport().get_visible_rect().size
    var camera_rect_size = viewport_size / main_camera.zoom / map_size * minimap_size
    var camera_rect_pos = (main_camera.position / map_size * minimap_size) - camera_rect_size / 2
    
    # Рисуем рамку
    draw_rect(
        Rect2(camera_rect_pos, camera_rect_size),
        Color(1, 1, 1, 0.5),
        false,
        2.0
    )

func _gui_input(event):
    if event is InputEventMouseButton and event.pressed:
        if event.button_index == MOUSE_BUTTON_LEFT:
            # Клик по мини-карте перемещает камеру
            var click_pos = event.position
            var world_pos = (click_pos / minimap_size) * map_size
            
            if main_camera:
                main_camera.focus_on_position(world_pos, true)
```

---

## Интеграция и тестирование

### 1. Интеграция PathfindingSystem с визуальной картой

**Обновление PathfindingSystem.gd:**
```gdscript
# scripts/systems/PathfindingSystem.gd
extends Node

const Constants = preload("res://scripts/utils/Constants.gd")

var astar: AStar2D = AStar2D.new()
var map_size: Vector2
var tile_size: int = Constants.TILE_SIZE
var map_reference: Map = null

func initialize(map_width: int, map_height: int, map: Map = null):
    map_size = Vector2(map_width, map_height)
    map_reference = map
    _build_astar_grid()

func _build_astar_grid():
    astar.clear()
    
    # Создаем узлы для каждого тайла
    for x in range(map_size.x):
        for y in range(map_size.y):
            var id = _get_point_id(x, y)
            astar.add_point(id, Vector2(x, y))
    
    # Соединяем соседние узлы с учетом проходимости
    for x in range(map_size.x):
        for y in range(map_size.y):
            var id = _get_point_id(x, y)
            
            # Проверяем проходимость текущего тайла
            if map_reference and not map_reference.is_walkable(x, y):
                astar.set_point_disabled(id, true)
                continue
            
            # 8 направлений (включая диагонали)
            var directions = [
                Vector2i(-1, 0), Vector2i(1, 0),   # Лево, Право
                Vector2i(0, -1), Vector2i(0, 1),   # Верх, Низ
                Vector2i(-1, -1), Vector2i(1, -1), # Диагонали верх
                Vector2i(-1, 1), Vector2i(1, 1)    # Диагонали низ
            ]
            
            for dir in directions:
                var nx = x + dir.x
                var ny = y + dir.y
                
                if nx >= 0 and nx < map_size.x and ny >= 0 and ny < map_size.y:
                    if not map_reference or map_reference.is_walkable(nx, ny):
                        var neighbor_id = _get_point_id(nx, ny)
                        
                        # Для диагоналей увеличиваем вес
                        var weight = 1.0
                        if abs(dir.x) + abs(dir.y) == 2:
                            weight = 1.414  # sqrt(2)
                        
                        astar.connect_points(id, neighbor_id)
                        astar.set_point_weight_scale(id, weight)

func find_path(from: Vector2, to: Vector2) -> Array:
    var from_id = _get_point_id(int(from.x), int(from.y))
    var to_id = _get_point_id(int(to.x), int(to.y))
    
    # Проверяем валидность точек
    if not astar.has_point(from_id) or not astar.has_point(to_id):
        return []
    
    if astar.is_point_disabled(from_id) or astar.is_point_disabled(to_id):
        return []
    
    var path = astar.get_point_path(from_id, to_id)
    
    # Оптимизация пути (удаление лишних точек на прямых линиях)
    return optimize_path(path)

func optimize_path(path: Array) -> Array:
    if path.size() <= 2:
        return path
    
    var optimized = [path[0]]
    var current_direction = Vector2.ZERO
    
    for i in range(1, path.size()):
        var new_direction = (path[i] - path[i-1]).normalized()
        
        if new_direction != current_direction:
            optimized.append(path[i-1])
            current_direction = new_direction
    
    optimized.append(path[path.size() - 1])
    return optimized

func _get_point_id(x: int, y: int) -> int:
    return x + y * int(map_size.x)

func set_point_disabled(x: int, y: int, disabled: bool):
    var id = _get_point_id(x, y)
    if astar.has_point(id):
        astar.set_point_disabled(id, disabled)

func update_walkability(x: int, y: int, walkable: bool):
    set_point_disabled(x, y, not walkable)
```

---

### 2. Демо-сцена для тестирования

**Создание TestScene.gd:**
```gdscript
# scenes/test/TestScene.gd
extends Node2D

@onready var map = $Map
@onready var camera = $Camera
@onready var ui = $UI

var test_units: Array = []
var spawn_timer: float = 0.0

func _ready():
    setup_test_environment()
    spawn_test_units(10)

func setup_test_environment():
    # Инициализация систем
    var pathfinding = get_node("/root/PathfindingSystem")
    pathfinding.initialize(map.map_width, map.map_height, map)
    
    # Настройка камеры
    camera.add_to_group("camera")
    camera.position = Vector2(
        map.map_width * map.tile_size / 2,
        map.map_height * map.tile_size / 2
    )

func spawn_test_units(count: int):
    var unit_scene = preload("res://scenes/units/BaseUnit.tscn")
    
    for i in range(count):
        var unit = unit_scene.instantiate()
        unit.race = Constants.RACE_CANIDS
        
        # Случайная позиция на карте
        var x = randi() % map.map_width
        var y = randi() % map.map_height
        
        # Проверяем проходимость
        while not map.is_walkable(x, y):
            x = randi() % map.map_width
            y = randi() % map.map_height
        
        unit.global_position = map.get_world_position_from_tile(x, y)
        add_child(unit)
        test_units.append(unit)

func _process(delta):
    spawn_timer += delta
    
    # Каждые 5 секунд отправляем случайного юнита в случайную точку
    if spawn_timer >= 5.0:
        spawn_timer = 0.0
        test_random_movement()

func test_random_movement():
    if test_units.is_empty():
        return
    
    var unit = test_units[randi() % test_units.size()]
    var target_x = randi() % map.map_width
    var target_y = randi() % map.map_height
    
    while not map.is_walkable(target_x, target_y):
        target_x = randi() % map.map_width
        target_y = randi() % map.map_height
    
    var target_pos = map.get_world_position_from_tile(target_x, target_y)
    unit.move_to(target_pos)

func _input(event):
    # Горячие клавиши для тестирования
    if event is InputEventKey and event.pressed:
        match event.keycode:
            KEY_F1:
                spawn_test_units(10)
            KEY_F2:
                clear_all_units()
            KEY_F3:
                test_performance()

func clear_all_units():
    for unit in test_units:
        unit.queue_free()
    test_units.clear()

func test_performance():
    print("=== Performance Test ===")
    print("Units count: ", test_units.size())
    print("FPS: ", Engine.get_frames_per_second())
    print("Memory: ", OS.get_static_memory_usage() / 1024.0 / 1024.0, " MB")
```

---

## Критерии приемки

### Функциональные требования

#### Карта и навигация
- [x] Карта генерируется процедурно
- [ ] Карта отображается визуально с разными типами местности
- [ ] Камера перемещается клавишами WASD
- [ ] Камера зумируется колесиком мыши
- [ ] Камера перемещается перетаскиванием средней кнопкой
- [ ] Камера ограничена границами карты
- [ ] Движение камеры плавное

#### Юниты
- [x] Юниты создаются и отображаются
- [x] Юниты двигаются по клику правой кнопкой
- [ ] Путь движения визуализируется
- [ ] Юниты избегают столкновений
- [ ] Юниты выделяются кликом
- [ ] Работает выделение рамкой
- [ ] Выделенные юниты имеют визуальный индикатор
- [ ] Работает групповое управление

#### UI
- [ ] Панель информации показывает данные выбранного юнита
- [ ] Health bar отображается над юнитами
- [ ] Мини-карта работает и кликабельна
- [ ] Все UI элементы читаемы и понятны

### Технические требования

#### Производительность
- [ ] 60 FPS с 50 юнитами
- [ ] 60 FPS с 100 юнитами (желательно)
- [ ] Время загрузки < 5 секунд
- [ ] Использование памяти < 500 MB

#### Качество кода
- [ ] Код следует стандартам GDScript
- [ ] Все публичные функции задокументированы
- [ ] Нет критических предупреждений
- [ ] Код покрыт базовыми тестами

---

## Чек-лист перед завершением фазы

### Неделя 1-2
- [ ] Тайлсет создан и интегрирован
- [ ] TileMap отображает карту
- [ ] Камера полностью функциональна
- [ ] Система чанков работает
- [ ] Оптимизация рендеринга завершена

### Неделя 3-4
- [ ] Движение юнитов улучшено
- [ ] Визуализация пути работает
- [ ] Избегание столкновений реализовано
- [ ] Система выделения полностью работает
- [ ] UI панели созданы и функциональны
- [ ] Мини-карта работает

### Интеграция
- [ ] PathfindingSystem интегрирован с картой
- [ ] Все системы работают вместе
- [ ] Производительность соответствует требованиям
- [ ] Демо-сцена создана и работает

### Документация
- [ ] Техническая документация обновлена
- [ ] API задокументирован
- [ ] Руководство для тестеров создано
- [ ] Известные проблемы задокументированы

---

## Следующие шаги

После завершения Фазы 3.1 переходим к **Фазе 3.2: Базовая экономика**:
1. Система ресурсов
2. Добыча ресурсов
3. Строительство
4. Базовые постройки

---

**Удачи в реализации! 🚀**