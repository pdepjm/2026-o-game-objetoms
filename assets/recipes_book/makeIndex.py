# Genera index.png (el índice del libro de recetas) e icon.png (el icono de la barra de herramientas).
# El índice usa de base una página de receta (su tapa, sus hojas y la cruz) y le escribe los platos
# encima, en las filas que el juego espera (ver docs/Plan-Libro-Recetas.md, fase 0).
# Uso: python makeIndex.py (desde esta carpeta). Si se dibujan a mano, se reemplazan con el mismo nombre.
from PIL import Image, ImageDraw, ImageFont

FOOD = '../food/'
# (texto, imagen del juego), en el orden de las páginas (recipeBookMenu.pages)
DISHES = [('Papas fritas', 'Ingredients/potatoes/potato_cooked.png'),
          ('Hamburguesa', 'Dishes/burgers/burger.png'),
          ('Cheeseburger', 'Dishes/burgers/cheeseburger.png'),
          ('Hamburguesa doble', 'Dishes/burgers/double-burger.png'),
          ('Pizza pepperoni', 'Dishes/pizzas/pizza-pepperoni.png'),
          ('Ensalada', 'Dishes/salad/salad.png'),
          ('Pancho', 'Dishes/hot-dog/hot-dog.png'),
          ('Sopa de tomate', 'Dishes/tomato-soup/tomato-soup.png')]

BROWN = (74, 47, 29, 255)
GRAY = (154, 147, 135, 255)
GOLD = (212, 175, 55, 255)
LINE = (217, 203, 178, 255)


def font(size, bold=False):
    return ImageFont.truetype('segoeuib.ttf' if bold else 'segoeui.ttf', size)


def blank_page(im, x0, x1, sample_x):
    """Borra lo escrito en una hoja copiando, fila por fila, el color de una columna sin nada:
    así se conserva el degradé de arriba hacia abajo."""
    px = im.load()
    for y in range(64, 437):
        color = px[sample_x, y]
        for x in range(x0, x1):
            px[x, y] = color


def dish_icon(path, size):
    """La imagen del plato recortada a su dibujo (los PNG del juego dejan margen) y llevada a size x size"""
    im = Image.open(FOOD + path).convert('RGBA')
    im = im.crop(im.getbbox())
    im.thumbnail((size, size), Image.LANCZOS)
    canvas = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    canvas.paste(im, ((size - im.width) // 2, (size - im.height) // 2), im)
    return canvas


def make_index():
    base = Image.open('recipe_hotDog.png').convert('RGBA')
    im = base.copy()
    # Las hojas sin lo escrito (se dejan los bordes del lomo, que tienen sombra). Las dos hojas tienen
    # el mismo degradé: se copia de una columna de la izquierda que nunca tiene nada.
    blank_page(im, 74, 368, 80)
    blank_page(im, 428, 727, 80)
    # La cruz, como estaba (el borrado le pisó la parte que entra en la hoja)
    im.paste(base.crop((700, 0, 800, 100)), (700, 0))
    d = ImageDraw.Draw(im)

    d.text((230, 100), 'Recetas', font=font(30, True), fill=BROWN, anchor='mm')
    d.line([(120, 125), (340, 125)], fill=GOLD, width=2)
    d.text((570, 100), 'Elegí un plato:', font=font(18), fill=GRAY, anchor='mm')

    used = [divmod(i, 5) for i in range(len(DISHES))]
    for i, (name, path) in enumerate(DISHES):
        side, n = divmod(i, 5)
        top = 150 + 50 * n
        x0, x1 = (100, 390) if side == 0 else (450, 700)
        im.paste(dish_icon(path, 40), (x0 + 5, top + 5), dish_icon(path, 40))
        d.text((x0 + 55, top + 25), name, font=font(19), fill=BROWN, anchor='lm')
        d.text((x1 - 10, top + 25), str(i + 1), font=font(14), fill=GRAY, anchor='rm')
        # una línea fina entre dos platos seguidos de la misma hoja
        if (side, n + 1) in used:
            d.line([(x0, top + 50), (x1 - 10, top + 50)], fill=LINE, width=1)

    d.text((230, 420), 'Q / E: pasar página', font=font(15), fill=GRAY, anchor='mm')
    d.text((570, 420), 'F: cerrar', font=font(15), fill=GRAY, anchor='mm')
    im.save('index.png')


def make_icon():
    s = 4  # se dibuja 4 veces más grande y se achica
    big = Image.new('RGBA', (50 * s, 50 * s), (0, 0, 0, 0))
    d = ImageDraw.Draw(big)
    # la tapa, el borde dorado y las hojas que asoman abajo
    d.rounded_rectangle([5 * s, 4 * s, 45 * s, 44 * s], radius=4 * s, fill=(66, 41, 24, 255), outline=(26, 13, 4, 255), width=2 * s)
    d.rounded_rectangle([9 * s, 8 * s, 41 * s, 37 * s], radius=2 * s, outline=(139, 107, 39, 255), width=s)
    d.rectangle([8 * s, 39 * s, 42 * s, 42 * s], fill=(252, 244, 229, 255))
    d.text((25 * s, 23 * s), 'F', font=font(24 * s, True), fill=(212, 175, 55, 255), anchor='mm')
    big.resize((50, 50), Image.LANCZOS).save('icon.png')


if __name__ == '__main__':
    make_index()
    make_icon()
    print('ok')
