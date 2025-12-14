# ECS Архитектура для "Три Расы"
## Переход на Entity-Component-System

**Версия:** 1.0  
**Дата:** 14.12.2024  
**Статус:** Проектирование

---

## 1. Рекомендация: Гибридный подход для Godot RTS

### 1.1 Обоснование выбора

После анализа вашего проекта и лучших практик для Godot RTS-игр, я рекомендую **гибридный подход**:

**Почему гибридный подход оптимален:**

✅ **Сохранение преимуществ Godot:**
- Godot имеет мощную систему Node для визуализации и физики
- CharacterBody2D и StaticBody2D отлично работают для коллизий
- Встроенные сигналы и система событий

✅ **Производительность где нужно:**
- ECS для логики симуляции (потребности, производство, AI)
- Массовая обработка данных без overhead виртуальных вызовов
- Cache-friendly обработка однотипных данных

✅ **Постепенная миграция:**
- Можно внедрять ECS поэтапно
- Минимальный риск поломки существующего кода
- Легче тестировать и отлаживать

✅ **Масштабируемость:**
- ECS отлично подходит для 200+ юнитов
- Легко добавлять новые компоненты и системы
- Параллелизация систем в будущем

### 1.2 Архитектурная модель

```
┌─────────────────────────────────────────────────────────────┐
│                    GODOT SCENE TREE                         │
│  (Визуализация, Физика, Input, Рендеринг)                  │
└─────────────────────┬───────────────────────────────────────┘
                      │
                      ↓
┌─────────────────────────────────────────────────────────────┐
│                   HYBRID LAYER                              │
│  (Связь между Node и ECS Entity)                           │
└─────────────────────┬───────────────────────────────────────┘
                      │
                      ↓
┌─────────────────────────────────────────────────────────────┐
│                    ECS WORLD                                │
│  (Логика симуляции, AI, Потребности, Производство)         │
│                                                             │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐                 │
│  │ Entities │  │Components│  │ Systems  │                 │
│  └──────────┘  └──────────┘  └──────────┘                 │
└─────────────────────────────────────────────────────────────┘
```

---

## 2. Архитектура ECS

### 2.1 Базовые концепции

#### Entity (Сущность)
```gdscript
# Просто уникальный ID
class_name Entity
extends RefCounted

var id: int
var is_active: bool = true

func _init(entity_id: int):
    id = entity_id
```

#### Component (Компонент)
```gdscript
# Базовый класс для всех компонентов
class_name Component
extends RefCounted

# Компоненты содержат только данные, без логики
```

#### System (Система)
```gdscript
# Базовый класс для всех систем
class_name System
extends Node

# Системы содержат логику обработки компонентов
func process_entities(delta: float, entities: Array):
    pass
```

### 2.2 ECS World Manager

```gdscript
# scripts/ecs/ECSWorld.gd
class_name ECSWorld
extends Node

# Хранилище всех сущностей
var entities: Dictionary = {}  # {entity_id: Entity}
var next_entity_id: int = 0

# Хранилище компонентов по типам
var components: Dictionary = {}  # {component_type: {entity_id: component}}

# Системы
var systems: Array[System] = []

# Индексы для быстрого поиска
var entity_queries: Dictionary = {}  # Кэш запросов

func _ready():
    setup_systems()

func _process(delta: float):
    for system in systems:
        system.process(delta, self)

# === Entity Management ===

func create_entity() -> Entity:
    var entity = Entity.new(next_entity_id)
    entities[next_entity_id] = entity
    next_entity_id += 1
    return entity

func destroy_entity(entity_id: int):
    if not entities.has(entity_id):
        return
    
    # Удаляем все компоненты
    for component_type in components:
        if components[component_type].has(entity_id):
            components[component_type].erase(entity_id)
    
    entities.erase(entity_id)
    
    # Очищаем кэш запросов
    entity_queries.clear()

# === Component Management ===

func add_component(entity_id: int, component: Component):
    var component_type = component.get_script().get_path()
    
    if not components.has(component_type):
        components[component_type] = {}
    
    components[component_type][entity_id] = component
    
    # Очищаем кэш запросов
    entity_queries.clear()

func get_component(entity_id: int, component_type: String):
    if not components.has(component_type):
        return null
    return components[component_type].get(entity_id)

func has_component(entity_id: int, component_type: String) -> bool:
    return components.has(component_type) and components[component_type].has(entity_id)

func remove_component(entity_id: int, component_type: String):
    if components.has(component_type):
        components[component_type].erase(entity_id)
        entity_queries.clear()

# === Query System ===

func query(component_types: Array) -> Array:
    # Создаем ключ для кэша
    var cache_key = "_".join(component_types)
    
    if entity_queries.has(cache_key):
        return entity_queries[cache_key]
    
    var result = []
    
    # Находим все entity с нужными компонентами
    for entity_id in entities:
        var has_all = true
        for comp_type in component_types:
            if not has_component(entity_id, comp_type):
                has_all = false
                break
        
        if has_all:
            result.append(entity_id)
    
    entity_queries[cache_key] = result
    return result

# === System Management ===

func setup_systems():
    # Порядок важен! Системы выполняются последовательно
    add_system(NeedsSystem.new())
    add_system(MovementSystem.new())
    add_system(ProductionSystem.new())
    add_system(CombatSystem.new())
    add_system(AISystem.new())

func add_system(system: System):
    systems.append(system)
    add_child(system)
```

