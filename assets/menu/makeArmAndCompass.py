# Buffet Albert Einstein - genera las imágenes del panel del brazo y la brújula de colocar.
# Este archivo NO forma parte del juego: es una herramienta auxiliar para crear
# sprites e imágenes del juego, y no se usa al jugarlo.
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

# Todo va alineado a celdas de 50 px (Wollok avisa el clic por celda). Genera, en assets/menu/:
#
# LA BRÚJULA DE COLOCAR ("HACIA DÓNDE MIRA", ver placeMenu): 4x4 celdas
# - compass_<dir>.png y compass_<dir>_on.png: arriba y abajo miden 100x50; izquierda y derecha, 50x100.
#   Una flecha y su tecla (W A S D). _on: la elegida, en amarillo.
# - compass_center.png (100x100): el cuadro del centro, donde va la máquina elegida.
# - dir_label.png (200x50): "HACIA DÓNDE MIRA".
#
# EL PANEL DEL BRAZO (ver armMenu)
# - arm_box_<auto|smart>_<dir>.png (100x100): el brazo como se ve en el tablero, en un cuadro.
# - arm_grab_<dir>.png (100x100): la ficha roja "AGARRA DE ← izquierda".
# - arm_item.png y arm_item_on.png (50x50): el casillero de un ingrediente (el ingrediente va encima, con
#   su imagen de siempre). _on: sale por algún lado, en amarillo.
# - arm_chip_<dir>.png (50x50, transparente): la flechita de la esquina: hacia dónde sale.
# - arm_dir_<dir>.png, _on y _grab (50x50): las flechas del brazo común (la de donde agarra, en rojo).
# - arm_tag_<dir>.png (24x30): en el tablero, al lado del brazo, la flecha de una salida (al lado van las
#   insignias de lo que sale, las de machines/makeBadges.py).
#
# (La comanda del nivel completo ya no sale de acá: es una imagen entera por nivel, que dibuja
# assets/levels/makeLevelImages.py.)
#
# Uso (desde la raíz del repositorio):   python assets/menu/makeArmAndCompass.py
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

from makeKeyHints import draw_key, font
from makeBoardUi import canvas, save, box, CREAM, BROWN, BROWN_DARK, YELLOW, WHITE, S

HERE = Path(__file__).resolve().parent
ASSETS = HERE.parent
RED = (200, 64, 47, 255)
RED_DARK = (122, 29, 18, 255)
CREAM_SHADE = (230, 214, 187, 255)
YELLOW_SHADE = (216, 173, 28, 255)
ARROWS = {'up': '↑', 'right': '→', 'down': '↓', 'left': '←'}
KEYS = {'up': 'W', 'left': 'A', 'down': 'S', 'right': 'D'}
NAMES = {'up': 'arriba', 'right': 'derecha', 'down': 'abajo', 'left': 'izquierda'}


def arrow_font(size):
    return ImageFont.truetype('seguisym.ttf', size)


def tile(w, h, kind):
    """El botón: crema (normal), amarillo (elegido) o rojo (de donde agarra el brazo)"""
    im = canvas(w, h)
    d = ImageDraw.Draw(im)
    fill, line, shade = {'off': (CREAM, BROWN, CREAM_SHADE), 'on': (YELLOW, BROWN_DARK, YELLOW_SHADE),
                         'grab': (RED, RED_DARK, (155, 46, 32, 255))}[kind]
    box(d, (3, 3, w - 3, h - 3), shade, line, 3, 9)
    box(d, (6, 6, w - 6, h - 10), fill, None, 0, 7)
    if kind == 'on':
        box(d, (1, 1, w - 1, h - 1), None, WHITE, 2, 11)
    return im


def write_arrow(im, direction, cx, cy, color, size=26):
    ImageDraw.Draw(im).text((cx * S, cy * S), ARROWS[direction], font=arrow_font(size * S), fill=color, anchor='mm')


# ----------- LA BRÚJULA DE COLOCAR -----------

