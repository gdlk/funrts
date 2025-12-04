# scenes/units/LizardUnit.gd
extends BaseUnit

# Специализированный класс для ящеров

# Уникальные характеристики ящеров
var mutation_level: int = 0
var spore_count: int = 0
var symbiote: Node = null

# Уникальные навыки ящеров
var biology_skill: int = 0
var mutation_skill: int = 0
var terraforming_skill: int = 0

func _ready():
	race = "lizards"
	biology_skill = 10
	mutation_skill = 5
	terraforming_skill = 3
	spore_count = 5
	
	# Вызов родительского _ready()
	super._ready()

func _process(delta):
	# Вызов родительского _process()
	super._process(delta)
	
	# Уникальная логика ящеров
	if current_state == Constants.UnitState.IDLE:
		_manage_spores()
		_check_for_symbiosis()

func _process_working(delta):
	# Специфическая логика работы для ящеров
	if current_task and current_task.type == "bioreactor_work":
		# Работа на биореакторе производит споры
		spore_count += int(5 * work_speed_modifier * delta)
	elif current_task and current_task.type == "terraforming":
		# Терраформирование местности
		_terraform_tile()

func _manage_spores():
	# Автоматическое потребление спор для восстановления здоровья
	if health < max_health * 0.7 and spore_count > 0:
		heal_with_spores()

func heal_with_spores():
	var heal_amount = min(10, spore_count)
	health = min(max_health, health + heal_amount)
	spore_count -= heal_amount

func _check_for_symbiosis():
	# Проверка возможности симбиоза с другими ящерами
	if mutation_level >= 2 and not symbiote:
		var nearby_lizards = _get_nearby_lizards(50)
		for lizard in nearby_lizards:
			if lizard != self and not lizard.symbiote and lizard.mutation_level >= 2:
				form_symbiosis(lizard)
				break

func _get_nearby_lizards(radius: float) -> Array:
	# Получение ближайших ящеров
	var lizards = []
	for unit in get_tree().get_nodes_in_group("units"):
		if unit != self and unit.race == "lizards":
			if global_position.distance_to(unit.global_position) <= radius:
				lizards.append(unit)
	return lizards

func form_symbiosis(other_lizard):
	# Формирование симбиотической связи
	symbiote = other_lizard
	other_lizard.symbiote = self
	
	# Бонусы от симбиоза
	strength += 2
	agility += 2
	max_health += 20
	health += 20

func gain_mutation():
	# Получение мутации
	mutation_level += 1
	
	# Эффекты мутаций
	match mutation_level:
		1:
			endurance += 2
		2:
			strength += 2
		3:
			intelligence += 3
			# Разблокировка способности к симбиозу
		4:
			max_health += 30
			health += 30
		5:
			# Мощная мутация
			strength += 3
			endurance += 3
			agility += 2

func _terraform_tile():
	# Терраформирование тайла под ногами
	var map = get_node("/root/Game/Map")
	if map:
		var tile_pos = map.get_tile_position_from_world(global_position)
		var tile = map.get_tile(tile_pos.x, tile_pos.y)
		if tile:
			# Улучшение тайла
			tile.fertility += 0.1 * work_speed_modifier

func take_damage(amount: float):
	# Ящеры имеют сопротивление к урону при высоком уровне мутации
	var damage = amount
	if mutation_level >= 3:
		damage *= 0.8  # 20% сопротивление
	
	super.take_damage(damage)

func die():
	# При смерти ящера высвобождаются споры
	if spore_count > 0:
		_release_spores()
	
	super.die()

func _release_spores():
	# Высвобождение спор при смерти
	var nearby_tiles = _get_nearby_tiles(3)
	for tile in nearby_tiles:
		tile.spore_concentration += spore_count / nearby_tiles.size()

func _get_nearby_tiles(radius: int) -> Array:
	# Получение ближайших тайлов
	var map = get_node("/root/Game/Map")
	if not map:
		return []
	
	var tiles = []
	var center_pos = map.get_tile_position_from_world(global_position)
	
	for x in range(center_pos.x - radius, center_pos.x + radius + 1):
		for y in range(center_pos.y - radius, center_pos.y + radius + 1):
			var tile = map.get_tile(x, y)
			if tile:
				tiles.append(tile)
	
	return tiles