---

## 3. Компоненты

### 3.1 Базовые компоненты

#### TransformComponent
```gdscript
# scripts/ecs/components/TransformComponent.gd
class_name TransformComponent
extends Component

var position: Vector2 = Vector2.ZERO
var rotation: float = 0.0
var scale: Vector2 = Vector2.ONE

# Ссылка на Node для синхронизации
var node_ref: Node2D = null
```

#### HealthComponent
```gdscript
# scripts/ecs/components/HealthComponent.gd
class_name HealthComponent
extends Component

var current: float = 100.0
var maximum: float = 100.0
var regeneration_rate: float = 0.0

func is_alive() -> bool:
    return current > 0

func take_damage(amount: float):
    current = max(0, current - amount)

func heal(amount: float):
    current = min(maximum, current + amount)

func get_health_percentage() -> float:
    return current / maximum if maximum > 0 else 0.0
```

#### VelocityComponent
```gdscript
# scripts/ecs/components/VelocityComponent.gd
class_name VelocityComponent
extends Component

var velocity: Vector2 = Vector2.ZERO
var max_speed: float = 100.0
var acceleration: float = 500.0
var friction: float = 0.9
```

### 3.2 Компоненты юнитов

#### NeedsComponent
```gdscript
# scripts/ecs/components/NeedsComponent.gd
class_name NeedsComponent
extends Component

var hunger: float = 100.0      # 0-100
var rest: float = 100.0         # 0-100
var comfort: float = 50.0       # 0-100
var social: float = 50.0        # 0-100

# Скорости изменения
var hunger_decay: float = 1.0
var rest_decay: float = 0.5
var comfort_decay: float = 0.2
var social_decay: float = 0.3

func get_average() -> float:
    return (hunger + rest + comfort + social) / 4.0

func get_mood() -> float:
    # Настроение от -100 до +100
    return (get_average() - 50) * 2
```

#### SkillsComponent
```gdscript
# scripts/ecs/components/SkillsComponent.gd
class_name SkillsComponent
extends Component

var mining: int = 0         # 0-100
var building: int = 0       # 0-100
var combat: int = 0         # 0-100
var crafting: int = 0       # 0-100

func improve_skill(skill_name: String, amount: int):
    match skill_name:
        "mining": mining = min(100, mining + amount)
        "building": building = min(100, building + amount)
        "combat": combat = min(100, combat + amount)
        "crafting": crafting = min(100, crafting + amount)
```

#### StatsComponent
```gdscript
# scripts/ecs/components/StatsComponent.gd
class_name StatsComponent
extends Component

var strength: int = 5
var agility: int = 5
var intelligence: int = 5
var endurance: int = 5

func get_work_speed_modifier() -> float:
    return 1.0 + (strength + agility) * 0.01
```

