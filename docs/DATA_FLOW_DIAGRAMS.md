# Диаграммы потока данных FunRTS

**Версия:** 1.0  
**Дата:** 04.12.2024

---


## 0. ECS Архитектура (Новое!)

### 0.1 Общая схема ECS

```mermaid
graph TB
    subgraph "Godot Scene Tree"
        Node[CharacterBody2D/StaticBody2D]
        Sprite[Sprite2D]
        Collision[CollisionShape2D]
    end
    
    subgraph "Гибридный слой"
        UnitNode[UnitNode/BuildingNode]
        UnitNode -->|entity_id| EntityRef[Ссылка на Entity]
    end
    
    subgraph "ECS World"
        Entity[Entity ID: 42]
        Components[Компоненты]
        Systems[Системы]
        
        Entity -->|имеет| Components
        Systems -->|обрабатывают| Components
    end
    
    subgraph "Компоненты Entity 42"
        Transform[TransformComponent<br/>position, rotation]
        Health[HealthComponent<br/>current: 85, max: 100]
        Needs[NeedsComponent<br/>hunger: 70, rest: 50]
        Task[TaskComponent<br/>current: MOVING]
    end
    
    Node -->|содержит| UnitNode
    UnitNode -->|создает| Entity
    Entity -->|содержит| Transform
    Entity -->|содержит| Health
    Entity -->|содержит| Needs
    Entity -->|содержит| Task
    
    Systems -->|обновляет| Transform
    Transform -->|синхронизация| Node
```

### 0.2 Поток данных в ECS

```mermaid
sequenceDiagram
    participant User as Игрок
    participant Node as UnitNode
    participant ECS as ECSWorld
    participant Sys as ECS Systems
    participant Comp as Components
    
    Note over User,Comp: Каждый кадр (_process)
    
    User->>Node: Клик ПКМ (move_to)
    Node->>ECS: get_component(PathComponent)
    ECS->>Comp: Возврат PathComponent
    Node->>Comp: set_path(new_path)
    
    Note over Sys: ECSWorld._process(delta)
    
    Sys->>ECS: query([Transform, Velocity, Path])
    ECS->>Sys: [entity_id: 42, 43, 44...]
    
    loop Для каждой entity
        Sys->>ECS: get_component(Transform)
        Sys->>ECS: get_component(Velocity)
        Sys->>ECS: get_component(Path)
        Sys->>Comp: Обновление позиции
        Comp->>Node: Синхронизация через node_ref
    end
    
    Node->>Node: Обновление визуала
```

### 0.3 Сравнение: OOP vs ECS

```mermaid
graph LR
    subgraph "OOP (Старый подход)"
        U1[Unit 1<br/>_process]
        U2[Unit 2<br/>_process]
        U3[Unit 3<br/>_process]
        U4[...<br/>200 юнитов]
        
        U1 -->|виртуальный вызов| P1[Обработка]
        U2 -->|виртуальный вызов| P2[Обработка]
        U3 -->|виртуальный вызов| P3[Обработка]
        U4 -->|200 вызовов| P4[...]
    end
    
    subgraph "ECS (Новый подход)"
        S[MovementSystem]
        E1[Entity 1]
        E2[Entity 2]
        E3[Entity 3]
        E4[... 200 entities]
        
        S -->|1 вызов| Batch[Пакетная обработка]
        Batch -->|обрабатывает| E1
        Batch -->|обрабатывает| E2
        Batch -->|обрабатывает| E3
        Batch -->|обрабатывает| E4
    end
    
    style P4 fill:#ff9999
    style Batch fill:#99ff99
```

---

## 1. Общая архитектура системы

```mermaid
graph TB
    subgraph "Пользовательский интерфейс"
        UI[UI Layer]
        HUD[HUD]
        Menu[Меню]
    end
    
    subgraph "Autoload Системы"
        GM[GameManager]
        RM[ResourceManager]
        EB[EventBus]
        SS[SaveSystem]
    end
    
    subgraph "Игровые Системы"
        PS[PathfindingSystem]
        NS[NeedsSystem]
        ProdS[ProductionSystem]
        CS[CombatSystem]
        TM[TaskManager]
        RS[ResearchSystem]
    end
    
    subgraph "Игровые Объекты"
        Units[Юниты]
        Buildings[Здания]
        Map[Карта]
    end
    
    UI --> GM
    UI --> RM
    HUD --> RM
    
    GM --> EB
    RM --> EB
    
    Units --> NS
    Units --> TM
    Units --> PS
    Units --> CS
    
    Buildings --> ProdS
    Buildings --> TM
    
    TM --> PS
    NS --> EB
    ProdS --> RM
    CS --> EB
    
    SS --> GM
    SS --> RM
    SS --> Units
    SS --> Buildings
```

