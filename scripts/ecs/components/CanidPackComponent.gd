# scripts/ecs/components/CanidPackComponent.gd
class_name CanidPackComponent
extends RefCounted

## Компонент стайных механик Песиголовцев
## Управляет принадлежностью к стае и иерархией

enum PackRole {
	OMEGA,   # Низший ранг
	BETA,    # Средний ранг
	ALPHA    # Лидер стаи
}

var pack_id: int = -1  # ID стаи (-1 = без стаи)
var pack_role: PackRole = PackRole.OMEGA
var pack_bonus: float = 1.0
var loyalty: float = 50.0  # 0-100

func _init():
	pass

func is_in_pack() -> bool:
	return pack_id >= 0

func join_pack(new_pack_id: int, role: PackRole = PackRole.OMEGA) -> void:
	pack_id = new_pack_id
	pack_role = role
	_update_pack_bonus()

func leave_pack() -> void:
	pack_id = -1
	pack_role = PackRole.OMEGA
	pack_bonus = 1.0

func promote() -> void:
	match pack_role:
		PackRole.OMEGA:
			pack_role = PackRole.BETA
		PackRole.BETA:
			pack_role = PackRole.ALPHA
	_update_pack_bonus()

func demote() -> void:
	match pack_role:
		PackRole.ALPHA:
			pack_role = PackRole.BETA
		PackRole.BETA:
			pack_role = PackRole.OMEGA
	_update_pack_bonus()

func _update_pack_bonus() -> void:
	match pack_role:
		PackRole.OMEGA:
			pack_bonus = 1.0
		PackRole.BETA:
			pack_bonus = 1.2
		PackRole.ALPHA:
			pack_bonus = 1.5

func get_role_name() -> String:
	match pack_role:
		PackRole.OMEGA: return "Omega"
		PackRole.BETA: return "Beta"
		PackRole.ALPHA: return "Alpha"
	return "Unknown"

func is_alpha() -> bool:
	return pack_role == PackRole.ALPHA