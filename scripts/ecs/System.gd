# scripts/ecs/System.gd
class_name System
extends Node

## Базовый класс для всех ECS систем
## Системы содержат логику обработки компонентов
## Каждая система определяет, какие компоненты ей нужны для работы

## Возвращает массив путей к компонентам, которые требуются этой системе
## Переопределяется в подклассах
func get_required_components() -> Array:
	return []

## Основной метод обработки системы
## Вызывается каждый кадр из ECSWorld
func process(delta: float, world) -> void:
	var entities = world.query(get_required_components())
	process_entities(delta, world, entities)

## Обработка конкретных сущностей
## Переопределяется в подклассах для реализации логики
func process_entities(delta: float, world, entities: Array) -> void:
	pass

func _to_string() -> String:
	return get_script().get_path().get_file().get_basename()