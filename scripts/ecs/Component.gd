# scripts/ecs/Component.gd
class_name Component
extends RefCounted

## Базовый класс для всех ECS компонентов
## Компоненты содержат только данные, без логики обработки
## Логика обработки находится в системах (Systems)

func _to_string() -> String:
	return get_script().get_path().get_file().get_basename()