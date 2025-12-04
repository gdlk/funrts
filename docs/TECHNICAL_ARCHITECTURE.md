# Техническая архитектура: Три Расы
## Выбор технологий и архитектурные решения

**Версия:** 1.0  
**Дата:** 01.12.2024

---

## 1. Выбор технологического стека

### 1.1 Рекомендуемый стек (Приоритет 1)

**Движок: Godot 4.x**

**Обоснование:**
- ✅ **Бесплатный и open-source** — нет лицензионных отчислений
- ✅ **Отличная 2D поддержка** — оптимизирован для 2D игр
- ✅ **Легкий вес** — быстрая загрузка и компиляция
- ✅ **Кроссплатформенность** — Windows, macOS, Linux, Web
- ✅ **GDScript** — простой язык, похожий на Python
- ✅ **Встроенный редактор** — все в одном месте
- ✅ **Активное сообщество** — много туториалов и ресурсов
- ✅ **Подходит для инди** — используется многими успешными инди-играми

**Языки программирования:**
- **GDScript** (основной) — для игровой логики
- **C#** (опционально) — для производительных участков

**Дополнительные инструменты:**
- **Aseprite** — создание пиксель-арт спрайтов
- **Tiled** — редактор карт (экспорт в Godot)
- **GIMP/Krita** — графика
- **Audacity** — звуковые эффекты
- **Git** — контроль версий

---

### 1.2 Альтернативный стек (Приоритет 2)

**Движок: Unity 2D**

**Обоснование:**
- ✅ **Мощный и зрелый** — проверенная технология
- ✅ **Большое сообщество** — много ресурсов
- ✅ **Asset Store** — готовые ассеты и инструменты
- ✅ **C#** — популярный язык
- ⚠️ **Лицензия** — бесплатно до $200k дохода
- ⚠️ **Тяжелее Godot** — больше размер и требования

**Когда выбирать Unity:**
- Если уже знаете C# и Unity
- Если планируете мобильные версии
- Если нужны готовые ассеты из Asset Store

---

### 1.3 Веб-версия (Приоритет 3)

**Стек: TypeScript + PixiJS/Phaser**

**Обоснование:**
- ✅ **Доступность** — играть в браузере
- ✅ **Быстрое распространение** — не нужна установка
- ✅ **TypeScript** — типизированный JavaScript
- ⚠️ **Производительность** — ограничения браузера
- ⚠️ **Больше работы** — нужно писать больше с нуля

**Когда выбирать веб:**
- Если хотите максимальную доступность
- Если планируете itch.io релиз
- Если есть опыт веб-разработки

---

## 2. Архитектура игры (Godot)

### 2.1 Структура проекта

```
funrts/
├── project.godot
├── assets/
│   ├── sprites/
│   │   ├── lizards/
│   │   ├── canids/
│   │   └── rus/
│   ├── audio/
│   │   ├── music/
│   │   └── sfx/
│   ├── fonts/
│   └── ui/
├── scenes/
│   ├── main/
│   │   ├── Main.tscn
│   │   └── Main.gd
│   ├── game/
│   │   ├── Game.tscn
│   │   └── Game.gd
│   ├── ui/
│   │   ├── MainMenu.tscn
│   │   ├── HUD.tscn
│   │   └── BuildMenu.tscn
│   ├── units/
│   │   ├── BaseUnit.tscn
│   │   ├── LizardUnit.tscn
│   │   ├── CanidUnit.tscn
│   │   └── RusUnit.tscn
│   ├── buildings/
│   │   ├── BaseBuilding.tscn
│   │   └── [расовые постройки]
│   └── world/
│       ├── Tile.tscn
│       ├── Map.tscn
│       └── MapGenerator.gd
├── scripts/
│   ├── autoload/
│   │   ├── GameManager.gd
│   │   ├── ResourceManager.gd
│   │   ├── EventBus.gd
│   │   └── SaveSystem.gd
│   ├── systems/
│   │   ├── PathfindingSystem.gd
│   │   ├── ProductionSystem.gd
│   │   ├── NeedsSystem.gd
│   │   └── CombatSystem.gd
│   ├── data/
│   │   ├── UnitData.gd
│   │   ├── BuildingData.gd
│   │   └── ResourceData.gd
│   └── utils/
│       ├── Constants.gd
│       └── Helpers.gd
└── data/
    ├── units/
    ├── buildings/
    ├── resources/
    └── events/
```

