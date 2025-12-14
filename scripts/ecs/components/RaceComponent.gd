# scripts/ecs/components/RaceComponent.gd
class_name RaceComponent
extends RefCounted

## Компонент расы
## Определяет расу сущности и расовые модификаторы

enum Race {
	LIZARD,  # Ящеры
	CANID,   # Песиголовцы
	RUS      # Русы
}

var race: Race = Race.LIZARD
var race_modifiers: Dictionary = {}

func _init(r: Race = Race.LIZARD):
	race = r
	_setup_default_modifiers()

func _setup_default_modifiers() -> void:
	match race:
		Race.LIZARD:
			race_modifiers = {
				"temperature_sensitivity": 1.5,
				"bio_efficiency": 1.2,
				"growth_speed": 0.8
			}
		Race.CANID:
			race_modifiers = {
				"pack_bonus": 1.3,
				"speed_bonus": 1.1,
				"social_need": 1.5
			}
		Race.RUS:
			race_modifiers = {
				"production_efficiency": 1.2,
				"resource_consumption": 1.1,
				"tech_speed": 1.3
			}

func get_race_name() -> String:
	match race:
		Race.LIZARD: return "lizard"
		Race.CANID: return "canid"
		Race.RUS: return "rus"
	return "unknown"

func get_modifier(modifier_name: String) -> float:
	return race_modifiers.get(modifier_name, 1.0)