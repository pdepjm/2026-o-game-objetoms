#!/usr/bin/env python3
# Buffet Albert Einstein - dibuja en UNA imagen cada mensaje del cocinero del tutorial.
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
Wollok dibuja todos los visuals en cada frame: el cocinero, su globo, el paso, el mensaje y las teclas van
juntos en una sola imagen por mensaje (ver chefGuide en src/menu/overBoard/tutorialGuide.wlk).

1. Le pide a Wollok lo que dice cada mensaje de los tutoriales y cómo se para el cocinero
   (chefGuide.signatureOf: imagen;paso;líneas;teclas;cara;pose;mira;lado del globo;cocinero x;y;globo x;y;
   ancho;alto, en px desde la esquina de arriba a la izquierda). Para eso corre un test temporal con
   `wollok test` (hace falta wollok-ts-cli).
2. Dibuja steps/<imagen>.png con el cocinero y el globo (makeChef.py) y, en el globo, el paso (gris, 11 px),
   las líneas (marrón, 14 px) y una fila por tecla, con las mismas medidas que tenía cuando se dibujaban por
   separado. Las letras salen de la fuente segoeuib.ttf de Windows.
3. Dibuja steps/oops_right.png y steps/oops_left.png: la queja genérica (cocinero "oops" y globo rojo a la
   derecha o a la izquierda), del mismo ancho que los mensajes.
4. Escribe src/menu/overBoard/tutorialImages.wlk con las firmas de lo que dibujó: un test de tutorialTest
   avisa si algún mensaje no tiene imagen o cambió desde que se dibujó.

Uso (desde la raíz del repositorio), cada vez que se cambia un mensaje, una celda o un paso de un tutorial:
    python assets/tutorial/makeSteps.py
