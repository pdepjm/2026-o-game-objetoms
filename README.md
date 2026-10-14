### Buffet Albert Einstein


La IA dominó el mundo, y echaron a todos los trabajadores del buffet.
Los ingenieros tenemos hambre y tenemos que seguir comiendo. 
Es tu tarea automatizar todos los procesos del buffet.

## Documentación

| Documento | Qué tiene |
|---|---|
| [`src/machines/README.md`](src/machines/README.md) | Las máquinas y **el contrato para crear una nueva** |
| [`src/simulation/README.md`](src/simulation/README.md) | El reloj de la simulación, la agenda de acciones y las animaciones |
| [`src/food/README.md`](src/food/README.md) | Los ingredientes y las recetas |
| [`src/menu/README.md`](src/menu/README.md) | Los menús de la pantalla |
| [`src/tools/README.md`](src/tools/README.md) | Las herramientas del jugador y la dirección elegida |
| [`src/input/README.md`](src/input/README.md) | Las teclas y los clicks |
| [`src/levels/README.md`](src/levels/README.md) | Niveles (todavía sin usar) |
| [`src/stressTest/README.md`](src/stressTest/README.md) | Pruebas de carga |
| [`assets/README.md`](assets/README.md) | Cómo nombrar y ubicar las imágenes |
| [`assets/machines/AutomaticArm/README.md`](assets/machines/AutomaticArm/README.md) | Las imágenes del brazo automático (caso especial) |
| [`docs/plan-contrato-maquinas.md`](docs/plan-contrato-maquinas.md) | Plan de implementación del contrato de las máquinas |

## Participantes
- Mateo Bustos
- Carlos Aramis Chambi Flores
- Facundo Ramounat
- Federico Scalise Giussani
- Mateo Silva




## KEYS
**Q**: Pagina anterior

**E**: Pagina siguiente

**P**: Herramienta de Place

**X**: Herramienta de Delete

**Z**: Herramienta de Edit

> [!NOTE]
> El juego arranca sin ninguna herramienta elegida. Volver a tocar la tecla de la herramienta activa la deselecciona.

### Rotaciones
**R**: Herramienta de Rotar

> [!NOTE] 
> La herramienta unicamente rota los objetos ya colocados

**W**: Rotar hacia arriba

**S**: Rotar hacia abajo

**A**: Rotar hacia la izquierda

**D**: Rotar hacia la derecha

> [!NOTE]
> Estas teclas solo rotan los objetos en el overlay, no los objetos ya colocados

### Simulación
**1**: establece la velocidad en x1
**2**: establece la velocidad en x2
**3**: establece la velocidad en x3
**5**: Inicia o termina la simulación

### Pruebas de carga
**M**: Prende o apaga el medidor de carga. Escribe en la terminal, cada segundo, la cantidad de items y cuánto tarda cada tick

**L**: Llena el tablero con una "serpiente" de cintas que arranca en un dispenser (sólo con la simulación apagada)

Cómo probar el rendimiento:
1. Correr el juego: `wollok run src.main.BuffetAlbertEinstein --skipValidations -p ./`
2. Tocar **M** para prender el medidor
3. Tocar **L** para llenar el tablero, y esperar a que la terminal muestre `tick` cerca de 100 ms (después de llenar, el juego se pone al día durante unos segundos)
4. Tocar **5** para iniciar la simulación y mirar cómo cambian los números a medida que aparecen items

Cada línea del medidor se ve así:
```
items=20 | tick=100 ms (ideal 100) | max=171 ms | x1 | SOBRECARGADO
```
- `tick`: tiempo promedio entre ticks del último segundo. Lo ideal es 100 ms
- `max`: el tick más lento del último segundo. Si es alto, en pantalla se ven tirones
- Estado (según `max`): `ok` hasta 140 ms, `justo` hasta 150 ms, `SOBRECARGADO` más de 150 ms

> [!NOTE]
> Aun con el tablero vacío, `max` ronda los 125 ms: Wollok sólo dispara un tick cuando dibuja un frame (cada ~17 ms), así que esa diferencia es normal.

> [!NOTE]
> La serpiente es el peor caso a propósito: con un solo dispenser regular, todos los items cambian de cinta en el mismo paso. Sirve para comparar antes y después de un cambio, no como una partida real.

El código de las pruebas de carga está en `src/stressTest`.



## TAMAÑOS

- Máquina en el tablero (`<direccion>_game.png` y su animación): 50x50px
- Máquina en el menú (`<direccion>_menu.png`): 100x100px
- Overlay: 200x200px

Todas las machines tienen que tener, para cada una de las 4 rotaciones (`up`, `down`, `left`, `right`):
- `<direccion>_menu.png` (100x100): la imagen del menú
- `<direccion>_game.png` (mismo tamaño que su animación): la máquina quieta
- su animación: `<direccion>.gif` en las máquinas con GIF (la cinta), o carpetas de frames `<direccion>_<accion>/` en las frame a frame (dispenser, cortadora, ensambladora, brazo)

Hay máquinas con su propia convención (por ejemplo, `AutomaticArm`). La guía completa y la lista de casos especiales está en [`assets/README.md`](assets/README.md).