#### TaskComponent
```gdscript
# scripts/ecs/components/TaskComponent.gd
class_name TaskComponent
extends Component

enum TaskType {
    NONE,
    MOVE,
    GATHER,
    BUILD,
    CRAFT,
    FIGHT,
    EAT,
    SLEEP
}

var current_task: TaskType = TaskType.NONE
var task_target: int = -1  # Entity ID цели
var task_position: Vector2 = Vector2.ZERO
var task_progress: float = 0.0
```

#### PathComponent
```gdscript
# scripts/ecs/components/PathComponent.gd
class_name PathComponent
extends Component

var path: Array = []  # Array of Vector2
var current_index: int = 0
var target_position: Vector2 = Vector2.ZERO

func has_path() -> bool:
    return not path.is_empty() and current_index < path.size()

func get_next_point() -> Vector2:
    if has_path():
        return path[current_index]
    return Vector2.ZERO

func advance():
    current_index += 1

func clear():
    path.clear()
    current_index = 0
```

### 3.3 Компоненты зданий

#### BuildingComponent
```gdscript
# scripts/ecs/components/BuildingComponent.gd
class_name BuildingComponent
extends Component

enum State {
    BLUEPRINT,
    CONSTRUCTING,
    OPERATIONAL,
    DAMAGED,
    DESTROYED
}

var building_type: String = ""
var state: State = State.BLUEPRINT
var construction_progress: float = 0.0
```

#### ProductionComponent
```gdscript
# scripts/ecs/components/ProductionComponent.gd
class_name ProductionComponent
extends Component

var production_queue: Array = []  # Array of recipe names
var current_recipe: String = ""
var production_progress: float = 0.0
var production_speed: float = 1.0

func add_to_queue(recipe: String):
    production_queue.append(recipe)

func get_current_recipe():
    if production_queue.is_empty():
        return null
    return production_queue[0]
```

#### WorkersComponent
```gdscript
# scripts/ecs/components/WorkersComponent.gd
class_name WorkersComponent
extends Component

var assigned_workers: Array = []  # Array of entity IDs
var max_workers: int = 1

func can_assign() -> bool:
    return assigned_workers.size() < max_workers

func assign_worker(worker_id: int):
    if can_assign():
        assigned_workers.append(worker_id)

func remove_worker(worker_id: int):
    assigned_workers.erase(worker_id)

func get_worker_count() -> int:
    return assigned_workers.size()
```

### 3.4 Расовые компоненты

#### RaceComponent
```gdscript
# scripts/ecs/components/RaceComponent.gd
class_name RaceComponent
extends Component

enum Race {
    LIZARD,
    CANID,
    RUS
}

var race: Race = Race.LIZARD
var race_modifiers: Dictionary = {}

func get_race_name() -> String:
    match race:
        Race.LIZARD: return "lizard"
        Race.CANID: return "canid"
        Race.RUS: return "rus"
    return "unknown"
```

#### LizardBioComponent
```gdscript
# scripts/ecs/components/LizardBioComponent.gd
class_name LizardBioComponent
extends Component

var biomass: float = 100.0
var mutation_level: int = 0
var symbiosis_bonus: float = 1.0
```

#### CanidPackComponent
```gdscript
# scripts/ecs/components/CanidPackComponent.gd
class_name CanidPackComponent
extends Component

var pack_id: int = -1
var pack_role: String = "omega"  # alpha, beta, omega
var pack_bonus: float = 1.0
```

#### RusMechanicalComponent
```gdscript
# scripts/ecs/components/RusMechanicalComponent.gd
class_name RusMechanicalComponent
extends Component

var steam_power: float = 0.0
var efficiency: float = 1.0
var automation_level: int = 0
```

---

## 4. Системы

### 4.1 Базовая система

```gdscript
# scripts/ecs/systems/BaseSystem.gd
class_name BaseSystem
extends Node

# Каждая система определяет, какие компоненты ей нужны
func get_required_components() -> Array:
    return []

# Основной метод обработки
func process(delta: float, world: ECSWorld):
    var entities = world.query(get_required_components())
    process_entities(delta, world, entities)

# Переопределяется в подклассах
func process_entities(delta: float, world: ECSWorld, entities: Array):
    pass
```

### 4.2 NeedsSystem

