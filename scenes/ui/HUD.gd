# scenes/ui/HUD.gd
extends CanvasLayer

# Основной интерфейс игры

@onready var unit_info_panel = $UnitInfoPanel
@onready var resources_panel = $ResourcesPanel
@onready var notification_label = $NotificationLabel
@onready var game_speed_label = $GameSpeedLabel

func _ready():
	update_resources_display()
	connect_signals()

func connect_signals():
	ResourceManager.connect("resource_changed", Callable(self, "_on_resource_changed"))
	GameManager.connect("game_speed_changed", Callable(self, "_on_game_speed_changed"))

func update_unit_info(unit):
	if not unit:
		unit_info_panel.hide()
		return
	
	unit_info_panel.show()
	
	# Обновление информации о юните
	var name_label = unit_info_panel.get_node("NameLabel")
	var health_bar = unit_info_panel.get_node("HealthBar")
	var needs_container = unit_info_panel.get_node("NeedsContainer")
	
	name_label.text = unit.unit_name
	health_bar.value = unit.health / unit.max_health * 100
	
	# Обновление потребностей
	for need in unit.needs:
		var need_bar = needs_container.get_node(need.capitalize() + "Bar")
		if need_bar:
			need_bar.value = unit.needs[need]

func clear_unit_info():
	unit_info_panel.hide()

func update_resources_display():
	# Обновление отображения ресурсов
	var wood_label = resources_panel.get_node("WoodLabel")
	var stone_label = resources_panel.get_node("StoneLabel")
	var food_label = resources_panel.get_node("FoodLabel")
	
	wood_label.text = "Дерево: " + str(ResourceManager.get_resource("wood"))
	stone_label.text = "Камень: " + str(ResourceManager.get_resource("stone"))
	food_label.text = "Еда: " + str(ResourceManager.get_resource("food"))

func _on_resource_changed(resource_name: String, amount: int):
	update_resources_display()

func _on_game_speed_changed():
	game_speed_label.text = "Скорость: " + str(GameManager.game_speed) + "x"

func show_notification(message: String):
	notification_label.text = message
	notification_label.show()
	
	# Скрытие уведомления через 3 секунды
	await get_tree().create_timer(3.0).timeout
	notification_label.hide()

func _on_pause_button_pressed():
	if GameManager.is_paused:
		GameManager.resume_game()
	else:
		GameManager.pause_game()

func _on_speed_button_pressed(speed: float):
	GameManager.set_game_speed(speed)
	_on_game_speed_changed()

func _on_save_button_pressed():
	SaveSystem.save_game()
	show_notification("Игра сохранена")

func _on_load_button_pressed():
	var success = SaveSystem.load_game()
	if success:
		show_notification("Игра загружена")
	else:
		show_notification("Ошибка загрузки")