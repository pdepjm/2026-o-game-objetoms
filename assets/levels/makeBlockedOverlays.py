# Buffet Albert Einstein - herramienta auxiliar: genera las capas de celdas bloqueadas de los niveles.
#
# Copyright (C) 2026  grupo objeTOMs (Mateo Bustos, Carlos Aramis Chambi Flores,
# Facundo Ramounat, Federico Scalise Giussani, Mateo Silva)
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

# NO FORMA PARTE DEL JUEGO: es una herramienta auxiliar para crear los assets.
#
# Para cada nivel que limita dónde se puede construir, genera una imagen del tamaño del tablero (1250x800,
# transparente) con la marca oscura (assets/blocked_cell.png) en cada celda donde NO se puede construir.
# El juego la dibuja como UN solo visual (BlockedLayer, en board.wlk) en vez de uno por celda, que
# era lo que hacía lento al juego.
#
# ZONES tiene que coincidir con los buildZones de cada nivel en src/levels/levelsTypes.wlk
# (cada zona es (minX, maxX, minY, maxY), con los bordes incluidos). Si se cambia un nivel, se cambia acá
# y se vuelve a correr:
#
#     python3 assets/levels/makeBlockedOverlays.py
#
# Requiere Pillow (pip install pillow). Escribe assets/levels/blocked_<nivel>.png.

import os
from PIL import Image

CELL = 50
GAME_HEIGHT = 16                 # celdas de alto de la pantalla (game.height)
GAME_WIDTH = 25                  # celdas de ancho (game.width)
BOARD_X = range(5, 20)           # columnas del tablero (board.inBoard)
BOARD_Y = range(1, 14)           # filas del tablero

ZONES = {
    "tutorial": [(6, 11, 7, 7)],
    "hotdog": [(7, 10, 9, 10)],
    "energy": [(12, 13, 13, 13)],
    "level3": [
        (6, 12, 7, 10),
        (13, 15, 7, 12),
        (13, 16, 13, 13),
        (6, 16, 2, 5),
        (17, 18, 2, 5),
        (17, 17, 6, 13),
    ],
}

HERE = os.path.dirname(os.path.abspath(__file__))
mark = Image.open(os.path.join(HERE, "..", "blocked_cell.png")).convert("RGBA")


def buildable(x, y, zones):
    return any(x0 <= x <= x1 and y0 <= y <= y1 for (x0, x1, y0, y1) in zones)


for name, zones in ZONES.items():
    layer = Image.new("RGBA", (GAME_WIDTH * CELL, GAME_HEIGHT * CELL), (0, 0, 0, 0))
    for x in BOARD_X:
        for y in BOARD_Y:
            if not buildable(x, y, zones):
                # Wollok cuenta las filas desde abajo; la imagen, desde arriba
                layer.paste(mark, (x * CELL, (GAME_HEIGHT - 1 - y) * CELL))
    out = os.path.join(HERE, "blocked_" + name + ".png")
    layer.save(out)
    print("escrito", out)