```gdscript
# scripts/ecs/systems/NeedsSystem.gd
class_name NeedsSystem
extends BaseSystem

func get_required_components() -> Array:
    return [
        "res://scripts/ecs/components/NeedsComponent.gd"
    ]

func process_entities(delta: float, world: ECSWorld, entities: Array):
    for entity_id in entities:
        var needs = world.get_component(entity_id, "res://scripts/ecs/components/NeedsComponent.gd")
        
        # Уменьшаем потребности со временем
        needs.hunger = max(0, needs.hunger - needs.hunger_decay * delta)
        needs.rest = max(0, needs.rest - needs.rest_decay * delta)
        needs.comfort = max(0, needs.comfort - needs.comfort_decay * delta)
        needs.social = max(0, needs.social - needs.social_decay * delta)
        
        # Проверяем критические потребности
        check_critical_needs(entity_id, needs, world)

func check_critical_needs(entity_id: int, needs: NeedsComponent, world: ECSWorld):
    var task = world.get_component(entity_id, "res://scripts/ecs/components/TaskComponent.gd")
    if not task:
        return
    
    # Если голод критический - ищем еду
    if needs.hunger < 30 and task.current_task != TaskComponent.TaskType.EAT:
        task.current_task = TaskComponent.TaskType.EAT
        EventBus.emit_signal("unit_needs_food", entity_id)
    
    # Если усталость критическая - ищем кровать
    elif needs.rest < 30 and task.current_task != TaskComponent.TaskType.SLEEP:
        task.current_task = TaskComponent.TaskType.SLEEP
        EventBus.emit_signal("unit_needs_rest", entity_id)
```

### 4.3 MovementSystem

```gdscript
# scripts/ecs/systems/MovementSystem.gd
class_name MovementSystem
extends BaseSystem

func get_required_components() -> Array:
    return [
        "res://scripts/ecs/components/TransformComponent.gd",
        "res://scripts/ecs/components/VelocityComponent.gd",
        "res://scripts/ecs/components/PathComponent.gd"
    ]

func process_entities(delta: float, world: ECSWorld, entities: Array):
    for entity_id in entities:
        var transform = world.get_component(entity_id, "res://scripts/ecs/components/TransformComponent.gd")
        var velocity = world.get_component(entity_id, "res://scripts/ecs/components/VelocityComponent.gd")
        var path = world.get_component(entity_id, "res://scripts/ecs/components/PathComponent.gd")
        
        if not path.has_path():
            # Применяем трение
            velocity.velocity *= velocity.friction
            continue
        
        # Движение к следующей точке пути
        var target = path.get_next_point()
        var direction = (target - transform.position).normalized()
        
        # Ускорение к цели
        var desired_velocity = direction * velocity.max_speed
        var steering = desired_velocity - velocity.velocity
        velocity.velocity += steering * velocity.acceleration * delta
        
        # Ограничиваем скорость
        if velocity.velocity.length() > velocity.max_speed:
            velocity.velocity = velocity.velocity.normalized() * velocity.max_speed
        
        # Обновляем позицию
        transform.position += velocity.velocity * delta
        
        # Синхронизируем с Node
        if transform.node_ref:
            transform.node_ref.global_position = transform.position
        
        # Проверяем достижение точки
        if transform.position.distance_to(target) < 5:
            path.advance()
            if not path.has_path():
                velocity.velocity = Vector2.ZERO
                EventBus.emit_signal("unit_reached_destination", entity_id)
```

### 4.4 ProductionSystem

