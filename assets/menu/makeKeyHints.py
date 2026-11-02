# Genera las ayudas de teclas que muestra la info del nivel al ganar (key_next.png y key_restart.png),
# con el mismo estilo que las teclas dibujadas en el fondo (F Recetario, M Menú): una tecla gris oscura
# con la letra blanca y el texto en amarillo. Miden 200x25: la tecla queda en x 6 a 37, como las del fondo.
# Uso: python makeKeyHints.py (desde esta carpeta)
from PIL import Image, ImageDraw, ImageFont

S = 4  # se dibuja 4 veces más grande y se achica
W, H = 200, 25
BORDER = (29, 37, 42, 255)
TOP = (74, 92, 99, 255)
BOTTOM = (47, 60, 65, 255)
LETTER = (250, 250, 250, 255)
LABEL = (255, 208, 21, 255)


def font(size):
    return ImageFont.truetype('segoeuib.ttf', size * S)


def key_hint(letter, label, path):
    im = Image.new('RGBA', (W * S, H * S), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    x0, x1 = 6, 37
    # la tecla: el borde oscuro, y adentro un degradé de arriba hacia abajo
    d.rounded_rectangle([x0 * S, 0, x1 * S, (H - 1) * S], radius=5 * S, fill=BORDER)
    inner = Image.new('RGBA', ((x1 - x0 - 3) * S, (H - 5) * S))
    for y in range(inner.height):
        t = y / (inner.height - 1)
        inner.paste(tuple(round(a + (b - a) * t) for a, b in zip(TOP, BOTTOM)), (0, y, inner.width, y + 1))
    mask = Image.new('L', inner.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, inner.width - 1, inner.height - 1], radius=4 * S, fill=255)
    im.paste(inner, (int((x0 + 1.5) * S), int(1.5 * S)), mask)
    d.text(((x0 + x1) / 2 * S, 11.5 * S), letter, font=font(16), fill=LETTER, anchor='mm')
    d.text((48 * S, 12.5 * S), label, font=font(14), fill=LABEL, anchor='lm')
    im.resize((W, H), Image.LANCZOS).save(path)


if __name__ == '__main__':
    key_hint('N', 'SIGUIENTE', 'key_next.png')
    key_hint('0', 'REINICIAR', 'key_restart.png')
    print('ok')
