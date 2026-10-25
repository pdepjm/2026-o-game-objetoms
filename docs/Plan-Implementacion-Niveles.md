# Roadmap: niveles

Plan para pasar del modo libre de hoy (todas las máquinas, sin objetivo) a **niveles**: cada uno con sus máquinas disponibles, máquinas ya colocadas, un objetivo de entrega y, más adelante, un tutorial.

> [!TIP]
> **Cómo usar este archivo:** al terminar una fase, tacharla en el [estado general](#estado-general) cambiando `- [ ]` por `- [x]`, en el mismo commit que la termina. Si una tarea cambia de idea, actualizarla acá antes de programarla.

## Estado general

- [ ] [Fase 0: Estabilidad](#fase-0-estabilidad)
- [ ] [Fase 1: Poder reiniciar todo](#fase-1-poder-reiniciar-todo)
- [ ] [Fase 2: Puntos de entrega y objetivos](#fase-2-puntos-de-entrega-y-objetivos)
- [ ] [Fase 3: `Level` y `levelManager`](#fase-3-level-y-levelmanager) ← con 0 a 3 ya hay un primer nivel jugable
- [ ] [Fase 4: Máquinas fijas y parametrizadas](#fase-4-máquinas-fijas-y-parametrizadas)
- [ ] [Fase 5: Entrada para el tutorial](#fase-5-entrada-para-el-tutorial)
- [ ] [Fase 6: Energía](#fase-6-energía) (opcional)

## La idea

**`levelManager` es el único que conoce los niveles**, igual que `machineManager` es el único que conoce las máquinas concretas. Un `Level` es sólo datos: qué máquinas se pueden usar, cuáles vienen colocadas, qué hay que lograr y qué tutorial lo acompaña. El tutorial es un objeto opcional del nivel que recibe eventos del juego; hoy es `noTutorial`, que no hace nada.

```
userController / userTools / simulationEngine / DeliverySlot
              │  (eventos: colocó, borró, prendió, entregó…)
              ▼
        levelManager ──▶ currentLevel ──▶ goal      (¿se cumplió?)
              │                     └──▶ tutorial  (hoy noTutorial)
              ├──▶ board / simulationEngine / machineManager  (cargar y reiniciar)
              └──▶ levelInfoMenu                          (mostrar el progreso)
```

Cada fase se puede commitear y testear por separado. **Cada fase actualiza los README de lo que toca** (no se deja la documentación para el final).

---

## Fase 0: Estabilidad

Lo que hoy rompe o se ve roto, antes de construir encima.

- **La agenda acepta demoras largas.** Hoy `simulationEngine.after` da error con 64 pasos o más (`slotCount`), y el Dispenser en velocidad *Lenta* pide 100: **prender la simulación con un Dispenser lento tira error**. Cada acción guarda el paso en el que vence; al pasar por su casillero se ejecutan sólo las que vencen en ese paso y las demás esperan la próxima vuelta. Así se saca el límite sin volver al `Dictionary`.
  - Test: un Dispenser en *Lenta* prende la simulación sin error y larga su item en el paso 100.
  - Actualizar el comentario de `slotCount` (dice que la demora más larga es la del dispenser, 10 pasos).
- **Imágenes de la freidora** (`assets/machines/Fryer/`). Mientras tanto, se puede usar `no_texture.png`.
- **Imagen de la papa quemada** (`assets/food/Ingredients/potatoes/potato_burnt.png` y su `.svg`).

## Fase 1: Poder reiniciar todo

Sin esto no se puede cargar un nivel ni volver a empezarlo.

- `board.machines()` y `board.clear()`: hace `pop` de cada máquina (que ya se lleva sus items). **No** saca los puntos de entrega (ver fase 2).
- `simulationEngine.reset()`: `stop()` si está prendida, vaciar `simulatedObjects` (salvo los puntos de entrega) y volver la velocidad a 1.
- `machineManager`:
  - `machines` pasa de `const` a `var`.
  - `catalog(factories)`: reemplaza la lista y vuelve `selectedMachine` a la primera.
  - `allMachines`: la lista completa de hoy, para el modo libre.
- `placeMenu.resetPage()`: vuelve a la página 0 y redibuja si está visible.
- `toolsManager.reset()`: sin herramienta elegida y dirección `right`.
- Tests:
  - `board.clear()` deja el tablero vacío y sin visuals.
  - Cambiar el catálogo arranca en la página 0 con la primera máquina elegida.

## Fase 2: Puntos de entrega y objetivos

La comida se entrega en **los dos platitos del fondo**, arriba del tablero: las celdas **(16, 14) y (17, 14)**, fuera de `inBoard` (que va de y 1 a 13). Una cinta o un brazo que apunta hacia un platito le entrega el plato.

### `DeliverySlot`

- Clase `DeliverySlot inherits Machine` (en `machines/types/deliverySlot.wlk`). Es una máquina para que `tryPush`, `canReceiveFrom` y los brazos le entreguen sin cambios:
  - `nextMachine()` = `null`: no entrega a nadie.
  - `onArrived(item)`: lo saca del inventario (`inventory.release`), del juego (`simulationEngine.removeItem`) y avisa `levelManager.delivered(item)`.
  - El plato viaja hasta el platito con el `onReceive` por defecto.
  - **No se agrega como visual**: el fondo ya dibuja los cubiertos.
  - Se crea con `position` y `direction = down` explícitos (no con la dirección elegida en el menú).
- `board` los conoce desde el principio, en una lista `deliverySlots`:
  - `machineAt(pos)`: si está en el tablero busca en la grilla; si no, entre los `deliverySlots`.
  - `inBoard` **no cambia**: así `canPlace` impide colocar ahí, y `toolsManager` ignora los clicks (no se pueden borrar ni rotar).
  - `board.clear()` y `board.machines()` no los incluyen: son parte del escenario, no del nivel.
- Se registran una sola vez en `simulationEngine` (`addSimulatedObject`), para que `stop()` los resetee y `allItems()` vea el plato mientras viaja.
- Tests:
  - Una cinta en (16, 13) apuntando hacia arriba entrega en el platito y el item desaparece.
  - Un brazo cuya salida da al platito también entrega.
  - No se puede colocar nada en (16, 14).
  - `board.clear()` deja los dos platitos.

### Objetivos

En `levels/goals.wlk`. Contrato de un objetivo:

| Método | Para qué |
|---|---|
| `delivered(item)` | Se entera de que se entregó algo |
| `isMet()` | ¿Se cumplió? |
| `progressText()` | Lo que muestra la info del nivel ("Hamburguesas: 2/5") |
| `reset()` | Vuelve a cero al apagar la simulación |

- `DeliveryGoal(kind, amount)`: entregar `amount` items de ese kind.
- `AllGoals(goals)`: se cumple cuando se cumplen todos (para combinar sin cambiar `Level`).
- `noGoal`: el objetivo del modo libre (nunca se cumple, `progressText()` vacío). Lo usa la [fase 3](#level-sólo-datos).
- Tests: entregar 5 hamburguesas cumple `DeliveryGoal(kind = burger, amount = 5)`; `reset()` lo vuelve a cero.

## Fase 3: `Level` y `levelManager`

El corazón de los niveles: qué es un nivel, quién los carga y cómo se gana. **Necesita las fases 1 y 2** (reiniciar el estado, `DeliverySlot` y los objetivos).

### Archivos

| Archivo | Qué tiene |
|---|---|
| `levels/levelClasses.wlk` | La clase `Level` |
| `levels/levels.wlk` | Los niveles concretos (`freePlay`, `level1`, ...), como objetos bien conocidos |
| `levels/levelManager.wlk` | `levelManager`: el nivel actual, cargarlo, reiniciarlo, pasar al siguiente y ganar |
| `menu/levelInfoMenu.wlk` | Hoy vacío: pasa a mostrar la información del nivel |

- Borrar `levels/niveles.wlk` (`Nivel` vacío): se reemplaza por `Level`, en inglés como el resto del código.
- **Imports circulares:** `DeliverySlot` importa `levelManager`, y `levelManager` importa (indirectamente) las máquinas. Verificar al principio que Wollok lo resuelve; si no, `levelManager` se le pasa al `DeliverySlot` al crearlo (`const listener`).

### `Level`: sólo datos

Un nivel no hace nada por sí mismo: dice cómo es, y `levelManager` lo usa.

```wollok
class Level {
	const property name
	const property availableMachines          // factories, como el catálogo de machineManager
	const property fixedMachines = []         // las coloca el nivel (las clases de Placement llegan en la fase 4)
	const property goal

	// Coloca las máquinas que trae el nivel. Con fixedMachines vacío (hasta la fase 4) no hace nada.
	method placeFixedMachines() {
		fixedMachines.forEach({ placement => board.push(placement.position(), placement.create()) })
	}
}
```

- El tutorial (`const property tutorial = noTutorial`) se agrega en la [fase 5](#fase-5-entrada-para-el-tutorial), no antes.
- Los niveles concretos son objetos, con la misma forma que `burgerRecipe`:

  ```wollok
  // Modo libre: todas las máquinas y sin objetivo, para probar (es el juego de hoy)
  object freePlay inherits Level(name = "Libre", availableMachines = machineManager.allMachines(), goal = noGoal) {}

  object level1 inherits Level(
  	name = "Nivel 1",
  	availableMachines = [{ => new Belt() }, { => new Dispenser() }],
  	goal = new DeliveryGoal(kind = friedPotato, amount = 3)
  ) {}
  ```

- `noGoal` (en `levels/goals.wlk`): el objetivo del modo libre. Nunca se cumple, no cuenta nada y su `progressText()` es vacío. Es un objeto nulo: así `levelManager` no pregunta `if (goal != null)` en ningún lado.

### `levelManager`

Estado: `currentLevel` (el nivel cargado) y `completed` (si ya se cumplió el objetivo). La lista `levels` define el orden en que se juegan, como `machines` define el orden del menú.

| Método | Qué hace |
|---|---|
| `start()` | Lo llama `main.wpgm` una sola vez: carga el primer nivel. **Mientras no haya niveles reales, carga `freePlay`**, así el juego se sigue comportando como hoy |
| `load(level)` | Arma el nivel desde cero (ver el orden abajo) |
| `restart()` | `load(currentLevel)`. **Borra también lo que construyó el jugador**: para sólo volver a correr la simulación está la tecla 5 |
| `next()` | Si `completed` y hay un nivel siguiente, lo carga. Si no se completó, no hace nada (para no saltearse niveles) |
| `hasNext()` | ¿Hay un nivel después del actual? |
| `toggleSimulation()` | Lo que hace la tecla 5 (ver abajo) |
| `delivered(item)` | Lo llama `DeliverySlot`: se lo pasa al objetivo, actualiza la info y, si se cumplió, `won()` |
| `won()` | El objetivo se cumplió (ver [Ganar](#ganar)) |
| `currentLevel()` | El nivel cargado (para el menú y los tests) |

**Orden de `load(level)`.** Importa: primero se apaga y limpia, después se arma.

1. `simulationEngine.reset()`: apaga la simulación (si estaba prendida) y saca los items.
2. `board.clear()`: saca las máquinas (no los `DeliverySlot`).
3. `toolsManager.reset()`: sin herramienta elegida y dirección `right`.
4. `currentLevel = level` y `completed = false`.
5. `machineManager.catalog(level.availableMachines())` y `placeMenu.resetPage()`.
6. `level.placeFixedMachines()`.
7. `level.goal().reset()`.
8. `levelInfoMenu.show(level)`.

**La tecla 5 pasa por `levelManager`.** Hoy `userController` llama directo a `simulationEngine.toggle()`. Pasa a llamar a `levelManager.toggleSimulation()`, que:

- si el nivel ya está completo, no hace nada (hay que pasar al siguiente o reiniciar);
- llama a `simulationEngine.toggle()`;
- si la apagó, hace `goal.reset()` y actualiza la info: al apagar se borran los items, así que el progreso también.

Así `simulationEngine` sigue sin saber nada de niveles, y en la fase 5 éste es el lugar donde se avisa al tutorial.

### Ganar

`delivered(item)` se ejecuta **en medio de un paso de simulación** (dentro del `onArrived` del `DeliverySlot`), y en ese mismo paso pueden quedar otras acciones por correr. Por eso `won()` no apaga la simulación en el momento:

1. `completed = true` (desde acá, las entregas que lleguen ya no cuentan).
2. Agenda el final para el paso siguiente: `simulationEngine.after(1, { self.finishLevel() })`.
3. `finishLevel()`: `simulationEngine.stop()` y `levelInfoMenu.showCompleted(self.hasNext())`.

En el último nivel no hay siguiente: la info muestra que se terminó el juego (ver [decisiones](#decisiones-abiertas)).

### `levelInfoMenu`

Usa la zona `levelInfoZone` (x 0 a 4, y 1 a 14: 5 celdas de ancho). Se dibuja de arriba hacia abajo, una línea por vez, como `editMenu`:

```
NIVEL 1                 ← nombre del nivel
OBJETIVO
Papas fritas: 2/3       ← goal.progressText()

¡Nivel completo!        ← sólo al ganar
N: siguiente            ← o "0: reiniciar" si no hay siguiente
```

| Método | Cuándo |
|---|---|
| `show(level)` | Al cargar un nivel: borra lo anterior y dibuja todo |
| `refresh()` | Cambió el progreso (una entrega, o se apagó la simulación): redibuja sólo el texto del objetivo |
| `showCompleted(hasNext)` | Al ganar: agrega el mensaje y la tecla para seguir |

- **Sólo se actualiza en esos eventos**, nunca en cada frame (ver la regla de rendimiento en [`src/README.md`](src/README.md#convenciones)).
- Reusa `MenuText`, que hoy está en `editMenu.wlk`. Conviene moverlo a un archivo propio (`menu/menuText.wlk`) para que los dos menús no dependan uno del otro.
- Wollok no corta el texto en varias líneas: con 5 celdas de ancho, los textos tienen que ser cortos.
- Con `freePlay` muestra sólo "Libre".

### Teclas

En `userController`. Las letras de hoy son Q, E, P, X, Z, R, W, A, S, D, y los números 1, 2, 3 y 5. **La R ya es rotar**, así que reiniciar tiene que ser otra (ver [decisiones](#decisiones-abiertas)). Propuesta:

| Tecla | Qué hace |
|---|---|
| 5 | `levelManager.toggleSimulation()` (antes iba directo al engine) |
| N | `levelManager.next()` |
| 0 | `levelManager.restart()` |

### Documentación

- Reescribir [`src/levels/README.md`](src/levels/README.md): `Level`, `levelManager`, el orden de `load` y cómo agregar un nivel.
- [`src/menu/README.md`](src/menu/README.md): `levelInfoMenu` (y `MenuText`, si se mueve).
- [`src/input/README.md`](src/input/README.md) y las teclas de [`README.md`](README.md).

### Tests (`test/levelManagerTest.wtest`)

- Cargar un nivel deja su catálogo, la página 0 y la primera máquina elegida.
- Cargar un nivel con la simulación prendida la apaga y saca items y máquinas (salvo los `DeliverySlot`).
- Entregar un item que pide el objetivo actualiza el progreso; uno que no pide, no.
- Cumplir el objetivo marca `completed` y la simulación se apaga **en el paso siguiente**, no en el mismo.
- Después de ganar, las entregas no cuentan y la tecla 5 no prende la simulación.
- Apagar la simulación sin haber ganado vuelve el progreso a cero.
- `next()` sin completar no hace nada; después de completar, carga el siguiente.
- `restart()` vuelve el progreso a cero y saca las máquinas que colocó el jugador.
- `freePlay` nunca se completa.

## Fase 4: Máquinas fijas y parametrizadas

### Máquinas que coloca el nivel

- Clase `Placement(position, factory, locked = true)`. `factory` es un bloque, por ejemplo `{ => new Dispenser(direction = up) }`.
- `Placement.create()`: crea la máquina con `factory` y le aplica `locked`. Es lo que usa `Level.placeFixedMachines()` (ya escrito en la fase 3).
- Test: `new Dispenser(direction = up)` respeta la dirección pasada y no la de `toolsManager.currentDirection()` (por el `initialize` de `MachineSprite`).

### Bloqueo

- `var property locked = false` en `Machine`.
- `delete` y `rotate` (en `tools/userTools.wlk`) no hacen nada si la máquina está bloqueada. `edit` sigue funcionando (ver [decisiones](#decisiones-abiertas)).
- Test: una máquina bloqueada no se borra ni se rota.

### Máquinas configurables desde el nivel

Para que cada nivel arme su catálogo con factories distintas:

- `Assembler`: `recipe` como parámetro (`new Assembler(recipe = burgerRecipe)`), con `burgerRecipe` por defecto para no romper los tests.
- `Dispenser`: los ingredientes del `ProductSetting` salen de un parámetro (`availableKinds`), con la lista de hoy por defecto.

## Fase 5: Entrada para el tutorial

Todavía no se sabe cómo va a ser el tutorial. Por eso esta fase define **sólo el contrato** y un objeto que no hace nada: cuando se implemente, ninguna parte del juego tiene que cambiar.

- `Level` recibe `const property tutorial = noTutorial`.
- `noTutorial` (en `levels/tutorial.wlk`):

  ```wollok
  // Lo que el juego le avisa al tutorial del nivel. noTutorial no hace nada y deja hacer todo.
  object noTutorial {
  	method onLevelLoaded(level) {}
  	method onToolSelected(tool) {}
  	method onMachinePlaced(machine) {}
  	method onMachineRemoved(machine) {}
  	method onMachineRotated(machine) {}
  	method onSettingChanged(machine, setting) {}
  	method onSimulationToggled(running) {}
  	method onDelivered(item) {}
  	method onLevelWon(level) {}

  	// ¿Deja hacer esta acción? Un tutorial puede, por ejemplo, permitir sólo colocar cintas
  	method allows(action, pos) = true

  	// El mensaje que muestra levelInfoMenu (vacío: no muestra nada)
  	method message() = ""
  }
  ```

- Emitir los eventos, siempre a través de `levelManager` (que los reenvía a `currentLevel.tutorial()`):

  | Evento | Lo emite |
  |---|---|
  | Herramienta elegida | `toolsManager.select` |
  | Colocar, borrar, rotar | `place`, `delete` y `rotate` en `userTools.wlk`, después de hacerlo |
  | Cambiar un setting | `editMenu`, al hacer `setting.select(option)` |
  | Prender o apagar | `simulationEngine.toggle` (el del jugador, no el de los tests) |
  | Entregar, ganar | `levelManager` |

- `toolsManager.onClick` pregunta `levelManager.allows(tool, pos)` antes de ejecutar la herramienta: es el único punto de bloqueo que va a necesitar el tutorial.
- `levelInfoMenu` muestra `tutorial.message()` si no está vacío.
- Test: un tutorial de prueba registra los eventos que recibe y bloquea `delete`.

> [!NOTE]
> Cuando se implemente, **el tutorial es un nivel más**: un `Level` (por ejemplo, el nivel 0) con su propio `tutorial`. Una forma posible es una lista de pasos, cada uno con su mensaje, lo que permite hacer y el evento que lo da por cumplido.

## Fase 6: Energía

Sólo si la energía va a ser una restricción de los niveles. `energyConsumption()` ya existe en cada máquina, pero nadie la suma.

- `Level` recibe `energyLimit` (`null` = sin límite).
- `board.totalEnergy()`: suma `energyConsumption()` de las máquinas.
- `levelInfoMenu` muestra "Energía: 7/10".
- Si se pasa del límite, la simulación no prende.

---

## Decisiones abiertas

Cuando el equipo decida, anotar la decisión al lado.

- **Celdas de entrega:** ¿son (16, 14) y (17, 14)? (salen de contar los píxeles de `background.png`).
- **¿Los platitos aceptan cualquier comida?** O cada uno es un cliente con su pedido (un filtro en `canReceive`, configurado por el nivel y mostrado en `levelInfoMenu`).
- **¿Qué pasa con lo que un platito no acepta?** Se queda trabado en la cinta (como hoy con cualquier máquina llena), lo acepta sin contarlo, o resta puntos.
- **Al ganar:** se apaga la simulación y se muestra "Nivel completo" hasta pasar al siguiente, o se sigue jugando. Recomendado: apagar y esperar la tecla (es lo que describe la [fase 3](#ganar)).
- **Después del último nivel:** se muestra "Fin del juego" y sólo se puede reiniciar, se vuelve al primero, o se pasa al modo libre.
- **¿Reiniciar borra lo que construyó el jugador?** La fase 3 propone que sí (vuelve a cargar el nivel); para sólo volver a correr está la tecla 5. La alternativa es reiniciar sin tocar las máquinas.
- **¿El progreso se pierde al apagar la simulación?** Recomendado: sí, el objetivo se cumple en una sola corrida.
- **¿Las máquinas fijas se pueden editar?** Recomendado: sí, pero no borrar ni rotar.
- **¿Queda un modo libre** con todas las máquinas y sin objetivo? Recomendado: sí, para probar.
- **Teclas** para reiniciar y pasar de nivel. La R ya es rotar; la propuesta es `N` (siguiente) y `0` (reiniciar).
