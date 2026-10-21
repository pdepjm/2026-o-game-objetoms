# `input/`

| Archivo | Qué tiene |
|---|---|
| `userController.wlk` | `userController`: conecta las teclas y los clicks con el resto del juego |

`userController.setUp()` se llama una vez desde `main.wpgm`. No tiene lógica propia: cada tecla le pasa la acción al objeto que corresponde.

| Tecla | Acción | Quién la hace |
|---|---|---|
| Click | Usar la herramienta elegida, o elegir en el menú | `toolsManager.onClick` |
| P / X / Z / R | Elegir la herramienta place / delete / edit / rotate | `toolsManager.select` |
| W / A / S / D | Dirección para colocar: arriba / izquierda / abajo / derecha | `toolsManager.currentDirection` |
| Q / E | Página anterior / siguiente del menú | `menuManager` |
| 1 / 2 / 3 | Velocidad de la simulación x1 / x2 / x3 | `simulationEngine.speed` |
| 5 | Prender / apagar la simulación | `simulationEngine.toggle` |

Para agregar una tecla, sumarla en `setUp()` y documentarla también en el [README principal](../../README.md).
