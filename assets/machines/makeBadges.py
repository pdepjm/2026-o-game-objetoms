# Buffet Albert Einstein - genera la insignia de cada ingrediente y de cada plato.
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

# La insignia: un círculo crema con borde marrón y la comida centrada. La muestran el dispenser (el
# ingrediente que larga) y el ensamblador (el plato de su receta), arriba a la derecha. Es una sola
# imagen por comida (30x30), así cada máquina dibuja un solo visual encima (ver Badge en
# src/machines/badge.wlk).
#
# Sale de la imagen de la comida (food/Ingredients/... o food/Dishes/...): se recorta lo dibujado (las
# imágenes traen el dibujo al 65% y no siempre centrado) y se centra en el círculo. Se guarda con la misma
# ruta adentro de badge/, así el juego arma el nombre con la imagen de la comida (FoodKind.badgeImage).
#
# Uso (desde la raíz del repositorio):   python assets/machines/makeBadges.py
from pathlib import Path

from PIL import Image, ImageDraw

HERE = Path(__file__).resolve().parent
ASSETS = HERE.parent
S = 4
SIZE = 30
CREAM = (253, 243, 225, 255)
BROWN = (90, 58, 30, 255)
SHADOW = (0, 0, 0, 90)
# El lado más largo del ingrediente adentro del círculo
FIT = 20


def circle():
    im = Image.new('RGBA', (SIZE * S, SIZE * S), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.ellipse([2 * S, 3 * S, 29 * S, 30 * S], fill=SHADOW)
    d.ellipse([1 * S, 1 * S, 28 * S, 28 * S], fill=CREAM, outline=BROWN, width=2 * S)
    return im


def save(im, target):
    target.parent.mkdir(parents=True, exist_ok=True)
    im.resize((SIZE, SIZE), Image.LANCZOS).save(target)


def badge(source, target):
    food = Image.open(source).convert('RGBA')
    food = food.crop(food.getchannel('A').getbbox())
    scale = FIT * S / max(food.size)
    food = food.resize((max(1, round(food.width * scale)), max(1, round(food.height * scale))), Image.LANCZOS)

    im = circle()
    center = 14.5 * S
    im.alpha_composite(food, (round(center - food.width / 2), round(center - food.height / 2)))
    save(im, target)


if __name__ == '__main__':
    sources = sorted((ASSETS / 'food').glob('*/*/*.png'))
    for source in sources:
        badge(source, HERE / 'badge' / source.relative_to(ASSETS))
    print(f'  badge/: {len(sources)}')
