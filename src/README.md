# `src/`

Código del juego. Cada carpeta agrupa una parte del juego y tiene su propio README.

## Carpetas

| Carpeta | Qué tiene |
|---|---|
| [`machines/`](machines/README.md) | Las máquinas: su lógica, cómo se dibujan, sus tipos y el catálogo del menú |
| [`simulation/`](simulation/README.md) | El reloj de la simulación y las animaciones |
| [`food/`](food/README.md) | Los ingredientes y las recetas |
| [`menu/`](menu/README.md) | Los menús de la derecha: barra de herramientas y paneles (place, edit) |
| [`tools/`](tools/README.md) | Las herramientas del jugador (colocar, borrar, editar, rotar) y la dirección elegida |
| [`input/`](input/README.md) | Las teclas y los clicks |
| [`levels/`](levels/README.md) | Niveles (en construcción): por ahora, los objetivos |

## Archivos de esta carpeta

| Archivo | Qué hace |
|---|---|
| `main.wpgm` | El programa que arranca el juego: arma la ventana (25x16 celdas de 50 px), el fondo, los controles, los menús, los puntos de entrega (`deliveryPoints.setUp()`) y el reloj de la simulación |
| `board.wlk` | El tablero (`board`): qué máquina hay en cada celda, colocar o quitar máquinas, y los puntos de entrega de afuera del tablero |
| `directions.wlk` | Las 4 direcciones (`up`, `down`, `left`, `right`): su nombre, cuál sigue al rotar, cuál es la opuesta y cómo moverse una celda hacia ellas |
| `cellPosition.wlk` | `CellPosition`: una posición de celda que se dibuja más rápido que una común (ver más abajo) |

### `board.wlk`

- El tablero jugable va de **x 5 a 19** y de **y 1 a 13** (`inBoard`). El resto de la pantalla son los menús.
- Por dentro es una grilla de casillas (`Cell`) que se arma una sola vez. Buscar una máquina es ir directo a su casilla, sin recorrer nada. Por eso no es un `Dictionary`: el comentario del archivo explica por qué era lento.
- `push(posición, máquina)` la coloca: le fija la posición del dibujo (con su `drawOffsetX`/`drawOffsetY`), la agrega a la pantalla y la anota en el `simulationEngine`. `pop(posición)` hace lo contrario, y se lleva los ingredientes que tenía encima.
- `machines()`: las máquinas colocadas, cada una una sola vez (una de 2x2 ocupa 4 casillas, pero aparece una vez).
- `clear()`: saca todas las máquinas (hace `pop` de cada una), con los ingredientes que tengan encima. Sirve para empezar de cero, por ejemplo al cargar un nivel.
- **Puntos de entrega:** los dos platitos del fondo, en (16, 14) y (17, 14), están **fuera** del tablero, pero las cintas y los brazos les entregan como a cualquier máquina (ver `DeliverySlot` en [`machines/README.md`](machines/README.md#types-las-máquinas)).
  - `addDeliverySlot(platito)`: lo anota en `deliverySlots` y lo registra en el `simulationEngine`, para que al apagar la simulación se borre el plato que estaba viajando hacia él y el platito quede vacío. Lo llama `deliveryPoints.setUp()`.
  - `machineAt(posición)`: dentro del tablero busca en la grilla; afuera, entre los `deliverySlots` (y si no hay ninguno ahí, `null`).
  - Como `inBoard` no los incluye, no se puede colocar nada encima ni hacerles click. Tampoco están en la grilla, así que `machines()` y `clear()` no los ven: son parte del escenario, no del nivel.
- **No usar `push`, `pop` ni `clear` con la simulación prendida:** las máquinas ya calcularon a sus vecinas. Los clicks se bloquean en `toolsManager`; `clear` no lo controla, así que antes hay que apagarla (`simulationEngine.reset()`).

### `cellPosition.wlk`

Wollok Game le pide a cada objeto su `position().round()` unas 60 veces por segundo. En una posición común, `round()` crea una posición nueva cada vez, y eso hacía que dibujar fuera mucho más caro. `CellPosition` devuelve la misma posición, porque una celda ya tiene coordenadas enteras. Para posiciones con decimales (ingredientes en movimiento) está `PosicionSuave`, en `simulation/animationEngine.wlk`.

## Cómo se conecta todo

```
teclas y clicks ─▶ input/userController
                     ├─▶ tools/toolsManager ─▶ tools/userTools ─▶ board ─▶ machines
                     │                       └─▶ menu/menuManager (paneles del menú)
                     └─▶ simulation/simulationEngine ─▶ machines (start / acciones agendadas / reset)
                                                     └─▶ simulation/animationEngine
```

1. El jugador elige una herramienta y hace click en el tablero: `toolsManager` le pasa el click a la herramienta, que coloca, borra o rota en el `board`.
2. Con la tecla **5**, el `simulationEngine` prende la simulación: avisa a cada máquina (`start`) y desde ahí ejecuta las acciones que cada una agendó (`after`). Ver [el contrato de las máquinas](machines/README.md#el-contrato-de-machine).
3. En cada paso, el `animationEngine` mueve los ingredientes y avanza las animaciones frame a frame.
4. Al apagar, el `simulationEngine` borra los ingredientes y vuelve cada máquina a su estado inicial (`reset`).

## Convenciones

- **Nombres en inglés** para clases, métodos y variables nuevas; los comentarios, en español. Hay código más viejo con nombres en español (por ejemplo `animationEngine.avanzar`).
- **Imports relativos a `src/`**, sin el prefijo `src.` (por ejemplo `import machines.machineClasses.*`). Los tests sí lo llevan (`import src.machines.machineClasses.*`).
- **Rendimiento:** lo que Wollok Game le pide a un objeto en cada frame (`image()` y `position()`) tiene que ser un dato ya guardado, no algo que se calcule. Los comentarios marcados `RENDIMIENTO` explican los casos que importaron.
- Las imágenes las busca el código por nombre: ver [`assets/README.md`](../assets/README.md).
