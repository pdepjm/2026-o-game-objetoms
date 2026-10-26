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
| [`src/levels/README.md`](src/levels/README.md) | Niveles (en construcción): por ahora, los objetivos |
| [`Plan-Implementacion-Niveles.md`](docs/Plan-Implementacion-Niveles.md) | **El plan para implementar los niveles**, por fases y con checklist |
| [`assets/README.md`](assets/README.md) | Cómo nombrar y ubicar las imágenes |
| [`assets/machines/AutomaticArm/README.md`](assets/machines/AutomaticArm/README.md) | Las imágenes del brazo automático (caso especial) |
| [`Diagrama de clase`](https://lucid.app/lucidchart/a3679667-4ca6-4fa7-b44c-518a1db91a84/edit?invitationId=inv_417f2848-4415-43b1-b901-ad3450eb3ba1) |

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

## TAMAÑOS

- Máquina en el tablero (`<direccion>_game.png` y su animación): 50x50px
- Máquina en el menú (`<direccion>_menu.png`): 100x100px
- Overlay: 200x200px

Todas las machines tienen que tener, para cada una de las 4 rotaciones (`up`, `down`, `left`, `right`):
- `<direccion>_menu.png` (100x100): la imagen del menú
- `<direccion>_game.png` (mismo tamaño que su animación): la máquina quieta
- su animación: `<direccion>.gif` en las máquinas con GIF (la cinta, el horno), o carpetas de frames `<direccion>_<accion>/` en las frame a frame (dispenser, cortadora, ensambladora, brazo)

Hay máquinas con su propia convención (por ejemplo, `AutomaticArm`). La guía completa y la lista de casos especiales está en [`assets/README.md`](assets/README.md).