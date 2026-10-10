# `src/`

Código del juego. Cada carpeta agrupa una parte del juego y tiene su propio README.

## Carpetas

| Carpeta | Qué tiene |
|---|---|
| [`machines/`](machines/README.md) | Las máquinas: su lógica, cómo se dibujan, sus tipos y el catálogo del menú |
| [`simulation/`](simulation/README.md) | El reloj de la simulación, las animaciones, los ingredientes y las recetas |
| [`menu/`](menu/README.md) | Los menús de la derecha: barra de herramientas y paneles (place, edit) |
| [`tools/`](tools/README.md) | Las herramientas del jugador (colocar, borrar, editar, rotar) y la dirección elegida |
| [`input/`](input/README.md) | Las teclas y los clicks |
| [`levels/`](levels/README.md) | Niveles (todavía sin usar) |
| [`stressTest/`](stressTest/README.md) | Pruebas de carga: medidor de rendimiento y tablero lleno |

## Archivos de esta carpeta

| Archivo | Qué hace |
|---|---|
| `main.wpgm` | El programa que arranca el juego: arma la ventana (25x16 celdas de 50 px), el fondo, los controles, los menús y el reloj de la simulación |
| `board.wlk` | El tablero (`board`): qué máquina hay en cada celda, y colocar o quitar máquinas |
| `directions.wlk` | Las 4 direcciones (`up`, `down`, `left`, `right`): su nombre, cuál sigue al rotar, cuál es la opuesta y cómo moverse una celda hacia ellas |
| `cellPosition.wlk` | `CellPosition`: una posición de celda que se dibuja más rápido que una común (ver más abajo) |

### `board.wlk`

- El tablero jugable va de **x 5 a 19** y de **y 1 a 13** (`inBoard`). El resto de la pantalla son los menús.
- Por dentro es una grilla de casillas (`Cell`) que se arma una sola vez. Buscar una máquina es ir directo a su casilla, sin recorrer nada. Por eso no es un `Dictionary`: el comentario del archivo explica por qué era lento.
- `push(posición, máquina)` la coloca: le fija la posición del dibujo (con su `offsetX`/`offsetY`), la agrega a la pantalla y la anota en el `simulationEngine`. `pop(posición)` hace lo contrario, y se lleva los ingredientes que tenía encima.
- **No usar `push` ni `pop` con la simulación prendida:** las máquinas ya calcularon a sus vecinas. Los clicks se bloquean en `toolsManager`.

### `cellPosition.wlk`

Wollok Game le pide a cada objeto su `position().round()` unas 60 veces por segundo. En una posición común, `round()` crea una posición nueva cada vez, y eso hacía que dibujar fuera mucho más caro. `CellPosition` devuelve la misma posición, porque una celda ya tiene coordenadas enteras. Para posiciones con decimales (ingredientes en movimiento) está `PosicionSuave`, en `simulation/animationEngine.wlk`.

## Cómo se conecta todo

```
teclas y clicks ─▶ input/userController
                     ├─▶ tools/toolsManager ─▶ tools/userTools ─▶ board ─▶ machines
                     │                       └─▶ menu/menuManager (paneles del menú)
                     └─▶ simulation/simulationEngine ─▶ machines (start / use / reset)
                                                     └─▶ simulation/animationEngine
```

1. El jugador elige una herramienta y hace click en el tablero: `toolsManager` le pasa el click a la herramienta, que coloca, borra o rota en el `board`.
2. Con la tecla **5**, el `simulationEngine` prende la simulación: avisa a cada máquina (`start`) y desde ahí la despierta en los pasos que ella pidió (`use`).
3. En cada paso, el `animationEngine` mueve los ingredientes y avanza las animaciones frame a frame.
4. Al apagar, el `simulationEngine` borra los ingredientes y vuelve cada máquina a su estado inicial (`reset`).

## Convenciones

- **Nombres en inglés** para clases, métodos y variables nuevas; los comentarios, en español. Hay código más viejo con nombres en español (por ejemplo `animationEngine.avanzar`).
- **Imports relativos a `src/`**, sin el prefijo `src.` (por ejemplo `import machines.machineClasses.*`). Los tests sí lo llevan (`import src.machines.machineClasses.*`).
- **Rendimiento:** lo que Wollok Game le pide a un objeto en cada frame (`image()` y `position()`) tiene que ser un dato ya guardado, no algo que se calcule. Los comentarios marcados `RENDIMIENTO` explican los casos que importaron.
- Las imágenes las busca el código por nombre: ver [`assets/README.md`](../assets/README.md).
