# scripts/systems/ProductionSystem.gd
extends Node

# Система управления производством и крафтом

func process_production(building, delta: float):
	if building.current_state == building.State.OPERATIONAL and not building.production_queue.is_empty():
		building.production_progress += delta * building.production_speed * building.assigned_workers.size()
		if building.production_progress >= 100:
			complete_production(building)

func complete_production(building):
	var item = building.production_queue.pop_front()
	building.production_progress = 0
	
	# Создаем произведенный предмет
	var produced_item = create_item(item)
	
	# Добавляем в инвентарь или выбрасываем на землю
	if produced_item:
		add_to_storage(produced_item, building.global_position)
	
	# Эмитируем сигнал о завершении производства
	building.emit_signal("production_completed", item)

func create_item(item_data) -> Node:
	# Создание предмета на основе данных
	# Возвращает Node с предметом или null если не удалось создать
	return null

func add_to_storage(item, position: Vector2):
	# Добавление предмета в хранилище или на землю
	pass

func can_produce(building, recipe_name: String) -> bool:
	# Проверка возможности производства по рецепту
	return true

func get_production_time(building, recipe_name: String) -> float:
	# Получение времени производства по рецепту
	return 10.0