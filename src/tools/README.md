# `tools/`

Lo que el jugador le hace al tablero: colocar, rotar, editar y borrar máquinas, la máquina elegida y la dirección con la que se colocan. **No se elige herramienta:** cada acción tiene su clic o su tecla.

| Archivo | Qué tiene |
|---|---|
| `toolsManager.wlk` | `toolsManager` (a dónde va cada clic y cada tecla del tablero), los modos `placingMode` (COLOCANDO) y `editingMode` (EDITANDO), y la celda elegida (`boardCursor`, que no se dibuja). El menú de la máquina elegida (`actionsMenu`) está en `src/menu/actionsMenu.wlk` |
| `userTools.wlk` | Las acciones: `place`, `delete`, `edit` y `rotate` |

## Cómo se juega

| Qué hace el jugador | Qué pasa |
|---|---|
| Clic en una celda vacía | Coloca la máquina elegida en el menú (`place`), mirando hacia la dirección actual, y la deja elegida con su menú abajo. **Sólo con el clic**: el teclado no coloca |
| Clic en una máquina | Queda **elegida**: abajo aparece su menú (ROTAR · EDITAR · BORRAR) |
| C | Rota la máquina elegida (`rotate`) |
| X | Edita la máquina elegida (`edit`): se abre su panel y el cartel dice EDITANDO. X otra vez lo cierra |
| V | Borra la máquina elegida (`delete`) |
| Clic en ROTAR, EDITAR o BORRAR del menú de la máquina | Lo mismo que C, X o V |
| Retroceso (Backspace) | Deja de editar |

El menú de la máquina aparece al **elegirla** y también **al colocarla**: la máquina nueva queda elegida, así C, X o V (o su menú) actúan sobre ella enseguida. Mientras está abierto, tapa las celdas de abajo: un clic ahí usa la acción. Wollok no avisa dónde está el mouse hasta el clic (sólo recibe teclas, clic y doble clic), por eso las teclas actúan sobre la última máquina clickeada (o a la que se llevó el cursor), y no sobre la que está "debajo del mouse".

## `toolsManager.wlk`

- **Clics (`onClick`):** en el menú de la máquina elegida usa esa acción; en el tablero, `clickCell` (coloca o elige); en la zona interactiva, se lo pasa a `menuManager`.
- **Teclas:** `arrow(dirección)`, `enter()` y `editKey()` se los delega al modo actual: COLOCANDO sólo edita (las flechas y Enter no hacen nada: el tablero es sólo con el mouse); EDITANDO mueve la marca del panel de editar, aplica la opción marcada y cierra el panel. `act(acción)` es C y V.
- **`useAt(acción, celda)`:** el único lugar que usa una acción en el tablero. **Sólo con la simulación apagada**, y si el tutorial no la deja (`levelManager.allowsTool`), el cocinero dice por qué (`levelManager.toolRejected`).
- **La celda del recuadro queda elegida sola** en cada paso del tutorial (`jumpTo`, lo llama `levelManager`): así C o X actúan ahí sin clickearla.
- **Dirección para colocar:** `currentDirection` (W/A/S/D o los botones del panel de colocar). Las máquinas nuevas nacen mirando hacia ahí. Cada cambio se le avisa a `menuManager`, para actualizar las imágenes del menú.
- **`reset()`:** vuelve a como arranca un nivel: COLOCANDO, dirección `right` y sin máquina elegida. Al cerrarse el panel de edit, `editMenu` olvida la máquina: por eso, al reiniciar, se llama después de `board.clear()`.
- **Rendimiento:** el menú de la máquina guarda su posición y su imagen; se recalculan sólo cuando pasa algo (un clic, una tecla, un cambio en el tablero), nunca al dibujarse. `boardChanged()` lo vuelve a agregar para que quede arriba de las máquinas (Wollok dibuja en el orden en que se agregan los visuales).

## `userTools.wlk`

Cada acción es un objeto que entiende `onClick(celda)`, y lo que le pregunta el tutorial (`canUseAnywhere`, `allowsMachine`, `complaintIn`):

| Acción | Cómo se usa | Qué hace en la celda |
|---|---|---|
| `place` | Clic en una celda vacía | Coloca la máquina elegida en el menú. Si no entra (celda ocupada o fuera de las zonas del nivel), no coloca nada |
| `rotate` | C | Rota la máquina (en el brazo automático mueve su entrada). No hace nada si está bloqueada |
| `edit` | X | Abre el panel de editar de la máquina (EDITANDO). Si no tiene nada para ajustar, no hace nada |
| `delete` | V | Quita la máquina (y los ingredientes que tenía). No hace nada si está bloqueada (`locked`: las fijas de un nivel) |

## Agregar una acción
1. Un objeto en `userTools.wlk` con `onClick(celda)` y lo que pregunta el tutorial.
2. Una tecla en `input/userController.wlk` que llame a `toolsManager.act(...)`.
3. Si va en el menú de la máquina elegida, agregarla en `actionsMenu` y en sus imágenes (`assets/menu/makeBoardUi.py`).
