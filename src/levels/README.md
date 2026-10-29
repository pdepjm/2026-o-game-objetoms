# `levels/`

Los niveles del juego: qué máquinas se pueden usar, cuáles vienen colocadas y qué hay que entregar para ganar.

| Archivo | Qué tiene |
|---|---|
| `levelClasses.wlk` | La clase `Level` y los objetivos (`DeliveryGoal` y `noGoal`) |
| `levelsTypes.wlk` | Los niveles concretos: `freePlay` (el modo libre) y `level1` |
| `levelManager.wlk` | `levelManager`: el nivel actual; cargarlo, reiniciarlo, pasar al siguiente y ganar |

> **Quién conoce los niveles:** sólo `levelManager`. El resto del juego le avisa lo que pasa (se entregó algo, el jugador apretó una tecla) y él decide qué hacer. `simulationEngine` y `board` no saben nada de niveles.

## `Level`: sólo datos

Un nivel no hace nada por sí mismo: dice cómo es, y `levelManager` lo usa.

| Atributo | Qué es |
|---|---|
| `name` | Cómo se llama ("Nivel 1"). La info del nivel lo muestra en mayúsculas |
| `availableMachines` | Las máquinas que se pueden colocar: bloques que crean máquinas, como el catálogo de `machineManager` (`{ => new Belt() }`) |
| `availableRecipes` | Las recetas que se pueden elegir en los Assembler (ver `recipeBook` en [`food/README.md`](../food/README.md)). **Obligatorio**: `freePlay` pone `recipeBook.all()` y un nivel sin Assembler pone `[]` (nunca `noRecipe`) |
| `fixedMachines` | Las que el nivel trae colocadas: una lista de `Placement` (ver abajo) |
| `buildZones` | Dónde puede colocar máquinas el jugador: una lista de `Zone` (ver abajo). Opcional: por defecto, todo el tablero (`[wholeBoard]`) |
| `goals` | Los objetivos. **Se gana cuando se cumplen todos** |

Y para hablar con sus objetivos sin que `levelManager` los recorra: `delivered(item)`, `goalsMet()`, `resetGoals()` y `progressLines()` (una línea de texto por objetivo; `noGoal` no suma línea).

## Objetivos

Todo objetivo entiende:

| Método | Para qué |
|---|---|
| `delivered(item)` | Se entera de que se entregó un item en un platito |
| `isMet()` | ¿Se cumplió? |
| `progressText()` | El texto que muestra la info del nivel, por ejemplo `"Papas Fritas: 2/3"` |
| `reset()` | Vuelve a cero |

- **`DeliveryGoal(kind, amount, label)`**: entregar `amount` items de ese kind. Cuenta sólo los del kind pedido (usa `kind.accepts(item)`). `label` es cómo se muestra, porque los kinds no tienen un nombre para mostrar. El texto no pasa de `amount` aunque se entreguen de más.
- **`noGoal`**: el objetivo del modo libre. Nunca se cumple, no cuenta nada y su texto es vacío. Es un objeto nulo: entiende los mismos mensajes, así nadie tiene que preguntar si un nivel tiene objetivo.

Para agregar otro tipo de objetivo (por ejemplo, "sin quemar nada"), alcanza con que entienda esos cuatro mensajes.

## `levelManager`

| Método | Qué hace |
|---|---|
| `start()` | Lo llama `main.wpgm` una sola vez: carga el nivel que toca jugar (`levelToPlay()`; al abrir el juego, el primero) |
| `load(nivel)` | Arma el nivel desde cero (ver el orden abajo) |
| `restart()` | Vuelve a cargar el nivel actual. **Borra también lo que construyó el jugador**: para sólo volver a correr la simulación está la tecla 5 |
| `loadNext()` | Si el nivel está completo y hay uno siguiente, lo carga. Si no, no hace nada (no se saltean niveles). El siguiente se calcula buscando el nivel actual en `levels` (`currentIndex()`), así no se desfasa cuando se llegó con la L |
| `loadFreePlay()` | Carga el modo libre (`freePlay`): todas las máquinas y sin objetivo |
| `toggleFreePlay()` | La tecla L: desde un nivel, va al modo libre; desde el modo libre, vuelve al nivel que toca jugar. **Con la simulación prendida no hace nada** |
| `levelToPlay()` | El nivel que toca jugar: el primero de `levels` que todavía no se ganó. Si se ganaron todos, el último |
| `completedLevels()` | Los niveles que ya se ganaron (los agrega `won()`, sin repetir y nunca el modo libre) |
| `changeLevels(niveles)` | **Sólo para los tests:** usar otros niveles, sin ninguno completado |
| `hasNext()` | ¿Hay un nivel después del actual? Con `freePlay`, no |
| `toggleSimulation()` | Lo que hace la tecla 5 (ver abajo) |
| `delivered(item)` | Lo llama `DeliverySlot` cuando llega algo a un platito |

- `levels` es la lista de niveles **en el orden en que se juegan**. `freePlay` no está en la lista.
- `currentLevel` arranca en `freePlay` y no en `null`: así una entrega o la tecla 5 antes de `start()` no rompen.
- **El progreso (`completedLevels`) se guarda mientras el juego está abierto**: al cerrarlo se pierde.
- **Ir al modo libre y volver no conserva lo construido:** el nivel se vuelve a cargar desde cero, como con la tecla 0.

### El orden de `load`

Primero se apaga y se limpia, después se arma:

