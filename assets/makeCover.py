# Buffet Albert Einstein - la portada sin las teclas de cada opción.
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

# Borra de startScreen.png las teclas de las opciones ("INICIAR (enter)", "CONTROLES (i)"...) y vuelve a
# escribir cada opción sin la tecla, con la misma letra (Rockwell Extra Bold). Las opciones se eligen con
# clic o con las flechas y Enter (ver startMenu). Se puede volver a correr: rellena y escribe lo mismo.
#
# Uso (desde la raíz del repositorio):   python assets/makeCover.py
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont, ImageFilter

HERE = Path(__file__).resolve().parent
src = Image.open(HERE / "startScreen.png").convert("RGBA")
out = HERE / "startScreen.png"

# Bandas con texto (y0, y1, x0, x1), medidas sobre la imagen original
BANDS = [(302, 338, 390, 715), (382, 414, 407, 688), (448, 482, 409, 686), (529, 564, 457, 634)]
LABELS = [("INICIAR", (255, 255, 255)), ("CONTROLES", (255, 255, 255)), ("RECETARIO", (255, 255, 255)), ("SALIR", (255, 69, 69))]

px = src.load()
for y0, y1, x0, x1 in BANDS:
    a, b = y0 - 4, y1 + 4            # filas limpias arriba y abajo
    for x in range(x0 - 4, x1 + 5):
        top, bot = px[x, a], px[x, b]
        for y in range(a + 1, b):
            t = (y - a) / (b - a)
            px[x, y] = tuple(round(top[i] * (1 - t) + bot[i] * t) for i in range(4))

FONT = "C:/Windows/Fonts/ROCKEB.TTF"
SIZES = [33, 32, 32, 32]   # INICIAR va un poco más grande, como en la original
SPACING = 3

def text_width(s, font):
    return sum(font.getlength(c) for c in s) + SPACING * (len(s) - 1)

def draw_spaced(draw, x, y, s, font, **kw):
    for c in s:
        draw.text((x, y), c, font=font, **kw)
        x += font.getlength(c) + SPACING

for (y0, y1, _, _), (label, color), size in zip(BANDS, LABELS, SIZES):
    font = ImageFont.truetype(FONT, size)
    cy = (y0 + y1) / 2
    x = 550 - text_width(label, font) / 2
    y = cy - size * 0.58
    # sombra difusa
    shadow = Image.new("RGBA", src.size, (0, 0, 0, 0))
    draw_spaced(ImageDraw.Draw(shadow), x + 2, y + 4, label, font, fill=(30, 10, 0, 230))
    src.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(3)))
    # letras con contorno oscuro
    draw_spaced(ImageDraw.Draw(src), x, y, label, font, fill=color, stroke_width=3, stroke_fill=(30, 22, 18))

src.convert("RGB").save(out)
print("listo:", out)
