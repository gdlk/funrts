# scripts/autoload/ResourceManager.gd
extends Node

# Словарь ресурсов: {"wood": 100, "stone": 50, ...}
var resources: Dictionary = {}

signal resource_changed(resource_name: String, amount: int)

func add_resource(resource_name: String, amount: int):
	if not resources.has(resource_name):
		resources[resource_name] = 0
	resources[resource_name] += amount
	emit_signal("resource_changed", resource_name, resources[resource_name])

func remove_resource(resource_name: String, amount: int) -> bool:
	if not has_resource(resource_name, amount):
		return false
	resources[resource_name] -= amount
	emit_signal("resource_changed", resource_name, resources[resource_name])
	return true

func has_resource(resource_name: String, amount: int) -> bool:
	return resources.get(resource_name, 0) >= amount

func get_resource(resource_name: String) -> int:
	return resources.get(resource_name, 0)