1. `simulationEngine.reset()`, `board.clear()` y `toolsManager.reset()`: apaga la simulación, saca las máquinas (los platitos quedan) y deja sin herramienta.
2. Guarda el nivel y lo marca sin completar.
3. `machineManager.changeCatalog(...)` con sus máquinas, y `placeMenu.resetPage()`.
4. Coloca sus máquinas fijas.
5. Pone sus objetivos en cero.
6. `levelInfoMenu.show(nivel)`.

### La tecla 5

Pasa por `levelManager` (no directo al engine) para que el engine no sepa de niveles:

- Si el nivel ya está completo, no hace nada: hay que pasar al siguiente (N) o reiniciar (0).
- Si no, prende o apaga la simulación. **Al apagar, los objetivos vuelven a cero**: se borran los items, así que el progreso también. El objetivo se cumple en una sola corrida.

### Ganar

`delivered(item)` se ejecuta **en medio de un paso de simulación**, y en ese mismo paso pueden quedar otras acciones por correr. Si se apagara la simulación ahí mismo, esas acciones correrían sobre máquinas ya reseteadas. Por eso:

1. `won()` marca el nivel como completo (desde ahí, las entregas no cuentan) y agenda el final para el paso siguiente.
2. `finishLevel()` apaga la simulación (directo al engine, así el progreso **no** se borra) y muestra el mensaje de nivel completo.

## Dónde se puede construir: `buildZones`

Una lista de rectángulos (`Zone`, de `src/board.wlk`), con las coordenadas del tablero (x 5 a 19, y 1 a 13) y los bordes incluidos. El jugador puede colocar una máquina si **todas** sus celdas están en alguna de las zonas; una de 2x2 puede quedar repartida entre dos zonas pegadas.

```wollok
// Sólo se puede construir en la mitad izquierda del tablero y en una franja arriba a la derecha
buildZones = [new Zone(minX = 5, maxX = 12, minY = 1, maxY = 13), new Zone(minX = 13, maxX = 19, minY = 11, maxY = 13)]
```

- Las celdas fuera de las zonas se ven oscurecidas, para que el jugador sepa dónde puede construir.
- **Las máquinas fijas no tienen esta restricción:** se pueden poner fuera de las zonas (por ejemplo, un Dispenser en un rincón bloqueado).
- `Zone` está en `board.wlk`: `levelsTypes.wlk` ya lo importa (`import board.*`).

## Máquinas fijas: `Placement`

Una máquina que trae el nivel: dónde va (`position`: `game.at(x, y)` o `CellPosition`) y cómo se crea (`factory`, un bloque). Por defecto queda **bloqueada** (`locked = true`): el jugador no la puede borrar ni rotar, pero sí editar. Con `locked = false`, la coloca el nivel pero el jugador la puede mover.

```wollok
new Placement(position = game.at(5, 7), factory = { => new Dispenser(direction = right, availableKinds = [potato]) })
```

- Pasarle la dirección al crearla (`direction = right`): si no, toma la que esté elegida en el menú.
- Al reiniciar o cambiar de nivel, `board.clear()` también saca las máquinas bloqueadas, y el nivel las vuelve a colocar.

## Agregar un nivel

1. En `levelsTypes.wlk`, un objeto que herede de `Level`, con la misma forma que `level1`:

   ```wollok
   object level2 inherits Level(
   	name = "Nivel 2",
   	availableMachines = [{ => new Belt() }, { => new Oven() }],
   	availableRecipes = [],
   	fixedMachines = [new Placement(position = game.at(5, 7), factory = { => new Dispenser(direction = right, availableKinds = [meat]) })],
   	goals = [new DeliveryGoal(kind = cookedMeat, amount = 2, label = "Carnes")]
   ) {}
   ```

2. Importar las máquinas que use (`levelsTypes.wlk` es el único archivo de niveles que conoce las máquinas concretas).
3. Agregarlo a `levels` en `levelManager`, en el lugar donde se juega.
4. **Sin comentarios dentro de las listas** (por ejemplo, entre los bloques de `availableMachines`): Wollok no puede leer el archivo y todo el juego falla con `Could not resolve reference to level1`. Los comentarios van arriba del atributo.
5. Que se pueda ganar con lo que ofrece, y **sólo** de la forma pensada: por ejemplo, la freidora necesita brazos, y para sacar papas fritas hace falta el brazo inteligente (el común se las lleva antes de freírlas). Si el Dispenser puede largar el resultado final (papas fritas), el nivel se gana sin procesar nada: limitarlo con `availableKinds`.
6. Las recetas (`availableRecipes`) tienen que poder armarse con los ingredientes que ofrece, e incluir los platos que piden sus objetivos.
7. Textos cortos: la zona de la info del nivel mide 5 celdas, y un nivel muestra como máximo 3 objetivos (ver [`menu/README.md`](../menu/README.md#levelinfomenuwlk)).
8. **Correr los tests.** "tests de todos los niveles" (en `test/levelManagerTest.wtest`) carga cada nivel de `levels` y el modo libre, y dice cuáles tienen un problema:
   - **no carga**: una máquina fija fuera del tablero (las de 2x2, como el Assembler, ocupan una celda más a la derecha y una más arriba de su posición) o encima de otra. En el juego, eso hace fallar el nivel al cargarlo;
   - **sus máquinas fijas no quedan en su lugar**;
   - **`availableRecipes` tiene algo que no es una receta del juego**: por ejemplo un plato (`cheeseBurger` en vez de `cheeseBurgerRecipe`) o `noRecipe`.

> [!NOTE]
> El plan completo de los niveles (incluidas las fases que faltan: máquinas fijas, tutorial y energía) está en [`docs/Plan-Implementacion-Niveles.md`](../../docs/Plan-Implementacion-Niveles.md).
