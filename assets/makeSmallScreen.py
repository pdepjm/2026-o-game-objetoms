# Buffet Albert Einstein - adapta las imágenes de pantalla completa a la pantalla de 22x13 celdas.
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

"""
La pantalla pasó de 25x16 celdas (1250x800) a 22x13 (1100x650), con un tablero de 12x10.
Este script arma las imágenes de pantalla completa del tamaño nuevo a partir de las de antes, que
saca de git (del commit ORIGINALS, el último con la pantalla grande): así se puede volver a correr.

- background.gif: la sala se rearma cuadro por cuadro. Las
  esquinas quedan iguales, las paredes se estiran repitiendo un tramo liso, el piso se recorta, y los
  adornos de la pared de arriba (ventanas y mostrador, que se animan) se reubican. El hueco de los
  platitos va arriba de las columnas 13 y 14 (deliveryPoints).
- menu/menu_background.png: el fondo de la portada, agrandado hasta cubrir la pantalla.
- startScreen.png y menu/menu_controls.png: lo que tienen encima del fondo se achica al 81% y se
  centra sobre el fondo nuevo.
- recipes_book/recetario_page<n>.png: el libro se achica al 81% sobre la misma sombra.

Uso (desde la raíz del repositorio):   python assets/makeSmallScreen.py
Requiere Pillow.
"""
import io
import os
import subprocess
import sys

from PIL import Image, ImageChops, ImageFilter

ORIGINALS = "b321b"          # commit con las imágenes de 1250x800
OLD_W, OLD_H = 1250, 800
W, H = 1100, 650             # game.width(22), game.height(13), celdas de 50
CELL = 50
SCALE = H / OLD_H            # 0.8125: lo que entra de alto

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)


def original(path):
    data = subprocess.run(["git", "show", f"{ORIGINALS}:assets/{path}"], cwd=ROOT, check=True, capture_output=True).stdout
    return Image.open(io.BytesIO(data))


def out(path):
    return os.path.join(HERE, path)


# ----------- LA SALA -----------
# Antes: paneles de 200 px, sala de x 200 a 1050 (paredes de 50), tablero de x 250 a 1000 y de y 100 a 750.
# Ahora: sala de x 200 a 900, tablero de x 250 a 850 y de y 100 a 600.
ROOM_LEFT, ROOM_RIGHT = 200, W - 200
BOARD_RIGHT, BOARD_BOTTOM = W - 250, H - 50
PLATE_COLUMN = 13
# Los adornos de la pared de arriba: (x0, y0, x1, y1) en la imagen vieja y la x nueva
DECOR = [
    ((335, 22, 407, 64), 335),           # ventana 1, donde estaba
    ((622, 22, 736, 74), 485),           # el mostrador, antes de los platitos
    ((486, 22, 560, 64), 770),           # ventana 2, después de los platitos
]
NOTCH = (793, 38, 909, 100)              # el hueco con los dos platitos (empieza 7 px antes de su columna)


def tile(frame, box, dest, size, canvas):
    """Repite el recorte box de frame hasta llenar size, a partir de dest."""
    piece = frame.crop(box)
    pw, ph = piece.size
    for x in range(dest[0], dest[0] + size[0], pw):
        for y in range(dest[1], dest[1] + size[1], ph):
            w = min(pw, dest[0] + size[0] - x)
            h = min(ph, dest[1] + size[1] - y)
            canvas.paste(piece.crop((0, 0, w, h)), (x, y))


