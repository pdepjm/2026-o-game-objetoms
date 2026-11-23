# `input/`

| Archivo | Qué tiene |
|---|---|
| `userController.wlk` | `userController`: conecta las teclas y los clics de Wollok con `screenManager` |
| `clickManager.wlk` | Lo común de los clics: `ClickTargets`, `CellArea` y `nothingClicked` |

## `userController.wlk`

`userController.setUp()` se llama una vez desde `main.wpgm` y configura **todas** las teclas (si se configuraran de nuevo, se ejecutarían dos veces). No tiene lógica propia: cada tecla le manda a `screenManager` un mensaje que dice qué quiere el jugador, y **lo resuelve la pantalla activa** (ver [`menu/README.md`](../menu/README.md#las-pantallas-screenmanagerwlk-y-screenswlk)). Por ejemplo, S en la portada es salir y jugando es mirar hacia abajo; con el libro abierto, las teclas del juego no hacen nada.

| Tecla | Mensaje | Jugando |
|---|---|---|
| Clic | `onClick(pos)` | Por capas: el globo del cocinero (seguir), el menú de la máquina elegida, el HUD (botones de abajo a la izquierda, SALTEAR TUTORIAL, el panel de la derecha) y el tablero (coloca en una celda vacía o elige una máquina) |
| C / X / V | `rotateMachine` / `editMachine` / `deleteMachine` | Rotar / editar / borrar la máquina elegida (la última clickeada). X con el panel de editar abierto lo cierra |
| W / A / D | `direction(lado)` | Dirección para colocar: arriba / izquierda / derecha |
| S | `pressS` | Dirección abajo (en la portada: salir) |
| Q / E | `chooseMachine(paso)` | Máquina anterior / siguiente del menú de colocar (pasa de página sola) |
| Flechas | `arrow(dirección)` | Sólo eligen la opción marcada del panel de editar (el tablero es sólo con el mouse). En la portada, arriba y abajo eligen la opción; con el libro abierto, izquierda y derecha pasan de página |
| Retroceso | `back` | Deja de editar. Cierra el libro o los controles. (Wollok no le pasa Esc al juego) |
| Enter | `enter` | Sigue el tutorial si el cocinero está explicando; si no, aplica la opción marcada del panel de editar. En la portada, la opción marcada; con el ticket, su primer botón |
| M | `backToMenu` | Volver a la portada |
| 1 / 2 / 3 | `speed(n)` | Velocidad de la simulación x1 / x2 / x3 (también con los botones de abajo a la izquierda) |
| Espacio / 5 | `toggleSimulation` | Prender / apagar la simulación (con el nivel completo, no hace nada) |
| N | `nextLevel` | Pasar al siguiente nivel (sólo después de ganar) |
| 0 | `restart` | Reiniciar el nivel (borra también lo que se construyó) |
| L | `toggleFreePlay` | Ir al modo libre (todas las máquinas, sin objetivo), o volver de él al nivel que toca jugar. Con la simulación prendida no hace nada |
| T | `skipTutorial` | Saltear los tutoriales (también con el botón SALTEAR TUTORIAL). Fuera de un tutorial no hace nada |
| F | `toggleBook` | Abrir o cerrar el libro de recetas (también desde la portada y los controles) |
| I | `pressI` | En la portada, los controles; en los controles, volver |

Para agregar una tecla: sumarla en `setUp()`, agregar su mensaje (vacío) en `Screen` y en `screenManager`, redefinirlo en la pantalla que la use, y documentarla también en el [README principal](../../README.md).

## `clickManager.wlk`

**No es un objeto que decide adónde va cada clic** (hubo uno así, con `if` por herramienta y por coordenadas, y se sacó): son los moldes que usa cada cosa para ser clickeable.

- Un **click target** es cualquier objeto que entiende `handlesClick(pos)` ("¿la celda es tuya?") y `onClick(pos)`.
- `ClickTargets`: un grupo (una pantalla, el HUD, un panel). Responde `handlesClick` con **su propia zona** (`zones()`), sin preguntarles a sus partes; al recibir el clic se lo pasa a la primera de sus partes (`clickTargets()`, de la que se ve más arriba a la de más abajo) que lo quiera. Cada uno es consultado una sola vez.
- `CellArea(zone, action)`: un lugar que se clickea. `press()` hace su acción (también lo usa Enter en el ticket). `Button` (en `menu/drawing/visuals.wlk`) es un `CellArea` con imagen.
- `nothingClicked`: lo que recibe un clic que no es de nadie. No hace nada.
- Las zonas son `Zone` (en `cellPosition.wlk`), la única forma de decir "esta parte de la pantalla". `rectangle.of(x, y, ancho, alto)` arma una desde su esquina de abajo a la izquierda.

> **Rendimiento:** por clic se hacen unas pocas comparaciones de números por nivel, y la búsqueda corta en el primero que dice que sí. No hace falta una tabla por celda (habría que rehacerla cada vez que algo aparece o se mueve).
