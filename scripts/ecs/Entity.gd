# scripts/ecs/Entity.gd
class_name Entity
extends RefCounted

## Базовый класс для ECS сущности
## Сущность - это просто уникальный ID, который связывает компоненты вместе

var id: int
var is_active: bool = true

func _init(entity_id: int):
	id = entity_id

func _to_string() -> String:
	return "Entity(%d)" % id