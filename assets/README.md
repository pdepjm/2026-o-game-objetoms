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
│   ├── Ingredients/
│   │   └── <ingredients>/
│   │       └── <ingredient>_<state>.png
│   └── Dishes/
│       └── <dishes>/
│           └── <dish>.png
├── machines/
│   └── <MachineName>/
│       ├── <dir>_menu.png
│       ├── <dir>_game.png
│       ├── <dir>.gif               (sólo las máquinas con GIF)
│       └── <dir>_<accion>/         (sólo las máquinas frame a frame)
│           └── 0.png, 1.png, ...
└── tools/
    ├── default.png
    └── <tool>_selected.png
```

## Tamaños

Cada celda del juego mide **50x50 px** (`game.cellSize(50)`) y el tablero es de 25x16 celdas.

| Imagen | Formato | Tamaño | Qué ocupa |
|---|---|---|---|
| Máquina en el tablero, quieta | `_game.png` | 50x50 (igual que su animación) | 1 celda |
| Máquina en el tablero, andando | `.gif` o carpeta de frames `.png` | 50x50 | 1 celda |
| Máquina en el menú | `_menu.png` | 100x100 | 2x2 celdas |
| Ingrediente | `.png` | 50x50 | 1 celda |
| Barra de herramientas | `.png` | 200x50 | 4x1 celdas |
| Overlay | `.png` | 200x200 | 4x4 celdas |
| Fondo | `.gif` / `.png` | 1250x800 | todo el juego |
| `no_texture.png` | `.png` | 50x50 | imagen de reemplazo |

## `machines/`

Cada máquina tiene su propia carpeta dentro de `machines/`, y el **nombre de la carpeta debe ser igual al `name()` de la clase** (ver `src/machines/types/`):

| Clase | Carpeta |
|---|---|
| `Belt` | `machines/Belt/` |
| `Assembler` | `machines/Assembler/` |
| `Oven` | `machines/Oven/` |
| `CuttingMachine` | `machines/CuttingMachine/` |
| `Fryer` | `machines/Fryer/` |
| `Dispenser` | `machines/Dispenser/` |
| `AutomaticArm` | `machines/AutomaticArm/` (caso especial, ver abajo) |

Hay **dos tipos de máquinas**, según cómo se animan. Todas tienen, para cada una de las 4 direcciones (`up`, `down`, `left`, `right`):

| Archivo | Tamaño | Cuándo se ve |
|---|---|---|
| `<direccion>_menu.png` | **100x100** | En el menú de máquinas |
| `<direccion>_game.png` | **El mismo que su animación** (50x50) | En el tablero, quieta: con la simulación apagada, y en las frame a frame también mientras no hacen nada |

Y además, según el tipo:

| Tipo | Animación | Cuándo se anima | Máquinas |
|---|---|---|---|
| **Con GIF** | `<direccion>.gif` | Todo el tiempo mientras la simulación está prendida | `Belt` |
| **Frame a frame** | Una carpeta `<direccion>_<accion>/` con `0.png`, `1.png`, ... por cada acción | Sólo cuando la máquina hace algo (por ejemplo, el dispenser al dispensar) | `Dispenser`, `CuttingMachine`, `Assembler`, `AutomaticArm` |

> [!NOTE]
> `Oven` y `Fryer` todavía no tienen sus imágenes completas: `Oven` sólo tiene `up_game.png` y `up.gif`, y `Fryer` no tiene carpeta.

Por ejemplo:
- una cinta hacia arriba tiene `up_menu.png`, `up_game.png` y `up.gif`;
- un dispenser hacia la derecha tiene `right_menu.png`, `right_game.png` y la carpeta `right_dispense/`.

Todas las máquinas empiezan quietas: al colocarlas y rotarlas se ven con su `_game.png`. Al prender la simulación (tecla **5**) las de GIF pasan a su `.gif`, y las frame a frame siguen quietas hasta que hacen algo. Al apagarla, todas vuelven al `_game.png`.

Que una máquina use GIF lo define su clase (`override method runningImage() = self.gifImage()`, ver por ejemplo `src/machines/types/belt.wlk`). Por defecto, una máquina es frame a frame.

> [!IMPORTANT]
> El `_game.png` y la animación de una misma dirección tienen que tener **el mismo tamaño** y la máquina en la misma posición: si no, al empezar y terminar la animación la máquina "salta". Lo más fácil es exportar el `_game.png` desde el primer frame de la animación.

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

Las máquinas frame a frame muestran una animación en un momento puntual (por ejemplo, el brazo cuando agarra un item), y para eso **no se usa el GIF directo**: Wollok comparte cada GIF entre todos los objetos que lo muestran, y la segunda vez no arranca desde el principio. En su lugar, la animación es una carpeta de PNG, uno por frame, que se reproduce con `MachineAnimator` (ver `src/machines/machineClasses.wlk`).

En el código, una animación de acción se arma con `self.actionAnimation("<accion>", <cantidad de frames>)`, que usa la carpeta `machines/<MachineName>/<direccion>_<accion>/`.

Si la animación se hizo como GIF, se convierte en carpeta de frames con:

```bash
python3 machines/gifToFrames.py machines/<MachineName>/<animacion>.gif
```

Cada GIF genera una carpeta con su mismo nombre (`down_to_up_catch.gif` → `down_to_up_catch/0.png`, `1.png`, ...). El juego muestra un frame por paso de simulación (100 ms a x1), así que el script remuestrea el GIF a ese intervalo para que la animación dure lo mismo. Si se cambia un GIF, hay que volver a correrlo (y actualizar la cantidad de frames en el código si cambió).

| Opción | Qué hace |
|---|---|
| `--ms` | milisegundos entre frames (por defecto 100, un paso de simulación) |

> Cada frame es una imagen más que el juego carga al arrancar: conviene que las animaciones sean cortas (de 6 a 10 frames, menos de 1 segundo). Después de convertir un GIF, borrarlo de la carpeta: el juego no lo usa, pero lo cargaría igual.

### Agregar una máquina nueva

1. Crear la carpeta `machines/<MachineName>/` con `_menu.png` y `_game.png` para cada dirección, y su animación: `.gif` o carpetas de frames, según el tipo.
2. Crear la clase y agregarla al catálogo siguiendo [`src/machines/README.md`](../src/machines/README.md#agregar-una-máquina-nueva), que tiene el contrato de qué métodos sobrescribir.

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

La comida se divide en dos carpetas: `Ingredients/` y `Dishes/` (platos).

- **Ingredientes:** cada uno tiene su propia carpeta, con el nombre del ingrediente en inglés y en plural, y adentro una imagen `.png` (50x50) por cada forma que puede tomar. El archivo se nombra `<ingredient>_<state>.png`, con el ingrediente en singular y el estado en inglés, separados por un guion bajo (si el estado tiene más de una palabra, también van unidas con `_`).
- **Platos:** cada uno tiene su carpeta en plural y una sola imagen, `<dish>.png`.

```
food/
├── Ingredients/
│   ├── potatoes/
│   │   ├── potato_raw.png
│   │   ├── potato_cut.png
│   │   └── potato_cooked.png
│   └── buns/
│       ├── bun_whole.png
│       └── bun_cut.png
└── Dishes/
    └── burgers/
        └── burger.png
```

| Estado | Nombre |
|---|---|
| crudo | `raw` |
| entero | `whole` |
| cortado | `cut` |
| cocinado | `cooked` |
| frito | `fried` |

Hay imágenes de papa, lechuga, tomate, pan, carne y hamburguesa. Las rutas las arman las familias de `src/food/foodPaths.wlk`.

## Archivos de la raíz

| Archivo | Para qué sirve |
|---|---|
| `background.gif` | fondo del juego (se carga con `game.boardGround`). `background.png` es la versión sin animar |
| `overlay.png` | marco que marca la máquina elegida en el menú |
| `no_texture.png` | imagen de reemplazo cuando todavía no hay una definitiva |
| `pepita.png` | imagen provisoria que usaban los ingredientes (ya no la usa el código) |