---

## 2. Поток данных: Жизненный цикл юнита

```mermaid
sequenceDiagram
    participant U as Юнит
    participant NS as NeedsSystem
    participant TM as TaskManager
    participant PS as PathfindingSystem
    participant RM as ResourceManager
    participant EB as EventBus
    participant B as Здание
    
    Note over U: Каждый кадр (_process)
    
    U->>NS: update_needs(delta)
    NS->>NS: Уменьшение потребностей
    NS->>U: Обновление настроения
    
    alt Голод < 30
        U->>TM: request_task("find_food")
        TM->>TM: Поиск ближайшей еды
        TM->>U: Назначение задачи
        U->>PS: find_path(current_pos, food_pos)
        PS->>U: Возврат пути
        U->>U: Состояние = MOVING
        
        Note over U: Движение по пути
        
        U->>RM: remove_resource("food", 1)
        RM->>EB: emit("resource_changed")
        EB->>HUD: Обновление UI
        U->>U: Состояние = EATING
        U->>NS: Восстановление голода
        
    else Отдых < 30
        U->>TM: request_task("find_bed")
        TM->>B: Поиск свободной кровати
        B->>TM: Возврат кровати
        TM->>U: Назначение задачи
        U->>PS: find_path(current_pos, bed_pos)
        PS->>U: Возврат пути
        U->>U: Состояние = MOVING
        U->>B: assign_worker(self)
        U->>U: Состояние = SLEEPING
        U->>NS: Восстановление отдыха
        
    else Нет критических потребностей
        U->>TM: request_task()
        TM->>TM: Поиск доступной работы
        
        alt Есть задача
            TM->>U: Назначение задачи
            U->>PS: find_path(current_pos, task_pos)
            PS->>U: Возврат пути
            U->>U: Состояние = MOVING
            U->>U: Состояние = WORKING
            U->>EB: emit("task_completed")
            
        else Нет задач
            U->>U: Состояние = IDLE
        end
    end
```

---

## 3. Поток данных: Строительство здания

```mermaid
sequenceDiagram
    participant P as Игрок
    participant UI as UI
    participant GM as GameManager
    participant RM as ResourceManager
    participant B as Здание
    participant TM as TaskManager
    participant U as Юнит
    participant EB as EventBus
    
    P->>UI: Выбор здания для постройки
    UI->>RM: has_resource(required_resources)
    
    alt Достаточно ресурсов
        RM->>UI: true
        UI->>GM: place_building(type, position)
        GM->>B: Создание здания (BLUEPRINT)
        B->>EB: emit("building_placed")
        
        B->>TM: Создание задач доставки ресурсов
        
        loop Для каждого ресурса
            TM->>U: Назначение задачи доставки
            U->>RM: remove_resource(resource, amount)
            RM->>EB: emit("resource_changed")
            U->>B: deliver_resource(resource, amount)
            B->>B: Обновление delivered_resources
        end
        
        B->>B: Проверка _has_all_resources()
        
        alt Все ресурсы доставлены
            B->>B: Состояние = CONSTRUCTING
            B->>TM: Создание задач строительства
            
            loop Пока construction_progress < 100
                TM->>U: Назначение задачи строительства
                U->>B: Работа над строительством
                B->>B: construction_progress += delta
            end
            
            B->>B: complete_construction()
            B->>B: Состояние = OPERATIONAL
            B->>EB: emit("construction_completed")
            EB->>UI: Обновление UI
        end
        
    else Недостаточно ресурсов
        RM->>UI: false
        UI->>P: Показать сообщение об ошибке
    end
```

---

## 4. Поток данных: Производственная цепочка

