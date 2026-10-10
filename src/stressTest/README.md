# `stressTest/`

Herramientas para medir el rendimiento del juego con muchos objetos. No forman parte del juego: sirven para comparar antes y después de un cambio.

| Archivo | Tecla | Qué hace |
|---|---|---|
| `stressMeter.wlk` | M | `stressMeter`: escribe en la terminal, cada segundo, cuántos items hay y cuánto tardan los ticks |
| `stressTestBoard.wlk` | L | `stressTestBoard`: llena el tablero con una "serpiente" de cintas que arranca en un dispenser |

## `stressMeter.wlk`

- Tiene su propio reloj (un `onTick` con el mismo intervalo que la simulación) que existe sólo mientras está prendido. Ni la simulación ni las máquinas saben que existe: les pregunta lo que necesita (`tickMs`, `speed`, `itemCount`).
- Mide cuánto tiempo real pasa entre un tick y el siguiente. Si el juego no llega a simular y dibujar a tiempo, los ticks se atrasan.
- Informa el promedio y el tick más lento. El estado (`ok`, `justo`, `SOBRECARGADO`) se calcula con el más lento, porque es el que se ve como tirones en pantalla.

## `stressTestBoard.wlk`

- Coloca un dispenser en la esquina inferior izquierda y llena todas las filas con cintas que van y vuelven, subiendo al final de cada fila. Así los items recorren todo el tablero.
- Es el **peor caso a propósito**: un solo dispenser perfectamente regular hace que todos los items cambien de cinta en el mismo paso.
- Sólo funciona con la simulación apagada, y no cambia la dirección que tenía elegida el jugador.

Cómo hacer una prueba de carga y cómo leer el medidor: ver la sección "Pruebas de carga" del [README principal](../../README.md).
