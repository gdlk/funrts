#!/usr/bin/env python3
"""
Скрипт для создания базового тайлсета для игры
"""

from PIL import Image

# Параметры
TILE_SIZE = 32
TILES_COUNT = 4

# Цвета для разных типов местности (RGB)
colors = [
    (74, 144, 226),   # Вода - #4A90E2
    (126, 211, 33),   # Равнина - #7ED321
    (65, 117, 5),     # Лес - #417505
    (139, 115, 85)    # Горы - #8B7355
]

# Создаем изображение
img = Image.new('RGB', (TILE_SIZE * TILES_COUNT, TILE_SIZE))

# Заполняем каждый тайл
for i, color in enumerate(colors):
    for x in range(TILE_SIZE):
        for y in range(TILE_SIZE):
            pixel_x = i * TILE_SIZE + x
            img.putpixel((pixel_x, y), color)

# Сохраняем
img.save('terrain_tileset.png')
print("Тайлсет создан: terrain_tileset.png")