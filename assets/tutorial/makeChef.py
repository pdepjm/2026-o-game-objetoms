#!/usr/bin/env python3
# Buffet Albert Einstein - genera el cocinero del tutorial, sus globos y el recuadro rojo.
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
Genera en esta carpeta lo que dibujan chefGuide y tutorialMarks (src/menu/overBoard/tutorialGuide.wlk). Los mensajes
del globo, ya escritos, los genera makeBubbleTexts.py:

- chef_<cara>_<pose>_<lado>.png (120x160): el cocinero.
    cara: talk (habla), oops (el jugador hizo algo que no va), happy (terminó el tutorial)
    pose: down (señala con la cuchara hacia abajo: se para arriba de la celda)
          up (señala hacia arriba: se para abajo de la celda)
    lado: right (mira a la derecha: se para a la izquierda de la celda), left (al revés, espejado)
  La punta de la cuchara queda 25 px adentro del borde del lado al que mira, y 5 px adentro del de
  arriba o de abajo. Si cambia, cambiar chefGuide (chefWidth, chefHeight, chefLeft, chefBottom).
- bubble_<cola>_<n>.png y bubble_<cola>_error_<n>.png: el globo para n líneas (1 a 6), con la cola a la
  izquierda o a la derecha (hacia el cocinero). El de error es rojo. Mide 214 px de ancho (200 de globo y
  14 de cola) y 16 + 25 + 27.5 por línea extra + 18 px de alto, como chefGuide.bubbleHeight.
- key_<nombre>.png (200x25): la fila del globo con la tecla que hay que apretar y qué hace
  ("[ENTER] para seguir"). Va en el globo debajo del mensaje, en el lugar de una línea (chefGuide usa el
  globo de una línea más). La tecla se dibuja como las del fondo (assets/menu/makeKeyHints.py). Para una
  tecla nueva, agregarla en KEYS y usar su nombre en keys de un paso (levels/levelsTypes.wlk).
- place_error.gif: el recuadro del tutorial (place.gif) en rojo.

El cocinero se dibuja en SVG con un navegador (Edge, Chrome o Chromium) sin abrir ventanas, como
assets/food/svgToSprite.py, a 4 veces el tamaño, y se achica para suavizar los bordes.

