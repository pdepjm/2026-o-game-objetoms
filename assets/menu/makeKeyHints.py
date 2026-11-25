# Buffet Albert Einstein - genera las imágenes de las teclas y la pantalla de controles.
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

# Genera las imágenes con teclas, con el mismo estilo que las teclas dibujadas en el fondo (F Recetario,
# M Menú): una tecla gris oscura con la letra blanca y, al lado, lo que hace en amarillo.
#
# - key_<nombre>.png (200x25): una tecla con su texto. Hoy sólo key_skip.png: el botón para saltear el
#   tutorial, en la info del nivel (ver levelInfoMenu). Las teclas de los pasos del tutorial las dice el
#   cocinero, en su globo (assets/tutorial/makeChef.py usa draw_key). La tecla empieza en x 6, como las del fondo.
# - menu_controls.png: la pantalla de controles (la tecla I en la portada), con todas las teclas del juego.
#   Se dibuja sobre menu_controls_base.png (el fondo con el título).
#
# Uso: python makeKeyHints.py (desde esta carpeta)
from PIL import Image, ImageDraw, ImageFont

BORDER = (29, 37, 42, 255)
TOP = (74, 92, 99, 255)
BOTTOM = (47, 60, 65, 255)
LETTER = (250, 250, 250, 255)
LABEL = (255, 208, 21, 255)


def font(size, name='segoeuib.ttf'):
    return ImageFont.truetype(name, size)


def key_width(text, height):
    """Las teclas de una letra son casi cuadradas; las de una palabra (ENTER) se estiran"""
    if len(text) <= 1:
        return round(height * 1.28)
    size = round(height * 0.5)
    return round(font(size).getlength(text) + height * 0.6)


def draw_key(im, x, y, text, height):
    """Dibuja una tecla con su esquina de arriba a la izquierda en (x, y). Devuelve dónde termina (x)."""
    w = key_width(text, height)
    d = ImageDraw.Draw(im)
    r = height * 0.2
    d.rounded_rectangle([x, y, x + w - 1, y + height - 1], radius=r, fill=BORDER)
    # adentro, un degradé de arriba hacia abajo
    inset = max(1, round(height * 0.07))
    inner = Image.new('RGBA', (w - 2 * inset, height - 3 * inset))
    for row in range(inner.height):
        t = row / max(1, inner.height - 1)
        inner.paste(tuple(round(a + (b - a) * t) for a, b in zip(TOP, BOTTOM)), (0, row, inner.width, row + 1))
    mask = Image.new('L', inner.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, inner.width - 1, inner.height - 1], radius=r * 0.8, fill=255)
    im.paste(inner, (x + inset, y + inset), mask)
    size = round(height * (0.64 if len(text) <= 1 else 0.48))
    # el símbolo de Retroceso (⌫) no está en Segoe UI Bold: va con la fuente de símbolos
    name = 'seguisym.ttf' if text == '⌫' else 'segoeuib.ttf'
    d.text((x + w / 2, y + height * 0.46), text, font=font(size, name), fill=LETTER, anchor='mm')
    return x + w


def key_hint(keys, label, path):
    """Una o más teclas con su texto, en una imagen de 200x25 (se dibuja 4 veces más grande y se achica)"""
    S = 4
    im = Image.new('RGBA', (200 * S, 25 * S), (0, 0, 0, 0))
    x = 6 * S
    for key in keys:
        x = draw_key(im, x, 0, key, 25 * S) + 4 * S
    d = ImageDraw.Draw(im)
    d.text((x + 6 * S, 12.5 * S), label, font=font(14 * S), fill=LABEL, anchor='lm')
    im.resize((200, 25), Image.LANCZOS).save(path)


# Las de la info del nivel: (nombre del archivo, teclas, texto)
HINTS = [
    # (las del tutorial las dice el cocinero: ver assets/tutorial/makeChef.py)
    # el botón para saltear el tutorial (también se clickea)
    ('skip', ['T'], 'SALTEAR TUTORIAL'),
]

# La pantalla de controles: dos columnas de (teclas, texto). Ya no hay herramientas: el clic coloca o elige
# una máquina, y C, X y V actúan sobre la elegida (ver toolsManager).
CONTROLS_LEFT = ('CONSTRUIR', [
    (['CLIC'], 'Colocar o elegir máquina'),
    (['←', '↑', '↓', '→'], 'Elegir opción (editando)'),
    (['ENTER'], 'Aplicar (editando)'),
    (['C'], 'Rotar la elegida'),
    (['X'], 'Editar la elegida'),
    (['V'], 'Borrar la elegida'),
    (['Q', 'E'], 'Cambiar de máquina'),
    (['W', 'A', 'S', 'D'], 'Hacia dónde mira'),
    (['⌫'], 'Dejar de editar'),
])
CONTROLS_RIGHT = ('JUGAR', [
    (['ESPACIO'], 'Iniciar / pausar'),
    (['1', '2', '3'], 'Velocidad'),
    (['ENTER'], 'Seguir (tutorial)'),
    (['T'], 'Saltear tutorial'),
    (['N'], 'Siguiente nivel'),
    (['0'], 'Reiniciar el nivel'),
    (['L'], 'Modo libre'),
    (['F'], 'Recetario'),
    (['M'], 'Volver al menú'),
])

# El panel de madera de menu_controls.png (adentro del marco con lamparitas): se pinta de nuevo y se
# escriben las dos columnas encima. El título y el "I volver al menú" de abajo quedan como están.
PANEL = (132, 150, 968, 576)
WOOD = (151, 68, 0, 255)


def controls_screen():
    im = Image.open('menu_controls.png').convert('RGBA')
    d = ImageDraw.Draw(im)
    d.rectangle(PANEL, fill=WOOD)
    d.line([(550, 175), (550, 560)], fill=(100, 45, 5, 255), width=3)
    title_font = font(26, 'segoeuib.ttf')
    label_font = font(16, 'segoeuib.ttf')
    for (title, rows), x0 in ((CONTROLS_LEFT, 155), (CONTROLS_RIGHT, 575)):
        d.text((x0 + 185, 178), title, font=title_font, fill=(255, 255, 255, 255), anchor='mm')
        d.line([(x0 + 70, 200), (x0 + 300, 200)], fill=(210, 160, 110, 255), width=2)
        y = 214
        for keys, label in rows:
            x = x0
            for key in keys:
                x = draw_key(im, x, y, key, 30) + 4
            d = ImageDraw.Draw(im)
            d.text((max(x, x0 + 138) + 8, y + 15), label, font=label_font, fill=LABEL, anchor='lm')
            y += 39
    im.save('menu_controls.png')


if __name__ == '__main__':
    for name, keys, label in HINTS:
        key_hint(keys, label, 'key_' + name + '.png')
    controls_screen()
    print('ok')