"""
import math
import shutil
import subprocess
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

from makeChef import BODY, LINE, S, TAIL, bubble, bubble_height, chef_images, draw_key_row

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent.parent
OUT = HERE / "steps"
WLK = ROOT / "src" / "menu" / "overBoard" / "tutorialImages.wlk"
DUMP = ROOT / "test" / "_tutorialImagesDump.wtest"

# Las letras: segoeuib.ttf, marrón para el mensaje y gris para el paso
TEXT_FONT = ImageFont.truetype("segoeuib.ttf", 14 * S)
TEXT_COLOR = (74, 47, 29, 255)
LABEL_FONT = ImageFont.truetype("segoeuib.ttf", 11 * S)
LABEL_COLOR = (154, 147, 135, 255)

# Medidas desde el borde de arriba del globo, en px: la base de la etiqueta, la de la primera línea y la fila
# de la primera tecla (la etiqueta y las líneas eran letras de 20 px con la base a 15 px de su borde de arriba)
LABEL_BASELINE = 6 + 15
FIRST_LINE_BASELINE = 31 + 15
FIRST_ROW_TOP = 28.5

# La queja: el mismo texto para todo lo que el paso no deja hacer
OOPS_LABEL = "¡UY!"
OOPS_LINES = ["Así no: fijate", "qué te pido."]
CHEF_W, CHEF_H = 120, 160
GAP = 3


def signatures():
    """Las firmas de todos los mensajes, como las calcula chefGuide.signatureOf"""
    DUMP.write_text('''import src.levels.levelManager.*
import src.menu.overBoard.tutorialGuide.*

describe "imagenes del tutorial" {
  test "firmas" {
    levelManager.levels().flatMap({ level => level.tutorial().allMessages() })
      .forEach({ speech => console.println("STEP;" + chefGuide.signatureOf(speech)) })
  }
}
''', encoding="utf-8")
    try:
        result = subprocess.run(f'wollok test --skipValidations -p ./ -f {DUMP.relative_to(ROOT).as_posix()}',
                                cwd=ROOT, shell=True, capture_output=True)
    finally:
        DUMP.unlink(missing_ok=True)
    output = result.stdout.decode("utf-8", errors="replace")
    found = [line.strip()[len("STEP;"):] for line in output.splitlines() if line.strip().startswith("STEP;")]
    if not found:
        sys.exit("Wollok no devolvió los mensajes:\n" + output + result.stderr.decode("utf-8", errors="replace"))
    return found


def parse(signature):
    (image, label, lines, keys, mood, pose, facing, side,
     chef_x, chef_y, bubble_x, bubble_y, width, height) = signature.split(";")
    return dict(image=image, label=label, lines=lines.split("|") if lines else [], keys=keys.split(",") if keys else [],
                mood=mood, pose=pose, facing=facing, side=side, chef=(int(chef_x), int(chef_y)),
                bubble=(int(bubble_x), int(bubble_y)), size=(int(width), int(height)))


def centered(draw, text, font, color, center_x, baseline):
    draw.text((center_x - font.getlength(text) / 2, baseline), text, font=font, fill=color, anchor="ls")


def written_bubble(label, lines, keys, side, error):
    """El globo con el paso, las líneas y las teclas, ya achicado (la cola apunta al cocinero)"""
    tail = "left" if side == "right" else "right"
    rows = len(lines) + len(keys)
    im = bubble(rows, tail, error)
    draw = ImageDraw.Draw(im)
    body_left = TAIL if tail == "left" else 0
    center_x = (body_left + BODY / 2) * S
    if label:
        centered(draw, label, LABEL_FONT, LABEL_COLOR, center_x, LABEL_BASELINE * S)
    for row, line in enumerate(lines):
        centered(draw, line, TEXT_FONT, TEXT_COLOR, center_x, (FIRST_LINE_BASELINE + math.floor(row * LINE)) * S)
    for row, key in enumerate(keys, start=len(lines)):
        draw_key_row(im, body_left * S, round((FIRST_ROW_TOP + row * LINE) * S), key)
    return im.resize((BODY + TAIL, bubble_height(rows)), Image.LANCZOS)


def compose(chef, chef_at, bubble_image, bubble_at, size):
    im = Image.new("RGBA", size, (0, 0, 0, 0))
    im.alpha_composite(chef, chef_at)
    im.alpha_composite(bubble_image, bubble_at)
    return im


def oops(side, chef):
    """La queja, con el cocinero donde está en los mensajes con el globo de ese lado (ChefLayout.errorPicture)"""
    width = CHEF_W + GAP + BODY + TAIL
    chef_x = 0 if side == "right" else width - CHEF_W
    bubble_x = width - BODY - TAIL if side == "right" else 0
    return compose(chef, (chef_x, 0), written_bubble(OOPS_LABEL, OOPS_LINES, [], side, True), (bubble_x, 0),
                   (width, CHEF_H))


def main():
    sys.stdout.reconfigure(encoding="utf-8")
    found = signatures()
    steps = [parse(signature) for signature in found]
    oops_chefs = {"right": ("oops", "down", "right"), "left": ("oops", "down", "left")}
    chefs = chef_images({(s["mood"], s["pose"], s["facing"]) for s in steps} | set(oops_chefs.values()))
    shutil.rmtree(OUT, ignore_errors=True)
    OUT.mkdir()
    for s in steps:
        bubble_image = written_bubble(s["label"], s["lines"], s["keys"], s["side"], False)
        compose(chefs[(s["mood"], s["pose"], s["facing"])], s["chef"], bubble_image, s["bubble"], s["size"]) \
            .save(OUT / f"{s['image']}.png")
    for side, chef in oops_chefs.items():
        oops(side, chefs[chef]).save(OUT / f"oops_{side}.png")
    texts = ",\n\t".join('"' + signature + '"' for signature in found)
    WLK.write_text(f'''// GENERADO por assets/tutorial/makeSteps.py: no editar a mano (cambiar los tutoriales y volver a correrlo)

// Lo que dibuja cada imagen de assets/tutorial/steps/ (chefGuide.signatureOf de su mensaje)
const tutorialImages = [
\t{texts}
]
''', encoding="utf-8", newline="\n")
    print(f"ok {len(steps)} mensajes + 2 quejas")


if __name__ == "__main__":
    main()
