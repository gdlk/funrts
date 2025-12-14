# scripts/ecs/components/HealthComponent.gd
class_name HealthComponent
extends RefCounted

## Компонент здоровья
## Управляет текущим и максимальным здоровьем, регенерацией

var current: float = 100.0
var maximum: float = 100.0
var regeneration_rate: float = 0.0  # HP в секунду

func _init(max_hp: float = 100.0, regen: float = 0.0):
	maximum = max_hp
	current = max_hp
	regeneration_rate = regen

func is_alive() -> bool:
	return current > 0

func take_damage(amount: float) -> void:
	current = max(0, current - amount)

func heal(amount: float) -> void:
	current = min(maximum, current + amount)

func get_health_percentage() -> float:
	return current / maximum if maximum > 0 else 0.0

func is_damaged() -> bool:
	return current < maximum

func is_critical() -> bool:
	return get_health_percentage() < 0.3