```gdscript
# scripts/ecs/systems/ProductionSystem.gd
class_name ProductionSystem
extends BaseSystem

func get_required_components() -> Array:
    return [
        "res://scripts/ecs/components/BuildingComponent.gd",
        "res://scripts/ecs/components/ProductionComponent.gd",
        "res://scripts/ecs/components/WorkersComponent.gd"
    ]

func process_entities(delta: float, world: ECSWorld, entities: Array):
    for entity_id in entities:
        var building = world.get_component(entity_id, "res://scripts/ecs/components/BuildingComponent.gd")
        var production = world.get_component(entity_id, "res://scripts/ecs/components/ProductionComponent.gd")
        var workers = world.get_component(entity_id, "res://scripts/ecs/components/WorkersComponent.gd")
        
        # Производство работает только в операционном состоянии
        if building.state != BuildingComponent.State.OPERATIONAL:
            continue
        
        # Нужны рабочие
        if workers.get_worker_count() == 0:
            continue
        
        # Нужен рецепт в очереди
        var recipe = production.get_current_recipe()
        if not recipe:
            continue
        
        # Прогресс производства
        var speed_modifier = workers.get_worker_count() * production.production_speed
        production.production_progress += delta * 10 * speed_modifier
        
        # Завершение производства
        if production.production_progress >= 100:
            complete_production(entity_id, production, world)

func complete_production(entity_id: int, production: ProductionComponent, world: ECSWorld):
    var recipe = production.production_queue.pop_front()
    production.production_progress = 0
    
    # Создаем произведенный предмет
    EventBus.emit_signal("production_completed", entity_id, recipe)
```

### 4.5 AISystem

```gdscript
# scripts/ecs/systems/AISystem.gd
class_name AISystem
extends BaseSystem

func get_required_components() -> Array:
    return [
        "res://scripts/ecs/components/TaskComponent.gd",
        "res://scripts/ecs/components/NeedsComponent.gd"
    ]

func process_entities(delta: float, world: ECSWorld, entities: Array):
    for entity_id in entities:
        var task = world.get_component(entity_id, "res://scripts/ecs/components/TaskComponent.gd")
        var needs = world.get_component(entity_id, "res://scripts/ecs/components/NeedsComponent.gd")
        
        # Если нет задачи - ищем новую
        if task.current_task == TaskComponent.TaskType.NONE:
            assign_new_task(entity_id, task, needs, world)

func assign_new_task(entity_id: int, task: TaskComponent, needs: NeedsComponent, world: ECSWorld):
    # Приоритет потребностям
    if needs.hunger < 50:
        task.current_task = TaskComponent.TaskType.EAT
        return
    
    if needs.rest < 50:
        task.current_task = TaskComponent.TaskType.SLEEP
        return
    
    # Запрашиваем задачу у TaskManager
    EventBus.emit_signal("request_task_for_unit", entity_id)
```

---

## 5. Гибридный слой (Node ↔ ECS)

### 5.1 EntityNode - связь между Node и Entity

```gdscript
# scripts/ecs/EntityNode.gd
class_name EntityNode
extends Node2D

# Ссылка на ECS entity
var entity_id: int = -1
var ecs_world: ECSWorld

func _ready():
    ecs_world = get_node("/root/ECSWorld")

func setup_entity(entity: Entity):
    entity_id = entity.id
    
    # Создаем TransformComponent и связываем с Node
    var transform_comp = TransformComponent.new()
    transform_comp.position = global_position
    transform_comp.node_ref = self
    ecs_world.add_component(entity_id, transform_comp)

func _process(delta):
    # Синхронизация позиции из ECS
    if entity_id >= 0:
        var transform = ecs_world.get_component(entity_id, "res://scripts/ecs/components/TransformComponent.gd")
        if transform:
            global_position = transform.position
```

### 5.2 UnitNode - визуальное представление юнита

```gdscript
# scripts/ecs/UnitNode.gd
class_name UnitNode
extends EntityNode

@onready var sprite: Sprite2D = $Sprite2D
@onready var health_bar: ProgressBar = $HealthBar
@onready var selection_indicator: Sprite2D = $SelectionIndicator

func _process(delta):
    super._process(delta)
    
    if entity_id >= 0:
        update_visuals()

func update_visuals():
    # Обновляем здоровье
    var health = ecs_world.get_component(entity_id, "res://scripts/ecs/components/HealthComponent.gd")
    if health:
        health_bar.value = health.get_health_percentage() * 100
    
    # Обновляем выделение
    var task = ecs_world.get_component(entity_id, "res://scripts/ecs/components/TaskComponent.gd")
    if task:
        selection_indicator.visible = (task.current_task != TaskComponent.TaskType.NONE)
```

### 5.3 BuildingNode - визуальное представление здания

