# Genera las letras para escribir sin contorno (Wollok dibuja todos los textos con un contorno oscuro que
# no se puede sacar, y sobre el papel de la info del nivel se ve raro). Ver src/menu/spriteText.wlk.
#
# Por cada estilo, una carpeta con una imagen por letra (<número>.png, el número es su lugar en CHARS) y,
# en src/menu/spriteFonts.wlk, un objeto con cuánto mide cada letra de ancho.
#
# Uso: python makeFont.py (desde esta carpeta). Para una letra nueva, agregarla a CHARS y volver a correrlo.
from PIL import Image, ImageDraw, ImageFont

S = 4  # se dibuja 4 veces más grande y se achica
HEIGHT = 20  # alto de cada letra; la base del texto queda a 15 px de arriba
BASELINE = 15

# Sin comillas dobles ni barra invertida: se escriben en una lista de Wollok
CHARS = list(" !¡?¿'(),-./0123456789:;+%ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyzÁÉÍÓÚÜÑáéíóúüñ")

# (nombre del objeto en Wollok, carpeta, fuente, tamaño, color)
STYLES = [
    ('textFont', 'text', 'segoeuib.ttf', 14, (74, 47, 29, 255)),    # marrón: los objetivos y el tutorial
    ('labelFont', 'label', 'segoeuib.ttf', 11, (154, 147, 135, 255)),  # gris: OBJETIVO, PASO 2 DE 8
]

WLK = '../../../src/menu/spriteFonts.wlk'


def glyph(font, char, color):
    width = font.getlength(char) / S
    w = max(1, round(width))
    im = Image.new('RGBA', (w * S, HEIGHT * S), (0, 0, 0, 0))
    ImageDraw.Draw(im).text((0, BASELINE * S), char, font=font, fill=color, anchor='ls')
    return im.resize((w, HEIGHT), Image.LANCZOS), round(width, 2)


def main():
    import os
    objects = []
    for name, folder, font_file, size, color in STYLES:
        os.makedirs(folder, exist_ok=True)
        font = ImageFont.truetype(font_file, size * S)
        widths = []
        for i, char in enumerate(CHARS):
            im, width = glyph(font, char, color)
            widths.append(width)
            if char != ' ':
                im.save(os.path.join(folder, str(i) + '.png'))
        objects.append(f'object {name} inherits SpriteFont(folder = "menu/font/{folder}/", widths = [{", ".join(str(w) for w in widths)}]) {{}}')

    chars = ', '.join('"' + c + '"' for c in CHARS)
    wlk = f'''// GENERADO por assets/menu/font/makeFont.py: no editar a mano (cambiar el script y volver a correrlo)
import menu.spriteText.*

// Las letras que hay, en el orden de sus imágenes (<número>.png) y de los anchos de cada estilo
object spriteFontChars {{
	const property chars = [{chars}]
}}

{chr(10).join(objects)}
'''
    with open(WLK, 'w', encoding='utf-8') as f:
        f.write(wlk)
    print('ok', len(CHARS), 'letras')


if __name__ == '__main__':
    main()
