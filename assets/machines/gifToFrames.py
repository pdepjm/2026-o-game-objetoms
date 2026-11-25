#!/usr/bin/env python3
# Buffet Albert Einstein - convierte GIFs animados en una carpeta de PNG, uno por frame.
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
Convierte GIFs animados en una carpeta de PNG, uno por frame, para animarlos
desde Wollok con FrameAnimation (ver src/simulation/animationEngine.wlk).

¿Por qué no usar el GIF directo? Wollok carga cada imagen una sola vez y todos
los objetos que la usan comparten la misma animación: la segunda vez que se
muestra, el GIF no arranca desde el principio. Con un PNG por frame, cada
objeto lleva su propio frame.

El juego avanza un frame por paso de simulación (100 ms a velocidad x1), así que
los frames se remuestrean a ese intervalo: la animación dura lo mismo que el GIF.

    down_to_left_catch.gif  ->  down_to_left_catch/0.png, 1.png, ..., 27.png

Con pasar UNA dirección alcanza: si el nombre tiene right/down/left/up, también
convierte los GIF de las otras direcciones que estén en la misma carpeta.
No rota nada: esos GIF ya tienen que existir (se generan con assetRotate.py).

    up_assemble.gif  ->  up_assemble/, right_assemble/, down_assemble/, left_assemble/

Uso:
    python3 gifToFrames.py machines/Assembler/up_assemble.gif
    python3 gifToFrames.py animacion.gif --ms 50     # otro intervalo entre frames
    python3 gifToFrames.py up_assemble.gif --solo    # sólo ese GIF, sin las otras direcciones
"""

import argparse
import math
import re
import sys
from pathlib import Path

try:
    from PIL import Image, ImageSequence
except ImportError:
    sys.exit("Falta Pillow. Instalalo con:  pip3 install Pillow")

# Tiene que coincidir con simulationEngine.tickMs
MS_POR_PASO = 100

# Las mismas direcciones y la misma forma de encontrarlas en el nombre que assetRotate.py
DIRECCIONES = ["right", "down", "left", "up"]
PATRON = re.compile(r"(?<![a-z])(right|down|left|up)(?![a-z])", re.IGNORECASE)


def con_otras_direcciones(ruta):
    """El GIF y los de las otras direcciones que existan, cambiando la última dirección del nombre.
    Si el nombre no tiene dirección, sólo el GIF."""
    coincidencias = list(PATRON.finditer(ruta.stem))
    if not coincidencias:
        return [ruta]
    m = coincidencias[-1]
    rutas = []
    for direccion in DIRECCIONES:
        nombre = ruta.stem[:m.start()] + direccion + ruta.stem[m.end():]
        hermano = ruta.with_name(nombre + ruta.suffix)
        if hermano.is_file():
            rutas.append(hermano)
        else:
            print(f"  - {hermano.name} no existe, lo salteo (se genera con assetRotate.py)")
    return rutas


def frames_con_tiempo(ruta):
    """Devuelve [(inicio_ms, frame RGBA)] con cada frame ya compuesto."""
    resultado, inicio = [], 0
    with Image.open(ruta) as img:
        for frame in ImageSequence.Iterator(img):
            resultado.append((inicio, frame.convert("RGBA")))
            inicio += frame.info.get("duration", img.info.get("duration", 100))
    return resultado, inicio


def convertir(ruta, ms):
    frames, total = frames_con_tiempo(ruta)
    cantidad = max(1, math.ceil(total / ms))
    carpeta = ruta.with_suffix("")
    carpeta.mkdir(exist_ok=True)
    # Borra los PNG viejos, por si antes la animación tenía más frames
    for viejo in carpeta.glob("*.png"):
        viejo.unlink()
    for i in range(cantidad):
        t = i * ms
        # El frame del GIF que se está viendo en el instante t
        frame = [f for inicio, f in frames if inicio <= t][-1]
        frame.save(carpeta / f"{i}.png")
    print(f"  ✓ {ruta.name}: {len(frames)} frames ({total} ms) -> {carpeta.name}/ con {cantidad} frames")


def main():
    # La consola de Windows no siempre muestra ✓/✗ si no se fuerza UTF-8
    sys.stdout.reconfigure(encoding="utf-8")
    parser = argparse.ArgumentParser(description="Convierte GIFs en una carpeta de PNG por frame.")
    parser.add_argument("archivos", nargs="+", type=Path, help="GIFs a convertir")
    parser.add_argument("--ms", type=int, default=MS_POR_PASO,
                        help=f"milisegundos entre frames (por defecto {MS_POR_PASO}, un paso de simulación)")
    parser.add_argument("--solo", action="store_true",
                        help="convertir sólo los GIF pasados, sin buscar los de las otras direcciones")
    args = parser.parse_args()

    # Cada GIF se convierte una sola vez, aunque se pasen varias direcciones de la misma animación
    convertidos = set()
    for ruta in args.archivos:
        if not ruta.is_file() or ruta.suffix.lower() != ".gif":
            print(f"  ✗ {ruta}: no es un GIF")
            continue
        for gif in ([ruta] if args.solo else con_otras_direcciones(ruta)):
            clave = gif.resolve()
            if clave not in convertidos:
                convertidos.add(clave)
                convertir(gif, args.ms)


if __name__ == "__main__":
    main()
