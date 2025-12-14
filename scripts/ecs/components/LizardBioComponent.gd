# scripts/ecs/components/LizardBioComponent.gd
class_name LizardBioComponent
extends RefCounted

## Компонент биологических механик Ящеров
## Управляет биомассой, мутациями и симбиозом

var biomass: float = 100.0
var max_biomass: float = 100.0
var mutation_level: int = 0  # 0-10
var symbiosis_bonus: float = 1.0
var temperature_preference: float = 25.0  # Градусы Цельсия

func _init():
	pass

func can_mutate() -> bool:
	return biomass >= 50.0 and mutation_level < 10

func mutate() -> void:
	if can_mutate():
		biomass -= 50.0
		mutation_level += 1
		symbiosis_bonus += 0.1

func consume_biomass(amount: float) -> bool:
	if biomass >= amount:
		biomass -= amount
		return true
	return false

func add_biomass(amount: float) -> void:
	biomass = min(max_biomass, biomass + amount)

func get_temperature_efficiency(current_temp: float) -> float:
	# Эффективность падает при отклонении от предпочитаемой температуры
	var diff = abs(current_temp - temperature_preference)
	return max(0.5, 1.0 - (diff / 20.0))