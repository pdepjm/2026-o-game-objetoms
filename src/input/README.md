# `input/`

| Archivo | Qué tiene |
|---|---|
| `userController.wlk` | `userController`: conecta las teclas y los clicks con el resto del juego |

`userController.setUp()` se llama una vez desde `main.wpgm`. No tiene lógica propia: cada tecla le pasa la acción al objeto que corresponde.

| Tecla | Acción | Quién la hace |
|---|---|---|
| Clic | Lo resuelve la pantalla activa (ver `startMenu`): en la portada, la opción clickeada; con el libro abierto, la cruz lo cierra y las flechas o las mitades pasan de página; jugando, los botones de abajo a la izquierda, SALTEAR TUTORIAL, el globo del cocinero (seguir) y el resto `toolsManager` (coloca en una celda vacía, elige una máquina, o elige en el menú de la derecha) | `userController.onClick` |
| C / X / V | Rotar / editar / borrar la máquina elegida (la última clickeada). X con el panel de editar abierto lo cierra | `toolsManager.act` / `editKey` |
| W / A / S / D | Dirección para colocar: arriba / izquierda / abajo / derecha | `toolsManager.currentDirection` |
| Q / E | Máquina anterior / siguiente del menú de colocar (pasa de página sola) | `menuManager.chooseMachine` |
| ← ↑ ↓ → | Lo resuelve la pantalla activa: en la portada, ↑ y ↓ eligen la opción; jugando, sólo eligen la opción marcada del panel de editar (el tablero es sólo con el mouse); con el libro abierto, ← y → pasan de página | `startMenu.arrow` |
| Retroceso | Volver: deja de editar, cierra el libro o los controles. (Wollok no le pasa Esc al juego) | `startMenu.back` |
| M | Volver a la portada | `startMenu.backToCover` |
| 1 / 2 / 3 | Velocidad de la simulación x1 / x2 / x3 (también con los botones de abajo a la izquierda) | `sideButtons.speed` |
| 5 | Prender / apagar la simulación (con el nivel completo, no hace nada) | `levelManager.toggleSimulation` |
| N | Pasar al siguiente nivel (sólo después de ganar) | `levelManager.loadNext` |
| 0 | Reiniciar el nivel (borra también lo que se construyó) | `levelManager.restart` |
| L | Ir al modo libre (todas las máquinas, sin objetivo), o volver de él al nivel que toca jugar. Con la simulación prendida no hace nada | `levelManager.toggleFreePlay` |
| Enter | Lo resuelve la pantalla activa: en la portada, la opción marcada; jugando, sigue el tutorial si el cocinero está explicando, y si no aplica la opción marcada del panel de editar (no coloca: las máquinas se colocan sólo con el clic) | `startMenu.start` |
| T | Saltear los tutoriales (también con el botón SALTEAR TUTORIAL de la info del nivel). Fuera de un tutorial no hace nada | `levelManager.skipTutorial` |
| F | Abrir o cerrar el libro de recetas | `startMenu.toggleRecipeBook` |
| Espacio | Lo mismo que la 5 | `levelManager.toggleSimulation` |

Para agregar una tecla, sumarla en `setUp()` y documentarla también en el [README principal](../../README.md).

**Con el libro de recetas abierto, o en la portada, sólo funcionan F, las flechas, Enter y Retroceso** (y en la portada, I y S). Las demás pasan por `whenPlaying`, que no hace nada en esos casos: así el juego de atrás no cambia sin que el jugador lo vea. Los clicks, igual (`onClick`).
