# scripts/utils/Constants.gd
extends Node

# Константы игры

# Размеры тайлов
const TILE_SIZE = 32

# Размеры карты
const MAP_WIDTH = 128
const MAP_HEIGHT = 128

# Типы ресурсов
const RESOURCE_WOOD = 4
const RESOURCE_STONE = 5
const RESOURCE_FOOD = 6
const RESOURCE_METAL = 7
const RESOURCE_STEAM = 8

# Типы местности
const TERRAIN_WATER = 0
const TERRAIN_PLAIN = 1
const TERRAIN_FOREST = 2
const TERRAIN_MOUNTAIN = 3

# Состояния юнитов
enum UnitState {
	IDLE,
	MOVING,
	WORKING,
	FIGHTING,
	SLEEPING,
	EATING
}

# Состояния зданий
enum BuildingState {
	BLUEPRINT,
	CONSTRUCTING,
	OPERATIONAL,
	DAMAGED,
	DESTROYED
}

# Расы
const RACE_LIZARDS = "lizards"
const RACE_CANIDS = "canids"
const RACE_RUS = "rus"

# Скорость игры
const GAME_SPEED_SLOW = 0.5
const GAME_SPEED_NORMAL = 1.0
const GAME_SPEED_FAST = 2.0
const GAME_SPEED_VERY_FAST = 3.0