#!/usr/bin/env python3
# Buffet Albert Einstein - escribe en una imagen cada mensaje del globo del cocinero.
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
Antes, el globo del cocinero escribía cada mensaje con una imagen por letra (unas 60 por mensaje), y Wollok
dibuja todos los visuals en cada frame. Ahora cada mensaje es UNA imagen (ver bubbleMessages en
src/menu/overBoard/tutorialGuide.wlk).

Busca los mensajes en src/levels y src/tools: toda lista de textos de Wollok (["...", "..."]) cuyas líneas
entren en el globo (16 letras como máximo). Por cada uno:
- messages/<número>.png: 200 px de ancho y 20 + 27.5 por línea extra de alto (redondeado para arriba),
  cada línea centrada y escrita con las mismas letras que spriteText (assets/menu/font/text/).
- src/menu/overBoard/bubbleTexts.wlk: la lista de mensajes (sus líneas unidas con "|"), en el orden de los números.

Uso: python makeBubbleTexts.py (desde esta carpeta), cada vez que se cambia o se agrega un mensaje (un test
de tutorialTest avisa si a algún mensaje de un tutorial le falta su imagen). Antes, si cambiaron las letras,
correr assets/menu/font/makeFont.py.
"""
import glob
import math
import os
import re

from PIL import Image

ROOT = os.path.join('..', '..')
SRC = os.path.join(ROOT, 'src')
FONT_DIR = os.path.join(ROOT, 'assets', 'menu', 'font', 'text')
FONTS_WLK = os.path.join(SRC, 'menu', 'drawing', 'spriteFonts.wlk')
OUT_DIR = 'messages'
WLK = os.path.join(SRC, 'menu', 'overBoard', 'bubbleTexts.wlk')

WIDTH = 200
LINE_STEP = 27.5   # chefGuide.lineHeight (0.55 celdas)
GLYPH_HEIGHT = 20
MAX_LENGTH = 16    # chefGuide.maxLength

STRING = r'"(?:[^"\\]|\\.)*"'
STRING_LIST = re.compile(r'\[\s*(' + STRING + r'(?:\s*,\s*' + STRING + r')*)\s*\]')


def font():
    text = open(FONTS_WLK, encoding='utf-8').read()
    chars = re.findall(r'"(.)"', re.search(r'spriteFontChars = \[(.*?)\]', text).group(1))
    widths = [float(w) for w in re.search(r'const textFont = .*?widths = \[(.*?)\]', text).group(1).split(',')]
    return {char: i for i, char in enumerate(chars)}, widths


def messages():
    found = []
    files = glob.glob(os.path.join(SRC, 'levels', '*.wlk')) + glob.glob(os.path.join(SRC, 'tools', '*.wlk'))
    for path in sorted(files):
        for match in STRING_LIST.finditer(open(path, encoding='utf-8').read()):
            lines = [s[1:-1] for s in re.findall(STRING, match.group(1))]
            # las teclas de un paso (["edit", "choose"]) y otras listas que no son mensajes
            if all(re.fullmatch(r'[a-z_]+', line) for line in lines):
                continue
            if all(len(line) <= MAX_LENGTH for line in lines) and lines not in found:
                found.append(lines)
    return found


def render(lines, indexes, widths):
    height = math.ceil((len(lines) - 1) * LINE_STEP) + GLYPH_HEIGHT
    image = Image.new('RGBA', (WIDTH, height), (0, 0, 0, 0))
    for row, line in enumerate(lines):
        index = [indexes.get(char, indexes['?']) for char in line]
        x = WIDTH / 2 - sum(widths[i] for i in index) / 2
        top = math.floor(row * LINE_STEP)
        for char, i in zip(line, index):
            if char != ' ':
                glyph = Image.open(os.path.join(FONT_DIR, f'{i}.png')).convert('RGBA')
                image.alpha_composite(glyph, (round(x), top))
            x += widths[i]
    return image


def main():
    indexes, widths = font()
    found = messages()
    os.makedirs(OUT_DIR, exist_ok=True)
    for old in glob.glob(os.path.join(OUT_DIR, '*.png')):
        os.remove(old)
    for number, lines in enumerate(found):
        render(lines, indexes, widths).save(os.path.join(OUT_DIR, f'{number}.png'))
    texts = ',\n\t'.join('"' + '|'.join(lines) + '"' for lines in found)
    wlk = f'''// GENERADO por assets/tutorial/makeBubbleTexts.py: no editar a mano (cambiar los mensajes y volver a correrlo)

// Los mensajes del globo que ya tienen imagen: tutorial/messages/<su lugar en la lista>.png
const bubbleTexts = [
	{texts}
]
'''
    with open(WLK, 'w', encoding='utf-8') as f:
        f.write(wlk)
    print('ok', len(found), 'mensajes')


if __name__ == '__main__':
    main()
