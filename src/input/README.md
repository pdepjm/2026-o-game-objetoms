# `input/`

| Archivo | Qué tiene |
|---|---|
| `userController.wlk` | `userController`: conecta las teclas y los clicks con el resto del juego |

`userController.setUp()` se llama una vez desde `main.wpgm`. No tiene lógica propia: cada tecla le pasa la acción al objeto que corresponde.

| Tecla | Acción | Quién la hace |
|---|---|---|
| Click | Con el libro de recetas abierto, lo que se clickeó en el libro. Si no, el icono del libro lo abre, y el resto usa la herramienta elegida o elige en el menú | `userController.onClick` |
| Z / X / C / V | Elegir la herramienta place / edit / rotate / delete | `toolsManager.select` |
| W / A / S / D | Dirección para colocar: arriba / izquierda / abajo / derecha | `toolsManager.currentDirection` |
| Q / E | Página anterior / siguiente del menú de máquinas | `menuManager` |
| ← / → | Receta anterior / siguiente del libro de recetas (con el libro abierto) | `recipeBookMenu.prevPage` / `nextPage` |
| M | Volver a la portada | `startMenu.backToCover` |
| 1 / 2 / 3 | Velocidad de la simulación x1 / x2 / x3 | `simulationEngine.speed` |
| 5 | Prender / apagar la simulación (con el nivel completo, no hace nada) | `levelManager.toggleSimulation` |
| N | Pasar al siguiente nivel (sólo después de ganar) | `levelManager.loadNext` |
| 0 | Reiniciar el nivel (borra también lo que se construyó) | `levelManager.restart` |
| L | Ir al modo libre (todas las máquinas, sin objetivo), o volver de él al nivel que toca jugar. Con la simulación prendida no hace nada | `levelManager.toggleFreePlay` |
| Enter | En el tutorial, seguir después de una explicación. En los demás niveles no hace nada | `levelManager.continueTutorial` |
| F | Abrir o cerrar el libro de recetas | `recipeBookMenu.toggle` |
| Espacio | Lo mismo que la 5 | `levelManager.toggleSimulation` |

Para agregar una tecla, sumarla en `setUp()` y documentarla también en el [README principal](../../README.md).

**Con el libro de recetas abierto, o en la portada, sólo funcionan F y las flechas** (y en la portada, las teclas de `startMenu`: Enter, I y S). Las demás pasan por `whenPlaying`, que no hace nada en esos casos: así el juego de atrás no cambia sin que el jugador lo vea. Los clicks, igual (`onClick`).
