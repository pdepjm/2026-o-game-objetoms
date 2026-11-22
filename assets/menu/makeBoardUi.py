# Buffet Albert Einstein - genera las imágenes de la interfaz sin herramientas.
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

# Genera (en assets/menu/):
# - actions_all.png, actions_noedit.png, actions_editonly.png, actions_none.png (150x50): el menú de la
#   máquina elegida: ROTAR (C), EDITAR (X) y BORRAR (V), una celda cada uno. Lo que no se puede, apagado.
# - mode_placing.png y mode_editing.png (200x50): el cartel COLOCANDO / EDITANDO, arriba a la derecha.
# - side_buttons.png (200x200) y speed_selected.png (50x50): los botones de abajo a la izquierda
#   (recetario, menú, iniciar y las velocidades), uno por fila de celdas para que se puedan clickear.
# - cover_focus.png (440x60): la opción marcada en la portada.
# - option_focus.png (50x50): la opción marcada en el panel de editar.
# - book_prev.png, book_next.png (y _off) (50x80) y book_close.png (100x100): los botones del recetario.
#
# Uso (desde la raíz del repositorio):   python assets/menu/makeBoardUi.py
from pathlib import Path

from PIL import Image, ImageDraw

from makeKeyHints import draw_key, font

HERE = Path(__file__).resolve().parent
S = 4   # se dibuja 4 veces más grande y se achica, para suavizar los bordes

CREAM = (253, 243, 225, 255)
BROWN = (90, 58, 30, 255)
BROWN_DARK = (59, 36, 18, 255)
YELLOW = (255, 210, 63, 255)
PANEL = (3, 133, 185, 255)
PLACE = (63, 163, 77, 255)
EDIT = (232, 163, 23, 255)
ROTATE = (47, 128, 200, 255)
DELETE = (214, 69, 65, 255)
WHITE = (255, 255, 255, 255)


def canvas(w, h):
    return Image.new('RGBA', (w * S, h * S), (0, 0, 0, 0))


def save(im, name):
    w, h = im.width // S, im.height // S
    im.resize((w, h), Image.LANCZOS).save(HERE / name)


def box(d, xy, fill, outline=None, width=0, radius=10):
    d.rounded_rectangle([v * S for v in xy], radius=radius * S, fill=fill, outline=outline, width=width * S)


# ----------- ÍCONOS (en un cuadrado de 24 unidades, como los del prototipo) -----------

def icon(d, kind, x, y, size, color):
    k = size / 24 * S
    X = lambda v: x * S + v * k
    Y = lambda v: y * S + v * k
    w = round(2.6 * k)
    if kind == 'place':
        d.rounded_rectangle([X(3.5), Y(3.5), X(20.5), Y(20.5)], radius=4 * k, outline=color, width=w)
        d.line([X(12), Y(8), X(12), Y(16)], fill=color, width=w)
        d.line([X(8), Y(12), X(16), Y(12)], fill=color, width=w)
    elif kind == 'edit':
        d.line([X(4), Y(7), X(14), Y(7)], fill=color, width=w)
        d.line([X(18), Y(7), X(20), Y(7)], fill=color, width=w)
        d.line([X(4), Y(17), X(8), Y(17)], fill=color, width=w)
        d.line([X(12), Y(17), X(20), Y(17)], fill=color, width=w)
        for cx, cy in ((16, 7), (10, 17)):
            d.ellipse([X(cx - 2.6), Y(cy - 2.6), X(cx + 2.6), Y(cy + 2.6)], outline=color, width=w)
    elif kind == 'rotate':
        d.arc([X(4.5), Y(4.5), X(19.5), Y(19.5)], start=-40, end=290, fill=color, width=w)
        d.line([X(19.5), Y(3.5), X(19.5), Y(9)], fill=color, width=w)
        d.line([X(14), Y(9), X(19.5), Y(9)], fill=color, width=w)
    elif kind == 'delete':
        d.line([X(4), Y(7), X(20), Y(7)], fill=color, width=w)
        d.line([X(9.5), Y(7), X(9.5), Y(4.5), X(14.5), Y(4.5), X(14.5), Y(7)], fill=color, width=w)
        d.line([X(6.5), Y(7), X(7.5), Y(20), X(16.5), Y(20), X(17.5), Y(7)], fill=color, width=w)
        d.line([X(10.5), Y(11), X(10.5), Y(16.5)], fill=color, width=w)
        d.line([X(13.5), Y(11), X(13.5), Y(16.5)], fill=color, width=w)


# ----------- EL MENÚ DE LA MÁQUINA ELEGIDA -----------

ACTIONS = [('rotate', 'ROTAR', 'C', ROTATE), ('edit', 'EDITAR', 'X', EDIT), ('delete', 'BORRAR', 'V', DELETE)]