def compass():
    for direction in ARROWS:
        w, h = (100, 50) if direction in ('up', 'down') else (50, 100)
        for kind in ('off', 'on'):
            im = tile(w, h, kind)
            write_arrow(im, direction, w / 2, h / 2 - 2, BROWN)
            draw_key(im, (w - 22) * S, (h - 24) * S, KEYS[direction], 17 * S)
            save(im, f'compass_{direction}' + ('_on' if kind == 'on' else '') + '.png')
    im = canvas(100, 100)
    d = ImageDraw.Draw(im)
    box(d, (1, 1, 99, 99), (255, 255, 255, 40), None, 0, 12)
    dashed_box(d, 2, 2, 98, 98)
    save(im, 'compass_center.png')
    im = canvas(200, 50)
    ImageDraw.Draw(im).text((100 * S, 25 * S), 'HACIA DÓNDE MIRA', font=font(13 * S), fill=YELLOW, anchor='mm')
    save(im, 'dir_label.png')


def dashed_box(d, x0, y0, x1, y1, color=(255, 255, 255, 150)):
    dash, gap, w = 6 * S, 4 * S, 2 * S
    for x in range(x0 * S + 8 * S, x1 * S - 8 * S, dash + gap):
        d.line([(x, y0 * S), (min(x + dash, x1 * S - 8 * S), y0 * S)], fill=color, width=w)
        d.line([(x, y1 * S), (min(x + dash, x1 * S - 8 * S), y1 * S)], fill=color, width=w)
    for y in range(y0 * S + 8 * S, y1 * S - 8 * S, dash + gap):
        d.line([(x0 * S, y), (x0 * S, min(y + dash, y1 * S - 8 * S))], fill=color, width=w)
        d.line([(x1 * S, y), (x1 * S, min(y + dash, y1 * S - 8 * S))], fill=color, width=w)


# ----------- EL PANEL DEL BRAZO -----------

def arm_panel():
    for folder, kind in (('AutomaticArm', 'auto'), ('SmartRoboticArm', 'smart')):
        for direction in ARROWS:
            im = canvas(100, 100)
            d = ImageDraw.Draw(im)
            box(d, (1, 1, 99, 99), (255, 255, 255, 40), None, 0, 12)
            dashed_box(d, 2, 2, 98, 98)
            # el brazo del tablero (150x150) a 200x200, centrado: se ve la base y la pinza
            arm = Image.open(ASSETS / 'machines' / folder / f'{direction}_game.png').convert('RGBA')
            arm = arm.resize((200 * S, 200 * S), Image.LANCZOS).crop((50 * S, 50 * S, 150 * S, 150 * S))
            im.alpha_composite(arm)
            save(im, f'arm_box_{kind}_{direction}.png')
    for direction in ARROWS:
        im = tile(100, 100, 'grab')
        d = ImageDraw.Draw(im)
        d.text((50 * S, 28 * S), 'AGARRA DE', font=font(11 * S), fill=WHITE, anchor='mm')
        write_arrow(im, direction, 50, 52, WHITE, 32)
        d.text((50 * S, 76 * S), NAMES[direction], font=font(11 * S), fill=WHITE, anchor='mm')
        save(im, f'arm_grab_{direction}.png')
    save(tile(50, 50, 'off'), 'arm_item.png')
    save(tile(50, 50, 'on'), 'arm_item_on.png')
    for direction in ARROWS:
        im = canvas(50, 50)
        d = ImageDraw.Draw(im)
        box(d, (30, 30, 48, 48), BROWN_DARK, WHITE, 1, 5)
        write_arrow(im, direction, 39, 38.5, WHITE, 13)
        save(im, f'arm_chip_{direction}.png')
        for kind in ('off', 'on', 'grab'):
            im = tile(50, 50, kind)
            write_arrow(im, direction, 25, 23, WHITE if kind == 'grab' else BROWN)
            save(im, f'arm_dir_{direction}' + ('' if kind == 'off' else '_' + kind) + '.png')
        im = canvas(24, 30)
        d = ImageDraw.Draw(im)
        box(d, (1, 2, 23, 28), (255, 253, 246, 255), BROWN, 2, 7)
        write_arrow(im, direction, 12, 14.5, BROWN, 16)
        save(im, f'arm_tag_{direction}.png')


if __name__ == '__main__':
    compass()
    arm_panel()
    print('ok')
