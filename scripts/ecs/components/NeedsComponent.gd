# scripts/ecs/components/NeedsComponent.gd
class_name NeedsComponent
extends RefCounted

## Компонент потребностей юнита
## Управляет голодом, отдыхом, комфортом и социализацией

var hunger: float = 100.0      # 0-100
var rest: float = 100.0         # 0-100
var comfort: float = 50.0       # 0-100
var social: float = 50.0        # 0-100

# Скорости уменьшения потребностей (в секунду)
var hunger_decay: float = 1.0
var rest_decay: float = 0.5
var comfort_decay: float = 0.2
var social_decay: float = 0.3

func _init():
	pass

func get_average() -> float:
	return (hunger + rest + comfort + social) / 4.0

func get_mood() -> float:
	# Настроение от -100 до +100 на основе средней потребности
	return (get_average() - 50) * 2

func is_critical(need_name: String) -> bool:
	match need_name:
		"hunger": return hunger < 30
		"rest": return rest < 30
		"comfort": return comfort < 30
		"social": return social < 30
	return false

func has_critical_need() -> bool:
	return hunger < 30 or rest < 30

func get_work_speed_modifier() -> float:
	var mood = get_mood()
	if mood > 50:
		return 1.2  # +20% при хорошем настроении
	elif mood < -50:
		return 0.8  # -20% при плохом настроении
	return 1.0