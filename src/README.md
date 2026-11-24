# `src/`

Código del juego. Cada carpeta agrupa una parte del juego y tiene su propio README.

## Carpetas

| Carpeta | Qué tiene |
|---|---|
| [`machines/`](machines/README.md) | Las máquinas: su lógica, cómo se dibujan, sus tipos y el catálogo del menú |
| [`simulation/`](simulation/README.md) | El reloj de la simulación y las animaciones |
| [`food/`](food/README.md) | Los ingredientes y las recetas |
| [`menu/`](menu/README.md) | Los menús: el cartel COLOCANDO / EDITANDO, los paneles (colocar, editar), la info del nivel, los botones de abajo a la izquierda, la portada y el recetario |
| [`tools/`](tools/README.md) | Lo que el jugador le hace al tablero (colocar, rotar, editar, borrar), la máquina elegida y la dirección |
| [`input/`](input/README.md) | Las teclas y los clicks |
| [`levels/`](levels/README.md) | Los niveles: qué máquinas se usan, qué hay que entregar, y `levelManager`, que los carga |

## Archivos de esta carpeta

| Archivo | Qué hace |
|---|---|
| `main.wpgm` | El programa que arranca el juego: arma la ventana (22x13 celdas de 50 px), el fondo, los controles, los menús, los puntos de entrega (`deliveryPoints.setUp()`), el primer nivel (`levelManager.start()`) y el reloj de la simulación |
| `cellPosition.wlk` | `CellPosition` (una posición que no crea nada al dibujarse) y `Zone`, un rectángulo de celdas: la única forma de decir "esta parte de la pantalla" (dónde se construye, dónde está cada cosa que se clickea) |
| `board.wlk` | El tablero (`board`): qué máquina hay en cada celda, colocar o quitar máquinas, los puntos de entrega de afuera del tablero y dónde se puede construir. Su zona (`board.zone()`) dice qué celdas son del tablero |
| `directions.wlk` | Las 4 direcciones (`up`, `down`, `left`, `right`): su nombre, cuál sigue al rotar, cuál es la opuesta y cómo moverse una celda hacia ellas |
| `cellPosition.wlk` | `CellPosition`: una posición de celda que se dibuja más rápido que una común (ver más abajo) |

### `board.wlk`

