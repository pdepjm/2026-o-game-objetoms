# Plan de implementación: niveles

Plan para pasar del modo libre de hoy (todas las máquinas, sin objetivo) a **niveles**: cada uno con sus máquinas disponibles, máquinas ya colocadas, un objetivo de entrega y, más adelante, un tutorial.

> [!TIP]
> **Cómo usar este archivo**
> - Al terminar una fase, tacharla en el [estado general](#estado-general) cambiando `- [ ]` por `- [x]`, en el mismo commit que la termina.
> - Cada fase dice **de qué depende**, **qué archivos toca**, **las tareas en orden**, **los tests** y **cuándo está terminada**.
> - Donde hay algo para decidir, el plan ya implementa una opción por defecto (ver [Decisiones](#decisiones)). Si el equipo decide otra cosa, se cambia acá **antes** de programarlo.

## Estado general

- [x] [Fase 0: Estabilidad](#fase-0-estabilidad) (pendiente: el arte del brazo inteligente en el tablero, y volver a escribir los tests borrados en [0.4](#04-tests-que-rompieron-las-recetas-nuevas))
- [x] [Fase 1: Poder reiniciar todo](#fase-1-poder-reiniciar-todo)
- [x] [Fase 2: Puntos de entrega y objetivos](#fase-2-puntos-de-entrega-y-objetivos)
- [x] [Fase 3: `Level` y `levelManager`](#fase-3-level-y-levelmanager)
- [x] [Fase 4: Máquinas fijas y parametrizadas](#fase-4-máquinas-fijas-y-parametrizadas) (incluye las recetas por nivel, [4.5](#45-recetas-disponibles-por-nivel), y dónde se puede construir, [4.6](#46-dónde-se-puede-construir))
- [x] [Fase 5: Entrada para el tutorial](#fase-5-entrada-para-el-tutorial) (con dos tutoriales: `tutorialLevel`, papas fritas, y `hotDogTutorialLevel`, panchos. El viejo nivel 1 se sacó y el nivel 2 pasó a ser el nivel 1)
- [ ] [Fase 6: Energía](#fase-6-energía) (opcional)

## La idea

- **`levelManager` es el único que conoce los niveles**, igual que `machineManager` es el único que conoce las máquinas concretas.
- **Un `Level` es sólo datos**: qué máquinas se pueden usar, cuáles vienen colocadas, qué hay que lograr y qué tutorial lo acompaña. No tiene lógica de juego.
- **El resto del juego le avisa a `levelManager` lo que pasa** (se entregó un plato, se prendió la simulación, se colocó una máquina) y él decide qué hacer: contar para el objetivo, ganar, avisarle al tutorial.
- **`simulationEngine` y `board` no saben nada de niveles.**

```
userController / userTools / editMenu / DeliverySlot
              │  (eventos: colocó, borró, prendió, entregó…)
              ▼
        levelManager ──▶ currentLevel ──▶ goal      (¿se cumplió?)
              │                     └──▶ tutorial  (desde la fase 5; hoy noTutorial)
              ├──▶ board / simulationEngine / machineManager  (cargar y reiniciar)
              └──▶ levelInfoMenu                          (mostrar el progreso)
```

**Reglas para todas las fases:**

- Nombres de código en inglés; comentarios y tests en español (ver [`src/README.md`](../src/README.md#convenciones)).
- Cada fase actualiza los README de lo que toca, en el mismo commit.
- Todos los tests existentes tienen que seguir pasando al terminar cada fase.

---

## Fase 0: Estabilidad

**Para qué:** arreglar lo que hoy rompe o se ve roto, antes de construir encima.
**Depende de:** nada.

### 0.1 La agenda acepta demoras largas

**El problema:** `simulationEngine.after(pasos, bloque)` da error si `pasos` es 64 o más (`slotCount`). El Dispenser en velocidad *Lenta* agenda cada 100 pasos (`5000 / 0.5` ms), así que **prender la simulación con un Dispenser en *Lenta* tira error**.

**La solución:** cada acción agendada recuerda en qué paso vence. Al llegar a su casillero, se ejecutan sólo las que vencen en ese paso; las demás se quedan para la próxima vuelta de la ronda.

Archivo: `src/simulation/simulationEngine.wlk`.

1. Agregar la clase:

   ```wollok
   // Una acción agendada y el paso en el que vence
   class ScheduledAction {
   	const property dueStep
   	const property action
   }
   ```

2. `after(steps, action)`: sacar el `self.error(...)` y guardar un `ScheduledAction`:

   ```wollok
   method after(steps, action) {
   	const dueStep = currentStep + steps.max(1)
   	agenda.get(dueStep % slotCount).add(new ScheduledAction(dueStep = dueStep, action = action))
   }
   ```

3. `step()`: del casillero, ejecutar sólo las que vencen ahora:

   ```wollok
   const slot = agenda.get(currentStep % slotCount)
   if (!slot.isEmpty()) {
   	const due = slot.filter({ scheduled => scheduled.dueStep() == currentStep })
   	slot.removeAll(due)
   	due.forEach({ scheduled => scheduled.action().apply() })
   }
   ```

4. Actualizar el comentario de `slotCount`: ya no es un límite, sólo el tamaño de la ronda.

**Tests** (`test/simulationTest.wtest`):

- Una acción agendada a 100 pasos se ejecuta en el paso 100, y no en el 36 (que cae en el mismo casillero).
- Un Dispenser en *Lenta* prende la simulación sin error y larga su primer item en el paso 100.

### 0.2 Imágenes

Faltaban imágenes o estaban con nombres que el código no busca (ver la convención en [`assets/README.md`](../assets/README.md)):

| Qué | Problema | Estado |
|---|---|---|
| Papa quemada | Faltaba `food/Ingredients/potatoes/potato_burnt.png` | **Hecho:** sale de la papa frita con colores más oscuros. Se puede redibujar editando su `.svg` |
| Freidora | Estaban `fryer.png`, `fryer_menu.png` y `fryer.gif`, pero el código busca `<dir>_game.png`, `<dir>_menu.png` y `<dir>.gif` | **Hecho:** renombradas como `down_*` y generadas las otras 3 direcciones con `assetRotate.py`. La freidora usa el GIF mientras fríe, como el horno |
| Brazo inteligente (menú) | Las imágenes estaban en `AutomaticArm-Smart/` y no se usaban | **Hecho:** la carpeta pasó a `SmartRoboticArm/` y el menú usa su `down_menu.png` |
| Brazo inteligente (tablero) | Sus `_game.png` son de 50x50, pero el brazo se dibuja en 3x3 (150x150), y no tiene animaciones `_rotate` ni `_catch` | **Pendiente (arte):** hacer sus `_game.png` de 150x150 y sus animaciones. Hasta entonces, en el tablero usa las del brazo común |
| Ingredientes y platos nuevos | Nombres con guion medio y estados fuera de la tabla | **Se quedan como están:** en `main` se pasaron las carpetas a plural, se redimensionaron y el código ya las usa con esos nombres (`cheese_cutted`, `egg_fryed`, `pizza-doughs/`, `hot-dog/`...). Renombrarlas es opcional: hay que cambiar a la vez las imágenes, `foodPaths.wlk` y `foodTypes.wlk` |

### 0.3 Tests que ya fallaban

Antes de empezar la fase 0 ya fallaban 9 tests. **Hecho:** pasan todos.

| Tests | Por qué fallaban | Qué se hizo |
|---|---|---|
| 4 de `multiCellTest` ("tests de la celda de salida") y 3 de `assemblerTest` | El commit "Agrego el ensamblador" sobrescribió `Assembler.outputTarget()`: la salida pasó a otra celda del borde, para coincidir con el sprite nuevo | Se dejó el Assembler como está y los tests usan la salida nueva: a la derecha, la celda de arriba de su borde derecho; abajo, la de la derecha de su borde de abajo |
| 1 de `assemblerTest` (la cadena de dispensers) | Además de la salida, los dispensers se creaban como constantes del `describe`, **antes** de que `initialize()` cambiara la dirección: todos miraban a la derecha | Se crean con la dirección explícita: `new Dispenser(direction = down)` |
| 1 de `menuManagerTest` ("la última página llena los slots...") | Suponía 6 máquinas en el catálogo y ahora hay 8 | Lo esperado se calcula desde `machineManager`, así no depende de cuántas máquinas haya |

> [!TIP]
> En los tests, una máquina creada como constante del `describe` toma la dirección que hay **al crearla**, no la de `initialize()`. Pasarle la dirección al crearla (`new Belt(direction = up)`) lo evita.

### 0.4 Tests que rompieron las recetas nuevas

El commit "agrego en codigo nuevas recetas" (después de la fase 0) hizo fallar 15 tests. **Se borraron**, así que quedaron sin cubrir estas partes:

| Tests borrados | Por qué fallaban | Qué queda sin probar |
|---|---|---|
| 10 de `assemblerTest` (incluida la cadena de dispensers completa) | La receta por defecto del Assembler pasó de `burgerRecipe` a `pizzaPepperoniRecipe`, y los tests armaban hamburguesas | Que el Assembler acepte lo que pide la receta, entregue el plato, consuma los ingredientes y espere si la máquina de adelante está llena |
| 3 de `foodTest` | `burgerRecipe` pasó de 2 carnes a 1 (la de 2 ahora es `doubleBurgerRecibe`) | Las cantidades de una receta (`totalItems`, aceptar hasta N de un ingrediente) |
| 2 de `settingsTest` (panel de edit) | El Dispenser ofrece 12 ingredientes en vez de 6: el panel ocupa más filas y lo de abajo se corre | Dónde se dibujan los títulos del panel y que clickear una velocidad la aplique |

Conviene volver a escribirlos cuando se definan las recetas: creando el Assembler con la receta explícita (`new Assembler(recipe = burgerRecipe)`) y calculando las posiciones del panel desde la cantidad de opciones.

**Listo cuando:** los tests pasan, un Dispenser en *Lenta* funciona en el juego y todas las imágenes de la tabla siguen la convención.

---

## Fase 1: Poder reiniciar todo

**Para qué:** poder dejar el juego como recién abierto sin cerrarlo: sin máquinas, con la simulación apagada, el menú en la primera página y sin herramienta elegida. Sin esto no se puede cargar un nivel ni volver a empezarlo.
**Depende de:** nada.
**Archivos:** `src/board.wlk`, `src/simulation/simulationEngine.wlk`, `src/machines/machineManager.wlk`, `src/menu/placeMenu.wlk`, `src/tools/toolsManager.wlk`.

> [!NOTE]
> En esta fase **el juego no cambia**: nadie llama todavía a lo nuevo (lo va a usar `levelManager.load` en la fase 3). Todo se comprueba con tests.

### 1.1 Qué queda "sucio" hoy

Si hoy se quisiera pasar del nivel 1 al 2, todos estos objetos globales guardan algo del nivel anterior. La tabla dice qué guarda cada uno y qué lo limpia:

| Objeto | Qué guarda | Lo limpia |
|---|---|---|
| `board` | Las máquinas en la grilla y sus visuals | `board.clear()` ([1.2](#12-board-listar-y-sacar-todas-las-máquinas)) |
| `simulationEngine` | Si está prendida, la velocidad, la agenda y `simulatedObjects` | `simulationEngine.reset()` ([1.3](#13-simulationenginereset)) apaga y vuelve a velocidad 1; `board.clear()` saca las máquinas de `simulatedObjects` (cada `pop` lo hace) |
| `animationEngine` | Los items que se están moviendo | `simulationEngine.stop()`, que ya lo hace y que `reset()` llama |
| `machineManager` | La lista de máquinas del menú y la elegida | `machineManager.changeCatalog(...)` ([1.4](#14-machinemanager-un-catálogo-que-se-puede-cambiar)) |
| `placeMenu` | La página que se ve y el overlay | `placeMenu.resetPage()` ([1.5](#15-placemenuresetpage)) |
| `toolsManager` | La herramienta elegida y la dirección para colocar | `toolsManager.reset()` ([1.6](#16-toolsmanagerreset)) |
| `menuManager` | El panel activo | `toolsManager.reset()`, que le avisa que no hay herramienta y cierra el panel |
| `editMenu` | La máquina elegida con edit | `toolsManager.reset()`: al cerrar el panel, `editMenu.hide()` ya la olvida |

**No hace falta limpiar:**

- `simulationEngine.currentStep`: sólo crece, y la agenda funciona con cualquier valor.
- Los settings de las máquinas: se van con las máquinas.

### 1.2 `board`: listar y sacar todas las máquinas

Archivo: `src/board.wlk`.

```wollok
// Las máquinas colocadas, cada una una sola vez (una de 2x2 está en 4 casillas)
method machines() = grid.flatMap({ column => column.map({ cell => cell.machine() }) })
	.filter({ machine => machine != null }).asSet().asList()

// Saca todas las máquinas, con los items que tengan encima.
// Como push y pop, sólo con la simulación apagada.
method clear() {
	self.machines().forEach({ machine => self.pop(machine.cell()) })
}
```

- `machine.cell()` es la celda donde se colocó (la de abajo a la izquierda en las de 2x2), así que `pop` la encuentra y libera todas sus casillas.
- `pop` ya hace todo lo demás: saca los items que tenía encima, saca la máquina del `simulationEngine` y de la pantalla.
- **No controla si la simulación está prendida:** quien lo llama tiene que apagarla antes (`simulationEngine.reset()`, ver [1.7](#17-el-orden)).

### 1.3 `simulationEngine.reset()`

Archivo: `src/simulation/simulationEngine.wlk`.

```wollok
// Vuelve a como arranca el juego: apagada y a velocidad normal.
// No saca las máquinas: se van del engine cuando el board las saca (board.clear(), que llama a pop).
method reset() {
	if (running) self.stop()
	speed = 1
}
```

- **Por qué no vacía `simulatedObjects`:** si lo hiciera, el engine se olvidaría de máquinas que siguen en el tablero (y, desde la fase 2, de los platitos, que no se sacan nunca). Cada objeto se ocupa de lo suyo: el board de las máquinas, el engine de prender y apagar.
- Con la simulación apagada, `reset()` sólo vuelve la velocidad a 1.

### 1.4 `machineManager`: un catálogo que se puede cambiar

Archivo: `src/machines/machineManager.wlk`.

```wollok
// Todas las máquinas del juego, en el orden del menú (la lista de hoy)
const allMachines = [
	{ => new Belt() },
	// ... el resto, igual que ahora
]

// Las que se ofrecen en el menú. Al arrancar, todas.
var machines = allMachines

var selectedMachine = allMachines.first()

method allMachines() = allMachines

// Cambia las máquinas que ofrece el menú (por ejemplo, las de un nivel) y elige la primera
method changeCatalog(factories) {
	machines = factories
	selectedMachine = factories.first()
}
```

- Lo demás (`machinesOfPage`, `pageCount`, `createMachine`, `selectedName`) no cambia: ya trabaja con `machines`.
- **Por qué se elige la primera:** si quedara elegida una máquina del catálogo anterior, el jugador podría colocar una máquina que el nivel no ofrece.
- Un catálogo vacío no tiene sentido: el menú no tendría nada y `first()` falla. **No se controla**: el que llama tiene que pasar al menos una máquina.
- `changeCatalog` **no redibuja el menú**: eso lo hace `placeMenu.resetPage()`. Quien cambia el catálogo llama a los dos (en la fase 3, `levelManager.load`).

### 1.5 `placeMenu.resetPage()`

Archivo: `src/menu/placeMenu.wlk`.

```wollok
// Vuelve a la primera página (por ejemplo, al cambiar el catálogo). Sólo redibuja si se está viendo.
method resetPage() {
	currentPage = 0
	if (visible) self.renderItems()
}
```

- **Por qué hace falta:** si el catálogo nuevo tiene menos páginas que el anterior, `currentPage` podría apuntar a una página que ya no existe y el menú quedaría vacío.
- `renderItems()` también llama a `updateOverlay()`, así que el overlay queda sobre la máquina elegida (la primera).
- Si el panel no se ve, no dibuja nada: se dibuja bien la próxima vez que se elige place (`show()`).

### 1.6 `toolsManager.reset()`

Archivo: `src/tools/toolsManager.wlk`.

```wollok
// Vuelve a como arranca el juego: sin herramienta y colocando hacia la derecha.
// Avisa a los menús, como cuando el jugador cambia de herramienta o de dirección.
method reset() {
	selectedTool = null
	currentDirection = right
	menuManager.toolChanged(null)
	menuManager.directionChanged()
}
```

- **No se usa `select(null)`:** `select` alterna (elegir la herramienta activa la deselecciona), así que no sirve para "dejar sin herramienta".
- `menuManager.toolChanged(null)` cierra el panel activo y actualiza la barra de herramientas. Si el panel era el de edit, `editMenu.hide()` olvida la máquina elegida: eso importa porque esa máquina ya no está en el tablero.
- `menuManager.directionChanged()` actualiza las imágenes del menú de place, que muestran la dirección.

### 1.7 El orden

Para reiniciar todo, siempre en este orden (es el que va a usar `levelManager.load` en la fase 3):

1. `simulationEngine.reset()`: primero se apaga, porque `board.clear()` no se debe usar con la simulación prendida (las máquinas ya calcularon a sus vecinas).
2. `board.clear()`.
3. `toolsManager.reset()`: después de sacar las máquinas, así `editMenu` no queda apuntando a una que ya no existe.
4. `machineManager.changeCatalog(...)` y `placeMenu.resetPage()`: aunque el catálogo sea el mismo, así el menú vuelve a la primera página con la primera máquina elegida.

### 1.8 Tests

**`test/boardTest.wtest`:**

- `machines()` con el tablero vacío es `[]`.
- `machines()` con una cinta y un ensamblador (2x2) devuelve 2 máquinas: cada una una sola vez.
- `clear()` saca la cinta y el ensamblador: ninguna de sus 5 casillas tiene máquina y ninguna de las dos está en pantalla (`game.hasVisual`).
- Después de `clear()` se puede volver a colocar en las mismas celdas.
- Después de `clear()`, el engine ya no las conoce: con un Dispenser y una cinta, `clear()`, prender la simulación y avanzar lo que tarda en dispensar no crea ningún item.

**`test/simulationTest.wtest`:**

- `reset()` con la simulación prendida la apaga y borra los items.
- `reset()` vuelve la velocidad a 1 (después de `speed(3)`).
- `reset()` con la simulación apagada la deja apagada.
- `reset()` no saca las máquinas: después siguen en el tablero, y al prender vuelven a funcionar.

**`test/menuManagerTest.wtest`:**

- `changeCatalog([horno, cinta])`: la máquina elegida es el horno y `pageCount()` es 1.
- Con place elegido, `changeCatalog(...)` y `resetPage()`: los slots 1 y 2 muestran el horno y la cinta, y los slots 3 y 4 quedan vacíos.
- `resetPage()` después de pasar a la segunda página vuelve a la primera (`currentPage()` es 0).
- `toolsManager.reset()` deja sin herramienta, con dirección `right`, la zona interactiva vacía y la barra con `tools/default.png`.
- `toolsManager.reset()` con edit mostrando un Dispenser: la zona interactiva queda vacía, y al volver a elegir edit no muestra nada hasta clickear otra máquina.

**Un test de todo junto** (en `test/boardTest.wtest`):

- Con máquinas colocadas, la simulación prendida a x3, la herramienta delete elegida, la dirección `up` y el menú en la segunda página: después de los pasos de [1.7](#17-el-orden), el tablero está vacío, la simulación apagada a x1, sin herramienta, con dirección `right` y en la primera página.

### 1.9 Documentación

- [`src/README.md`](../src/README.md) (sección `board.wlk`): `machines()` y `clear()`.
- [`src/simulation/README.md`](../src/simulation/README.md): `reset()`, y por qué no saca las máquinas.
- [`src/machines/README.md`](../src/machines/README.md) (sección `machineManager.wlk`): `allMachines`, `changeCatalog(...)` y que no redibuja.
- [`src/menu/README.md`](../src/menu/README.md): `placeMenu.resetPage()`.
- [`src/tools/README.md`](../src/tools/README.md): `toolsManager.reset()`.

**Listo cuando:** los tests de 1.8 pasan, todos los anteriores siguen pasando, y los pasos de [1.7](#17-el-orden) dejan el juego como recién abierto.

---

## Fase 2: Puntos de entrega y objetivos

**Para qué:** que la comida tenga un lugar donde entregarse, y que se pueda medir si se cumplió lo que pide un nivel.
**Depende de:** fase 1 (`board.clear()` no tiene que llevarse los puntos de entrega).

La comida se entrega en **los dos platitos del fondo**, arriba del tablero: las celdas **(16, 14) y (17, 14)**. Están fuera de `inBoard` (que va de y 1 a 13): el jugador no puede colocar nada ahí, pero una cinta o un brazo que apunta hacia un platito le entrega el plato.

### 2.1 `DeliverySlot`

Archivo nuevo: `src/machines/types/deliverySlot.wlk`.

Es una `Machine` para que `tryPush`, `canReceiveFrom` y los brazos le entreguen sin cambiar nada de ellos. Con el `onReceive` por defecto, el plato viaja hasta el platito; al llegar, desaparece y cuenta como entregado.

```wollok
// Uno de los platitos del fondo, donde se entrega la comida. Está fuera del tablero:
// no lo coloca el jugador ni se dibuja (el fondo ya muestra los cubiertos).
class DeliverySlot inherits Machine {
	override method name() = "DeliverySlot"
	override method nextMachine() = null

	// El plato llegó al platito: sale del juego y cuenta para el nivel
	override method onArrived(item) {
		inventory.release(item)
		simulationEngine.removeItem(item)
		levelManager.delivered(item)
	}
}

// Los platitos del fondo. Sus posiciones están sólo acá.
object deliveryPoints {
	const property slots = [
		new DeliverySlot(position = game.at(16, 14), direction = down),
		new DeliverySlot(position = game.at(17, 14), direction = down)
	]

	// Lo llama main.wpgm al arrancar (y los tests que los necesiten)
	method setUp() {
		slots.forEach({ slot => board.addDeliverySlot(slot) })
	}
}
```

- **No se agregan como visuals** (`game.addVisual`): el fondo ya los dibuja.
- Se crean con `direction = down` explícito, para no depender de la dirección elegida en el menú.
- `levelManager.delivered(item)` todavía no existe. En esta fase se crea **`src/levels/levelManager.wlk` con sólo ese método, vacío**, con un comentario de que se completa en la fase 3.

### 2.2 Que el `board` los conozca

Archivo: `src/board.wlk`. `board` **no importa** `deliverySlot.wlk` (lo importaría al revés): sólo guarda los que le pasan.

1. `const deliverySlots = []`.
2. `method addDeliverySlot(slot)`: lo agrega a `deliverySlots` y lo registra en el engine (`simulationEngine.addSimulatedObject(slot)`). Así `stop()` lo resetea y `allItems()` ve el plato mientras viaja.
3. `machineAt(pos)`:

   ```wollok
   method machineAt(position) =
   	if (self.inBoard(position)) self.cellAt(position).machine()
   	else deliverySlots.findOrDefault({ slot => slot.cell() == position }, null)
   ```

4. **No cambian:** `inBoard` (así `canPlace` impide colocar ahí y `toolsManager` ignora esos clicks) ni `machines()` (recorre la grilla, y los platitos no están ahí, así que `clear()` no se los lleva).
5. `main.wpgm`: llamar a `deliveryPoints.setUp()` antes de `simulationEngine.start()`.

### 2.3 Objetivos

Archivo nuevo: `src/levels/goals.wlk`. Todo objetivo entiende:

| Método | Para qué |
|---|---|
| `delivered(item)` | Se entera de que se entregó un item |
| `isMet()` | ¿Se cumplió? |
| `progressText()` | El texto que muestra la info del nivel, por ejemplo `"Papas cortadas: 2/3"` |
| `reset()` | Vuelve a cero |

Dos objetivos:

- **`DeliveryGoal`**: entregar `amount` items de un kind. Los kinds no tienen nombre para mostrar, por eso recibe `label`:

  ```wollok
  class DeliveryGoal {
  	const kind
  	const amount
  	const label          // cómo se muestra: "Papas cortadas"
  	var delivered = 0

  	method delivered(item) { if (kind.accepts(item)) delivered += 1 }
  	method isMet() = delivered >= amount
  	method progressText() = label + ": " + delivered.min(amount) + "/" + amount
  	method reset() { delivered = 0 }
  }
  ```

- **`noGoal`**: el objetivo del modo libre. No cuenta nada, `isMet()` es siempre `false` y `progressText()` es `""`. Es un objeto nulo: así nadie pregunta `if (goal != null)`.

Si más adelante hace falta combinar objetivos ("3 hamburguesas y 2 papas"), se agrega un objetivo compuesto con el mismo contrato. **No es parte de esta fase.**

**Tests** (`test/deliveryTest.wtest`, nuevo):

- Una cinta en (16, 13) apuntando hacia arriba le entrega un item al platito, y el item desaparece del juego.
- Un brazo cuya salida da a (17, 14) también entrega.
- `board.canPlace(game.at(16, 14), ...)` es `false`.
- `board.clear()` no saca los platitos: después, `machineAt(game.at(16, 14))` sigue siendo un `DeliverySlot`.
- `DeliveryGoal(kind = cutPotato, amount = 3)`: entregar 3 papas cortadas lo cumple; entregar papas enteras no suma; `reset()` lo vuelve a 0.
- `progressText()` no pasa de `amount` aunque se entreguen más.

**Listo cuando:** en el juego, una cinta que llega a un platito hace desaparecer la comida ahí.

---

## Fase 3: `Level` y `levelManager`

**Para qué:** que exista el concepto de nivel, que se pueda cargar, ganar, reiniciar y pasar al siguiente, y que se vea en pantalla.
**Depende de:** fases 1 y 2.

> [!NOTE]
> Esta fase describe **cómo quedó implementada**. Lo que cambió respecto del plan original: los niveles concretos están en `levelsTypes.wlk` (no `levels.wlk`); los objetivos, junto con `Level` en `levelClasses.wlk` (no en `goals.wlk`); un nivel tiene **una lista** de objetivos; y los métodos de las teclas se llaman `loadNext()` y `loadFreePlay()`.

### 3.1 Archivos

| Archivo | Qué tiene |
|---|---|
| `src/levels/levelClasses.wlk` | La clase `Level` y los objetivos (`DeliveryGoal` y `noGoal`, de la fase 2) |
| `src/levels/levelsTypes.wlk` (nuevo) | Los niveles concretos: `freePlay` y `level1`. Es el único archivo de niveles que conoce las máquinas concretas |
| `src/levels/levelManager.wlk` | `levelManager`: el nivel actual, cargarlo, ganar, reiniciarlo y pasar al siguiente |
| `src/levels/niveles.wlk` | **Borrado** (`Nivel` vacío, reemplazado por `Level`) |
| `src/menu/menuText.wlk` (nuevo) | `MenuText`, movido desde `editMenu.wlk` para que lo usen los dos menús |
| `src/menu/levelInfoMenu.wlk` | La información del nivel, en la zona de la izquierda |
| `src/input/userController.wlk` | Las teclas nuevas |
| `src/main.wpgm` | Llama a `levelManager.start()` |

> [!IMPORTANT]
> **Imports circulares:** `deliverySlot.wlk` importa `levelManager`, y `levelManager` importa los niveles, que importan las máquinas. Wollok lo resuelve bien.
>
> **Pero no hay que poner comentarios dentro de una lista** (por ejemplo, entre los bloques de `availableMachines`): Wollok no puede leer el archivo, y todo el juego y todos los tests fallan con `Could not resolve reference to level1`. Los comentarios van arriba del atributo.

### 3.2 `Level`: sólo datos

Archivo: `src/levels/levelClasses.wlk`. Un nivel dice cómo es, y `levelManager` lo usa. Para que `levelManager` no recorra los objetivos, el nivel habla con ellos:

```wollok
class Level {
	const property name
	const property availableMachines          // Las máquinas disponibles para colocar
	const property fixedMachines = []         // Máquinas colocadas desde el comienzo (fase 4)
	const property goals                      // Lo que hay que cumplir para ganar: TODOS los objetivos

	method placeFixedMachines() {
		fixedMachines.forEach({ placement => board.push(placement.position(), placement.create()) })
	}

	method delivered(item) { goals.forEach({ goal => goal.delivered(item) }) }
	method goalsMet() = goals.all({ goal => goal.isMet() })
	method resetGoals() { goals.forEach({ goal => goal.reset() }) }
	// Una línea por objetivo, para la info del nivel. noGoal no tiene texto: no suma línea.
	method progressLines() = goals.map({ goal => goal.progressText() }).filter({ text => text != "" })
}
```

**Se gana cuando se cumplen todos los objetivos.** Con `noGoal`, nunca.

### 3.3 Los niveles concretos

Archivo: `src/levels/levelsTypes.wlk`. Son objetos bien conocidos, con la misma forma que `burgerRecipe`:

```wollok
// Modo libre: todas las máquinas y sin objetivo, para probar
object freePlay inherits Level(name = "Libre", availableMachines = machineManager.allMachines(), goals = [noGoal]) {}

// Primer nivel: freír papas y entregarlas
object level1 inherits Level(
	name = "Nivel 1",
	availableMachines = [
		{ => new Belt() }, { => new Dispenser() }, { => new CuttingMachine() },
		{ => new Fryer() }, { => new AutomaticArm() }
	],
	goals = [new DeliveryGoal(kind = friedPotato, amount = 3, label = "Papas Fritas")]
) {}
```

> [!NOTE]
> **Resuelto en la fase 4.** Con este catálogo, `level1` no se podía ganar usando la freidora: la freidora sólo trabaja con brazos, y el brazo común le saca la papa **apenas entra**, todavía cortada (hay un test que lo comprueba en `smartArmTest`). Para sacarla frita hace falta el brazo inteligente, con su salida filtrando papas fritas.
>
> Además, el Dispenser podía largar papas fritas directamente, y así se ganaba sin procesar nada. En la [fase 4](#44-usarlo-en-level1) el nivel trae el Dispenser fijo, limitado a papa, lechuga y tomate, y ofrece el brazo inteligente.

### 3.4 `levelManager`

Archivo: `src/levels/levelManager.wlk`.

**Estado:**

| Atributo | Qué guarda |
|---|---|
| `const levels = [level1]` | Los niveles en el orden en que se juegan. `freePlay` **no** está en la lista |
| `var indexCurrentLevel = 0` | La posición del nivel actual en `levels` (la usa `loadNext()`) |
| `var currentLevel = freePlay` | El nivel cargado. Arranca en `freePlay` y no en `null`: así una entrega o la tecla 5 antes de `start()` no rompen |
| `var completed = false` | Si ya se cumplieron los objetivos del nivel cargado |

**Métodos:**

| Método | Qué hace |
|---|---|
| `start()` | Lo llama `main.wpgm` una sola vez: `self.load(levels.first())` |
| `load(level)` | Arma el nivel desde cero (ver [3.5](#35-el-orden-de-load)) |
| `restart()` | `self.load(currentLevel)`. Borra también lo que construyó el jugador |
| `loadNext()` | Si `completed` y `hasNext()`, carga el siguiente de `levels`. Si no, no hace nada (no se saltean niveles) |
| `loadFreePlay()` | `self.load(freePlay)`. Así `userController` no tiene que conocer los niveles |
| `hasNext()` | `true` si `currentLevel` está en `levels` y no es el último. Con `freePlay` es `false` |
| `toggleSimulation()` | Lo que hace la tecla 5 (ver [3.6](#36-la-tecla-5-pasa-por-levelmanager)) |
| `delivered(item)` | Lo llama `DeliverySlot` (ver [3.7](#37-entregar-y-ganar)) |
| `currentLevel()`, `completed()` | Getters, para los tests |

### 3.5 El orden de `load`

Primero se apaga y se limpia, después se arma:

1. `simulationEngine.reset()`, `board.clear()` y `toolsManager.reset()` (en `_clear()`): apaga la simulación, saca las máquinas (los platitos quedan) y deja sin herramienta.
2. `currentLevel = level` y `completed = false`.
3. `machineManager.changeCatalog(level.availableMachines())` y `placeMenu.resetPage()`.
4. `level.placeFixedMachines()`.
5. `level.resetGoals()`.
6. `levelInfoMenu.show(level)`.

### 3.6 La tecla 5 pasa por `levelManager`

`userController` ya no llama directo a `simulationEngine.toggle()`, sino a `levelManager.toggleSimulation()`:

```wollok
method toggleSimulation() {
	if (!completed) {
		simulationEngine.toggle()
		// Al apagar se borran los items: el progreso vuelve a cero
		if (!simulationEngine.running()) {
			currentLevel.resetGoals()
			levelInfoMenu.updateProgress(currentLevel)
		}
	}
}
```

Con el nivel completo, la tecla 5 no hace nada: hay que pasar al siguiente (N) o reiniciar (0). Así `simulationEngine` sigue sin saber nada de niveles.

### 3.7 Entregar y ganar

`delivered(item)` se ejecuta **en medio de un paso de simulación** (dentro del `onArrived` del `DeliverySlot`), y en ese mismo paso pueden quedar otras acciones por correr. Si se apagara la simulación ahí mismo, esas acciones correrían sobre máquinas ya reseteadas. Por eso el final se agenda para el paso siguiente:

```wollok
method delivered(item) {
	if (!completed) {
		currentLevel.delivered(item)
		levelInfoMenu.updateProgress(currentLevel)
		if (currentLevel.goalsMet()) self.won()
	}
}

method won() {
	completed = true                                       // las próximas entregas ya no cuentan
	simulationEngine.after(1, { self.finishLevel() })
}

method finishLevel() {
	simulationEngine.stop()                                // directo al engine: el progreso NO se borra
	levelInfoMenu.showCompleted(self.hasNext())
}
```

### 3.8 `levelInfoMenu`

Archivo: `src/menu/levelInfoMenu.wlk`. Usa la zona `levelInfoZone` (x 0 a 4, y 1 a 14). Escribe con `MenuText` en la columna 2 (el centro de la zona), en estas filas:

| Fila (y) | Qué muestra |
|---|---|
| 13 | El nombre del nivel, en mayúsculas |
| 11 | `OBJETIVO` (no se muestra si el nivel no tiene objetivos con texto, como `freePlay`) |
| 10 a 8 | Una línea por objetivo (`level.progressLines()`): como máximo 3 |
| 6 | Al ganar: `¡Nivel completo!`, o `¡Fin del juego!` si no hay siguiente |
| 5 | Al ganar: `N: siguiente`, o `0: reiniciar` si no hay siguiente |
| 4 a 1 | Libres: reservadas para el mensaje del tutorial (fase 5) |

| Método | Lo llama | Qué hace |
|---|---|---|
| `show(level)` | `levelManager.load` | Borra todo lo que había y dibuja el nombre, el título y los objetivos |
| `updateProgress(level)` | `levelManager`, al entregar y al apagar | Reemplaza sólo las líneas de los objetivos |
| `showCompleted(hasNext)` | `levelManager.finishLevel` | Agrega las filas 6 y 5 |
| `positionOfRow(fila)` | Los tests | La posición en pantalla de una fila |

- **Sólo se actualiza cuando lo llaman**, nunca en cada frame (ver la regla de rendimiento en [`src/README.md`](../src/README.md#convenciones)). `MenuText` tiene el texto fijo: para cambiarlo, se saca el visual y se agrega uno nuevo.
- Guarda lo dibujado en tres listas (nombre y título, progreso, y mensaje de nivel completo) para reemplazar sólo lo que cambia.
- Wollok no corta el texto en varias líneas: los textos tienen que ser cortos (unos 15 o 20 caracteres).
- Comprobado en el juego: los textos quedan centrados en la zona y no se cortan.

### 3.9 Teclas

Archivo: `src/input/userController.wlk`.

| Tecla | Qué hace |
|---|---|
| 5 | `levelManager.toggleSimulation()` (antes, `simulationEngine.toggle()`) |
| N | `levelManager.loadNext()` |
| 0 | `levelManager.restart()` (la R ya es rotar) |
| L | `levelManager.loadFreePlay()`: pasar al modo libre |

### 3.10 Documentación

- [`src/levels/README.md`](../src/levels/README.md): `Level`, objetivos, `levelManager`, el orden de `load`, cómo se gana y **cómo agregar un nivel**.
- [`src/menu/README.md`](../src/menu/README.md): `levelInfoMenu` y `MenuText` en su archivo.
- [`src/input/README.md`](../src/input/README.md) y la sección de teclas de [`README.md`](../README.md).

### 3.11 Tests

En `test/levelManagerTest.wtest` (20 tests):

- **Cargar:** al arrancar se carga `level1`, sin completar; el catálogo es el de `level1`, en la primera página, con la cinta elegida; cargar con la simulación prendida la apaga y saca las máquinas, pero no los platitos.
- **Entregar:** el progreso arranca en cero; entregar papas fritas suma; entregar papas enteras o cortadas no; apagar la simulación sin haber ganado vuelve a cero.
- **Ganar:** con la tercera papa frita se completa, y la simulación se apaga en el paso siguiente (no en el mismo); al ganar, el progreso no se borra; después de ganar, la tecla 5 no vuelve a prender.
- **Siguiente, reiniciar y modo libre:** `loadNext()` sin ganar no cambia de nivel; el último nivel no tiene siguiente; `restart()` vuelve a cero, saca lo construido y, después de ganar, vuelve a dejar jugar; el modo libre tiene todas las máquinas, nunca se completa y no tiene siguiente.
- **Lo que se ve:** nombre, título y progreso en sus filas; una entrega reemplaza el texto sin dejar el anterior; al ganar el último nivel se ve `¡Fin del juego!` y `0: reiniciar`; al volver a cargar se borra ese mensaje; el modo libre muestra sólo `LIBRE`.

En `test/smartArmTest.wtest`: el brazo común saca la papa de la freidora antes de que se fría, y el inteligente (filtrando papas fritas) espera a que se fría.

**Listo cuando:** al abrir el juego arranca el nivel 1, se ve su objetivo a la izquierda, se puede ganar entregando 3 papas fritas, y las teclas N, 0 y L funcionan. Se cumple (el atajo del Dispenser se cerró en la fase 4).

### 3.12 Progreso y la tecla L

**Para qué:** que la L sirva para ir al modo libre **y volver**, al nivel que toca jugar. Para eso, `levelManager` guarda qué niveles se ganaron. **Hecho.**

- **`completedLevels`:** `won()` agrega el nivel actual, sin repetir y nunca `freePlay`. Se guarda mientras el juego está abierto.
- **`levelToPlay()`:** el primer nivel de `levels` que no se ganó; si se ganaron todos, el último. `start()` carga éste.
- **`toggleFreePlay()`** (la tecla L): desde un nivel, va al modo libre; desde el modo libre, carga `levelToPlay()`. **Con la simulación prendida no hace nada.**
- **"Siguiente" sin índice guardado:** antes, `loadNext()` usaba `indexCurrentLevel`, que sólo cambiaba con `loadNext()`. Si se llegaba a un nivel por otro camino (la L, `start`, `load`), quedaba desfasado y "siguiente" podía volver a cargar el mismo nivel. Ahora el siguiente se calcula buscando el nivel actual en `levels` (`currentIndex()`).
- **En pantalla:** en el modo libre, debajo del nombre, `L: volver` (`levelInfoMenu.showHint`, fila 12).
- **`changeLevels(niveles)`:** sólo para los tests, para usar sus propios niveles sin depender del diseño de los reales.

**Tests** (`test/levelManagerTest.wtest`, "tests del progreso y la tecla L", 11, con tres niveles de prueba): al arrancar se juega el primero; ganar uno lo guarda y el que toca pasa a ser el siguiente; ganarlo de nuevo no lo guarda dos veces; con todos ganados, el que toca es el último; la L va al modo libre y vuelve; ganar el primero, ir y volver lleva al segundo; el modo libre nunca queda completado; con la simulación prendida la L no hace nada; después de llegar con la L, "siguiente" lleva al que sigue; la ayuda `L: volver` aparece sólo en el modo libre.

---

## Fase 4: Máquinas fijas y parametrizadas

**Para qué:** que un nivel pueda traer máquinas ya colocadas que el jugador no puede mover, armar su catálogo con máquinas configuradas, decir qué recetas se pueden armar y dónde se puede construir.
**Depende de:** fase 3.

> [!NOTE]
> **Cómo quedó implementada** (lo que cambió respecto de lo que sigue):
> - `Placement` está en `levels/levelClasses.wlk`, junto con `Level` (no en `placement.wlk`). Su `position` puede ser `game.at(x, y)` o `CellPosition`.
> - **El bloqueo lo controlan las herramientas, no el tablero.** Al principio quedó en `board.pop`, y entonces `board.clear()` no sacaba las máquinas fijas: al reiniciar el nivel, el juego fallaba al volver a colocarlas ("No se puede colocar la máquina en 5@7"), y al pasar al modo libre quedaban en el tablero. Ahora `pop` saca siempre, y `delete` y `rotate` preguntan `board.isThereAMachineUnlocked(posición)`.
> - `level1` quedó así: cinta, cortadora, freidora y brazo inteligente; un Dispenser fijo en (5, 7) que larga papa, lechuga o tomate; sin recetas (`availableRecipes = []`); y hay que entregar 10 papas fritas.
> - Los tests de `levelManagerTest` usan un nivel de prueba (`testLevel`, definido en el archivo de test) y no `level1`: así no se rompen cada vez que cambia el diseño del nivel 1.

### 4.1 Máquinas que coloca el nivel

Archivo: `src/levels/levelClasses.wlk` (junto con `Level`).

```wollok
// Una máquina que trae el nivel: dónde va y cómo se crea
class Placement {
	const property position      // game.at(x, y), la celda donde se coloca
	const factory                // { => new Dispenser(direction = right) }
	const locked = true

	method create() {
		const machine = factory.apply()
		machine.locked(locked)
		return machine
	}
}
```

`Level.placeFixedMachines()` ya los usa (fase 3).

### 4.2 Bloqueo

1. `src/machines/machineClasses.wlk`: `var property locked = false` en `Machine`.
2. `src/tools/userTools.wlk`: `delete` y `rotate` no hacen nada si `board.machineAt(pos).locked()`.
3. `edit` sigue funcionando: se puede cambiar, por ejemplo, la velocidad de un Dispenser fijo.

### 4.3 Máquinas configurables

Para que cada nivel arme su catálogo y sus máquinas fijas con factories distintas:

- **`Assembler`:** su receta deja de estar fija en el código y se elige entre las del nivel. Ver [4.5](#45-recetas-disponibles-por-nivel).
- **`Dispenser`:** agregar `const availableKinds = [lettuce, bun, friedPotato, potato, tomato, meat]` (la lista de hoy) y usarlo en el `ProductSetting` (`kinds = availableKinds`). Ojo: el valor por defecto (`potato`) tiene que estar en la lista; si un nivel pasa una lista sin papa, también tiene que pasar `value`.

### 4.4 Usarlo en `level1`

`level1` pasa a traer el Dispenser colocado y bloqueado, que sólo larga papas, y lo saca del catálogo. Así se cierra el atajo de largar papas fritas directamente (ver [3.3](#33-los-niveles-concretos)):

```wollok
object level1 inherits Level(
	name = "Nivel 1",
	availableMachines = [
		{ => new Belt() }, { => new CuttingMachine() }, { => new Fryer() },
		{ => new AutomaticArm() }, { => new SmartRoboticArm() }
	],
	fixedMachines = [new Placement(position = game.at(5, 7), factory = { => new Dispenser(direction = right, availableKinds = [potato]) })],
	goals = [new DeliveryGoal(kind = friedPotato, amount = 3, label = "Papas Fritas")]
) {}
```

El brazo inteligente está en el catálogo porque, sin el atajo, es la única forma de sacar papas fritas de la freidora (ver [Decisiones](#decisiones)).

### 4.5 Recetas disponibles por nivel

**Para qué:** que cada nivel diga qué platos se pueden armar, y que el jugador elija en cada Assembler cuál de esos arma (con la herramienta edit, como el ingrediente de un Dispenser). Hoy el Assembler tiene la receta fija en el código (`const recipe = cheeseBurgerRecipe`), y para cambiarla hay que editar `assembler.wlk`.

**Cómo funciona:**

```
Level.availableRecipes ──(load)──▶ recipeBook.available ──▶ RecipeSetting.options ──▶ panel de edit
                                                                    │
                                                    el jugador elige una (value)
                                                                    │
                                              Assembler.start(): la toma como su receta
```

#### 4.5.1 `recipeBook`: las recetas del juego y las del nivel

Archivo: `src/food/recipes.wlk`. Es a las recetas lo que `machineManager` es a las máquinas: conoce todas, y guarda cuáles se ofrecen ahora.

```wollok
object recipeBook {
	// Todas las recetas del juego, en el orden en que se muestran en el panel de edit
	const all = [burgerRecipe, cheeseBurgerRecipe, doubleBurgerRecipe, pizzaPepperoniRecipe, saladRecipe, hotDogRecipe, tomatoSoupRecipe]
	// Las que se pueden elegir ahora (las del nivel). Al arrancar, todas.
	var available = all

	method all() = all
	method available() = available

	// La receta con la que arranca un Assembler: la primera disponible, o noRecipe si el nivel no ofrece ninguna
	method firstAvailable() = if (available.isEmpty()) noRecipe else available.first()

	// Lo llama levelManager.load con las recetas del nivel
	method changeAvailable(recipes) {
		available = recipes
	}
}

// La receta de un Assembler cuando el nivel no ofrece ninguna: no pide nada y nunca arma un plato.
// Es un objeto nulo (como noGoal): así un nivel sin recetas no rompe al crear un Assembler,
// por ejemplo al dibujarlo en el menú. No es una de las opciones del panel de edit.
object noRecipe {
	method totalItems() = 0
	method stillNeeds(item, items) = false
	method canBeMadeWith(items) = false
}
```

- Al agregar una receta nueva a `recipes.wlk`, hay que sumarla a `all`; si no, no aparece en el modo libre.
- **No es obligatorio que un nivel tenga recetas.** Sólo las necesita si ofrece un Assembler (en el catálogo o fijo). Sin recetas, un Assembler arranca con `noRecipe`: al prender la simulación su inventario queda en 0, así que no acepta ningún ingrediente, y en el panel de edit muestra "Receta" sin opciones. **Sin `noRecipe`, el juego fallaría apenas se crea un Assembler** (`first()` de una lista vacía), y el menú de place crea una máquina de muestra de cada una del catálogo para dibujarla.
- `noRecipe` sólo entiende lo que el Assembler le pide antes de armar un plato. `assembleTime()` y `prepare()` no hacen falta: nunca llega a armar uno.

#### 4.5.2 `Recipe`: mostrar el plato

Archivo: `src/food/recipesClasses.wlk`. El panel de edit muestra cada receta con la imagen de su plato, así que hace falta leer `result`: agregar `method result() = result`.

#### 4.5.3 `RecipeSetting`

Archivo: `src/machines/settings.wlk`. Un setting más, con la misma forma que `ProductSetting`:

```wollok
// Qué plato arma un Assembler. Las opciones son las recetas del nivel (recipeBook), con la imagen de su plato.
class RecipeSetting inherits Setting {
	override method name() = "Receta"
	override method category() = production
	override method options() = recipeBook.available().map({ recipe =>
		new SettingOption(value = recipe, image = recipe.result().image())
	})
}
```

Las opciones **se calculan cuando se piden** (como todas las de `Setting`), así que siempre son las del nivel actual.

#### 4.5.4 El Assembler usa la receta elegida

Archivo: `src/machines/types/assembler.wlk`.

```wollok
// La receta que eligió el jugador. Arranca con la primera del nivel (noRecipe si el nivel no tiene).
const recipeSetting = new RecipeSetting(value = recipeBook.firstAvailable())
// La que usa mientras corre la simulación: se toma de recipeSetting al prender (ver start)
var recipe = recipeSetting.value()

override method settings() = [recipeSetting]

// Al prender, toma la receta elegida y ajusta el inventario a lo que pide
override method start() {
	recipe = recipeSetting.value()
	inventory.changeCapacity(recipe.totalItems())
	super()
}
```

- El resto del Assembler (`canReceive`, `onArrived`, `assemble`, `capacity`) sigue usando `recipe`, sin cambios.
- **Por qué se toma al prender y no en cada uso:** el panel de edit se puede usar con la simulación prendida. Si la receta cambiara en el medio, el Assembler podría quedarse con ingredientes de la receta anterior que la nueva no pide, y trabarse para siempre. Así, **la receta elegida se usa desde la próxima vez que se prende la simulación** (al apagar, el inventario ya queda vacío).
- **El inventario tiene que poder cambiar de tamaño.** Se crea una sola vez con la capacidad del momento (`const inventory = new Inventory(capacity = self.capacity())` en `Machine`), y cada receta pide una cantidad distinta de ingredientes. En `src/machines/inventory.wlk`, `capacity` pasa a ser `var`, con `changeCapacity(nueva)`.
- Un Assembler fijo con una receta ya elegida: `{ => new Assembler(recipeSetting = new RecipeSetting(value = saladRecipe)) }`.

#### 4.5.5 Cada nivel dice sus recetas

- **`Level`** (`src/levels/levelClasses.wlk`): `const property availableRecipes`, **obligatorio** (sin valor por defecto): todo nivel dice sus recetas. `freePlay` pone `recipeBook.all()`, y un nivel sin Assembler puede poner `[]` (ver `noRecipe` en [4.5.1](#451-recipebook-las-recetas-del-juego-y-las-del-nivel)).
- **`levelManager.load`**: después de limpiar y **antes** de cambiar el catálogo y colocar las máquinas fijas (los Assembler nuevos toman la primera receta disponible al crearse):

  ```wollok
  recipeBook.changeAvailable(level.availableRecipes())
  ```

- **Un nivel que usa recetas** (`src/levels/levelsTypes.wlk`):

  ```wollok
  object level2 inherits Level(
  	name = "Nivel 2",
  	availableMachines = [{ => new Belt() }, { => new CuttingMachine() }, { => new Assembler() }],
  	availableRecipes = [saladRecipe],
  	fixedMachines = [new Placement(position = game.at(5, 7), factory = { => new Dispenser(direction = right, availableKinds = [lettuce, tomato]) })],
  	goals = [new DeliveryGoal(kind = salad, amount = 2, label = "Ensaladas")]
  ) {}
  ```

  Ojo: las recetas del nivel tienen que poder armarse con los ingredientes que ofrece, y tienen que incluir los platos que piden sus objetivos.

#### 4.5.6 Documentación

- [`src/food/README.md`](../src/food/README.md): `recipeBook` (con `firstAvailable()`), `noRecipe` y `result()`.
- [`src/machines/README.md`](../src/machines/README.md): `RecipeSetting` en la sección de configuración; el Assembler (sus settings y que toma la receta al prender); `Inventory` con capacidad variable.
- [`src/levels/README.md`](../src/levels/README.md): `availableRecipes` en `Level` y en "Agregar un nivel".

### 4.6 Dónde se puede construir

**Para qué:** que cada nivel limite las celdas donde el jugador puede colocar máquinas. **Hecho.**

- **`Zone`** pasó de `menu/menuManager.wlk` a `src/board.wlk`: un rectángulo de celdas con `contains(posición)`. Está en el tablero porque es el tablero el que define dónde se puede construir; los menús también la usan, para sus zonas de la pantalla.
- **`Level`**: `const property buildZones = [wholeBoard]`. Opcional; por defecto, todo el tablero. Ejemplo: `buildZones = [new Zone(minX = 5, maxX = 12, minY = 1, maxY = 13)]`.
- **`board`** (`src/board.wlk`):
  - `buildZones(zonas)`: las cambia, y marca las celdas donde no se puede construir con un visual `BlockedCell` (`assets/blocked_cell.png`, oscurecido con rayas). Las marcas se crean sólo acá, no en cada frame.
  - `isBuildable(posición)`: en el tablero y en alguna zona.
  - `canBuild(posición, máquina)`: `canPlace` y, además, todas sus celdas en alguna zona (una de 2x2 puede quedar repartida entre dos zonas pegadas).
  - `push` **no** mira las zonas: las máquinas fijas del nivel se pueden poner en cualquier lugar.
  - `wholeBoard`: la zona "todo el tablero".
- **`place`** (`src/tools/userTools.wlk`) usa `board.canBuild` en lugar de `canPlace`.
- **`levelManager.load`** llama a `board.buildZones(level.buildZones())` antes de colocar las máquinas fijas, así las marcas quedan debajo de ellas.

**Tests** (`test/buildZonesTest.wtest`, 15): por defecto se construye en todo el tablero y no hay marcas; fuera del tablero nunca; con una zona, adentro sí y afuera no; una marca por celda bloqueada, y cambiar las zonas reemplaza las marcas; place no coloca afuera y sí adentro; una de 2x2 en parte afuera no se coloca, y repartida entre dos zonas pegadas sí; `push` no mira las zonas; cargar un nivel aplica sus zonas; las máquinas fijas se colocan fuera de las zonas; reiniciar no duplica las marcas; el modo libre vuelve a todo el tablero.

> [!NOTE]
> **Rendimiento:** con zonas chicas puede haber hasta 195 marcas (15 x 13 celdas). Son visuals quietos, con la imagen y la posición ya guardadas, como pide la regla de rendimiento. Si con muchas marcas el juego se pone lento, se puede usar una sola imagen grande por zona bloqueada en lugar de una por celda.

**Tests** (en `test/levelMachinesTest.wtest`, 21 tests, salvo los de `noRecipe`, que están en `assemblerTest`). **Hechos**, salvo volver a escribir los del Assembler borrados en 0.4:

- `new Dispenser(direction = up)` queda mirando hacia arriba aunque `toolsManager.currentDirection()` sea otra (por el `initialize` de `MachineSprite`). Ya se sabe que funciona (lo usa el test de la cadena de `assemblerTest` desde la fase 0), pero conviene un test propio.
- Una máquina bloqueada no se borra ni se rota con las herramientas, pero sí se puede editar. Y `board.clear()` **sí** la saca.
- Reiniciar `level1` no falla y deja un solo Dispenser fijo; pasar al modo libre lo saca.
- `load(level1)` coloca el Dispenser fijo en (5, 7), bloqueado.
- Un Dispenser con `availableKinds = [potato]` ofrece sólo la papa en su setting.
- **Recetas** (`test/assemblerTest.wtest` y `test/levelManagerTest.wtest`):
  - `recipeBook.changeAvailable([saladRecipe])` hace que `available()` sea sólo la ensalada; `all()` no cambia.
  - Un `RecipeSetting` ofrece las recetas disponibles, cada una con la imagen de su plato.
  - Un Assembler nuevo arranca con la primera receta disponible.
  - **Sin recetas disponibles** (`test/assemblerTest.wtest`, "tests de Assembler sin recetas disponibles"): `firstAvailable()` es `noRecipe`; un Assembler se puede crear y arranca con `noRecipe`; su setting no ofrece opciones; al prender no acepta ningún ingrediente; un catálogo con Assembler se puede mostrar en el menú. **Hechos.**
  - Elegir otra receta en su setting y prender la simulación: acepta los ingredientes de esa receta y no los de la anterior, y su capacidad es la de la receta nueva.
  - Cambiar la receta con la simulación prendida no la cambia hasta volver a prenderla.
  - `load(nivel)` con `availableRecipes = [saladRecipe]`: un Assembler del catálogo ofrece sólo la ensalada. `loadFreePlay()` vuelve a ofrecer todas.
  - Con la receta explícita, se pueden volver a escribir los tests del Assembler que se borraron en [0.4](#04-tests-que-rompieron-las-recetas-nuevas) (entregar el plato, consumir los ingredientes, esperar si la de adelante está llena).

**Listo cuando:** el nivel 1 arranca con el Dispenser colocado, que no se puede borrar ni rotar; y en un nivel con Assembler, el panel de edit ofrece sólo las recetas de ese nivel y el Assembler arma la que se eligió; y en un nivel con `buildZones`, el jugador sólo puede construir dentro de sus zonas, que se distinguen en el tablero.

---

## Fase 5: Entrada para el tutorial

**Para qué:** dejar preparado el lugar donde se va a enchufar el tutorial, sin implementarlo. Todavía no se sabe cómo va a ser, así que esta fase define **sólo el contrato** y un tutorial que no hace nada. Cuando se implemente, ninguna otra parte del juego tiene que cambiar.
**Depende de:** fase 3.

### 5.1 El contrato

Archivo nuevo: `src/levels/tutorial.wlk`.

```wollok
// Lo que el juego le avisa al tutorial del nivel. noTutorial no hace nada y deja hacer todo.
object noTutorial {
	// ----------- EVENTOS -----------
	method onLevelLoaded(level) {}
	method onToolSelected(tool) {}
	method onMachinePlaced(machine) {}
	method onMachineRemoved(machine) {}
	method onMachineRotated(machine) {}
	method onSettingChanged(machine, setting) {}
	method onSimulationToggled(running) {}
	method onDelivered(item) {}
	method onLevelWon(level) {}

	// ----------- PERMISOS -----------
	// ¿Deja usar esta herramienta (place, delete, edit, rotate) en esa celda?
	method allowsTool(tool, pos) = true
	// ¿Deja prender o apagar la simulación?
	method allowsSimulationToggle() = true

	// ----------- MENSAJE -----------
	// Las líneas que muestra levelInfoMenu en las filas 4 a 1 (cortas: unos 15 caracteres cada una)
	method messageLines() = []
}
```

`Level` recibe `const property tutorial = noTutorial`.

**Cómo quedó:** `Tutorial` es una clase con estos métodos, y `noTutorial` un objeto que hereda de ella (así los tutoriales nuevos heredan de `Tutorial`). Además del mensaje, tiene **indicadores**: `targetCells()` (dónde hay que hacer algo, con un recuadro) y `pointedCells()` (qué máquina se explica, con una flecha arriba), que dibuja `tutorialMarks`. El mensaje puede tener hasta 6 líneas.

### 5.2 Quién avisa qué

Todos los eventos pasan por `levelManager`, que los reenvía a `currentLevel.tutorial()` y después actualiza el mensaje (`levelInfoMenu.showTutorialMessage(tutorial.messageLines())`).

| Evento | Dónde se llama | Método de `levelManager` | Método del tutorial |
|---|---|---|---|
| Se cargó el nivel | `levelManager.load`, al final | (interno) | `onLevelLoaded(level)` |
| Se eligió una herramienta | `toolsManager.select` | `toolSelected(tool)` | `onToolSelected(tool)` |
| Se colocó una máquina | `place.onClick`, después del `board.push` | `machinePlaced(machine)` | `onMachinePlaced(machine)` |
| Se borró una máquina | `delete.onClick`, después del `board.pop` (la máquina se guarda antes: así el tutorial ve el tablero sin ella) | `machineRemoved(machine)` | `onMachineRemoved(machine)` |
| Se rotó una máquina | `rotate.onClick`, después de rotar | `machineRotated(machine)` | `onMachineRotated(machine)` |
| Se cambió un setting | `editMenu.onClick`, después de `setting.select(option)` | `settingChanged(machine, setting)` | `onSettingChanged(machine, setting)` |
| Se prendió o apagó | `levelManager.toggleSimulation` | (interno) | `onSimulationToggled(running)` |
| Se entregó un item | `levelManager.delivered` | (interno) | `onDelivered(item)` |
| Se ganó | `levelManager.won` | (interno) | `onLevelWon(level)` |
| Enter (seguir después de una explicación) | `userController` | `continueTutorial()` | `onContinue()` |

Los métodos de `levelManager` no hacen otra cosa que reenviar. **No se emite nada desde `board` ni desde `simulationEngine`**, para que los tests que los usan directo no dependan de los niveles.

### 5.3 Permisos

- `toolsManager.onClick`: antes de `selectedTool.onClick(pos)`, preguntar `levelManager.allowsTool(selectedTool, pos)`. Si es `false`, no hace nada.
- `levelManager.toggleSimulation()`: si `tutorial.allowsSimulationToggle()` es `false`, no hace nada. La barra espaciadora también pasa por acá (antes iba directo a `simulationEngine.toggle()` y se salteaba el nivel completo).

### 5.4 Mensaje

`levelInfoMenu.showTutorialMessage(lines)`: borra las filas 4 a 1 y escribe una línea por fila. Con `[]` (lo que devuelve `noTutorial`) quedan vacías.

**Tests** (`test/tutorialTest.wtest`, nuevo). Usan un tutorial de prueba que guarda los eventos que recibe y no deja usar `delete`:

- Colocar, rotar y borrar una máquina le llega al tutorial, en ese orden.
- Con ese tutorial, `delete` no borra.
- Prender la simulación le llega como `onSimulationToggled(true)`.
- Su `messageLines()` se ve en las filas 4 a 1.

> [!NOTE]
> Cuando se implemente, **el tutorial es un nivel más**: un `Level` (por ejemplo, el nivel 0) con su propio `tutorial`. Una forma posible es una lista de pasos, cada uno con sus líneas de mensaje, lo que permite hacer y el evento que lo da por cumplido.

**Listo cuando:** el juego funciona igual que antes (todos los niveles usan `noTutorial`) y el tutorial de prueba de los tests recibe todos los eventos.

---

## Fase 6: Energía

**Para qué:** que un nivel pueda limitar cuánta energía consumen las máquinas. Sólo si el equipo decide usar la energía como restricción. `energyConsumption()` ya existe en cada máquina, pero nadie la suma.
**Depende de:** fase 5 (la energía cambia al colocar, borrar y editar, y esos eventos ya pasan por `levelManager`).

1. `Level`: `const property energyLimit = null` (sin límite) y `method hasEnergyLimit() = energyLimit != null`.
2. `board.totalEnergy()`: `self.machines().sum({ machine => machine.energyConsumption() })`.
3. `levelInfoMenu`: si el nivel tiene límite, una fila más con `Energía: 7/10`. `levelManager` la actualiza en `machinePlaced`, `machineRemoved` y `settingChanged`.
4. `levelManager.toggleSimulation()`: al prender, si `board.totalEnergy() > energyLimit`, no prende y `levelInfoMenu` muestra `Sin energía`.

**Tests:** la suma de energía con varias máquinas; no prende si se pasa del límite; prende si está justo en el límite; sin límite, prende siempre.

**Listo cuando:** un nivel con `energyLimit` muestra la energía y no deja prender la simulación si se pasa.

---

## Decisiones

Lo que el equipo todavía puede cambiar. **El plan implementa la opción "por defecto"**; si se decide otra, actualizar la fase correspondiente antes de programarla, y anotar acá lo que se decidió.

| Decisión | Por defecto (lo que implementa el plan) | Alternativas | Fase |
|---|---|---|---|
| Celdas de entrega | (16, 14) y (17, 14), contando los píxeles de `background.png` | Otras celdas | 2 |
| ¿Qué acepta cada platito? | Cualquier comida | Cada platito es un cliente con su pedido (un filtro en `canReceive`, configurado por el nivel) | 2 |
| Al ganar | Se apaga la simulación y se espera la tecla N | Seguir jugando | 3 |
| Después del último nivel | `¡Fin del juego!`; se puede reiniciar (0) o pasar al modo libre (L) | Volver al primer nivel | 3 |
| ¿Reiniciar borra lo construido? | Sí: vuelve a cargar el nivel. Para sólo volver a correr está la tecla 5 | Reiniciar sin tocar las máquinas | 3 |
| ¿El progreso se pierde al apagar? | Sí: el objetivo se cumple en una sola corrida | Acumular entre corridas | 3 |
| Modo libre | Existe (`freePlay`, tecla L), y la L también vuelve al nivel que toca jugar | Sacarlo | 3 |
| ¿Se conserva lo construido al ir al modo libre y volver? | No: el nivel se vuelve a cargar desde cero | Guardar las máquinas del nivel y restaurarlas (mucho más trabajo) | 3 |
| ¿Se guarda el progreso al cerrar el juego? | No: sólo mientras está abierto | — | 3 |
| ¿La L funciona con la simulación prendida? | **Decidido:** no, no hace nada | Apagar la simulación y cambiar | 3 |
| Teclas | N (siguiente), 0 (reiniciar), L (libre) | Otras | 3 |
| ¿Cómo se sacan papas fritas de la freidora en `level1`? | Con el brazo inteligente filtrando papas fritas: `level1` lo ofrece desde la fase 4 | Que el brazo común espere a que el item esté procesado antes de sacarlo de la freidora (cambia su comportamiento en todos los niveles) | 3 y 4 |
| ¿Las máquinas fijas se pueden editar? | Sí, pero no borrar ni rotar | No se pueden tocar | 4 |
| ¿Dónde dice un nivel qué recetas se pueden armar? | En el nivel (`availableRecipes`), y `levelManager` se las pasa a `recipeBook`, como el catálogo de máquinas | En cada Assembler del catálogo (`new Assembler(availableRecipes = [...])`), como `availableKinds` del Dispenser: no necesita `recipeBook`, pero hay que repetirlas en cada Assembler | 4 |
| ¿Qué pasa si se cambia la receta con la simulación prendida? | Se usa desde la próxima vez que se prende | Bloquear el panel de edit mientras corre la simulación (afecta a todos los settings) | 4 |
| ¿Hay límite de energía? | No se implementa hasta decidirlo (fase 6 opcional) | Implementar la fase 6 | 6 |
