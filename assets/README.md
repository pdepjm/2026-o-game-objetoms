# Assets

Guía de cómo nombrar y ubicar las imágenes. El código arma las rutas a partir de los nombres (por ejemplo `"machines/" + name + "/" + direction + "_game.png"`), así que **si un nombre no coincide, el juego no encuentra la imagen**.

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
│       ├── up_menu.png    up_game.png    up.gif
│       ├── down_menu.png  down_game.png  down.gif
│       ├── left_menu.png  left_game.png  left.gif
│       └── right_menu.png right_game.png right.gif
└── tools/
    ├── default.png
    └── <tool>_selected.png
```

## Tamaños

Cada celda del juego mide **50x50 px** (`game.cellSize(50)`) y el tablero es de 25x16 celdas.

| Imagen | Formato | Tamaño | Qué ocupa |
|---|---|---|---|
| Máquina en el tablero, apagada | `_game.png` | 50x50 (igual que su `.gif`) | 1 celda |
| Máquina en el tablero, andando | `.gif` | 50x50 | 1 celda |
| Máquina en el menú | `_menu.png` | 100x100 | 2x2 celdas |
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
| `AutomaticArm` | `machines/AutomaticArm/` (caso especial, ver abajo) |

Dentro de la carpeta van **3 imágenes por cada una de las 4 direcciones** (`up`, `down`, `left`, `right`), con estos nombres exactos:

| Archivo | Tamaño | Cuándo se ve |
|---|---|---|
| `<direccion>_menu.png` | **100x100** | En el menú de máquinas |
| `<direccion>_game.png` | **El mismo que su `.gif`** (50x50) | En el tablero con la simulación **apagada**: la máquina quieta, en su pose por defecto |
| `<direccion>.gif` | 50x50 | En el tablero con la simulación **prendida**: la máquina andando |

Por ejemplo, para una máquina hacia arriba: `up_menu.png`, `up_game.png` y `up.gif`.

Las máquinas empiezan apagadas: al colocarlas y rotarlas se ven con su `_game.png`. Al prender la simulación (tecla **5**) pasan a su `.gif`, y al apagarla vuelven al `_game.png`.

> [!IMPORTANT]
> El `_game.png` y el `.gif` de una misma dirección tienen que tener **el mismo tamaño** y la máquina en la misma posición: si no, al prender y apagar la simulación la máquina "salta". Lo más fácil es exportar el `_game.png` desde el primer frame del `.gif`.

### Casos especiales

Algunas máquinas no siguen esta convención y tienen su propio README en su carpeta. Antes de modificar sus imágenes, leerlo:

| Máquina | Qué tiene de distinto | Guía |
|---|---|---|
| `AutomaticArm` | Ocupa 3x3 celdas (imágenes de 150x150), no rota, y en vez de `.gif` usa carpetas de PNG por frame que se reproducen cuando le llega un ingrediente | [`machines/AutomaticArm/README.md`](machines/AutomaticArm/README.md) |

### Generar las rotaciones

Con una sola dirección alcanza para obtener las otras tres: `machines/assetGenerator.py` deduce la dirección por el nombre del archivo (`up_menu.png`, `up_game.png`, `right.gif`, etc.) y genera las que faltan, tanto para `.png` como para `.gif` (incluso animados).

```bash
pip3 install Pillow
python3 machines/assetGenerator.py machines/Oven/up_menu.png machines/Oven/up_game.png machines/Oven/up.gif
```

| Opción | Qué hace |
|---|---|
| `--espejar` | la dirección opuesta se espeja en vez de rotar 180° |
| `-f`, `--forzar` | sobrescribe los archivos que ya existen |

### Animaciones cuadro por cuadro

Si una máquina tiene que mostrar una animación en un momento puntual (por ejemplo, el brazo cuando agarra un item), **no se usa el GIF directo**: Wollok comparte cada GIF entre todos los objetos que lo muestran, y la segunda vez no arranca desde el principio. En su lugar, el GIF se convierte en una carpeta de PNG, uno por frame, y se anima con `FrameAnimated` (ver `src/simulation/animationEngine.wlk`).

```bash
python3 machines/gifToFrames.py machines/<MachineName>/<animacion>.gif
```

Cada GIF genera una carpeta con su mismo nombre (`down_to_up_catch.gif` → `down_to_up_catch/0.png`, `1.png`, ...). El juego muestra un frame por paso de simulación (100 ms a x1), así que el script remuestrea el GIF a ese intervalo para que la animación dure lo mismo. Si se cambia un GIF, hay que volver a correrlo (y actualizar la cantidad de frames en el código si cambió).

| Opción | Qué hace |
|---|---|
| `--ms` | milisegundos entre frames (por defecto 100, un paso de simulación) |

> Cada frame es una imagen más que el juego carga al arrancar: conviene que las animaciones sean cortas.

### Agregar una máquina nueva

1. Crear la carpeta `machines/<MachineName>/` con las 12 imágenes: `_menu.png`, `_game.png` y `.gif` para cada dirección.
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
