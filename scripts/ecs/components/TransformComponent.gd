# scripts/ecs/components/TransformComponent.gd
class_name TransformComponent
extends RefCounted

## Компонент позиции, поворота и масштаба
## Синхронизируется с Node2D для визуализации

const Component = preload("res://scripts/ecs/Component.gd")

var position: Vector2 = Vector2.ZERO
var rotation: float = 0.0
var scale: Vector2 = Vector2.ONE

# Ссылка на Node для синхронизации визуализации
var node_ref: Node2D = null

func _init(pos: Vector2 = Vector2.ZERO, rot: float = 0.0, scl: Vector2 = Vector2.ONE):
	position = pos
	rotation = rot
	scale = scl