- El tablero jugable va de **x 5 a 16** y de **y 1 a 10** (12x10 celdas, `inBoard`). El resto de la pantalla son los menús.
- Por dentro es una grilla de casillas (`Cell`) que se arma una sola vez. Buscar una máquina es ir directo a su casilla, sin recorrer nada. Por eso no es un `Dictionary`: el comentario del archivo explica por qué era lento.
- `push(posición, máquina)` la coloca: le fija la posición del dibujo (con su `drawOffsetX`/`drawOffsetY`), la agrega a la pantalla y la anota en el `simulationEngine`. `pop(posición)` hace lo contrario, y se lleva los ingredientes que tenía encima. **`pop` saca la máquina aunque esté bloqueada**: el bloqueo es para el jugador y lo controlan las herramientas (con `isThereAMachineUnlocked(posición)`).
- `machines()`: las máquinas colocadas, cada una una sola vez (una de 2x2 ocupa 4 casillas, pero aparece una vez).
- `clear()`: saca todas las máquinas (hace `pop` de cada una), con los ingredientes que tengan encima. Sirve para empezar de cero, por ejemplo al cargar un nivel.
- **Puntos de entrega:** los dos platitos del fondo, en (13, 11) y (14, 11), están **fuera** del tablero, pero las cintas y los brazos les entregan como a cualquier máquina (ver `DeliverySlot` en [`machines/README.md`](machines/README.md#types-las-máquinas)).
  - `addDeliverySlot(platito)`: lo anota en `deliverySlots` y lo registra en el `simulationEngine`, para que al apagar la simulación se borre el plato que estaba viajando hacia él y el platito quede vacío. Lo llama `deliveryPoints.setUp()`.
  - `machineAt(posición)`: dentro del tablero busca en la grilla; afuera, entre los `deliverySlots` (y si no hay ninguno ahí, `noMachine`: nunca devuelve `null`).
  - Como `inBoard` no los incluye, no se puede colocar nada encima ni hacerles click. Tampoco están en la grilla, así que `machines()` y `clear()` no los ven: son parte del escenario, no del nivel.
- **Zonas donde se puede construir:** el tablero es el que sabe dónde se puede construir. El nivel le dice en qué celdas puede colocar máquinas el jugador (`buildZones(zonas)`, lo llama `levelManager.load`), como una lista de `Zone` (rectángulos de celdas, definidos en este mismo archivo). Por defecto, todo el tablero (`wholeBoard`).
  - `isBuildable(posición)`: está en el tablero y en alguna de las zonas.
  - `canBuild(posición, máquina)`: como `canPlace`, y además todas sus celdas están en alguna zona (una de 2x2 puede quedar repartida entre dos zonas pegadas). Lo usa la herramienta place.
  - `push` **no** mira las zonas: así el nivel puede colocar sus máquinas fijas en cualquier lugar.
  - Las celdas donde no se puede construir se ven oscurecidas con UNA sola imagen por nivel (`BlockedLayer`, la `blockedLayer` del nivel: `assets/levels/blocked_<nivel>.png`), no con un visual por celda. Se genera con `assets/levels/makeBlockedOverlays.py`, y se cambia sólo al cargar el nivel. Si se cambian los `buildZones` de un nivel, hay que actualizar `ZONES` en ese script y volver a correrlo.
- **No usar `push`, `pop` ni `clear` con la simulación prendida:** las máquinas ya calcularon a sus vecinas. Los clicks se bloquean en `toolsManager`; `clear` no lo controla, así que antes hay que apagarla (`simulationEngine.reset()`).

### `cellPosition.wlk`

Wollok Game le pide a cada objeto su `position().round()` unas 60 veces por segundo. En una posición común, `round()` crea una posición nueva cada vez, y eso hacía que dibujar fuera mucho más caro. `CellPosition` devuelve la misma posición, porque una celda ya tiene coordenadas enteras. Para posiciones con decimales (ingredientes en movimiento) está `SmoothPosition`, en `simulation/animationEngine.wlk`.

## Cómo se conecta todo

```
teclas y clicks ─▶ input/userController ─▶ menu/screenManager ─▶ la pantalla activa (menu/screens)
                     jugando:  playingScreen ─▶ menu/hud, el tablero ─▶ tools/toolsManager ─▶ tools/userTools ─▶ board ─▶ machines
                     └─▶ simulation/simulationEngine ─▶ machines (start / acciones agendadas / reset)
                                                     └─▶ simulation/animationEngine
```

1. El jugador hace clic en el tablero: `toolsManager` coloca en una celda vacía, o elige la máquina, y C, X o V la rotan, editan o borran en el `board`.
2. Con la tecla **5**, el `simulationEngine` prende la simulación: avisa a cada máquina (`start`) y desde ahí ejecuta las acciones que cada una agendó (`after`). Ver [el contrato de las máquinas](machines/README.md#el-contrato-de-machine).
3. En cada paso, el `animationEngine` mueve los ingredientes y avanza las animaciones frame a frame.
4. Al apagar, el `simulationEngine` borra los ingredientes y vuelve cada máquina a su estado inicial (`reset`).

## Convenciones

- **Nombres en inglés** para clases, métodos y variables nuevas; los comentarios, en español. (El código más viejo, como `animationEngine`, ya se pasó al inglés.)
- **Imports relativos a `src/`**, sin el prefijo `src.` (por ejemplo `import machines.machineClasses.*`). Los tests sí lo llevan (`import src.machines.machineClasses.*`).
- **Rendimiento:** lo que Wollok Game le pide a un objeto en cada frame (`image()` y `position()`) tiene que ser un dato ya guardado, no algo que se calcule. Los comentarios marcados `RENDIMIENTO` explican los casos que importaron.
- Las imágenes las busca el código por nombre: ver [`assets/README.md`](../assets/README.md).

## Null objects: nada de `null`

El código no usa `null` ni lo compara. Donde "no hay nada" se usa un objeto que entiende los mismos mensajes y no hace nada, así nadie tiene que preguntar antes si hay algo:

| Objeto | Es "no hay…" | Dónde se usa |
|---|---|---|
| `noMachine` | máquina | celdas vacías (`board.machineAt`), destino de una máquina sin vecina (`next`), la máquina elegida en edit |
| `noItem` | item | una máquina sin nada para entregar (`itemToPush`) o para que un brazo agarre (`grabbableItem`) |
| `placingMode` / `editingMode` | modo | COLOCANDO o EDITANDO (ver `toolsManager`) |
| `noAnimation` / `noAction` | animación / bloque final | `MachineAnimator` |
| `noDestination` | destino | lo que está quieto (`Animated`) |
| `noSlot` | opción clickeada | un click afuera de las opciones (`editMenu`) |
| `noSkipButton` | botón de saltear | niveles sin tutorial (`levelInfoMenu`) |
| `noSound` | sonido | `musicManager` antes de arrancar la música |
| `unlimitedEnergy`, `noGoal`, `noTutorial` | límite / objetivo / tutorial | los niveles que no los tienen. `noTutorial` también sabe saltearse (`skip`) y devolver `noSkipButton` |

Para no preguntar qué es algo, se le pide lo que se necesita (polimorfismo) en vez de comparar:
- **Qué hace cada nivel con L y al cargarse:** `level.toggleFreePlay(manager)` y `level.showHints(menu)`; el modo libre las sobrescribe (no se compara con `freePlay`).
- **Qué máquina pide un paso del tutorial:** `MachineStep.allowedMachines` guarda las fábricas del catálogo (`machineManager.beltFactory()`), y `tool.allowsMachine(...)` mira si está seleccionada. Ya no se compara `machine.name()`.
- **Qué acción se usa:** `tool.canUseAnywhere()` (edit) en lugar de `tool == edit`. **Qué hace cada tecla según el modo:** `mode.arrow(...)`, `mode.enter(...)`, `mode.editKey(...)` en lugar de preguntar si se está editando.
- **Cómo entrega el ensamblador:** `direction.outputEdgeShift(celda)`: cada dirección sabe por qué celda de su borde sale el plato (la que marca la flecha del sprite).
- **Qué visual es un texto o una barra:** los visuales de la info del nivel responden `textLines()` y `barImages()` (listas, vacías si no corresponde).
