#!/usr/bin/env python3
"""
Genera las cuatro direcciones (right, down, left, up) de un sprite.

La dirección original se deduce del nombre del archivo:
    cinta_right.png  ->  cinta_down.png, cinta_left.png, cinta_up.png
    up.gif           ->  right.gif, down.gif, left.gif

Soporta PNG y GIF (incluso animados, manteniendo tiempos y transparencia).

Uso:
    python3 rotar.py cinta_right.png
    python3 rotar.py *_right.png *_up.gif
    python3 rotar.py maquina_left.png --espejar   # el opuesto se espeja en vez de rotar 180°
    python3 rotar.py cinta_right.png -f           # sobrescribe si ya existen
"""

import argparse
import re
import sys
from pathlib import Path

try:
    from PIL import Image, ImageSequence
except ImportError:
    sys.exit("Falta Pillow. Instalalo con:  pip3 install Pillow")

# Orden horario: cada paso es un giro de 90° en sentido horario
DIRECCIONES = ["right", "down", "left", "up"]

# Giro horario en cuartos de vuelta -> transformación de Pillow
GIROS = {
    1: Image.Transpose.ROTATE_270,   # 90° horario
    2: Image.Transpose.ROTATE_180,
    3: Image.Transpose.ROTATE_90,    # 270° horario
}

PATRON = re.compile(r"(?<![a-z])(right|down|left|up)(?![a-z])", re.IGNORECASE)


def detectar_direccion(nombre):
    """Devuelve (direccion, match) usando la última aparición en el nombre."""
    coincidencias = list(PATRON.finditer(nombre))
    if not coincidencias:
        return None, None
    m = coincidencias[-1]
    return m.group(1).lower(), m


def transformacion(origen, destino, espejar):
    pasos = (DIRECCIONES.index(destino) - DIRECCIONES.index(origen)) % 4
    if pasos == 2 and espejar:
        horizontal = origen in ("right", "left")
        return Image.Transpose.FLIP_LEFT_RIGHT if horizontal else Image.Transpose.FLIP_TOP_BOTTOM
    return GIROS[pasos]


def nombre_destino(ruta, match, destino):
    stem = ruta.stem
    original = match.group(1)
    # Respeta mayúsculas si el original las tenía (Right -> Left, RIGHT -> LEFT)
    if original.isupper():
        destino = destino.upper()
    elif original[0].isupper():
        destino = destino.capitalize()
    nuevo = stem[:match.start()] + destino + stem[match.end():]
    return ruta.with_name(nuevo + ruta.suffix)


def guardar_gif(img, salida, op):
    frames, duraciones = [], []
    for frame in ImageSequence.Iterator(img):
        frames.append(frame.convert("RGBA").transpose(op))
        duraciones.append(frame.info.get("duration", img.info.get("duration", 100)))
    frames[0].save(
        salida,
        save_all=True,
        append_images=frames[1:],
        duration=duraciones,
        loop=img.info.get("loop", 0),
        disposal=2,
        optimize=False,
    )


def procesar(ruta, espejar, forzar):
    origen, match = detectar_direccion(ruta.stem)
    if origen is None:
        print(f"  ✗ {ruta.name}: el nombre no contiene right/down/left/up, lo salteo")
        return

    with Image.open(ruta) as img:
        es_gif = img.format == "GIF"
        for destino in DIRECCIONES:
            if destino == origen:
                continue
            salida = nombre_destino(ruta, match, destino)
            if salida.exists() and not forzar:
                print(f"  - {salida.name} ya existe (usá -f para sobrescribir)")
                continue
            op = transformacion(origen, destino, espejar)
            if es_gif:
                guardar_gif(img, salida, op)
            else:
                img.transpose(op).save(salida)
            print(f"  ✓ {salida.name}")


def main():
    parser = argparse.ArgumentParser(
        description="Genera las 4 direcciones de un sprite según su nombre (right/down/left/up)."
    )
    parser.add_argument("archivos", nargs="+", type=Path, help="PNG o GIF a rotar")
    parser.add_argument("--espejar", action="store_true",
                        help="para la dirección opuesta, espejar en vez de rotar 180°")
    parser.add_argument("-f", "--forzar", action="store_true",
                        help="sobrescribir archivos existentes")
    args = parser.parse_args()

    for ruta in args.archivos:
        if not ruta.is_file():
            print(f"  ✗ {ruta}: no existe")
            continue
        print(f"{ruta.name} ({detectar_direccion(ruta.stem)[0] or '?'})")
        procesar(ruta, args.espejar, args.forzar)


if __name__ == "__main__":
    main()