# `simulation/`

El reloj del juego y las animaciones. Los ingredientes y las recetas están en [`food/`](../food/README.md).

| Archivo | Qué tiene |
|---|---|
| `simulationEngine.wlk` | El reloj de la simulación: prender, apagar, velocidad y la agenda de acciones |
| `animationEngine.wlk` | Lo que se anima paso a paso: ingredientes que se mueven y animaciones frame a frame |

## `simulationEngine.wlk`

Es el **único reloj del juego**. Wollok Game le manda `tick()` cada 100 ms (`tickMs`), y cada tick ejecuta 1, 2 o 3 pasos según la velocidad (teclas 1, 2 y 3).

- **Dos modos:**
  - **Apagada** (modo construcción): no corre ningún paso y se puede editar el tablero.
  - **Prendida** (tecla 5): corren los pasos y el tablero queda bloqueado.
- **`run()`:** prende la simulación y le manda `start()` a cada máquina.
- **`stop()`:** la apaga, vacía la agenda, borra los ingredientes y le manda `reset()` a cada máquina.
- **`reset()`:** vuelve a como arranca el juego: si está prendida la apaga (`stop()`) y pone la velocidad en 1. **No saca las máquinas**: se van del engine cuando el tablero las saca (`board.clear()`, que llama a `pop`). Así el engine nunca se olvida de una máquina que sigue en el tablero.
- **La agenda:** las máquinas **no se recorren en cada paso** (con muchas era lo más lento del juego). Quien necesita hacer algo más adelante lo agenda con **`after(pasos, bloque)`**, y cuando llega ese paso el engine ejecuta el bloque. Se puede agendar a cualquier cantidad de pasos.
- **Cómo se guarda:** la agenda es una ronda de `slotCount` (64) casilleros, y una acción que vence en el paso `p` va al casillero `p % slotCount`. Así cada paso revisa un solo casillero, no todas las acciones pendientes. Cada acción es un `ScheduledAction`, que recuerda en qué paso vence (`dueStep`): una acción a más de 64 pasos espera en su casillero las vueltas que haga falta. `slotCount` no es un límite; sólo conviene que sea mayor que las demoras que se agendan seguido.
- **El bloque dice qué se hace:** `after(5, { self.onArrived(item) })`. Nadie tiene que deducir por qué lo despertaron.
- **En cada paso (`step()`):** primero ejecuta las acciones agendadas y después avanza las animaciones (`animationEngine.tick()`).
- **Items:** `addItem` pone un ingrediente en pantalla; `removeItem` lo saca del tablero (lo usan las máquinas que consumen ingredientes, como el Assembler); `allItems` devuelve todos los que tienen las máquinas encima (`heldItems()` de cada una).
- `stepsFor(milisegundos)`: convierte un tiempo en pasos de simulación.

> [!IMPORTANT]
> **Toda acción agendada revisa el estado antes de actuar.** Entre que se agenda y que se ejecuta pueden pasar cosas, y una misma acción puede quedar agendada dos veces. Una acción que vuelve a preguntar (como `tryPush()`) es segura; una que actúa sin preguntar (entregar "porque sí") puede entregar dos veces.

Los tests llaman a `step()` directamente para avanzar sin depender del tiempo real.

## `animationEngine.wlk`

Avanza todo lo que se anima. No tiene reloj propio: el `simulationEngine` le avisa una vez por paso, así **la pausa y la velocidad afectan a las animaciones sin hacer nada extra**.

| Qué | Para qué |
|---|---|
| `animationEngine` | Lista de lo que se está animando. En cada `tick()` le manda `avanzar()` a cada uno, saca a los que terminaron (`animando()` en false) y después ejecuta los bloques de fin de animación |
| `PosicionSuave` | Una posición con decimales, para dibujar un ingrediente a mitad de camino entre dos celdas |
| `Animado` (mixin) | Movimiento suave entre celdas: `move`, `moveInSteps`, `moverHacia`, `detener`. Lo usan los ingredientes |
| `FrameAnimation` | Una animación frame a frame: la carpeta de PNG y la lista de rutas, armada una sola vez. La reproduce `MachineAnimator` (en `machines/machineClasses.wlk`) |
| `TimedAnimation` | Una animación que dura exactamente N pasos, armada con una lista de imágenes. La usa `ProcessingMachine` para ajustar la animación al tiempo del ingrediente |

- `pasosPorCelda` (5): cuántos pasos tarda un ingrediente en recorrer una celda. Las máquinas lo usan para saber cuándo termina de llegar un item.
- **Bloques de fin de animación:** cuando una animación termina, su bloque no se ejecuta en ese momento: queda pendiente y se ejecuta **después de recorrer la lista**. Por eso en el bloque se puede mover items o encadenar otra animación sin romper el recorrido.
- Un mismo objeto no puede ser `Animado` y animarse frame a frame a la vez: los dos definen `avanzar()`.