def room_frame(frame):
    frame = frame.convert("RGB")
    im = Image.new("RGB", (W, H))
    # paneles: el de la izquierda tiene el logo arriba y las teclas abajo; el medio es azul liso
    im.paste(frame.crop((0, 0, 200, H // 2)), (0, 0))
    im.paste(frame.crop((0, OLD_H - (H - H // 2), 200, OLD_H)), (0, H // 2))
    im.paste(frame.crop((1050, 0, 1250, H // 2)), (W - 200, 0))
    im.paste(frame.crop((1050, OLD_H - (H - H // 2), 1250, OLD_H)), (W - 200, H // 2))
    # paredes: tramos lisos repetidos
    tile(frame, (740, 0, 790, 100), (ROOM_LEFT + 50, 0), (ROOM_RIGHT - ROOM_LEFT - 100, 100), im)
    tile(frame, (500, 750, 550, 800), (ROOM_LEFT + 50, H - 50), (ROOM_RIGHT - ROOM_LEFT - 100, 50), im)
    tile(frame, (200, 300, 250, 350), (ROOM_LEFT, 100), (50, H - 150), im)
    tile(frame, (1000, 300, 1050, 350), (ROOM_RIGHT - 50, 100), (50, H - 150), im)
    # esquinas
    im.paste(frame.crop((200, 0, 250, 100)), (ROOM_LEFT, 0))
    im.paste(frame.crop((1000, 0, 1050, 100)), (ROOM_RIGHT - 50, 0))
    im.paste(frame.crop((200, 750, 250, 800)), (ROOM_LEFT, H - 50))
    im.paste(frame.crop((1000, 750, 1050, 800)), (ROOM_RIGHT - 50, H - 50))
    # piso: las primeras 12x10 celdas del tablero viejo
    im.paste(frame.crop((250, 100, 250 + BOARD_RIGHT - 250, 100 + BOARD_BOTTOM - 100)), (250, 100))
    # adornos y platitos
    for box, x in DECOR:
        im.paste(frame.crop(box), (x, box[1]))
    im.paste(frame.crop(NOTCH), (PLATE_COLUMN * CELL - 7, NOTCH[1]))
    return im


def background():
    gif = original("background.gif")
    frames, durations = [], []
    for index in range(gif.n_frames):
        gif.seek(index)
        frames.append(room_frame(gif))
        durations.append(gif.info.get("duration", 70))
    frames[0].save(out("background.gif"), save_all=True, append_images=frames[1:], duration=durations, loop=0,
                   optimize=False, disposal=1)
    print("  background.gif:", len(frames), "cuadros")


# ----------- PORTADA, CONTROLES Y RECETARIO -----------

def cover(im):
    """Agranda la imagen hasta cubrir W x H y recorta lo que sobra, centrado."""
    scale = max(W / im.width, H / im.height)
    big = im.resize((round(im.width * scale), round(im.height * scale)), Image.LANCZOS)
    left, top = (big.width - W) // 2, (big.height - H) // 2
    return big.crop((left, top, left + W, top + H))


def shrink(im):
    return im.resize((round(im.width * SCALE), round(im.height * SCALE)), Image.LANCZOS)


def menu_screens():
    old_background = original("menu/menu_background.png").convert("RGBA")
    new_background = cover(old_background)
    new_background.save(out("menu/menu_background.png"))
    print("  menu/menu_background.png")
    for path in ["startScreen.png", "menu/menu_controls.png"]:
        screen = original(path).convert("RGBA")
        # lo que tiene encima del fondo: lo que es distinto del fondo, con el borde un poco agrandado
        difference = ImageChops.difference(screen.convert("RGB"), old_background.convert("RGB")).convert("L")
        mask = difference.point(lambda v: 255 if v > 14 else 0).filter(ImageFilter.MaxFilter(5)).filter(ImageFilter.GaussianBlur(1))
        foreground = screen.copy()
        foreground.putalpha(mask)
        small = shrink(foreground)
        result = new_background.copy()
        result.alpha_composite(small, ((W - small.width) // 2, 0))
        result.save(out(path))
        print("  " + path)


def recipe_book():
    for page in range(11):
        path = f"recipes_book/recetario_page{page}.png"
        old = original(path).convert("RGBA")
        result = Image.new("RGBA", (W, H), old.getpixel((5, 5)))
        small = shrink(old)
        # la sombra de la imagen vieja ya está en el fondo: se reemplaza, no se suma
        result.paste(small, ((W - small.width) // 2, 0))
        result.save(out(path))
    print("  recipes_book: 11 páginas")


if __name__ == "__main__":
    sys.stdout.reconfigure(encoding="utf-8")
    background()
    menu_screens()
    recipe_book()
    print("ok")
