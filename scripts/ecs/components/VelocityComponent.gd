# scripts/ecs/components/VelocityComponent.gd
class_name VelocityComponent
extends RefCounted

## Компонент скорости и движения
## Используется MovementSystem для перемещения сущностей

var velocity: Vector2 = Vector2.ZERO
var max_speed: float = 100.0
var acceleration: float = 500.0
var friction: float = 0.9  # Коэффициент трения (0-1)

func _init(max_spd: float = 100.0, accel: float = 500.0):
	max_speed = max_spd
	acceleration = accel

func apply_friction(delta: float) -> void:
	velocity *= pow(friction, delta * 60)  # Нормализуем по FPS

func limit_speed() -> void:
	if velocity.length() > max_speed:
		velocity = velocity.normalized() * max_speed