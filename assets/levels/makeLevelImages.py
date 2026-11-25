# Buffet Albert Einstein - genera las imágenes de cada nivel: la info de la izquierda y la comanda del final.
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

# Los niveles son fijos: todo lo que se escribe sobre ellos se dibuja acá, ya listo, para que el juego
# muestre una imagen y no una por letra. Genera (ver src/menu/hud/levelInfoMenu.wlk y src/menu/levelComplete.wlk):
#
# EN info/ (la columna izquierda)
# - ribbon.png (184x46): la cinta roja del nombre del nivel (el nombre lo escribe Wollok encima).
# - goal_title.png (184x47): la parte de arriba de la tarjeta de papel, con "OBJETIVO".
# - <nivel>_goal<i>_<k>.png (184x50): el objetivo i del nivel con k entregados (de 0 a la cantidad): el
#   pedazo de tarjeta de su fila (la del último objetivo, con el borde de abajo), el plato, "<texto>: k/n"
#   y la barra llena k/n (en décimos, como antes).
#
# EN complete/ (el final)
# - <nivel>.png (1100x650): la pantalla oscurecida con la comanda, el cocinero, el nombre del nivel, lo
#   entregado, el título del final ("PEDIDO COMPLETO", o "¡FIN DEL JUEGO!" en el último nivel) y los
#   botones. Los botones se clickean en celdas fijas (ver levelComplete.wlk): si se mueven, moverlos en los dos.
#
# <nivel> es el nombre en minúsculas con "_" en vez de espacios (Level.imageKey()): "Tutorial 1" -> tutorial_1.
# Los niveles se los pide a Wollok (Level.imageSignature(), con un test temporal; hace falta wollok-ts-cli), y
# escribe src/levels/levelImages.wlk con lo que dibujó: un test de levelManagerTest avisa si un nivel cambió y
# hay que volver a correrlo. El cocinero sale de assets/tutorial/ y las teclas de assets/menu/makeKeyHints.py.
#
# Uso (desde la raíz del repositorio):   python assets/levels/makeLevelImages.py
import subprocess
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

HERE = Path(__file__).resolve().parent
ASSETS = HERE.parent
ROOT = ASSETS.parent
WLK = ROOT / 'src' / 'levels' / 'levelImages.wlk'
DUMP = ROOT / 'test' / '_levelImagesDump.wtest'
sys.path.insert(0, str(ASSETS / 'menu'))
from makeKeyHints import draw_key, font  # noqa: E402
from makeBoardUi import box  # noqa: E402

S = 4  # se dibuja 4 veces más grande y se achica
H = 650  # alto de la pantalla: Wollok cuenta las filas desde abajo
PARCHMENT = (252, 244, 229, 255)
PARCHMENT_DARK = (234, 222, 203, 255)
BORDER = (90, 55, 30, 255)
GOLD = (212, 175, 55, 255)
RED = (200, 30, 30, 255)
RED_DARK = (150, 10, 10, 255)
RED_BORDER = (120, 0, 0, 255)
WHITE = (255, 255, 255, 255)
GREEN = (63, 163, 77, 255)
GREEN_DARK = (34, 104, 44, 255)
BLUE = (47, 128, 200, 255)
BLUE_DARK = (29, 79, 125, 255)
GREY = (141, 115, 87, 255)
GREY_DARK = (90, 70, 48, 255)

# Los dos estilos de letra que tenían los textos sobre papel: (fuente, tamaño, color)
TEXT = ('segoeuib.ttf', 14, (74, 47, 29, 255))     # marrón: los objetivos y las filas de la comanda
LABEL = ('segoeuib.ttf', 11, (154, 147, 135, 255))  # gris: OBJETIVO y el nombre del nivel en la comanda

def signatures():
    """Lo que dibuja cada nivel, en el orden en que se juegan, como lo calcula Level.imageSignature()"""
    DUMP.write_text('''import src.levels.levelManager.*

describe "imagenes de los niveles" {
  test "firmas" {
    levelManager.levels().forEach({ level => console.println("LEVEL;" + level.imageSignature()) })
  }
}
''', encoding='utf-8')
    try:
        result = subprocess.run(f'wollok test --skipValidations -p ./ -f {DUMP.relative_to(ROOT).as_posix()}',
                                cwd=ROOT, shell=True, capture_output=True)
    finally:
        DUMP.unlink(missing_ok=True)
    output = result.stdout.decode('utf-8', errors='replace')
    found = [line.strip()[len('LEVEL;'):] for line in output.splitlines() if line.strip().startswith('LEVEL;')]
    if not found:
        sys.exit('Wollok no devolvió los niveles:\n' + output + result.stderr.decode('utf-8', errors='replace'))
    return found


def parse(signature):
    """nombre;texto|cantidad|plato;... -> (nombre, [(texto, cantidad, plato)])"""
    name, *goals = signature.split(';')
    return name, [(label, int(amount), plate) for label, amount, plate in (goal.split('|') for goal in goals)]


