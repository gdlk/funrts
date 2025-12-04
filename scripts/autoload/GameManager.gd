# scripts/autoload/GameManager.gd
extends Node

# Глобальные переменные
var current_race: String = ""
var game_speed: float = 1.0
var is_paused: bool = false
var game_time: float = 0.0

# Ссылки на системы
var resource_manager: ResourceManager
var event_bus: EventBus

func _ready():
	resource_manager = get_node("/root/ResourceManager")
	event_bus = get_node("/root/EventBus")

func _process(delta):
	if not is_paused:
		game_time += delta * game_speed
		
func pause_game():
	is_paused = true
	get_tree().paused = true
	
func resume_game():
	is_paused = false
	get_tree().paused = false
	
func set_game_speed(speed: float):
	game_speed = clamp(speed, 0.5, 3.0)