```mermaid
graph LR
    subgraph "Добыча ресурсов"
        A[Юнит-добытчик] -->|добывает| B[Дерево]
        A -->|добывает| C[Камень]
        A -->|добывает| D[Руда]
    end
    
    subgraph "ResourceManager"
        B --> E[Склад: Дерево]
        C --> F[Склад: Камень]
        D --> G[Склад: Руда]
    end
    
    subgraph "Первичная обработка"
        E -->|Лесопилка| H[Доски]
        G -->|Плавильня| I[Металл]
    end
    
    subgraph "Производство"
        H -->|Мастерская| J[Мебель]
        I -->|Кузница| K[Инструменты]
        H -->|Кузница| K
    end
    
    subgraph "Использование"
        J -->|Строительство| L[Жилые здания]
        K -->|Экипировка| M[Юниты]
        K -->|Улучшение| N[Производство]
    end
    
    L --> O[Повышение комфорта]
    M --> P[Повышение эффективности]
    N --> Q[Ускорение производства]
    
    O --> R[Улучшение настроения]
    P --> R
    Q --> R
    
    R --> S[Более эффективная колония]
```

---

## 5. Поток данных: Боевая система

```mermaid
sequenceDiagram
    participant E as Враг
    participant U as Юнит
    participant CS as CombatSystem
    participant NS as NeedsSystem
    participant EB as EventBus
    participant GM as GameManager
    
    Note over E,U: Враг входит в зону видимости
    
    U->>U: Обнаружение врага
    U->>U: Состояние = FIGHTING
    
    loop Пока враг жив и в радиусе
        U->>CS: calculate_damage(attacker, target)
        CS->>CS: Расчёт урона с учётом характеристик
        CS->>E: take_damage(damage)
        
        alt Враг жив
            E->>CS: calculate_damage(attacker, target)
            CS->>U: take_damage(damage)
            U->>NS: Проверка здоровья
            
            alt Юнит жив
                U->>U: Продолжение боя
            else Юнит мёртв
                U->>EB: emit("unit_died", self)
                EB->>GM: Обработка смерти юнита
                U->>U: queue_free()
            end
            
        else Враг мёртв
            E->>EB: emit("enemy_died", self)
            EB->>GM: Обработка смерти врага
            E->>E: queue_free()
            U->>U: Состояние = IDLE
            U->>NS: Проверка потребностей
        end
    end
```

---

## 6. Поток данных: Система событий (EventBus)

```mermaid
graph TB
    subgraph "Источники событий"
        U[Юниты]
        B[Здания]
        M[Карта]
        S[Системы]
    end
    
    subgraph "EventBus"
        EB[Центральная шина событий]
    end
    
    subgraph "Подписчики"
        UI[UI/HUD]
        GM[GameManager]
        TM[TaskManager]
        SS[SaveSystem]
        AS[AudioSystem]
    end
    
    U -->|unit_died| EB
    U -->|unit_selected| EB
    U -->|task_completed| EB
    
    B -->|building_constructed| EB
    B -->|building_destroyed| EB
    B -->|production_completed| EB
    
    M -->|resource_depleted| EB
    
    S -->|day_passed| EB
    S -->|season_changed| EB
    S -->|enemy_raid_started| EB
    
    EB -->|Обновление UI| UI
    EB -->|Логирование| GM
    EB -->|Переназначение задач| TM
    EB -->|Автосохранение| SS
    EB -->|Звуковые эффекты| AS
```

---

## 7. Поток данных: Система сохранения

```mermaid
sequenceDiagram
    participant P as Игрок
    participant UI as UI
    participant SS as SaveSystem
    participant GM as GameManager
    participant RM as ResourceManager
    participant U as Юниты
    participant B as Здания
    participant M as Карта
    participant FS as FileSystem
    
    P->>UI: Нажатие "Сохранить"
    UI->>SS: save_game()
    
    SS->>GM: Получение game_time, race
    GM->>SS: Возврат данных
    
    SS->>RM: Получение resources
    RM->>SS: Возврат словаря ресурсов
    
    SS->>U: _serialize_units()
    loop Для каждого юнита
        U->>SS: Данные юнита (позиция, здоровье, навыки)
    end
    
    SS->>B: _serialize_buildings()
    loop Для каждого здания
        B->>SS: Данные здания (тип, позиция, состояние)
    end
    
    SS->>M: _serialize_map()
    M->>SS: Seed и изменённые тайлы
    
    SS->>SS: Формирование JSON
    SS->>FS: Запись в user://savegame.json
    FS->>SS: Подтверждение
    SS->>UI: Сохранение завершено
    UI->>P: Показать уведомление
    
    Note over P,FS: Загрузка работает в обратном порядке
```