Uso (desde la raíz del repositorio):   python assets/tutorial/makeChef.py
"""
import os
import subprocess
import sys
import tempfile
from pathlib import Path

from PIL import Image, ImageDraw

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent / "food"))
from svgToSprite import find_browser  # noqa: E402
sys.path.insert(0, str(HERE.parent / "menu"))
from makeKeyHints import draw_key, font, key_width  # noqa: E402

W, H = 120, 160
S = 4

# ----------- EL COCINERO -----------

INK = "#2b2b2b"


def face(mood):
    if mood == "oops":
        brows = f'<path d="M38 50 l12 5 M82 50 l-12 5" stroke="#3a2a1a" stroke-width="4" stroke-linecap="round"/>'
    else:
        brows = '<path d="M38 51 q6 -5 12 0 M70 51 q6 -5 12 0" stroke="#3a2a1a" stroke-width="3.5" fill="none" stroke-linecap="round"/>'
    if mood == "happy":
        eyes = f'<path d="M40 61 q5 -6 10 0 M70 61 q5 -6 10 0" stroke="{INK}" stroke-width="3.5" fill="none" stroke-linecap="round"/>'
    else:
        eyes = (f'<circle cx="45" cy="61" r="4.2" fill="{INK}"/><circle cx="75" cy="61" r="4.2" fill="{INK}"/>'
                '<circle cx="46.5" cy="59.5" r="1.3" fill="#fff"/><circle cx="76.5" cy="59.5" r="1.3" fill="#fff"/>')
    if mood == "oops":
        mouth = f'<ellipse cx="60" cy="86" rx="5" ry="6" fill="#7a1f1f" stroke="{INK}" stroke-width="2"/>'
        extra = '<path d="M92 44 q5 8 0 11 q-5 -3 0 -11z" fill="#8fd3ff" stroke="#2b6a8a" stroke-width="1.5"/>'
    elif mood == "happy":
        mouth = f'<path d="M48 82 q12 14 24 0 z" fill="#7a1f1f" stroke="{INK}" stroke-width="2.5" stroke-linejoin="round"/>'
        extra = ''
    else:
        mouth = f'<ellipse cx="60" cy="86" rx="7" ry="5" fill="#7a1f1f" stroke="{INK}" stroke-width="2"/>'
        extra = ''
    return f'''
    <g stroke="{INK}" stroke-width="3" stroke-linejoin="round">
      <rect x="34" y="30" width="52" height="16" rx="3" fill="#fff"/>
      <circle cx="40" cy="22" r="14" fill="#fff"/><circle cx="60" cy="14" r="16" fill="#fff"/><circle cx="80" cy="22" r="14" fill="#fff"/>
      <path d="M30 60 q0 -16 30 -16 q30 0 30 16 q0 34 -30 36 q-30 -2 -30 -36z" fill="#f4c49c"/>
      <circle cx="30" cy="66" r="6" fill="#f4c49c"/><circle cx="90" cy="66" r="6" fill="#f4c49c"/>
    </g>
    <rect x="34" y="40" width="52" height="7" fill="#fff"/><path d="M34 47 h52" stroke="{INK}" stroke-width="3"/>
    <circle cx="38" cy="73" r="5" fill="#f29a8a" opacity=".7"/><circle cx="82" cy="73" r="5" fill="#f29a8a" opacity=".7"/>
    {brows}{eyes}
    <path d="M60 64 q4 6 0 9" stroke="#c98d63" stroke-width="3" fill="none" stroke-linecap="round"/>
    <path d="M40 78 q10 -8 20 -2 q10 -6 20 2 q-6 6 -20 2 q-14 4 -20 -2z" fill="#5a3a22" stroke="{INK}" stroke-width="2"/>
    {mouth}{extra}'''


def body(mood):
    """El cocinero sin el brazo derecho, en coordenadas de 120x165 (se achica al 80% al ubicarlo)."""
    return f'''
      <g stroke="{INK}" stroke-width="3" stroke-linejoin="round">
        <rect x="40" y="140" width="14" height="22" rx="3" fill="#3b3b3b"/><rect x="66" y="140" width="14" height="22" rx="3" fill="#3b3b3b"/>
        <path d="M28 145 q-2 -42 32 -46 q34 4 32 46z" fill="#fff"/>
        <rect x="38" y="118" width="44" height="26" rx="4" fill="#f3efe6"/>
        <path d="M46 100 l14 13 l14 -13 l-4 -4 l-10 8 l-10 -8z" fill="#e0312b"/>
        <path d="M30 112 q-14 10 -10 24" fill="none" stroke-width="9"/><path d="M30 112 q-14 10 -10 24" fill="none" stroke-width="5" stroke="#fff"/>
      </g>{face(mood)}'''


def arm(path, hand, spoon_from, spoon_to, bowl, bowl_angle):
    return f'''
      <g stroke-linejoin="round" stroke-linecap="round">
        <path d="{path}" fill="none" stroke="{INK}" stroke-width="8"/><path d="{path}" fill="none" stroke="#fff" stroke-width="4"/>
        <path d="M{spoon_from[0]} {spoon_from[1]} L{spoon_to[0]} {spoon_to[1]}" stroke="{INK}" stroke-width="6"/>
        <path d="M{spoon_from[0]} {spoon_from[1]} L{spoon_to[0]} {spoon_to[1]}" stroke="#a8743f" stroke-width="3"/>
        <ellipse cx="{bowl[0]}" cy="{bowl[1]}" rx="5" ry="7" transform="rotate({bowl_angle} {bowl[0]} {bowl[1]})" fill="#c08a4a" stroke="{INK}" stroke-width="2"/>
        <circle cx="{hand[0]}" cy="{hand[1]}" r="5" fill="#f4c49c" stroke="{INK}" stroke-width="2.5"/>
      </g>'''


def chef_svg(mood, pose):
    if pose == "down":
        # arriba de la celda: la cuchara apunta hacia abajo, con la punta en (95, 155)
        figure = f'<g transform="translate(0 6) scale(0.8)">{body(mood)}</g>'
        hand = arm("M72 94 q15 6 17 22", (89, 117), (90, 121), (94, 143), (95, 149), -8)
    else:
        # abajo de la celda: la cuchara apunta hacia arriba, con la punta en (95, 5)
        figure = f'<g transform="translate(0 28) scale(0.8)">{body(mood)}</g>'
        hand = arm("M72 116 q20 -18 20 -62", (92, 52), (93, 47), (95, 17), (95, 11), 4)
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" width="{W}" height="{H}">'
            f'{figure}{hand}</svg>')


def render(svg, browser, work_dir):
    page = work_dir / "chef.svg"
    shot = work_dir / "chef.png"
    page.write_text(svg, encoding="utf-8")
    shot.unlink(missing_ok=True)
    subprocess.run([browser, "--headless=new", "--disable-gpu", "--hide-scrollbars",
                    "--default-background-color=00000000", f"--force-device-scale-factor={S}",
                    f"--window-size={W},{H}", f"--screenshot={shot}", page.as_uri()],
                   check=True, capture_output=True)
    with Image.open(shot) as big:
        return big.convert("RGBA").resize((W, H), Image.LANCZOS)


def chefs():
    browser = find_browser(None)
    with tempfile.TemporaryDirectory() as work_dir:
        for mood in ["talk", "oops", "happy"]:
            for pose in ["down", "up"]:
                image = render(chef_svg(mood, pose), browser, Path(work_dir))
                image.save(HERE / f"chef_{mood}_{pose}_right.png")
                image.transpose(Image.FLIP_LEFT_RIGHT).save(HERE / f"chef_{mood}_{pose}_left.png")
    print("  chef_*.png: 12")


# ----------- LOS GLOBOS -----------

PARCHMENT = (252, 244, 229, 255)
BORDER = (90, 55, 30, 255)
ERROR_FILL = (255, 228, 223, 255)
ERROR_BORDER = (200, 40, 30, 255)
BODY = 200
TAIL = 14
LINE = 0.55 * 50


def bubble(lines, tail_side, error):
    fill, border = (ERROR_FILL, ERROR_BORDER) if error else (PARCHMENT, BORDER)
    w = BODY + TAIL
    h = round(16 + 25 + (lines - 1) * LINE + 18)
    im = Image.new("RGBA", (w * S, h * S), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    x0 = TAIL if tail_side == "left" else 0
    d.rounded_rectangle([x0 * S, 0, (x0 + BODY) * S - 1, h * S - 1], radius=14 * S, fill=fill, outline=border, width=3 * S)
    # la cola, a la altura de la cabeza del cocinero
    if tail_side == "left":
        edge = (x0 + 3) * S
        tail = [(edge, 18 * S), (edge, 38 * S), (0, 30 * S)]
    else:
        edge = (x0 + BODY - 3) * S
        tail = [(edge, 18 * S), (edge, 38 * S), (w * S - 1, 30 * S)]
    d.polygon(tail, fill=fill)
    d.line([tail[0], tail[2]], fill=border, width=3 * S)
    d.line([tail[1], tail[2]], fill=border, width=3 * S)
    name = f"bubble_{tail_side}_{'error_' if error else ''}{lines}.png"
    im.resize((w, h), Image.LANCZOS).save(HERE / name)


def bubbles():
    for lines in range(1, 7):
        for side in ["left", "right"]:
            for error in [False, True]:
                bubble(lines, side, error)
    print("  bubble_*.png: 24")


# ----------- LAS TECLAS DEL GLOBO -----------

# (nombre, tecla, lo que hace): los mismos nombres que keys de los pasos del tutorial
KEYS = [
    # colocar: sólo con el clic en el recuadro (ver toolsManager)
    ("place", "CLIC", "para colocar"),
    # rotar y editar: la tecla, sobre la máquina elegida (el cursor salta solo al recuadro)
    ("edit", "X", "para editar"),
    ("rotate", "C", "para rotar"),
    # en el panel de editar: clic en la opción, o flechas y Enter
    ("choose", "CLIC", "o Enter: elegir"),
    ("up", "W", "mira arriba"),
    ("left", "A", "mira a la izq."),
    # seguir: Enter, o un clic en el globo (ver playingScreen)
    ("continue", "ENTER", "o clic: seguir"),
    ("start", "ESPACIO", "para cocinar"),
    ("stop", "ESPACIO", "para apagar"),
]
KEY_TEXT = (76, 48, 30, 255)     # el marrón de las letras del globo (menu/font/text)


def key_line(name, key, label):
    """La tecla y su texto, centrados en el ancho del globo"""
    w, h = BODY, 25
    im = Image.new("RGBA", (w * S, h * S), (0, 0, 0, 0))
    text_font = font(13 * S)
    key_h = 22 * S
    gap = 6 * S
    total = key_width(key, key_h) + gap + text_font.getlength(label)
    x = round((w * S - total) / 2)
    x = draw_key(im, x, (h * S - key_h) // 2, key, key_h) + gap
    ImageDraw.Draw(im).text((x, h * S / 2), label, font=text_font, fill=KEY_TEXT, anchor="lm")
    im.resize((w, h), Image.LANCZOS).save(HERE / f"key_{name}.png")


def keys():
    for name, key, label in KEYS:
        key_line(name, key, label)
    print(f"  key_*.png: {len(KEYS)}")


# ----------- EL RECUADRO ROJO -----------

def place_error():
    gif = Image.open(HERE / "place.gif")
    frames, durations = [], []
    for index in range(gif.n_frames):
        gif.seek(index)
        frame = gif.convert("RGBA")
        pixels = frame.load()
        for x in range(frame.width):
            for y in range(frame.height):
                r, g, b, a = pixels[x, y]
                # el amarillo pasa a rojo; el negro del borde queda
                if a > 0 and r > 120 and g > 90 and b < 110:
                    pixels[x, y] = (min(255, r + 10), int(g * 0.2), int(b * 0.2), a)
        frames.append(frame)
        durations.append(gif.info.get("duration", 100))
    frames[0].save(HERE / "place_error.gif", save_all=True, append_images=frames[1:], duration=durations,
                   loop=0, disposal=2)
    print("  place_error.gif")


if __name__ == "__main__":
    sys.stdout.reconfigure(encoding="utf-8")
    chefs()
    bubbles()
    keys()
    place_error()
    print("ok")
