# scripts/ecs/components/WorkersComponent.gd
class_name WorkersComponent
extends RefCounted

## Компонент рабочих
## Управляет назначенными рабочими для здания

var assigned_workers: Array = []  # Array of entity IDs
var max_workers: int = 1

func _init(max_wrk: int = 1):
	max_workers = max_wrk

func can_assign() -> bool:
	return assigned_workers.size() < max_workers

func assign_worker(worker_id: int) -> bool:
	if not can_assign():
		return false
	
	if worker_id in assigned_workers:
		return false
	
	assigned_workers.append(worker_id)
	return true

func remove_worker(worker_id: int) -> bool:
	var index = assigned_workers.find(worker_id)
	if index >= 0:
		assigned_workers.remove_at(index)
		return true
	return false

func get_worker_count() -> int:
	return assigned_workers.size()

func get_efficiency() -> float:
	# Эффективность зависит от количества рабочих
	if max_workers == 0:
		return 0.0
	return float(assigned_workers.size()) / float(max_workers)

func is_fully_staffed() -> bool:
	return assigned_workers.size() >= max_workers

func clear_workers() -> void:
	assigned_workers.clear()