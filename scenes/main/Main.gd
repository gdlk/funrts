# scenes/main/Main.gd
extends Node

# Главная сцена игры

# Импортируем константы
const Constants = preload("res://scripts/utils/Constants.gd")

@onready var game_scene = preload("res://scenes/game/Game.tscn")

func _ready():
	# Инициализация систем
	initialize_systems()
	
	# Загрузка игры или начало новой
	start_game()

func initialize_systems():
	# Инициализация системы пути
	var pathfinding = get_node("/root/PathfindingSystem")
	if pathfinding:
		pathfinding.initialize(Constants.MAP_WIDTH, Constants.MAP_HEIGHT)

func start_game():
	# Пока просто загружаем игровую сцену
	var game_instance = game_scene.instantiate()
	add_child(game_instance)

func new_game(race: String):
	GameManager.current_race = race
	# Здесь будет логика начала новой игры
	
func load_game():
	var success = SaveSystem.load_game()
	if not success:
		print("Не удалось загрузить сохранение")
		return false
	return true

func quit_game():
	get_tree().quit()