---

## 8. Поток данных: Система потребностей

```mermaid
graph TB
    subgraph "Потребности юнита"
        H[Голод: 0-100]
        R[Отдых: 0-100]
        C[Комфорт: 0-100]
        S[Социализация: 0-100]
    end
    
    subgraph "Скорость убывания"
        H -->|-1.0/сек| H1[Голод уменьшается]
        R -->|-0.5/сек| R1[Отдых уменьшается]
        C -->|-0.2/сек| C1[Комфорт уменьшается]
        S -->|-0.3/сек| S1[Социализация уменьшается]
    end
    
    subgraph "Расчёт настроения"
        H1 --> M[Среднее значение потребностей]
        R1 --> M
        C1 --> M
        S1 --> M
        
        M --> Mood[Настроение = average - 50 × 2]
    end
    
    subgraph "Эффекты настроения"
        Mood -->|> 50| Good[Хорошее настроение]
        Mood -->|-50 до 50| Neutral[Нейтральное]
        Mood -->|< -50| Bad[Плохое настроение]
        
        Good --> GE[+20% скорость работы]
        Neutral --> NE[Нормальная работа]
        Bad --> BE[-20% скорость работы<br/>Риск бунта]
    end
    
    subgraph "Удовлетворение потребностей"
        Food[Еда] -->|+30/сек| H
        Bed[Кровать] -->|+20/сек| R
        Furniture[Мебель] -->|+10/сек| C
        Social[Общение] -->|+15/сек| S
    end
```

---

## 9. Поток данных: Поиск пути (A*)

```mermaid
graph TB
    subgraph "Запрос пути"
        U[Юнит] -->|find_path| PS[PathfindingSystem]
        PS -->|from, to| A[A* алгоритм]
    end
    
    subgraph "Инициализация"
        A --> Init[Инициализация открытого/закрытого списков]
        Init --> Start[Добавить стартовую точку в открытый список]
    end
    
    subgraph "Основной цикл"
        Start --> Loop{Открытый список не пуст?}
        Loop -->|Да| Current[Взять узел с наименьшим F]
        Current --> Goal{Это цель?}
        
        Goal -->|Да| Path[Восстановить путь]
        Goal -->|Нет| Neighbors[Получить соседей]
        
        Neighbors --> CheckN{Для каждого соседа}
        CheckN --> Walkable{Проходим?}
        Walkable -->|Да| CalcG[Вычислить G стоимость]
        Walkable -->|Нет| CheckN
        
        CalcG --> InClosed{В закрытом списке?}
        InClosed -->|Нет| CalcH[Вычислить H эвристику]
        InClosed -->|Да| CheckN
        
        CalcH --> CalcF[F = G + H]
        CalcF --> AddOpen[Добавить в открытый список]
        AddOpen --> CheckN
        
        CheckN -->|Ещё есть| Walkable
        CheckN -->|Нет больше| AddClosed[Добавить текущий в закрытый]
        AddClosed --> Loop
        
        Loop -->|Нет| NoPath[Путь не найден]
    end
    
    subgraph "Возврат результата"
        Path --> Return[Массив точек пути]
        NoPath --> Empty[Пустой массив]
        Return --> U
        Empty --> U
    end
```

---

## 10. Поток данных: Расовые особенности

### 10.1 Ящеры - Биологическая система

```mermaid
graph TB
    subgraph "Биореактор"
        BR[Биореактор<br/>Центральный организм]
        BR -->|Производит| BM[Биомасса]
        BR -->|Требует| Sun[Солнечный свет]
        BR -->|Требует| Water[Вода]
    end
    
    subgraph "Размножение"
        BM -->|Создание| Spore[Споры]
        Spore -->|Инкубация| Pod[Спороносный мешок]
        Pod -->|Вылупление| Larva[Личинка]
        Larva -->|Рост| Adult[Взрослый ящер]
    end
    
    subgraph "Мутации"
        Adult -->|Биомасса + Нектар| Mutate[Процесс мутации]
        Mutate -->|Специализация| Worker[Рабочий]
        Mutate -->|Специализация| Warrior[Воин]
        Mutate -->|Специализация| Builder[Строитель]
    end
    
    subgraph "Симбиоз"
        Worker -->|Слияние| Symbiote[Симбиот]
        Warrior -->|Слияние| Symbiote
        Symbiote -->|Усиленные способности| Enhanced[Улучшенный юнит]
    end
```

