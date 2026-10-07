# Assets

Guía de cómo nombrar y ubicar las imágenes. El código arma las rutas a partir de los nombres (por ejemplo `"machines/" + name + "/" + direction + ".gif"`), así que **si un nombre no coincide, el juego no encuentra la imagen**.

## Convención de nombres

- **Siempre en inglés**: carpetas y archivos (`background.gif`, `potato_cooked.png`), no en español.
- **Nunca espacios ni guiones medios**: donde iría un espacio se usa guion bajo `_` (`no_texture.png`, `place_selected.png`).
- **En minúsculas**, salvo las carpetas de las máquinas, que deben ser **iguales al `name()` de su clase** (`CuttingMachine`, `Oven`), porque el código arma la ruta con ese nombre.

> [!IMPORTANT]
> Los nombres de carpetas y archivos distinguen mayúsculas de minúsculas (el CI corre en Linux). `Oven` y `oven` son carpetas distintas.

## Estructura

```
assets/
├── background.gif / background.png
├── overlay.png
├── no_texture.png
├── pepita.png
├── food/
│   └── <ingredients>/
│       └── <ingredient>_<state>.png
├── machines/
│   └── <MachineName>/
│       ├── up.png    up.gif
│       ├── down.png  down.gif
│       ├── left.png  left.gif
│       └── right.png right.gif
└── tools/
    ├── default.png
    └── <tool>_selected.png
```

## Tamaños

Cada celda del juego mide **50x50 px** (`game.cellSize(50)`) y el tablero es de 25x16 celdas.

| Imagen | Formato | Tamaño | Qué ocupa |
|---|---|---|---|
| Máquina en el tablero | `.gif` | 50x50 | 1 celda |
| Máquina en el menú | `.png` | 100x100 | 2x2 celdas |
| Ingrediente | `.png` | 50x50 | 1 celda |
| Barra de herramientas | `.png` | 200x50 | 4x1 celdas |
| Overlay | `.png` | 200x200 | 4x4 celdas |
| Fondo | `.gif` / `.png` | 1250x800 | todo el juego |
| `no_texture.png` | `.png` | 50x50 | imagen de reemplazo |

## `machines/`

Cada máquina tiene su propia carpeta dentro de `machines/`, y el **nombre de la carpeta debe ser igual al `name()` de la clase** (ver `src/machines/machineTypes.wlk`):

| Clase | Carpeta |
|---|---|
| `Belt` | `machines/Belt/` |
| `Assembler` | `machines/Assembler/` |
| `Oven` | `machines/Oven/` |
| `CuttingMachine` | `machines/CuttingMachine/` |
| `Fryer` | `machines/Fryer/` |
| `Dispenser` | `machines/Dispenser/` |

Dentro de la carpeta van las 4 rotaciones de la máquina, cada una en `.png` y en `.gif`, con estos nombres exactos:

| Rotación | Archivos |
|---|---|
| Hacia arriba | `up.png` y `up.gif` |
| Hacia abajo | `down.png` y `down.gif` |
| Hacia la izquierda | `left.png` y `left.gif` |
| Hacia la derecha | `right.png` y `right.gif` |

- El **`.gif`** (50x50) es el que se ve sobre el tablero, y puede estar animado.
- El **`.png`** (100x100) es el que se ve en el menú de máquinas.

### Generar las rotaciones

Con una sola dirección alcanza para obtener las otras tres: `machines/assetGenerator.py` deduce la dirección por el nombre del archivo (`up.png`, `right.gif`, etc.) y genera las que faltan, tanto para `.png` como para `.gif` (incluso animados).

```bash
pip3 install Pillow
python3 machines/assetGenerator.py machines/Oven/up.png machines/Oven/up.gif
```

| Opción | Qué hace |
|---|---|
| `--espejar` | la dirección opuesta se espeja en vez de rotar 180° |
| `-f`, `--forzar` | sobrescribe los archivos que ya existen |

### Agregar una máquina nueva

1. Crear la carpeta `machines/<MachineName>/` con las 8 imágenes.
2. Crear la clase en `src/machines/machineTypes.wlk` con `override method name() = "<MachineName>"`.
3. Agregarla a la lista de `src/machines/machineManager.wlk` (el orden de la lista es el orden del menú).

## `tools/`

La barra de herramientas es **una sola imagen** de 200x50 que se cambia según la herramienta elegida. Hacen falta:

| Archivo | Cuándo se ve |
|---|---|
| `default.png` | no hay ninguna herramienta elegida (al iniciar el juego) |
| `place_selected.png` | herramienta de colocar |
| `edit_selected.png` | herramienta de edición |
| `rotate_selected.png` | herramienta de rotar |
| `delete_selected.png` | herramienta de borrar |

El nombre sale del `name()` de cada herramienta (ver `src/tools/userTools.wlk`): `<tool>_selected.png`. Si se agrega una herramienta nueva, hace falta su `<tool>_selected.png`.

## `food/`

Cada ingrediente tiene su propia carpeta, con el nombre del ingrediente en inglés y en plural, y adentro una imagen `.png` (50x50) por cada forma que puede tomar. El archivo se nombra `<ingredient>_<state>.png`, con el ingrediente en singular y el estado en inglés, separados por un guion bajo (si el estado tiene más de una palabra, también van unidas con `_`).

```
food/
└── potatoes/
    ├── potato_raw.png
    ├── potato_cut.png
    └── potato_cooked.png
```

| Estado | Nombre |
|---|---|
| crudo | `raw` |
| cortado | `cut` |
| cocinado | `cooked` |
| frito | `fried` |

> [!NOTE]
> Por ahora el código no usa estas imágenes (los ingredientes todavía se dibujan con `pepita.png`).

## Archivos de la raíz

| Archivo | Para qué sirve |
|---|---|
| `background.gif` | fondo del juego (se carga con `game.boardGround`). `background.png` es la versión sin animar |
| `overlay.png` | marco que marca la máquina elegida en el menú |
| `no_texture.png` | imagen de reemplazo cuando todavía no hay una definitiva |
| `pepita.png` | imagen provisoria de los ingredientes |
