# scripts/ecs/components/SkillsComponent.gd
class_name SkillsComponent
extends RefCounted

## Компонент навыков юнита
## Навыки улучшаются с опытом и влияют на эффективность работы

var mining: int = 0         # 0-100
var building: int = 0       # 0-100
var combat: int = 0         # 0-100
var crafting: int = 0       # 0-100

func _init():
	pass

func improve_skill(skill_name: String, amount: int) -> void:
	match skill_name:
		"mining":
			mining = min(100, mining + amount)
		"building":
			building = min(100, building + amount)
		"combat":
			combat = min(100, combat + amount)
		"crafting":
			crafting = min(100, crafting + amount)

func get_skill(skill_name: String) -> int:
	match skill_name:
		"mining": return mining
		"building": return building
		"combat": return combat
		"crafting": return crafting
	return 0

func get_skill_modifier(skill_name: String) -> float:
	# Навык 0 = 0.5x, навык 50 = 1.0x, навык 100 = 1.5x
	var skill_value = get_skill(skill_name)
	return 0.5 + (skill_value / 100.0)