```gdscript
# scripts/ecs/BuildingNode.gd
class_name BuildingNode
extends EntityNode

@onready var sprite: Sprite2D = $Sprite2D
@onready var progress_bar: ProgressBar = $ProgressBar

func _process(delta):
    super._process(delta)
    
    if entity_id >= 0:
        update_visuals()

func update_visuals():
    var building = ecs_world.get_component(entity_id, "res://scripts/ecs/components/BuildingComponent.gd")
    if not building:
        return
    
    match building.state:
        BuildingComponent.State.BLUEPRINT:
            sprite.modulate = Color(1, 1, 1, 0.5)
            progress_bar.visible = false
        
        BuildingComponent.State.CONSTRUCTING:
            sprite.modulate = Color(1, 1, 1, 0.7)
            progress_bar.visible = true
            progress_bar.value = building.construction_progress
        
        BuildingComponent.State.OPERATIONAL:
            sprite.modulate = Color(1, 1, 1, 1)
            progress_bar.visible = false
        
        BuildingComponent.State.DAMAGED:
            sprite.modulate = Color(1, 0.5, 0.5, 1)
```

---

## 6. План миграции

### 6.1 Фаза 1: Инфраструктура (1-2 недели)

**Цель:** Создать базовую ECS инфраструктуру

- [ ] Создать ECSWorld и базовые классы (Entity, Component, System)
- [ ] Создать EntityNode для связи Node ↔ ECS
- [ ] Настроить автозагрузку ECSWorld
- [ ] Создать систему тестов для ECS

**Результат:** Работающая ECS инфраструктура, готовая к использованию

### 6.2 Фаза 2: Базовые компоненты (1 неделя)

**Цель:** Создать основные компоненты

- [ ] TransformComponent, HealthComponent, VelocityComponent
- [ ] NeedsComponent, SkillsComponent, StatsComponent
- [ ] TaskComponent, PathComponent
- [ ] BuildingComponent, ProductionComponent, WorkersComponent

**Результат:** Полный набор компонентов для юнитов и зданий

### 6.3 Фаза 3: Базовые системы (2 недели)

**Цель:** Создать основные системы обработки

- [ ] MovementSystem - движение юнитов
- [ ] NeedsSystem - обработка потребностей
- [ ] ProductionSystem - производство в зданиях
- [ ] AISystem - базовый AI для юнитов

**Результат:** Работающие системы для основной логики

### 6.4 Фаза 4: Миграция юнитов (2 недели)

**Цель:** Перевести юниты на ECS

- [ ] Создать UnitNode с EntityNode
- [ ] Мигрировать BaseUnit на ECS компоненты
- [ ] Обновить LizardUnit, CanidUnit, RusUnit
- [ ] Тестирование и отладка

**Результат:** Юниты работают на ECS

### 6.5 Фаза 5: Миграция зданий (2 недели)

**Цель:** Перевести здания на ECS

- [ ] Создать BuildingNode с EntityNode
- [ ] Мигрировать BaseBuilding на ECS компоненты
- [ ] Обновить расовые здания
- [ ] Тестирование и отладка

**Результат:** Здания работают на ECS

### 6.6 Фаза 6: Расовые системы (2-3 недели)

**Цель:** Добавить уникальные расовые механики

- [ ] LizardBioSystem - биологические механики
- [ ] CanidPackSystem - стайные механики
- [ ] RusMechanicalSystem - механические системы
- [ ] Тестирование баланса

**Результат:** Полностью функциональные расовые механики

### 6.7 Фаза 7: Оптимизация (1-2 недели)

**Цель:** Оптимизировать производительность

- [ ] Профилирование систем
- [ ] Оптимизация запросов
- [ ] Кэширование часто используемых данных
- [ ] Тестирование с 200+ юнитами

**Результат:** Стабильная производительность

---

## 7. Преимущества ECS для вашего проекта

### 7.1 Производительность

**До (OOP):**
```gdscript
# Каждый юнит вызывает _process
func _process(delta):
    match current_state:
        State.IDLE: _process_idle(delta)
        State.MOVING: _process_moving(delta)
        # ... виртуальные вызовы, разрозненные данные
```

**После (ECS):**
```gdscript
# Система обрабатывает все юниты сразу
func process_entities(delta, world, entities):
    for entity_