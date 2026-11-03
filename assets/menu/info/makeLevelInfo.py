# Genera los fondos de la info del nivel (ver src/menu/levelInfoMenu.wlk). Los textos los escribe el juego
# encima: acá van sólo las formas.
#
# - ribbon.png: la cinta roja del nombre del nivel (como el título del juego)
# - card_<n>.png: la tarjeta de papel del objetivo, para 1, 2 o 3 objetivos
# - bar_<d>.png: la barra de progreso de un objetivo, llena d décimos (0 a 10)
# - bubble_<n>.png: el globo de diálogo del tutorial, para 1 a 6 líneas
#
# Las medidas salen de las filas de levelInfoMenu: una fila mide 50 px, y las líneas del tutorial van
# cada 0.55 filas. Si cambian ahí, cambiarlas acá y volver a correrlo.
# Uso: python makeLevelInfo.py (desde esta carpeta)
from PIL import Image, ImageDraw

S = 4  # se dibuja 4 veces más grande y se achica
PARCHMENT = (252, 244, 229, 255)
PARCHMENT_DARK = (234, 222, 203, 255)
BORDER = (90, 55, 30, 255)
GOLD = (212, 175, 55, 255)
RED = (200, 30, 30, 255)
RED_DARK = (150, 10, 10, 255)
RED_BORDER = (120, 0, 0, 255)

WIDTH = 184           # ancho de la tarjeta y del globo (de x 12 a 196 del panel)
LINE = 0.55 * 50      # distancia entre líneas del tutorial, en px


def canvas(w, h):
    return Image.new('RGBA', (w * S, h * S), (0, 0, 0, 0))


def save(im, w, h, name):
    im.resize((w, h), Image.LANCZOS).save(name)


def ribbon():
    w, h = WIDTH, 46
    im = canvas(w, h)
    d = ImageDraw.Draw(im)
    d.rounded_rectangle([0, 4 * S, w * S - 1, h * S - 1], radius=10 * S, fill=RED_DARK)
    d.rounded_rectangle([0, 0, w * S - 1, (h - 5) * S], radius=10 * S, fill=RED, outline=RED_BORDER, width=2 * S)
    save(im, w, h, 'ribbon.png')


def card(goals):
    # de 22 px arriba del centro de la fila del título hasta el borde de abajo de la fila del último objetivo
    w, h = WIDTH, 22 + 25 + 50 * goals
    im = canvas(w, h)
    d = ImageDraw.Draw(im)
    d.rounded_rectangle([0, 0, w * S - 1, h * S - 1], radius=10 * S, fill=PARCHMENT, outline=BORDER, width=3 * S)
    # la línea dorada debajo de "OBJETIVO"
    d.line([(28 * S, 36 * S), (156 * S, 36 * S)], fill=GOLD, width=2 * S)
    save(im, w, h, 'card_' + str(goals) + '.png')


def bar(tenths):
    w, h = 126, 12
    im = canvas(w, h)
    d = ImageDraw.Draw(im)
    d.rounded_rectangle([0, 0, w * S - 1, h * S - 1], radius=6 * S, fill=PARCHMENT_DARK, outline=BORDER, width=S)
    if tenths > 0:
        filled = round((w - 2) * tenths / 10)
        d.rounded_rectangle([S, S, (1 + filled) * S - 1, (h - 1) * S - 1], radius=5 * S, fill=GOLD)
    save(im, w, h, 'bar_' + str(tenths) + '.png')


def bubble(lines):
    # desde 16 px arriba de la etiqueta del paso (media fila arriba de la primera línea) hasta 18 px
    # debajo de la última línea, más la cola de 16 px
    body = 16 + 25 + (lines - 1) * LINE + 18
    w, h = WIDTH, round(body + 16)
    im = canvas(w, h)
    d = ImageDraw.Draw(im)
    bottom = round(body) * S
    d.rounded_rectangle([0, 0, w * S - 1, bottom], radius=14 * S, fill=PARCHMENT, outline=BORDER, width=3 * S)
    # la cola, abajo a la izquierda
    tail = [(28 * S, bottom - 2 * S), (48 * S, bottom - 2 * S), (30 * S, h * S - 1)]
    d.polygon(tail, fill=PARCHMENT)
    d.line([tail[1], tail[2]], fill=BORDER, width=3 * S)
    d.line([tail[2], tail[0]], fill=BORDER, width=3 * S)
    save(im, w, h, 'bubble_' + str(lines) + '.png')


if __name__ == '__main__':
    ribbon()
    for n in (1, 2, 3):
        card(n)
    for t in range(11):
        bar(t)
    for n in range(1, 7):
        bubble(n)
    print('ok')