---

### 2.2 Основные системы

#### 2.2.1 GameManager (Autoload)

Центральный менеджер игры, управляющий глобальным состоянием.

```gdscript
# scripts/autoload/GameManager.gd
extends Node

# Глобальные переменные
var current_race: String = ""
var game_speed: float = 1.0
var is_paused: bool = false
var game_time: float = 0.0

# Ссылки на системы
var resource_manager: ResourceManager
var event_bus: EventBus

func _ready():
    resource_manager = get_node("/root/ResourceManager")
    event_bus = get_node("/root/EventBus")

func _process(delta):
    if not is_paused:
        game_time += delta * game_speed
        
func pause_game():
    is_paused = true
    get_tree().paused = true
    
func resume_game():
    is_paused = false
    get_tree().paused = false
    
func set_game_speed(speed: float):
    game_speed = clamp(speed, 0.5, 3.0)
```

---

#### 2.2.2 ResourceManager (Autoload)

Управление всеми ресурсами в игре.

```gdscript
# scripts/autoload/ResourceManager.gd
extends Node

# Словарь ресурсов: {"wood": 100, "stone": 50, ...}
var resources: Dictionary = {}

signal resource_changed(resource_name: String, amount: int)

func add_resource(resource_name: String, amount: int):
    if not resources.has(resource_name):
        resources[resource_name] = 0
    resources[resource_name] += amount
    emit_signal("resource_changed", resource_name, resources[resource_name])

func remove_resource(resource_name: String, amount: int) -> bool:
    if not has_resource(resource_name, amount):
        return false
    resources[resource_name] -= amount
    emit_signal("resource_changed", resource_name, resources[resource_name])
    return true

func has_resource(resource_name: String, amount: int) -> bool:
    return resources.get(resource_name, 0) >= amount

func get_resource(resource_name: String) -> int:
    return resources.get(resource_name, 0)
```

---

#### 2.2.3 EventBus (Autoload)

Система событий для связи между компонентами.

```gdscript
# scripts/autoload/EventBus.gd
extends Node

# Сигналы для различных событий
signal unit_selected(unit)
signal unit_died(unit)
signal building_constructed(building)
signal building_destroyed(building)
signal resource_depleted(resource_node)
signal enemy_raid_started()
signal day_passed()
signal season_changed(season)

# Можно добавлять новые сигналы по мере необходимости
```

---

#### 2.2.4 PathfindingSystem

A* алгоритм для поиска пути.

```gdscript
# scripts/systems/PathfindingSystem.gd
extends Node

class_name PathfindingSystem

var astar: AStar2D = AStar2D.new()
var map_size: Vector2
var tile_size: int = 32

func initialize(map_width: int, map_height: int):
    map_size = Vector2(map_width, map_height)
    _build_astar_grid()

func _build_astar_grid():
    # Создаем узлы для каждого тайла
    for x in range(map_size.x):
        for y in range(map_size.y):
            var id = _get_point_id(x, y)
            astar.add_point(id, Vector2(x, y))
    
    # Соединяем соседние узлы
    for x in range(map_size.x):
        for y in range(map_size.y):
            var id = _get_point_id(x, y)
            # 4 направления (можно добавить диагонали)
            if x > 0:
                astar.connect_points(id, _get_point_id(x-1, y))
            if x < map_size.x - 1:
                astar.connect_points(id, _get_point_id(x+1, y))
            if y > 0:
                astar.connect_points(id, _get_point_id(x, y-1))
            if y < map_size.y - 1:
                astar.connect_points(id, _get_point_id(x, y+1))

func find_path(from: Vector2, to: Vector2) -> Array:
    var from_id = _get_point_id(int(from.x), int(from.y))
    var to_id = _get_point_id(int(to.x), int(to.y))
    return astar.get_point_path(from_id, to_id)

func _get_point_id(x: int, y: int) -> int:
    return x + y * int(map_size.x)

func set_point_disabled(x: int, y: int, disabled: bool):
    var id = _get_point_id(x, y)
    astar.set_point_disabled(id, disabled)
```

