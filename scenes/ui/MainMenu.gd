# scenes/ui/MainMenu.gd
extends Control

# Главное меню игры

@onready var new_game_button = $Panel/NewGameButton
@onready var load_game_button = $Panel/LoadGameButton
@onready var settings_button = $Panel/SettingsButton
@onready var quit_button = $Panel/QuitButton
@onready var race_selection_panel = $RaceSelectionPanel
@onready var notification_label = $NotificationLabel

func _ready():
	connect_signals()
	check_save_file()

func connect_signals():
	new_game_button.connect("pressed", Callable(self, "_on_new_game_pressed"))
	load_game_button.connect("pressed", Callable(self, "_on_load_game_pressed"))
	settings_button.connect("pressed", Callable(self, "_on_settings_pressed"))
	quit_button.connect("pressed", Callable(self, "_on_quit_pressed"))
	
	# Подключение кнопок выбора расы
	for button in race_selection_panel.get_node("RacesContainer").get_children():
		if button is Button:
			button.connect("pressed", Callable(self, "_on_race_selected").bind(button.name))
	
	race_selection_panel.get_node("BackButton").connect("pressed", Callable(self, "_on_back_pressed"))
	race_selection_panel.get_node("StartButton").connect("pressed", Callable(self, "_on_start_pressed"))

func check_save_file():
	# Проверка наличия сохранения
	if not FileAccess.file_exists("user://savegame.json"):
		load_game_button.disabled = true

func _on_new_game_pressed():
	# Показываем панель выбора расы
	$Panel.hide()
	race_selection_panel.show()

func _on_load_game_pressed():
	# Загрузка игры
	var success = SaveSystem.load_game()
	if success:
		# Переход в игровую сцену
		get_tree().change_scene_to_file("res://scenes/game/Game.tscn")
	else:
		show_notification("Ошибка загрузки сохранения")

func _on_settings_pressed():
	# Открытие настроек
	show_notification("Настройки пока не реализованы")

func _on_quit_pressed():
	get_tree().quit()

func _on_race_selected(race_name):
	# Выбор расы
	GameManager.current_race = race_name
	
	# Обновление визуального выделения
	for button in race_selection_panel.get_node("RacesContainer").get_children():
		if button is Button:
			if button.name == race_name:
				button.modulate = Color(1, 1, 0.5)  # Подсветка выбранной расы
			else:
				button.modulate = Color(1, 1, 1)  # Нормальный цвет

func _on_back_pressed():
	# Возврат в главное меню
	race_selection_panel.hide()
	$Panel.show()

func _on_start_pressed():
	# Начало новой игры
	if GameManager.current_race == "":
		show_notification("Пожалуйста, выберите расу")
		return
	
	# Сохраняем выбор расы и начинаем игру
	get_tree().change_scene_to_file("res://scenes/game/Game.tscn")

func show_notification(message: String):
	notification_label.text = message
	notification_label.show()
	
	# Скрытие уведомления через 3 секунды
	await get_tree().create_timer(3.0).timeout
	notification_label.hide()

func _on_race_info_pressed(race_name):
	# Показ информации о расе
	var info_text = ""
	
	match race_name:
		"lizards":
			info_text = "ЯЩЕРЫ\n\nБиологическая раса с уникальными способностями к мутации и симбиозу. Их сила раскрывается в долгосрочной перспективе.\n\nОсобенности:\n- Биореактор как центр колонии\n- Система мутаций юнитов\n- Симбиотическое слияние существ\n- Терраформирование местности"
		"canids":
			info_text = "ПЕСИГОЛОВЦЫ\n\nСильная стайная раса с акцентом на численность и агрессию. Отлично подходят для быстрого захвата территории.\n\nОсобенности:\n- Система стай и иерархии\n- Быстрое размножение\n- Территориальные метки\n- Боевой вой как форма коммуникации"
		"rus":
			info_text = "РУСЫ\n\nТехнологическая раса с акцентом на автоматизацию и эффективность. Идеальны для игроков, любящих строительство и оптимизацию.\n\nОсобенности:\n- Паровая энергетика\n- Производственные линии\n- Конвейерная система\n- Коллективный труд"
	
	show_notification(info_text)