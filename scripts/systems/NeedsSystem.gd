# scripts/systems/NeedsSystem.gd
extends Node

const NEED_DECAY_RATE = {
	"hunger": 1.0,      # Голод уменьшается на 1 в секунду
	"rest": 0.5,        # Усталость на 0.5 в секунду
	"comfort": 0.2,     # Комфорт на 0.2 в секунду
	"social": 0.3,      # Социализация на 0.3 в секунду
}

func update_needs(unit, delta: float):
	for need in unit.needs:
		var decay = NEED_DECAY_RATE.get(need, 0.1)
		unit.needs[need] = max(0, unit.needs[need] - decay * delta)
	
	# Обновляем настроение на основе потребностей
	update_mood(unit)

func update_mood(unit):
	var total_needs = 0.0
	var need_count = unit.needs.size()
	
	for need_value in unit.needs.values():
		total_needs += need_value
	
	var average_need = total_needs / need_count if need_count > 0 else 50.0
	
	# Настроение от -100 до +100
	unit.mood = (average_need - 50) * 2
	
	# Применяем эффекты настроения
	apply_mood_effects(unit)

func apply_mood_effects(unit):
	if unit.mood > 50:
		unit.work_speed_modifier = 1.2
	elif unit.mood < -50:
		unit.work_speed_modifier = 0.8
	else:
		unit.work_speed_modifier = 1.0