### 10.2 Песиголовцы - Стайная система

```mermaid
graph TB
    subgraph "Иерархия"
        Alpha[Альфа<br/>Лидер стаи]
        Beta[Бета<br/>Заместитель]
        Omega[Омега<br/>Рядовой]
        
        Alpha -->|Командует| Beta
        Beta -->|Командует| Omega
    end
    
    subgraph "Стайные бонусы"
        Pack[Стая 5+ юнитов]
        Pack -->|+20%| Attack[Урон]
        Pack -->|+15%| Speed[Скорость]
        Pack -->|+10%| Morale[Мораль]
        
        Alpha -->|Дополнительно +10%| Pack
    end
    
    subgraph "Территория"
        Omega -->|Метит| Territory[Территория]
        Territory -->|Бонусы в пределах| Defense[+25% защита]
        Territory -->|Бонусы в пределах| Regen[+10% регенерация]
    end
    
    subgraph "Коммуникация"
        Alpha -->|Вой| Signal[Сигнал]
        Signal -->|Радиус 50 тайлов| Buff[Баф союзникам]
        Signal -->|Радиус 50 тайлов| Debuff[Дебаф врагам]
    end
```

### 10.3 Русы - Технологическая система

```mermaid
graph TB
    subgraph "Энергетика"
        Coal[Уголь]
        Water[Вода]
        Coal -->|Сжигание| Boiler[Котёл]
        Water -->|Нагрев| Boiler
        Boiler -->|Производит| Steam[Пар]
    end
    
    subgraph "Производство"
        Steam -->|Питает| Factory[Завод]
        Factory -->|Автоматизация| Conveyor[Конвейер]
        Conveyor -->|Транспорт| Resources[Ресурсы]
        Resources -->|Обработка| Products[Продукты]
    end
    
    subgraph "Исследования"
        Lab[Лаборатория]
        Lab -->|Изобретения| Tech1[Улучшенные машины]
        Lab -->|Изобретения| Tech2[Новые рецепты]
        Lab -->|Изобретения| Tech3[Автоматизация]
        
        Tech1 -->|Применение| Factory
        Tech2 -->|Применение| Factory
        Tech3 -->|Применение| Conveyor
    end
    
    subgraph "Коллективный труд"
        Worker1[Рабочий 1]
        Worker2[Рабочий 2]
        Worker3[Рабочий 3]
        
        Worker1 -->|Работают вместе| Team[Бригада]
        Worker2 -->|Работают вместе| Team
        Worker3 -->|Работают вместе| Team
        
        Team -->|+30% эффективность| Bonus[Бонус производства]
    end
```

---

## 11. Оптимизация: Система чанков

```mermaid
graph TB
    subgraph "Карта 128x128"
        M[Полная карта]
        M -->|Разделение| C1[Чанк 0,0<br/>32x32]
        M -->|Разделение| C2[Чанк 1,0<br/>32x32]
        M -->|Разделение| C3[Чанк 0,1<br/>32x32]
        M -->|Разделение| C4[Чанк 1,1<br/>32x32]
    end
    
    subgraph "Запрос сущностей"
        U[Юнит в позиции 50,50]
        U -->|get_nearby_entities| CM[ChunkManager]
        CM -->|Определить чанк| Calc[Чанк 1,1]
        Calc -->|Получить соседние| N[Чанки 0,0 0,1 1,0 1,1]
        N -->|Вернуть сущности| Result[Только близкие объекты]
    end
    
    subgraph "Преимущества"
        Result -->|Вместо проверки| All[Всех 1000+ объектов]
        Result -->|Проверяем только| Few[~100 объектов в радиусе]
        Few -->|Результат| Perf[10x улучшение производительности]
    end
```

---

## Заключение

Эти диаграммы показывают основные потоки данных в игре FunRTS. Архитектура построена на принципах:

1. **Модульность** — системы слабо связаны через EventBus
2. **Эффективность** — оптимизация через чанки и пулы объектов
3. **Расширяемость** — легко добавлять новые расы и механики
4. **Читаемость** — чёткое разделение ответственности

Каждая система имеет определённую роль и взаимодействует с другими через чётко определённые интерфейсы.