def write_signatures(found):
    texts = ',\n\t'.join('"' + signature + '"' for signature in found)
    WLK.write_text(f'''// GENERADO por assets/levels/makeLevelImages.py: no editar a mano (cambiar los niveles y volver a correrlo)

// Lo que dibujan las imágenes de assets/levels/ (Level.imageSignature() de cada nivel, en orden)
const levelImages = [
	{texts}
]
''', encoding='utf-8', newline='\n')


WIDTH = 184        # ancho de la cinta y de la tarjeta (de x 12 a 196 de la pantalla)
TITLE_HEIGHT = 47  # la tarjeta empieza 22 px arriba del centro de la fila del título
ROW = 50


def key(name):
    return name.lower().replace(' ', '_')


def canvas(w, h):
    return Image.new('RGBA', (w * S, h * S), (0, 0, 0, 0))


def shrink(im):
    return im.resize((im.width // S, im.height // S), Image.LANCZOS)


def write(im, text, style, center_x, baseline):
    """Escribe el texto centrado en x, con su base en esa altura (px desde arriba), como lo hacían las letras
    sueltas: cada una con su ancho redondeado a centésimos, una al lado de la otra"""
    face = ImageFont.truetype(style[0], style[1] * S)
    widths = [round(face.getlength(char) / S, 2) for char in text]
    start = center_x - sum(widths) / 2
    left = int(start)
    layer = canvas(int(sum(widths)) + 4, 20)
    d = ImageDraw.Draw(layer)
    x = start - left
    for char, width in zip(text, widths):
        d.text((x * S, 15 * S), char, font=face, fill=style[2], anchor='ls')
        x += width
    im.alpha_composite(shrink(layer), (left, round(baseline) - 15))


# ----------- LA INFO DEL NIVEL -----------

def ribbon():
    w, h = WIDTH, 46
    im = canvas(w, h)
    d = ImageDraw.Draw(im)
    d.rounded_rectangle([0, 4 * S, w * S - 1, h * S - 1], radius=10 * S, fill=RED_DARK)
    d.rounded_rectangle([0, 0, w * S - 1, (h - 5) * S], radius=10 * S, fill=RED, outline=RED_BORDER, width=2 * S)
    shrink(im).save(HERE / 'info' / 'ribbon.png')


def card(goals):
    """La tarjeta entera: el título y una fila por objetivo (después se corta en pedazos)"""
    w, h = WIDTH, TITLE_HEIGHT + ROW * goals
    im = canvas(w, h)
    d = ImageDraw.Draw(im)
    d.rounded_rectangle([0, 0, w * S - 1, h * S - 1], radius=10 * S, fill=PARCHMENT, outline=BORDER, width=3 * S)
    # la línea dorada debajo de "OBJETIVO"
    d.line([(28 * S, 36 * S), (156 * S, 36 * S)], fill=GOLD, width=2 * S)
    return shrink(im)


def bar(delivered, amount):
    """La barra de progreso, llena por décimos"""
    tenths = delivered * 10 // amount
    w, h = 126, 12
    im = canvas(w, h)
    d = ImageDraw.Draw(im)
    d.rounded_rectangle([0, 0, w * S - 1, h * S - 1], radius=6 * S, fill=PARCHMENT_DARK, outline=BORDER, width=S)
    if tenths > 0:
        filled = round((w - 2) * tenths / 10)
        d.rounded_rectangle([S, S, (1 + filled) * S - 1, (h - 1) * S - 1], radius=5 * S, fill=GOLD)
    return shrink(im)


def goal_title():
    im = card(1).crop((0, 0, WIDTH, TITLE_HEIGHT))
    # "OBJETIVO", centrado en x 100 de la pantalla y en la fila 8 (su centro, 22 px abajo del borde)
    write(im, 'OBJETIVO', LABEL, 100 - 12, 22 + 5)
    im.save(HERE / 'info' / 'goal_title.png')


def goals(name, level_goals):
    background = card(len(level_goals))
    for number, (label, amount, plate) in enumerate(level_goals, start=1):
        top = TITLE_HEIGHT + ROW * (number - 1)
        for delivered in range(amount + 1):
            im = background.crop((0, top, WIDTH, top + ROW))
            im.alpha_composite(Image.open(ASSETS / plate).convert('RGBA'), (0, 0))
            # el texto, centrado en x 125 de la pantalla y un poco arriba del centro de la fila
            write(im, f'{label}: {delivered}/{amount}', TEXT, 125 - 12, 21)
            im.alpha_composite(bar(delivered, amount), (65 - 12, 31))
            im.save(HERE / 'info' / f'{key(name)}_goal{number}_{delivered}.png')


# ----------- LA COMANDA DEL FINAL -----------

def button(w, label, key_text, fill, shade):
    im = canvas(w, 50)
    d = ImageDraw.Draw(im)
    box(d, (3, 8, w - 3, 46), shade, None, 0, 10)
    box(d, (3, 4, w - 3, 42), fill, None, 0, 10)
    text_font = font(13 * S)
    key_w = 20
    total = text_font.getlength(label) / S + 6 + key_w
    x = (w - total) / 2
    d.text((x * S, 23 * S), label, font=text_font, fill=WHITE, anchor='lm')
    draw_key(im, round((x + total - key_w) * S), 13 * S, key_text, 20 * S)
    return shrink(im)


def paper():
    """El papel de la comanda (400x460), con "COMANDA #1", el sello ENTREGADO y las líneas punteadas"""
    w, h = 400, 460
    im = canvas(w, h)
    d = ImageDraw.Draw(im)
    color = (255, 253, 246, 255)
    # sombra, papel y borde de abajo cortado
    d.rectangle([6 * S, 10 * S, (w - 2) * S, (h - 12) * S], fill=(0, 0, 0, 70))
    d.rectangle([2 * S, 2 * S, (w - 6) * S, (h - 20) * S], fill=color)
    teeth = [(2 * S, (h - 20) * S)]
    for x in range(2, w - 6, 14):
        teeth.append((x * S, (h - 20) * S))
        teeth.append(((x + 7) * S, (h - 10) * S))
    teeth.append(((w - 6) * S, (h - 20) * S))
    d.polygon(teeth, fill=color)
    mono = ImageFont.truetype('courbd.ttf', 24 * S)
    d.text((198 * S, 34 * S), 'COMANDA #1', font=mono, fill=(51, 51, 51, 255), anchor='mm')
    d.text((198 * S, 60 * S), 'Buffet Albert Einstein', font=ImageFont.truetype('cour.ttf', 13 * S), fill=(110, 110, 110, 255), anchor='mm')
    # las líneas punteadas de las filas
    for y in (104, 134, 164, 194, 224, 254, 284):
        for x in range(28, w - 32, 8):
            d.line([(x * S, y * S), ((x + 4) * S, y * S)], fill=(187, 187, 187, 255), width=S)
    # el sello, abajo a la derecha (entre las filas y los botones)
    stamp = canvas(150, 44)
    sd = ImageDraw.Draw(stamp)
    box(sd, (3, 3, 147, 41), None, (192, 57, 43, 220), 3, 7)
    sd.text((75 * S, 23 * S), 'ENTREGADO', font=font(19 * S), fill=(192, 57, 43, 220), anchor='mm')
    stamp = stamp.rotate(10, expand=True, resample=Image.BICUBIC)
    im.alpha_composite(stamp, ((w - 180) * S, 284 * S))
    return shrink(im)


def at(cell_x, cell_y, image):
    """Dónde va una imagen que el juego ponía en esa celda (Wollok cuenta desde abajo a la izquierda)"""
    return round(cell_x * 50), round(H - cell_y * 50 - image.height)


# Las filas del texto, de arriba hacia abajo (sus centros, en filas de la pantalla, entre las líneas punteadas)
TICKET_ROWS = [8.42, 7.82, 7.22, 6.62, 6.02, 5.42]
NEXT_BUTTONS = [((9, 3), 200, 'SIGUIENTE NIVEL', 'N', GREEN, GREEN_DARK),
                ((9, 2), 100, 'REPETIR', '0', BLUE, BLUE_DARK),
                ((11, 2), 100, 'MENÚ', 'M', GREY, GREY_DARK)]
LAST_BUTTONS = [((9, 3), 200, 'JUGAR DE NUEVO', '0', GREEN, GREEN_DARK),
                ((10, 2), 100, 'MENÚ', 'M', GREY, GREY_DARK)]


def ticket(name, level_goals, last):
    im = Image.new('RGBA', (1100, H), (10, 24, 32, 176))  # oscurece la pantalla
    sheet = paper()
    im.alpha_composite(sheet, at(7, 1.6, sheet))
    chef = Image.open(ASSETS / 'tutorial' / 'chef_happy_up_left.png').convert('RGBA')
    im.alpha_composite(chef, at(15.2, 2.2, chef))
    # el texto centrado en la columna 11, con su centro en esa fila: la base queda 5 px más abajo
    write(im, name, LABEL, 550, H - 9.12 * 50 + 5)
    lines = [f'{label}: {amount}/{amount}' for label, amount, _ in level_goals]
    lines.append('¡FIN DEL JUEGO!' if last else 'PEDIDO COMPLETO')
    for line, row in zip(lines, TICKET_ROWS):
        write(im, line, TEXT, 550, H - row * 50 + 5)
    for (x, y), w, label, key_text, fill, shade in (LAST_BUTTONS if last else NEXT_BUTTONS):
        im.alpha_composite(button(w, label, key_text, fill, shade), at(x, y, Image.new('RGBA', (w, 50))))
    im.save(HERE / 'complete' / f'{key(name)}.png', optimize=True)


if __name__ == '__main__':
    (HERE / 'info').mkdir(exist_ok=True)
    (HERE / 'complete').mkdir(exist_ok=True)
    ribbon()
    goal_title()
    found = signatures()
    levels = [parse(signature) for signature in found]
    for index, (level_name, level_goals) in enumerate(levels):
        goals(level_name, level_goals)
        ticket(level_name, level_goals, index == len(levels) - 1)
    write_signatures(found)
    print('ok')