def actions(name, enabled):
    im = canvas(150, 50)
    d = ImageDraw.Draw(im)
    box(d, (1, 2, 149, 49), BROWN_DARK, radius=11)
    label = font(round(7.5 * S))
    for i, (kind, text, key, color) in enumerate(ACTIONS):
        tile = canvas(50, 50)
        t = ImageDraw.Draw(tile)
        box(t, (4, 6, 46, 46), CREAM, BROWN, 2, 8)
        icon(t, kind, 14, 9, 21, color)
        t.text((25 * S, 38 * S), text, font=label, fill=color, anchor='mm')
        draw_key(tile, 32 * S, 1 * S, key, 15 * S)
        if not enabled[i]:
            alpha = tile.getchannel('A').point(lambda a: a * 35 // 100)
            tile.putalpha(alpha)
        im.alpha_composite(tile, (i * 50 * S, 0))
    save(im, name)


# ----------- EL CARTEL DEL MODO -----------

def mode(name, kind, text, color, key=None):
    im = canvas(200, 50)
    d = ImageDraw.Draw(im)
    box(d, (5, 7, 195, 49), BROWN_DARK, radius=12)          # la sombra de abajo
    box(d, (5, 3, 195, 45), color, BROWN, 3, 12)
    icon(d, kind, 14, 12, 22, WHITE)
    d.text((44 * S, 24 * S), text, font=font(round(19 * S)), fill=WHITE, anchor='lm',
           stroke_width=S, stroke_fill=(0, 0, 0, 60))
    if key:
        draw_key(im, 160 * S, 13 * S, key, 20 * S)
    save(im, name)


# ----------- LOS BOTONES DE ABAJO A LA IZQUIERDA -----------

LABEL = (255, 208, 21, 255)


def side_buttons():
    im = Image.new('RGBA', (200 * S, 200 * S), PANEL)
    d = ImageDraw.Draw(im)
    rows = [('F', 'RECETARIO'), ('M', 'MENÚ'), ('ESPACIO', 'INICIAR / PAUSA')]
    for i, (key, text) in enumerate(rows):
        top = i * 50
        box(d, (6, top + 6, 194, top + 44), (2, 112, 157, 255), radius=9)   # opaco: tapa las teclas del fondo
        end = draw_key(im, 12 * S, (top + 12) * S, key, 26 * S)
        d = ImageDraw.Draw(im)
        size = 14 if end + 8 * S + font(14 * S).getlength(text) < 190 * S else 12
        d.text((end + 8 * S, (top + 25) * S), text, font=font(round(size * S)), fill=LABEL, anchor='lm')
    for i in range(3):
        draw_key(im, (i * 50 + 8) * S, 158 * S, str(i + 1), 30 * S)
    d = ImageDraw.Draw(im)
    d.text((175 * S, 175 * S), 'VEL.', font=font(round(13 * S)), fill=LABEL, anchor='mm')
    save(im, 'side_buttons.png')

    sel = canvas(50, 50)
    box(ImageDraw.Draw(sel), (3, 4, 49, 41), None, YELLOW, 3, 9)
    save(sel, 'speed_selected.png')


# ----------- PORTADA, PANEL DE EDITAR Y RECETARIO -----------

def cover_focus():
    im = canvas(440, 60)
    d = ImageDraw.Draw(im)
    box(d, (2, 2, 438, 58), (255, 210, 63, 45), YELLOW, 4, 12)
    save(im, 'cover_focus.png')


def option_focus():
    im = canvas(50, 50)
    d = ImageDraw.Draw(im)
    box(d, (1, 1, 49, 49), None, (0, 0, 0, 160), 2, 8)
    box(d, (3, 3, 47, 47), None, YELLOW, 3, 7)
    save(im, 'option_focus.png')


def book_arrow(name, symbol, key, enabled):
    im = canvas(50, 80)
    d = ImageDraw.Draw(im)
    d.ellipse([2 * S, 6 * S, 48 * S, 52 * S], fill=BROWN_DARK)
    d.ellipse([2 * S, 2 * S, 48 * S, 48 * S], fill=CREAM, outline=BROWN, width=3 * S)
    # el triángulo de la flecha
    if symbol == '<':
        d.polygon([(30 * S, 14 * S), (30 * S, 36 * S), (15 * S, 25 * S)], fill=BROWN)
    else:
        d.polygon([(20 * S, 14 * S), (20 * S, 36 * S), (35 * S, 25 * S)], fill=BROWN)
    draw_key(im, 13 * S, 56 * S, key, 22 * S)
    if not enabled:
        im.putalpha(im.getchannel('A').point(lambda a: a * 30 // 100))
    save(im, name)


def book_close():
    im = canvas(100, 100)
    d = ImageDraw.Draw(im)
    d.ellipse([10 * S, 14 * S, 90 * S, 94 * S], fill=(109, 26, 21, 255))
    d.ellipse([10 * S, 10 * S, 90 * S, 90 * S], fill=(224, 74, 63, 255), outline=(165, 42, 34, 255), width=4 * S)
    w = 7 * S
    d.line([(36 * S, 36 * S), (64 * S, 64 * S)], fill=WHITE, width=w)
    d.line([(64 * S, 36 * S), (36 * S, 64 * S)], fill=WHITE, width=w)
    draw_key(im, 38 * S, 76 * S, 'F', 22 * S)
    save(im, 'book_close.png')


if __name__ == '__main__':
    actions('actions_all.png', [True, True, True])
    actions('actions_noedit.png', [True, False, True])
    actions('actions_editonly.png', [False, True, False])
    actions('actions_none.png', [False, False, False])
    mode('mode_placing.png', 'place', 'COLOCANDO', PLACE)
    mode('mode_editing.png', 'edit', 'EDITANDO', EDIT, '⌫')
    side_buttons()
    cover_focus()
    option_focus()
    book_arrow('book_prev.png', '<', '←', True)
    book_arrow('book_prev_off.png', '<', '←', False)
    book_arrow('book_next.png', '>', '→', True)
    book_arrow('book_next_off.png', '>', '→', False)
    book_close()
    print('ok')
