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
# - key_<nombre>.png (200x25): una tecla con su texto. Las muestra la info del nivel: al ganar (N y 0) y
#   en el tutorial (ver levelInfoMenu). La tecla empieza en x 6, como las del fondo.
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
    d.text((x + w / 2, y + height * 0.46), text, font=font(size), fill=LETTER, anchor='mm')
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
    ('next', ['N'], 'SIGUIENTE'),
    ('restart', ['0'], 'REINICIAR'),
    # las del tutorial
    ('place', ['Z'], 'COLOCAR'),
    ('edit', ['X'], 'EDITAR'),
    ('rotate', ['C'], 'ROTAR'),
    ('up', ['W'], 'MIRAR ARRIBA'),
    ('left', ['A'], 'MIRAR A LA IZQ.'),
    ('continue', ['ENTER'], 'SEGUIR'),
    ('start', ['ESPACIO'], 'COCINAR'),
    ('stop', ['ESPACIO'], 'APAGAR'),
    # el botón para saltear el tutorial (también se clickea)
    ('skip', ['T'], 'SALTEAR TUTORIAL'),
]

# La pantalla de controles: dos columnas de (teclas, texto)
CONTROLS_LEFT = ('CONSTRUIR', [
    (['CLICK'], 'Usar la herramienta'),
    (['Z'], 'Colocar'),
    (['X'], 'Editar'),
    (['C'], 'Rotar'),
    (['V'], 'Borrar'),
    (['W', 'A', 'S', 'D'], 'Hacia dónde mira'),
    (['Q', 'E'], 'Páginas de máquinas'),
    (['T'], 'Saltear el tutorial'),
])
CONTROLS_RIGHT = ('JUGAR', [
    (['ESPACIO'], 'Prender / apagar'),
    (['1', '2', '3'], 'Velocidad'),
    (['ENTER'], 'Seguir (tutorial)'),
    (['N'], 'Siguiente nivel'),
    (['0'], 'Reiniciar el nivel'),
    (['L'], 'Modo libre'),
    (['F'], 'Recetario'),
    (['←', '→'], 'Pasar recetas'),
    (['M'], 'Volver al menú'),
])


def bulbs(d, box, step=50):
    """Las lamparitas del marco, como el panel de la portada"""
    x0, y0, x1, y1 = box
    points = [(x, y0) for x in range(x0 + 25, x1 - 10, step)] + [(x, y1) for x in range(x0 + 25, x1 - 10, step)]
    points += [(x0, y) for y in range(y0 + 25, y1 - 10, step)] + [(x1, y) for y in range(y0 + 25, y1 - 10, step)]
    for (x, y) in points:
        d.ellipse([x - 7, y - 7, x + 7, y + 7], fill=(255, 236, 170, 255))
        d.ellipse([x - 4, y - 4, x + 4, y + 4], fill=(255, 250, 225, 255))


def controls_screen():
    im = Image.open('menu_controls_base.png').convert('RGBA')
    d = ImageDraw.Draw(im)
    # el panel: marco gris con lamparitas y madera adentro, como el de la portada
    frame = (95, 150, 1155, 770)
    d.rounded_rectangle(frame, radius=24, fill=(120, 120, 125, 255))
    bulbs(d, frame)
    wood = (125, 180, 1125, 740)
    d.rectangle(wood, fill=(150, 72, 10, 255), outline=(90, 40, 5, 255), width=4)
    d.line([(625, 200), (625, 690)], fill=(100, 45, 5, 255), width=3)

    title_font = font(30, 'ROCKEB.TTF')
    label_font = font(22, 'segoeuib.ttf')
    for (title, rows), x0 in ((CONTROLS_LEFT, 165), (CONTROLS_RIGHT, 665)):
        d.text((x0 + 210, 215), title, font=title_font, fill=(255, 255, 255, 255), anchor='mm',
               stroke_width=3, stroke_fill=(40, 20, 5, 255))
        y = 255
        for keys, label in rows:
            x = x0
            for key in keys:
                x = draw_key(im, x, y, key, 38) + 6
            d = ImageDraw.Draw(im)
            d.text((max(x, x0 + 150) + 10, y + 19), label, font=label_font, fill=LABEL, anchor='lm')
            y += 50
    d.text((625, 712), 'I: volver', font=font(22, 'ROCKEB.TTF'), fill=(255, 255, 255, 255), anchor='mm',
           stroke_width=2, stroke_fill=(40, 20, 5, 255))
    im.save('menu_controls.png')


if __name__ == '__main__':
    for name, keys, label in HINTS:
        key_hint(keys, label, 'key_' + name + '.png')
    controls_screen()
    print('ok')
