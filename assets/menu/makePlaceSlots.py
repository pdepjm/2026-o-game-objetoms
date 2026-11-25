#!/usr/bin/env python3
# Buffet Albert Einstein - genera los casilleros del menú de colocar, sus marcos y la ayuda.
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
Genera lo que dibuja src/menu/hud/placeMenu.wlk (los casilleros miden 2x2 celdas, 100x100):

- machines/<Máquina>/<dirección>_menu.png: el casillero con la máquina en chico y su nombre abajo
  (Machine.menuImage). El dibujo sale de la imagen de menú original (100x100, la máquina sola), que se
  saca de git (del commit ORIGINALS): así se puede volver a correr. Si se agrega una máquina, agregar su
  nombre en LABELS (y, si no estaba en ese commit, su imagen original en ORIGINAL_FILES).
- menu/slot_selected.png: el marco amarillo de la máquina elegida
- menu/slot_hint.gif: el marco que titila en la máquina que pide el tutorial
- menu/slot_error.png: el marco rojo de una máquina que no va (se ve un momento)
- menu/place_help.png: la ayuda debajo de los casilleros (clic y Q/E). Hacia dónde mira va en la brújula
  (ver makeArmAndCompass.py)

Uso (desde la raíz del repositorio):   python assets/menu/makePlaceSlots.py
Requiere Pillow.
"""
import io
import subprocess
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ASSETS = Path(__file__).resolve().parent.parent
ROOT = ASSETS.parent
ORIGINALS = "b321b"          # commit con las imágenes de menú originales (la máquina sola)
S = 4
SIZE = 100
INSET = 4             # el casillero deja 4 px alrededor, para que no se toquen
ICON = 58

# El nombre que ve el jugador, por carpeta (el mismo que Machine.label)
LABELS = {
    "Belt": "Cinta",
    "Assembler": "Ensamblador",
    "CuttingMachine": "Cortadora",
    "Oven": "Horno",
    "Dispenser": "Dispenser",
    "AutomaticArm": "Brazo",
    "SmartRoboticArm": "Brazo intel.",
    "Fryer": "Freidora",
}

WHITE = (255, 255, 255, 255)
HELP = (214, 238, 248, 255)
YELLOW = (246, 201, 21)
RED = (224, 49, 43)


def font(size):
    return ImageFont.truetype("segoeuib.ttf", size)


def box(d, fill, outline, width):
    d.rounded_rectangle([INSET * S, INSET * S, (SIZE - INSET) * S - 1, (SIZE - INSET) * S - 1],
                        radius=10 * S, fill=fill, outline=outline, width=width * S)


def original(path):
    data = subprocess.run(["git", "show", f"{ORIGINALS}:assets/{path}"], cwd=ROOT, check=True, capture_output=True).stdout
    return Image.open(io.BytesIO(data))


def original_menu_images(folder):
    listing = subprocess.run(["git", "ls-tree", "--name-only", ORIGINALS, f"assets/machines/{folder}/"], cwd=ROOT,
                             check=True, capture_output=True, text=True).stdout.split()
    return [path[len("assets/"):] for path in listing if path.endswith("_menu.png")]


def slot(menu_image, label):
    im = Image.new("RGBA", (SIZE * S, SIZE * S), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    box(d, (0, 0, 0, 46), (255, 255, 255, 70), 3)
    small = original(menu_image).convert("RGBA").resize((ICON * S, ICON * S), Image.LANCZOS)
    im.alpha_composite(small, ((SIZE - ICON) * S // 2, 9 * S))
    d.text((SIZE * S // 2, 81 * S), label, font=font(12 * S), fill=WHITE, anchor="mm",
           stroke_width=S, stroke_fill=(0, 40, 60, 160))
    return im.resize((SIZE, SIZE), Image.LANCZOS)


def slots():
    count = 0
    for folder, label in LABELS.items():
        for menu_image in original_menu_images(folder):
            slot(menu_image, label).save(ASSETS / menu_image)
            count += 1
    print(f"  machines/*/*_menu.png: {count}")


def frame(color, fill_alpha, width):
    im = Image.new("RGBA", (SIZE * S, SIZE * S), (0, 0, 0, 0))
    box(ImageDraw.Draw(im), color + (fill_alpha,), color + (255,), width)
    return im.resize((SIZE, SIZE), Image.LANCZOS)


def frames():
    frame(YELLOW, 40, 4).save(ASSETS / "menu" / "slot_selected.png")
    frame(RED, 110, 4).save(ASSETS / "menu" / "slot_error.png")
    # el que titila: el borde amarillo se engrosa y se aclara. Un GIF no tiene transparencias a medias,
    # así que se dibuja sólo el borde, sin relleno y sin suavizar
    pulse = []
    for width, light in [(3, 0), (4, 40), (5, 80), (6, 120), (5, 80), (4, 40)]:
        im = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
        color = tuple(min(255, c + light) for c in YELLOW) + (255,)
        ImageDraw.Draw(im).rounded_rectangle([INSET, INSET, SIZE - INSET - 1, SIZE - INSET - 1], radius=10,
                                             outline=color, width=width)
        pulse.append(im)
    pulse[0].save(ASSETS / "menu" / "slot_hint.gif", save_all=True, append_images=pulse[1:], duration=110,
                  loop=0, disposal=2)
    print("  menu/slot_selected.png, slot_error.png, slot_hint.gif")


def help_image(lines, name):
    w, line = 200, 19
    h = line * len(lines) + 6
    im = Image.new("RGBA", (w * S, h * S), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    for index, text in enumerate(lines):
        d.text((8 * S, (4 + line * index + line / 2) * S), text, font=font(12 * S), fill=HELP, anchor="lm")
    im.resize((w, h), Image.LANCZOS).save(ASSETS / "menu" / name)


def helps():
    # hacia dónde mira va abajo, en la brújula (compass_*.png, ver makeArmAndCompass.py)
    lines = ["Clic: elegir máquina", "Q / E: cambiar de máquina"]
    help_image(lines, "place_help.png")
    print("  menu/place_help.png")


if __name__ == "__main__":
    sys.stdout.reconfigure(encoding="utf-8")
    slots()
    frames()
    helps()
    print("ok")
