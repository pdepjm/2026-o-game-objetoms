# `tools/`

Las herramientas con las que el jugador construye, y la dirección con la que se colocan las máquinas.

| Archivo | Qué tiene |
|---|---|
| `toolsManager.wlk` | `toolsManager`: qué herramienta está elegida, la dirección para colocar, y a dónde va cada click |
| `userTools.wlk` | Las herramientas: `place`, `delete`, `edit` y `rotate` |

## `toolsManager.wlk`

- **Herramienta elegida:** `select(herramienta)` la elige. Volver a elegir la misma la deselecciona (queda `null`). El juego arranca sin ninguna. Cada cambio se le avisa a `menuManager`.
- **Dirección para colocar:** `currentDirection` (W/A/S/D). Las máquinas nuevas nacen mirando hacia ahí. Cada cambio se le avisa a `menuManager`, para actualizar las imágenes del menú.
- **Clicks (`onClick`):**
  - en el tablero, se lo pasa a la herramienta elegida, **sólo si la simulación está apagada** (así no se edita el tablero mientras corre);
  - en la zona interactiva del menú, se lo pasa a `menuManager`.
- **`reset()`:** vuelve a como arranca el juego: sin herramienta y con dirección `right`, y se lo avisa a `menuManager` (cierra el panel activo y actualiza las imágenes del menú). No usa `select(null)`, porque `select` alterna. Al cerrarse el panel de edit, `editMenu` olvida la máquina elegida: por eso, al reiniciar, se llama después de `board.clear()`.

## `userTools.wlk`

Cada herramienta es un objeto que entiende `name()` y `onClick(posición)`:

| Herramienta | Tecla | Al hacer click en el tablero |
|---|---|---|
| `place` | P | Coloca la máquina elegida en el menú, mirando hacia la dirección actual |
| `delete` | X | Quita la máquina de esa celda (y los ingredientes que tenía) |
| `edit` | Z | Elige esa máquina y muestra sus settings en el panel de edit |
| `rotate` | R | Rota la máquina de esa celda (en el brazo automático mueve su entrada) |

`name()` se usa para la imagen de la barra (`assets/tools/<name>_selected.png`).

## Agregar una herramienta
1. Un objeto en `userTools.wlk` con `name()` y `onClick(posición)`.
2. Su imagen `assets/tools/<name>_selected.png`.
3. Una tecla en `input/userController.wlk` que la elija con `toolsManager.select(...)`.
4. Si tiene panel propio, agregarlo en `menuManager.initialize()` (ver [`menu/README.md`](../menu/README.md)).
