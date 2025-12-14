# scripts/ecs/components/RusMechanicalComponent.gd
class_name RusMechanicalComponent
extends RefCounted

## Компонент механических систем Русов
## Управляет паровой энергией и автоматизацией

var steam_power: float = 0.0  # Текущая паровая энергия
var max_steam: float = 100.0
var efficiency: float = 1.0   # Эффективность механизмов
var automation_level: int = 0  # 0-10

# Потребление и производство пара
var steam_consumption: float = 0.0  # В секунду
var steam_production: float = 0.0   # В секунду

func _init():
	pass

func has_steam(amount: float) -> bool:
	return steam_power >= amount

func consume_steam(amount: float) -> bool:
	if has_steam(amount):
		steam_power -= amount
		return true
	return false

func add_steam(amount: float) -> void:
	steam_power = min(max_steam, steam_power + amount)

func get_automation_bonus() -> float:
	# Автоматизация дает бонус к производству
	return 1.0 + (automation_level * 0.1)

func upgrade_automation() -> bool:
	if automation_level < 10:
		automation_level += 1
		return true
	return false

func get_steam_percentage() -> float:
	return steam_power / max_steam if max_steam > 0 else 0.0

func is_powered() -> bool:
	return steam_power > 10.0  # Минимум 10% для работы