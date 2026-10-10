#!/usr/bin/env python3
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

Uso:
    python3 gifToFrames.py machines/AutomaticArm/*.gif
    python3 gifToFrames.py animacion.gif --ms 50     # otro intervalo entre frames
"""

import argparse
import math
import sys
from pathlib import Path

try:
    from PIL import Image, ImageSequence
except ImportError:
    sys.exit("Falta Pillow. Instalalo con:  pip3 install Pillow")

# Tiene que coincidir con simulationEngine.tickMs
MS_POR_PASO = 100


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
    args = parser.parse_args()

    for ruta in args.archivos:
        if not ruta.is_file() or ruta.suffix.lower() != ".gif":
            print(f"  ✗ {ruta}: no es un GIF")
            continue
        convertir(ruta, args.ms)


if __name__ == "__main__":
    main()