---

#### 2.2.5 NeedsSystem

Система потребностей юнитов.

```gdscript
# scripts/systems/NeedsSystem.gd
extends Node

class_name NeedsSystem

const NEED_DECAY_RATE = {
    "hunger": 1.0,      # Голод уменьшается на 1 в секунду
    "rest": 0.5,        # Усталость на 0.5 в секунду
    "comfort": 0.2,     # Комфорт на 0.2 в секунду
    "social": 0.3,      # Социализация на 0.3 в секунду
}

func update_needs(unit, delta: float):
    for need in unit.needs:
        var decay = NEED_DECAY_RATE.get(need, 0.1)
        unit.needs[need] = max(0, unit.needs[need] - decay * delta)
    
    # Обновляем настроение на основе потребностей
    update_mood(unit)

func update_mood(unit):
    var total_needs = 0.0
    var need_count = unit.needs.size()
    
    for need_value in unit.needs.values():
        total_needs += need_value
    
    var average_need = total_needs / need_count if need_count > 0 else 50.0
    
    # Настроение от -100 до +100
    unit.mood = (average_need - 50) * 2
    
    # Применяем эффекты настроения
    apply_mood_effects(unit)

func apply_mood_effects(unit):
    if unit.mood > 50:
        unit.work_speed_modifier = 1.2
    elif unit.mood < -50:
        unit.work_speed_modifier = 0.8
    else:
        unit.work_speed_modifier = 1.0
```

---

### 2.3 Архитектура юнитов

#### Базовый класс Unit

```gdscript
# scenes/units/BaseUnit.gd
extends CharacterBody2D

class_name BaseUnit

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

# Текущее состояние
enum State { IDLE, MOVING, WORKING, FIGHTING, SLEEPING, EATING }
var current_state: State = State.IDLE

# Текущая задача
var current_task = null

# Путь движения
var path: Array = []
var path_index: int = 0

signal task_completed()
signal died()

func _ready():
    add_to_group("units")
    unit_name = _generate_name()

func _process(delta):
    match current_state:
        State.IDLE:
            _process_idle(delta)
        State.MOVING:
            _process_moving(delta)
        State.WORKING:
            _process_working(delta)
        State.FIGHTING:
            _process_fighting(delta)
        State.SLEEPING:
            _process_sleeping(delta)
        State.EATING:
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
        current_state = State.IDLE
        return
    
    var target = path[path_index]
    var direction = (target - global_position).normalized()
    velocity = direction * 100 * work_speed_modifier
    move_and_slide()
    
    if global_position.distance_to(target) < 5:
        path_index += 1
        if path_index >= path.size():
            path.clear()
            current_state = State.IDLE
            if current_task:
                start_working()

func move_to(target_position: Vector2):
    var pathfinding = get_node("/root/PathfindingSystem")
    path = pathfinding.find_path(global_position, target_position)
    path_index = 0
    current_state = State.MOVING

func take_damage(amount: float):
    health -= amount
    if health <= 0:
        die()

func die():
    emit_signal("died")
    queue_free()

func _generate_name() -> String:
    # Генерация случайного имени
    var names = ["Грок", "Зара", "Торн", "Лира", "Крок"]
    return names[randi() % names.size()]

# Переопределяется в подклассах
func _process_working(delta):
    pass

func _process_fighting(delta):
    pass

func _process_sleeping(delta):
    needs["rest"] = min(100, needs["rest"] + 20 * delta)
    if needs["rest"] >= 100:
        current_state = State.IDLE

func _process_eating(delta):
    needs["hunger"] = min(100, needs["hunger"] + 30 * delta)
    if needs["hunger"] >= 100:
        current_state = State.IDLE

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
    current_state = State.WORKING
```

---

### 2.4 Архитектура построек

#### Базовый класс Building

