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




## Controles

> [!NOTE]
> **Modo de herramientas:** El juego inicia sin ninguna herramienta seleccionada. Presionar la tecla de una herramienta la activa, y volver a presionarla la deselecciona (vuelve a `null`).
> Mientras la simulación está corriendo (Play), la edición del tablero queda bloqueada para proteger la integridad del circuito.

## - BINDING
| Control | Herramienta | Acción al hacer click en el tablero |  
|:---:|---|---|
| <kbd>Click</kbd> | **Interactuar** | Aplica la herramienta activa en el tablero o selecciona opciones en el menú lateral |  


### - TOOLS (MENÚ)
| Tecla | Herramienta | Comportamiento |  
|:---:|---|---|
| <kbd>Z</kbd> | **Construir (Place)** | Coloca la máquina seleccionada en el menú con la orientación actual |
| <kbd>X</kbd> | **Configurar (Edit)** | Abre en el menú lateral los ajustes, velocidades y filtros de la máquina clickeada |
| <kbd>C</kbd> | **Herramienta Rotar** | Selecciona la herramienta para rotar en sentido horario máquinas **ya colocadas** en el tablero |
| <kbd>V</kbd> | **Demoler (Delete)** | Quita la máquina clickeada del tablero (junto con los items que contenga) |


### - ORIENTACIÓN (Antes de colocar en tablero)
| Tecla | Acción | Comportamiento |
|:---:|---|---|
| <kbd>W</kbd> | **Orientar Arriba** | Rota hacia arriba la máquina a colocar (afecta a la próxima máquina) |
| <kbd>A</kbd> | **Orientar Izquierda** | Rota hacia la izquierda la máquina a colocar |
| <kbd>S</kbd> | **Orientar Abajo** | Rota hacia abajo la máquina a colocar |
| <kbd>D</kbd> | **Orientar Derecha** | Rota hacia la derecha la máquina a colocar |

### - PAGES DEL MENÚ
| Tecla | Acción | Descripción |
|:---:|---|---|
| <kbd>Q</kbd> | **Página Anterior** | Retrocede una página en el catálogo de máquinas del menú |
| <kbd>E</kbd> | **Página Siguiente** | Avanza una página en el catálogo de máquinas del menú |  


### - Control de Simulación
| Tecla | Acción | Descripción |
|:---:|---|---|
| <kbd>Espacio</kbd> | **Play / Pausa** | Inicia o detiene la simulación *(en pausa se construye libremente; al pausar se limpian los items sueltos)* |
| <kbd>1</kbd> | **Velocidad x1** | Velocidad estándar (1 paso por tick de 100 ms) |
| <kbd>2</kbd> | **Velocidad x2** | Velocidad rápida (2 pasos por tick) |
| <kbd>3</kbd> | **Velocidad x3** | Velocidad ultra rápida (3 pasos por tick) |



## TAMAÑOS

- Máquina en el tablero (`<direccion>_game.png` y su animación): 50x50px
- Máquina en el menú (`<direccion>_menu.png`): 100x100px
- Overlay: 200x200px

Todas las machines tienen que tener, para cada una de las 4 rotaciones (`up`, `down`, `left`, `right`):
- `<direccion>_menu.png` (100x100): la imagen del menú
- `<direccion>_game.png` (mismo tamaño que su animación): la máquina quieta
- su animación: `<direccion>.gif` en las máquinas con GIF (la cinta, el horno), o carpetas de frames `<direccion>_<accion>/` en las frame a frame (dispenser, cortadora, ensambladora, brazo)

Hay máquinas con su propia convención (por ejemplo, `AutomaticArm`). La guía completa y la lista de casos especiales está en [`assets/README.md`](assets/README.md).