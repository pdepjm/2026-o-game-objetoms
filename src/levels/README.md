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
| `fixedMachines` | Las que el nivel trae colocadas. Por ahora siempre vacío (llegan en la fase 4 del plan) |
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
| `start()` | Lo llama `main.wpgm` una sola vez: carga el primer nivel de `levels` |
| `load(nivel)` | Arma el nivel desde cero (ver el orden abajo) |
| `restart()` | Vuelve a cargar el nivel actual. **Borra también lo que construyó el jugador**: para sólo volver a correr la simulación está la tecla 5 |
| `loadNext()` | Si el nivel está completo y hay uno siguiente, lo carga. Si no, no hace nada (no se saltean niveles) |
| `loadFreePlay()` | Carga el modo libre (`freePlay`): todas las máquinas y sin objetivo |
| `hasNext()` | ¿Hay un nivel después del actual? Con `freePlay`, no |
| `toggleSimulation()` | Lo que hace la tecla 5 (ver abajo) |
| `delivered(item)` | Lo llama `DeliverySlot` cuando llega algo a un platito |

- `levels` es la lista de niveles **en el orden en que se juegan**. `freePlay` no está en la lista.
- `currentLevel` arranca en `freePlay` y no en `null`: así una entrega o la tecla 5 antes de `start()` no rompen.

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

## Agregar un nivel

1. En `levelsTypes.wlk`, un objeto que herede de `Level`, con la misma forma que `level1`:

   ```wollok
   object level2 inherits Level(
   	name = "Nivel 2",
   	availableMachines = [{ => new Belt() }, { => new Dispenser() }, { => new Oven() }],
   	goals = [new DeliveryGoal(kind = cookedMeat, amount = 2, label = "Carnes")]
   ) {}
   ```

2. Importar las máquinas que use (`levelsTypes.wlk` es el único archivo de niveles que conoce las máquinas concretas).
3. Agregarlo a `levels` en `levelManager`, en el lugar donde se juega.
4. **Sin comentarios dentro de las listas** (por ejemplo, entre los bloques de `availableMachines`): Wollok no puede leer el archivo y todo el juego falla con `Could not resolve reference to level1`. Los comentarios van arriba del atributo.
5. Que se pueda ganar con lo que ofrece: por ejemplo, la freidora necesita brazos, y para sacar papas fritas hace falta el brazo inteligente (el común se las lleva antes de freírlas).
6. Textos cortos: la zona de la info del nivel mide 5 celdas, y un nivel muestra como máximo 3 objetivos (ver [`menu/README.md`](../menu/README.md#levelinfomenuwlk)).

> [!NOTE]
> El plan completo de los niveles (incluidas las fases que faltan: máquinas fijas, tutorial y energía) está en [`docs/Plan-Implementacion-Niveles.md`](../../docs/Plan-Implementacion-Niveles.md).