```gdscript
# scenes/buildings/BaseBuilding.gd
extends StaticBody2D

class_name BaseBuilding

# Основные параметры
var building_name: String = ""
var building_type: String = ""
var race: String = ""

# Состояние
enum State { BLUEPRINT, CONSTRUCTING, OPERATIONAL, DAMAGED, DESTROYED }
var current_state: State = State.BLUEPRINT

# Здоровье
var health: float = 100.0
var max_health: float = 100.0

# Строительство
var construction_progress: float = 0.0
var required_resources: Dictionary = {}
var delivered_resources: Dictionary = {}

# Производство (если применимо)
var production_queue: Array = []
var production_progress: float = 0.0
var production_speed: float = 1.0

# Рабочие
var assigned_workers: Array = []
var max_workers: int = 1

signal construction_completed()
signal production_completed(item)
signal destroyed()

func _ready():
    add_to_group("buildings")

func _process(delta):
    match current_state:
        State.CONSTRUCTING:
            _process_construction(delta)
        State.OPERATIONAL:
            _process_operation(delta)
        State.DAMAGED:
            _process_damaged(delta)

func _process_construction(delta):
    if _has_all_resources():
        construction_progress += delta * 10 * assigned_workers.size()
        if construction_progress >= 100:
            complete_construction()

func _process_operation(delta):
    if not production_queue.is_empty():
        production_progress += delta * production_speed * assigned_workers.size()
        if production_progress >= 100:
            complete_production()

func _process_damaged(delta):
    # Логика для поврежденного здания
    pass

func deliver_resource(resource_name: String, amount: int):
    if not delivered_resources.has(resource_name):
        delivered_resources[resource_name] = 0
    delivered_resources[resource_name] += amount

func _has_all_resources() -> bool:
    for resource in required_resources:
        if delivered_resources.get(resource, 0) < required_resources[resource]:
            return false
    return true

func complete_construction():
    current_state = State.OPERATIONAL
    construction_progress = 100
    emit_signal("construction_completed")

func add_to_production_queue(item):
    production_queue.append(item)

func complete_production():
    var item = production_queue.pop_front()
    production_progress = 0
    emit_signal("production_completed", item)

func assign_worker(worker):
    if assigned_workers.size() < max_workers:
        assigned_workers.append(worker)

func remove_worker(worker):
    assigned_workers.erase(worker)

func take_damage(amount: float):
    health -= amount
    if health <= 0:
        destroy()
    elif health < max_health * 0.5:
        current_state = State.DAMAGED

func destroy():
    current_state = State.DESTROYED
    emit_signal("destroyed")
    queue_free()
```

---

### 2.5 Система карты и тайлов

```gdscript
# scenes/world/Map.gd
extends Node2D

class_name Map

var map_width: int = 128
var map_height: int = 128
var tile_size: int = 32

# Двумерный массив тайлов
var tiles: Array = []

# TileMap для отрисовки
@onready var tilemap: TileMap = $TileMap

func _ready():
    generate_map()

func generate_map():
    tiles.clear()
    
    # Создаем двумерный массив
    for x in range(map_width):
        tiles.append([])
        for y in range(map_height):
            var tile = create_tile(x, y)
            tiles[x].append(tile)
            tilemap.set_cell(0, Vector2i(x, y), 0, tile.terrain_type)

func create_tile(x: int, y: int) -> Dictionary:
    # Простая генерация с шумом Перлина
    var noise = FastNoiseLite.new()
    noise.seed = randi()
    var value = noise.get_noise_2d(x, y)
    
    var tile = {
        "position": Vector2(x, y),
        "terrain_type": _get_terrain_from_noise(value),
        "resources": [],
        "walkable": true,
        "building": null
    }
    
    return tile

func _get_terrain_from_noise(value: float) -> int:
    if value < -0.3:
        return 0  # Вода
    elif value < 0.0:
        return 1  # Равнина
    elif value < 0.3:
        return 2  # Лес
    else:
        return 3  # Горы

func get_tile(x: int, y: int):
    if x >= 0 and x < map_width and y >= 0 and y < map_height:
        return tiles[x][y]
    return null

func is_walkable(x: int, y: int) -> bool:
    var tile = get_tile(x, y)
    return tile != null and tile.walkable and tile.building == null
```

---

## 3. Оптимизация производительности

### 3.1 Стратегии оптимизации

