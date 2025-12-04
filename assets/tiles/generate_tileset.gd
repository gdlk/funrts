@tool
extends EditorScript

# Скрипт для генерации базового тайлсета
# Запустить через File -> Run в редакторе Godot

const TILE_SIZE = 32
const TILES_PER_ROW = 4

func _run():
	print("Генерация тайлсета...")
	
	var image = Image.create(TILE_SIZE * TILES_PER_ROW, TILE_SIZE, false, Image.FORMAT_RGBA8)
	
	# Цвета для разных типов местности
	var colors = [
		Color(0.29, 0.56, 0.89),  # Вода - #4A90E2
		Color(0.49, 0.83, 0.13),  # Равнина - #7ED321
		Color(0.25, 0.46, 0.02),  # Лес - #417505
		Color(0.55, 0.45, 0.33)   # Горы - #8B7355
	]
	
	# Заполняем каждый тайл
	for tile_idx in range(TILES_PER_ROW):
		var color = colors[tile_idx]
		for x in range(TILE_SIZE):
			for y in range(TILE_SIZE):
				var pixel_x = tile_idx * TILE_SIZE + x
				image.set_pixel(pixel_x, y, color)
	
	# Сохраняем изображение
	var err = image.save_png("res://assets/tiles/terrain_tileset.png")
	if err == OK:
		print("Тайлсет успешно создан: res://assets/tiles/terrain_tileset.png")
	else:
		print("Ошибка при сохранении тайлсета: ", err)
	
	print("Готово!")