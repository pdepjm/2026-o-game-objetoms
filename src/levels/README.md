# `levels/`

Los niveles del juego: qué máquinas se pueden usar, cuáles vienen colocadas y qué hay que entregar para ganar.

| Archivo | Qué tiene |
|---|---|
| `levelClasses.wlk` | La clase `Level` y los objetivos (`DeliveryGoal` y `noGoal`) |
| `levelsTypes.wlk` | Los niveles concretos: `freePlay` (el modo libre), los tutoriales `tutorialLevel` (papas fritas) y `hotDogTutorialLevel` (panchos), y los niveles `level1` (ensaladas), `level2` (hamburguesas) y `level3` (desayunos y pizzas) |
| `levelManager.wlk` | `levelManager`: el nivel actual; cargarlo, reiniciarlo, pasar al siguiente y ganar |
| `tutorial.wlk` | Lo que el juego le avisa al tutorial de un nivel (`Tutorial`, `noTutorial`) y los tutoriales por pasos (`StepTutorial`) |

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
| `tutorial` | El tutorial que lo acompaña (ver [Tutorial](#tutorial)). Opcional: por defecto, `noTutorial` |

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

## Tutorial

Un nivel puede traer un tutorial (`tutorial = ...`). El juego le avisa lo que pasa, le pregunta qué deja hacer, muestra su mensaje debajo de la info del nivel y dibuja sus indicadores sobre el tablero (`tutorialMarks`, en `src/menu/`). **Todo pasa por `levelManager`**: las herramientas, `toolsManager` y `editMenu` le avisan a `levelManager`, y él le reenvía al tutorial del nivel actual y vuelve a dibujar el mensaje. `board` y `simulationEngine` no avisan nada.

| Mensaje | Cuándo |
|---|---|
| `onLevelLoaded(nivel)` | Al final de `levelManager.load` (también al reiniciar) |
| `onToolSelected(herramienta)` | `toolsManager.select` (llega `null` si se deselecciona) |
| `onMachinePlaced(maquina)` | `place`, después de colocarla |
| `onMachineRemoved(maquina)` | `delete`, **después** de sacarla (se guarda la máquina antes, así el tutorial ve el tablero sin ella) |
| `onMachineRotated(maquina)` | `rotate`, después de rotarla |
| `onSettingChanged(maquina, setting)` | `editMenu.onClick`, después de elegir la opción |
| `onSimulationToggled(prendida)` | `levelManager.toggleSimulation` (la tecla 5 y la barra espaciadora) |
| `onDelivered(item)` | `levelManager.delivered` |
| `onLevelWon(nivel)` | `levelManager.won` |
| `onContinue()` | La tecla Enter (`levelManager.continueTutorial`): seguir después de una explicación |
| `allowsTool(herramienta, pos)` | `toolsManager.onClick`, antes de usar la herramienta en el tablero. Si es `false`, el click no hace nada |
| `allowsSimulationToggle()` | `levelManager.toggleSimulation`. Si es `false`, no prende ni apaga |
| `messageLines()` | Después de cada aviso: las líneas del mensaje (de hasta `levelInfoMenu.tutorialMaxLength()`, 16 caracteres) |
| `stepLabel()` | Después de cada aviso: dónde va el jugador, arriba del mensaje (`StepTutorial`: `PASO 2 DE 8`). Vacío: no se muestra |
| `messageKeys()` | Después de cada aviso: las teclas que acompañan al mensaje (`"place"`, `"continue"`…), que se dibujan con el estilo de las teclas del fondo. **Entre líneas y teclas, como máximo `tutorialMaxLines()` (6)**: lo revisa un test |
| `allMessages()` | Todos los mensajes que puede mostrar. Sólo para los tests (ver abajo) |
| `targetCells()` | Después de cada aviso: las celdas donde el jugador tiene que hacer algo. Se marcan con un recuadro amarillo que late |
| `pointedCells()` | Después de cada aviso: las celdas de las máquinas que explica el mensaje. Se señala la máquina con una flecha naranja arriba (centrada, si es de 2x2) |

- **`TutorialEvents`** tiene los diez eventos sin hacer nada. La entienden los tutoriales y también los pasos.
- **`Tutorial`** hereda de ella y agrega los permisos, el mensaje y los indicadores, dejando hacer todo; **`noTutorial`** es el objeto que usan los niveles sin tutorial. Un tutorial nuevo hereda de `Tutorial` y sobrescribe sólo lo que necesita.
- **`StepTutorial(steps, finishedLines)`**: una lista de pasos en orden. El paso actual es **el primero que todavía no se cumplió**. La mayoría de los pasos miran el tablero: no importa el orden en que el jugador haga las cosas, y si deshace algo vuelve a ese paso. Cada evento se le reenvía al paso actual, para los pasos que dependen de algo que no se ve en el tablero. Al cargar o reiniciar el nivel, todos los pasos vuelven a empezar (`reset()`). Al ganar muestra `finishedLines` y deja hacer todo.
  - Lo normal es que el último paso no se cumpla solo (un `TutorialStep`, "esperá a que lleguen las papas"). Si igual se cumplen todos sin ganar, se queda mostrando el último.

### Los pasos

Todos tienen `lines`, y opcionalmente:

| Atributo | Qué es |
|---|---|
| `cells` | Las celdas donde deja **colocar, borrar y rotar** (en ningún otro lado). Se marcan con el recuadro. Para una máquina de 2x2, sus cuatro celdas |
| `pointsAt` | Las celdas de las máquinas de las que habla el mensaje. Se señalan con la flecha: así el texto puede decir "de la flecha" en vez de "a la derecha de las papas" |
| `allowsSimulation` | Si deja prender y apagar la simulación (por defecto, no) |
| `keys` | Las teclas que explica el paso, por nombre: `place` (Z), `edit` (X), `rotate` (C), `up` (W), `left` (A), `continue` (Enter), `start` y `stop` (Espacio). Se muestran como las teclas del fondo, así el texto no dice "Z:". Para una tecla nueva, agregarla en `HINTS` de `assets/menu/makeKeyHints.py` y correrlo |

**Un paso o pide hacer algo (`cells`, el recuadro) o explica (`pointsAt`, la flecha), no las dos cosas:** si tiene `cells`, la flecha no se muestra. Para explicar una máquina y después pedir otra, dos pasos: un `ExplainStep` y el que pide.

Fuera de sus `cells`, un paso deja **editar cualquier máquina, también las fijas**: el jugador tiene que poder configurarlas (por ejemplo, qué larga un Dispenser).

| Paso | Se cumple… |
|---|---|
| `TutorialStep` | Nunca. Para el último |
| `MachineStep(cells, condition)` | Cuando en todas sus celdas hay una máquina que cumple `condition` (`{ machine => machine.name() == "Belt" }`). Si son las cuatro celdas de una de 2x2, es la misma máquina en todas |
| `RunStep` | Mientras la simulación está prendida (y deja prenderla) |
| `ExplainStep` | Al apretar Enter. Para explicar una máquina (con `pointsAt`) antes del paso que pide algo. **Queda cumplido**: si el jugador vuelve a un paso anterior, no se repite |
| `ToolStep(tool)` | Al elegir esa herramienta. **Queda cumplido** aunque después se elija otra |

Para un paso que se cumpla con otro evento ("cambiá un setting", "entregá algo"), una subclase de `EventStep` que sobrescriba ese evento y llame a `happened()`, como `ToolStep`:

```wollok
class SettingStep inherits EventStep {
	override method onSettingChanged(machine, setting) { self.happened() }
}
```

**Las condiciones le preguntan a la máquina, no a cómo guarda las cosas.** Por ejemplo, el paso de editar el brazo inteligente usa `exitSideFor(kind)` (por dónde saldría ese ingrediente, o `null`) y no el orden de sus salidas.

### Agregar un tutorial

1. Un `Level` con `tutorial = new StepTutorial(steps = [...], finishedLines = [...])`, en `levelsTypes.wlk`, y agregarlo a `levels` en `levelManager`.
2. **Las celdas, en un solo lugar:** un objeto con las celdas del armado, como `friesTutorialCells`, que usen tanto las máquinas fijas y la zona de construcción como los pasos. Así, para mover el armado se cambia una sola cosa.
3. Textos de hasta 16 caracteres por línea y 6 líneas. **"tests de todos los niveles" lo revisa** ("los mensajes de los tutoriales entran en el panel").
4. Un test que lo juegue entero, como "armado como dice el tutorial, entrega las papas fritas y se gana".

### Saltear los tutoriales

En los tutoriales (los niveles con `tutorial`: `level.hasTutorial()`), la info del nivel muestra el botón **T SALTEAR TUTORIAL**, que se clickea o se aprieta con T. `levelManager.skipTutorial()` da por hechos **todos** los tutoriales y carga el primer nivel que toca jugar. Fuera de un tutorial no hace nada.

### `tutorialLevel` ("Tutorial 1"): papas fritas

El primer nivel. Trae armada la línea de la fila 7 salvo cuatro máquinas (las celdas están en `friesTutorialCells`), y se juega así. Antes de cada máquina, una explicación señala con la flecha la máquina de la que viene (se sigue con Enter); después, el recuadro marca dónde va:

1. Explica el Dispenser; colocar una cinta en (6, 7).
2. Explica la cinta; la cortadora en (7, 7).
3. Explica el brazo común fijo de (9, 7); la freidora en (10, 7), donde él deja las papas.
4. Explica la freidora; el brazo inteligente en (11, 7).
5. Rotarlo (C) hasta que agarre de la freidora.
6. Prender la simulación (5) y esperar 2 papas fritas en el platito. El brazo inteligente sólo agarra ingredientes ya procesados, así que espera a que la papa se fría: no hace falta editarlo.

Para cambiarlo, los tests de `test/tutorialTest.wtest` lo juegan entero ("armado como dice el tutorial, entrega las papas fritas y se gana").

### `hotDogTutorialLevel` ("Tutorial 2"): panchos

El segundo. Enseña a configurar un Dispenser, el horno, el ensamblador y con qué trabaja un brazo. Las celdas están en `hotDogTutorialCells`: dos líneas que llegan al ensamblador, las salchichas por la fila 10 y los panes por la fila 8. Ningún nivel se arma igual: otro plato, y es el único con el brazo común trayendo del horno.

1. Explica que hacen falta pan y salchicha, y que el Dispenser de abajo larga salchichas. **Editarlo (X) para que largue pan.**
2. Explica el Dispenser de las salchichas, que hay que cocinarlas; **colocar el horno**.
3. Explica la cinta que sube los panes cortados al ensamblador; **colocar el ensamblador apuntando arriba (W)**, en sus cuatro celdas.
4. **Editar el ensamblador** y elegir la receta del pancho (arranca con la sopa de tomate).
5. Explica el brazo, en dos pasos: toma de las cintas, de la freidora y de lo que le entregan (señala el horno), y lo deja en cualquier máquina (señala el ensamblador).
6. **Colocar el brazo mirando a la izquierda (A)**, entre el horno y el ensamblador.
7. Prender la simulación y esperar 2 panchos.

Lo juega entero "armado como dice el tutorial, entrega los panchos y se gana".

> [!NOTE]
> El plan completo de los niveles (incluida la fase que falta: energía) está en [`docs/Plan-Implementacion-Niveles.md`](../../docs/Plan-Implementacion-Niveles.md).

## Los niveles

Van de menos a más difícil. Todos tienen los Dispensers fijos a la izquierda, y el resto lo arma el jugador. `test/levelSolutionsTest.wtest` arma una forma de ganar cada uno: si un cambio hace que un nivel no se pueda ganar, falla ahí.

| Nivel | Plato | Qué tiene de nuevo |
|---|---|---|
| `level1` | 3 ensaladas | Dos ingredientes que sólo hay que cortar. Los Dispensers ya largan lechuga y tomate. Hay que elegir la receta (también ofrece la sopa de tomate) |
| `level2` | 3 hamburguesas | Cuatro ingredientes y dos procesos (cortar y cocinar). Los cuatro Dispensers ofrecen todo: hay que elegir qué larga cada uno, y que cada ingrediente llegue al ensamblador por su lado (el que sobra traba a los demás) |
| `level3` | 2 desayunos y 2 pizzas | Dos platos a la vez, con dos ensambladores y los dos platitos. El huevo se fríe: la freidora necesita un brazo común que se lo lleve y uno inteligente que lo saque frito. El queso de la pizza se corta una sola vez. **El tablero está limitado**: la pizza se arma arriba (filas 7 a 10) y el desayuno abajo (filas 2 a 5), separados por la fila 6, cada uno con un pasillo angosto hasta su platito |