**1. Пространственное разбиение (Spatial Partitioning)**
```gdscript
# Используем встроенную систему групп Godot
# Разделяем карту на чанки для эффективного поиска
class_name ChunkManager

var chunk_size: int = 32
var chunks: Dictionary = {}

func get_chunk_key(position: Vector2) -> Vector2i:
    return Vector2i(
        int(position.x / chunk_size),
        int(position.y / chunk_size)
    )

func add_to_chunk(entity, position: Vector2):
    var key = get_chunk_key(position)
    if not chunks.has(key):
        chunks[key] = []
    chunks[key].append(entity)

func get_nearby_entities(position: Vector2, radius: int) -> Array:
    var result = []
    var center_chunk = get_chunk_key(position)
    var chunk_radius = int(radius / chunk_size) + 1
    
    for x in range(-chunk_radius, chunk_radius + 1):
        for y in range(-chunk_radius, chunk_radius + 1):
            var key = center_chunk + Vector2i(x, y)
            if chunks.has(key):
                result.append_array(chunks[key])
    
    return result
```

**2. Object Pooling**
```gdscript
# Переиспользование объектов вместо создания новых
class_name ObjectPool

var pool: Array = []
var scene: PackedScene

func _init(scene_path: String, initial_size: int = 10):
    scene = load(scene_path)
    for i in range(initial_size):
        var obj = scene.instantiate()
        obj.visible = false
        pool.append(obj)

func get_object():
    if pool.is_empty():
        return scene.instantiate()
    var obj = pool.pop_back()
    obj.visible = true
    return obj

func return_object(obj):
    obj.visible = false
    pool.append(obj)
```

**3. Ленивые вычисления**
```gdscript
# Обновляем только видимые объекты
func _process(delta):
    var camera_rect = get_viewport_rect()
    for unit in get_tree().get_nodes_in_group("units"):
        if camera_rect.has_point(unit.global_position):
            unit.update_logic(delta)
        else:
            unit.update_minimal(delta)  # Минимальное обновление
```

**4. Мультипоточность для тяжелых операций**
```gdscript
# Генерация карты в отдельном потоке
var thread: Thread

func generate_map_async():
    thread = Thread.new()
    thread.start(_generate_map_thread)

func _generate_map_thread():
    # Тяжелые вычисления
    var map_data = _generate_large_map()
    call_deferred("_on_map_generated", map_data)

func _on_map_generated(map_data):
    # Применяем результат в основном потоке
    apply_map_data(map_data)
    thread.wait_to_finish()
```

---

### 3.2 Профилирование

**Встроенный профайлер Godot:**
- Debugger → Profiler
- Monitors → Performance

**Ключевые метрики:**
- FPS (должно быть 60+)
- Process Time (< 16ms для 60 FPS)
- Physics Time (< 5ms)
- Memory Usage (< 500MB для средней игры)

---

## 4. Система сохранений

### 4.1 Формат сохранения

```gdscript
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
```

---

## 5. Модульность и расширяемость

### 5.1 Система модов

```gdscript
# scripts/ModLoader.gd
extends Node

const MODS_PATH = "user://mods/"

func load_mods():
    var dir = DirAccess.open(MODS_PATH)
    if dir:
        dir.list_dir_begin()
        var file_name = dir.get_next()
        while file_name != "":
            if dir.current_is_dir() and file_name != "." and file_name != "..":
                load_mod(file_name)
            file_name = dir.get_next()

func load_mod(mod_name: String):
    var mod_path = MODS_PATH + mod_name + "/mod.gd"
    if FileAccess.file_exists(mod_path):
        var mod_script = load(mod_path)
        var mod_instance = mod_script.new()
        mod_instance.initialize()
```

### 5.2 Система данных (Data-Driven Design)

Все игровые данные хранятся в JSON/YAML файлах:

```json
// data/units/lizard_worker.json
{
    "id": "lizard_worker",
    "name": "Ящер-рабочий",
    "race": "lizards",
    "base_stats": {
        "health": 100,
        "strength": 5,
        "agility": 4,
        "intelligence": 3,
        "endurance": 6
    },
    "skills": {
        "mining": 10,
        "building": 15,
        "combat": 5,
        "crafting": 8
    },
    "sprite":