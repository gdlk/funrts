# scripts/ecs/components/StatsComponent.gd
class_name StatsComponent
extends RefCounted

## Компонент базовых характеристик юнита
## Влияют на различные аспекты поведения и эффективности

var strength: int = 5       # Сила - урон, переноска
var agility: int = 5        # Ловкость - скорость, уклонение
var intelligence: int = 5   # Интеллект - крафт, исследования
var endurance: int = 5      # Выносливость - здоровье, выносливость

func _init(str: int = 5, agi: int = 5, intel: int = 5, end: int = 5):
	strength = str
	agility = agi
	intelligence = intel
	endurance = end

func get_work_speed_modifier() -> float:
	# Сила и ловкость влияют на скорость работы
	return 1.0 + (strength + agility) * 0.01

func get_max_health_bonus() -> float:
	# Выносливость дает бонус к максимальному здоровью
	return endurance * 5.0

func get_learning_speed() -> float:
	# Интеллект влияет на скорость обучения навыкам
	return 1.0 + intelligence * 0.02