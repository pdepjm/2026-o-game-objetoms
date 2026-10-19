#!/usr/bin/env python3
"""
Exporta los SVG de comida al PNG que usa el juego: 50x50, fondo transparente y
el dibujo achicado al 65% alrededor del centro (ver "Tamaño del dibujo" en
assets/README.md).

Cada PNG se guarda al lado de su SVG, con el mismo nombre:

    Ingredients/tomatoes/tomato_cut.svg  ->  Ingredients/tomatoes/tomato_cut.png

El SVG se dibuja con un navegador (Edge, Chrome o Chromium) sin abrir ventanas,
a 4 veces el tamaño, y después se achica a 50x50 para que los bordes queden suaves.

Uso:
    python3 food/svgToSprite.py food/Ingredients/tomatoes/*.svg
    python3 food/svgToSprite.py food/Dishes/burgers/burger.svg --escala 0.8
    python3 food/svgToSprite.py archivo.svg --navegador "C:/ruta/a/chrome.exe"
"""

import argparse
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

try:
    from PIL import Image
except ImportError:
    sys.exit("Falta Pillow. Instalalo con:  pip3 install Pillow")

SIZE = 50
DEFAULT_SCALE = 0.65
# Se dibuja más grande y se achica al final, para suavizar los bordes
SUPERSAMPLE = 4

BROWSER_COMMANDS = ["msedge", "microsoft-edge", "google-chrome", "chrome", "chromium", "chromium-browser"]
BROWSER_PATHS = [
    r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe",
    r"C:\Program Files\Microsoft\Edge\Application\msedge.exe",
    r"C:\Program Files\Google\Chrome\Application\chrome.exe",
    r"C:\Program Files (x86)\Google\Chrome\Application\chrome.exe",
    "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
    "/Applications/Microsoft Edge.app/Contents/MacOS/Microsoft Edge",
    "/Applications/Chromium.app/Contents/MacOS/Chromium",
]


def find_browser(explicit):
    if explicit:
        return explicit
    for command in BROWSER_COMMANDS:
        found = shutil.which(command)
        if found:
            return found
    for path in BROWSER_PATHS:
        if Path(path).is_file():
            return path
    sys.exit("No encontré Edge, Chrome ni Chromium. Indicá cuál usar con --navegador <ruta>")


def scaled_svg(path, scale):
    """Devuelve el SVG con todo su contenido escalado alrededor del centro."""
    text = path.read_text(encoding="utf-8")
    match = re.match(r"\s*(<svg[^>]*>)(.*)</svg>\s*$", text, re.S)
    if not match:
        raise ValueError("no tiene un único <svg> raíz")
    root, body = match.groups()
    view_box = re.search(r'viewBox="([^"]+)"', root)
    if not view_box or [float(n) for n in view_box.group(1).split()] != [0, 0, SIZE, SIZE]:
        raise ValueError(f'tiene que tener viewBox="0 0 {SIZE} {SIZE}"')
    center = SIZE / 2
    return (f'{root}\n<g transform="translate({center} {center}) scale({scale}) translate({-center} {-center})">'
            f"{body}</g>\n</svg>\n")


def export(svg_path, scale, browser, work_dir):
    png_path = svg_path.with_suffix(".png")
    temp_svg = work_dir / "sprite.svg"
    temp_png = work_dir / "sprite.png"
    temp_svg.write_text(scaled_svg(svg_path, scale), encoding="utf-8")
    temp_png.unlink(missing_ok=True)
    subprocess.run([browser, "--headless=new", "--disable-gpu", "--hide-scrollbars",
                    "--default-background-color=00000000",
                    f"--force-device-scale-factor={SUPERSAMPLE}", f"--window-size={SIZE},{SIZE}",
                    f"--screenshot={temp_png}", temp_svg.as_uri()],
                   check=True, capture_output=True)
    if not temp_png.is_file():
        raise RuntimeError("el navegador no generó la imagen")
    with Image.open(temp_png) as big:
        if big.size != (SIZE * SUPERSAMPLE, SIZE * SUPERSAMPLE):
            raise RuntimeError(f"el navegador generó una imagen de {big.size[0]}x{big.size[1]}")
        big.convert("RGBA").resize((SIZE, SIZE), Image.LANCZOS).save(png_path)
    print(f"  ✓ {svg_path.name} -> {png_path.name} ({SIZE}x{SIZE}, dibujo al {scale:.0%})")


def main():
    # La consola de Windows no siempre muestra ✓/✗ si no se fuerza UTF-8
    sys.stdout.reconfigure(encoding="utf-8")
    parser = argparse.ArgumentParser(description="Exporta SVG de comida a PNG de 50x50 con el dibujo achicado.")
    parser.add_argument("archivos", nargs="+", type=Path, help="SVG a exportar")
    parser.add_argument("--escala", type=float, default=DEFAULT_SCALE,
                        help=f"tamaño del dibujo dentro del PNG (por defecto {DEFAULT_SCALE})")
    parser.add_argument("--navegador", help="ruta a Edge, Chrome o Chromium, si no se encuentra solo")
    args = parser.parse_args()

    browser = find_browser(args.navegador)
    with tempfile.TemporaryDirectory() as work_dir:
        for path in args.archivos:
            if not path.is_file() or path.suffix.lower() != ".svg":
                print(f"  ✗ {path}: no es un SVG")
                continue
            try:
                export(path.resolve(), args.escala, browser, Path(work_dir))
            except (ValueError, RuntimeError, subprocess.CalledProcessError) as error:
                print(f"  ✗ {path.name}: {error}")


if __name__ == "__main__":
    main()
