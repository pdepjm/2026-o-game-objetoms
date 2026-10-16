# `simulation/`

El reloj del juego y las animaciones. Los ingredientes y las recetas están en [`food/`](../food/README.md).

| Archivo | Qué tiene |
|---|---|
| `simulationEngine.wlk` | El reloj de la simulación: prender, apagar, velocidad y la agenda de las máquinas |
| `animationEngine.wlk` | Lo que se anima paso a paso: ingredientes que se mueven y animaciones frame a frame |

## `simulationEngine.wlk`

Es el **único reloj del juego**. Wollok Game le manda `tick()` cada 100 ms (`tickMs`), y cada tick ejecuta 1, 2 o 3 pasos según la velocidad (teclas 1, 2 y 3).

- **Dos modos:**
  - **Apagada** (modo construcción): no corre ningún paso y se puede editar el tablero.
  - **Prendida** (tecla 5): corren los pasos y el tablero queda bloqueado.
- **`run()`:** prende la simulación y le manda `start()` a cada máquina.
- **`stop()`:** la apaga, borra los ingredientes, vacía la agenda y le manda `reset()` a cada máquina.
- **La agenda:** las máquinas **no se recorren en cada paso** (con muchas era lo más lento del juego). Cada máquina pide "despertame dentro de N pasos" con `schedule(pasos, máquina)`, y cuando llega ese paso el engine le manda `use()`. Como máximo se agenda a 15 pasos.
- **En cada paso (`step()`):** primero despierta a las máquinas agendadas y después avanza las animaciones (`animationEngine.tick()`).
- **Items:** `addItem` pone un ingrediente en pantalla y lo cuenta; `allItems` devuelve todos los que tienen las máquinas encima.
- `stepsFor(milisegundos)`: convierte un tiempo en pasos de simulación.

Los tests llaman a `step()` directamente para avanzar sin depender del tiempo real.

## `animationEngine.wlk`

Avanza todo lo que se anima. No tiene reloj propio: el `simulationEngine` le avisa una vez por paso, así **la pausa y la velocidad afectan a las animaciones sin hacer nada extra**.

| Qué | Para qué |
|---|---|
| `animationEngine` | Lista de lo que se está animando. En cada `tick()` le manda `avanzar()` a cada uno y saca a los que terminaron (`animando()` en false) |
| `PosicionSuave` | Una posición con decimales, para dibujar un ingrediente a mitad de camino entre dos celdas |
| `Animado` (mixin) | Movimiento suave entre celdas: `move`, `moveInSteps`, `moverHacia`, `detener`. Lo usan los ingredientes |
| `FrameAnimation` | Una animación frame a frame: la carpeta de PNG y la lista de rutas, armada una sola vez. La reproduce `MachineAnimator` (en `machines/machineClasses.wlk`) |

- `pasosPorCelda` (5): cuántos pasos tarda un ingrediente en recorrer una celda. Las máquinas lo usan para saber cuándo termina de llegar un item.
- `ticking()`: dice si el engine está avanzando en este momento. Mientras tanto no se puede agregar nada a la lista que se está recorriendo; por eso, por ejemplo, el brazo no mueve items en el bloque del final de una animación.
- Un mismo objeto no puede ser `Animado` y animarse frame a frame a la vez: los dos definen `avanzar()`.
