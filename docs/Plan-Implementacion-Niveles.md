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
- [ ] [Fase 2: Puntos de entrega y objetivos](#fase-2-puntos-de-entrega-y-objetivos)
- [ ] [Fase 3: `Level` y `levelManager`](#fase-3-level-y-levelmanager) ← con 0 a 3 ya hay un primer nivel jugable
- [ ] [Fase 4: Máquinas fijas y parametrizadas](#fase-4-máquinas-fijas-y-parametrizadas)
- [ ] [Fase 5: Entrada para el tutorial](#fase-5-entrada-para-el-tutorial)
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

### 3.1 Archivos

| Archivo | Qué tiene |
|---|---|
| `src/levels/levelClasses.wlk` (nuevo) | La clase `Level` |
| `src/levels/levels.wlk` (nuevo) | Los niveles concretos: `freePlay` y `level1` |
| `src/levels/levelManager.wlk` (de la fase 2) | Se completa: el nivel actual, cargarlo, ganar, reiniciarlo y pasar al siguiente |
| `src/levels/niveles.wlk` | **Se borra** (`Nivel` vacío, reemplazado por `Level`) |
| `src/menu/menuText.wlk` (nuevo) | `MenuText`, movido desde `editMenu.wlk` para que lo usen los dos menús |
| `src/menu/levelInfoMenu.wlk` | Hoy vacío: pasa a mostrar la información del nivel |
| `src/input/userController.wlk` | Las teclas nuevas |
| `src/main.wpgm` | Llama a `levelManager.start()` |

> [!IMPORTANT]
> **Primera tarea: comprobar los imports circulares.** `deliverySlot.wlk` importa `levelManager`, y `levelManager` importa `machineManager`, que importa todas las máquinas. Correr los tests apenas se crea `levelManager.wlk` completo. Si Wollok no lo resuelve, el `DeliverySlot` recibe a quién avisar al crearlo (`const listener`) y `deliveryPoints` le pasa `levelManager`.

### 3.2 `Level`: sólo datos

Archivo: `src/levels/levelClasses.wlk`.

```wollok
class Level {
	const property name
	const property availableMachines          // factories, como el catálogo de machineManager
	const property fixedMachines = []         // Placements (fase 4); hasta entonces, vacío
	const property goal

	// Coloca las máquinas que trae el nivel. Con fixedMachines vacío no hace nada.
	method placeFixedMachines() {
		fixedMachines.forEach({ placement => board.push(placement.position(), placement.create()) })
	}
}
```

### 3.3 Los niveles concretos

Archivo: `src/levels/levels.wlk`. Son objetos bien conocidos, con la misma forma que `burgerRecipe`:

```wollok
// Modo libre: todas las máquinas y sin objetivo. Es el juego de hoy, para probar.
object freePlay inherits Level(name = "Libre", availableMachines = machineManager.allMachines(), goal = noGoal) {}

// Primer nivel: cortar papas y entregarlas
object level1 inherits Level(
	name = "Nivel 1",
	availableMachines = [{ => new Belt() }, { => new Dispenser() }, { => new CuttingMachine() }],
	goal = new DeliveryGoal(kind = cutPotato, amount = 3, label = "Papas cortadas")
) {}
```

### 3.4 `levelManager`

Archivo: `src/levels/levelManager.wlk`.

**Estado:**

| Atributo | Qué guarda |
|---|---|
| `const levels = [level1]` | Los niveles en el orden en que se juegan. `freePlay` **no** está en la lista |
| `var currentLevel = null` | El nivel cargado |
| `var completed = false` | Si ya se cumplió el objetivo del nivel cargado |

**Métodos:**

| Método | Qué hace |
|---|---|
| `start()` | Lo llama `main.wpgm` una sola vez: `self.load(levels.first())` |
| `load(level)` | Arma el nivel desde cero (ver [3.5](#35-el-orden-de-load)) |
| `restart()` | `self.load(currentLevel)`. Borra también lo que construyó el jugador |
| `hasNext()` | `true` si `currentLevel` está en `levels` y no es el último. Con `freePlay` es `false` |
| `next()` | Si `completed` y `hasNext()`, carga el siguiente de `levels`. Si no, no hace nada |
| `toggleSimulation()` | Lo que hace la tecla 5 (ver [3.6](#36-la-tecla-5-pasa-por-levelmanager)) |
| `delivered(item)` | Lo llama `DeliverySlot` (ver [3.7](#37-entregar-y-ganar)) |
| `currentLevel()`, `completed()` | Getters, para los menús y los tests |

### 3.5 El orden de `load`

Primero se apaga y se limpia, después se arma:

1. `simulationEngine.reset()`: apaga la simulación (si estaba prendida), saca los items y vuelve a velocidad 1.
2. `board.clear()`: saca las máquinas (los platitos quedan).
3. `toolsManager.reset()`: sin herramienta y dirección `right`.
4. `currentLevel = level` y `completed = false`.
5. `machineManager.changeCatalog(level.availableMachines())` y `placeMenu.resetPage()`.
6. `level.placeFixedMachines()`.
7. `level.goal().reset()`.
8. `levelInfoMenu.show(level)`.

### 3.6 La tecla 5 pasa por `levelManager`

Hoy `userController` llama directo a `simulationEngine.toggle()`. Pasa a llamar a `levelManager.toggleSimulation()`:

```wollok
method toggleSimulation() {
	if (!completed) {
		simulationEngine.toggle()
		// Al apagar se borran los items: el progreso vuelve a cero
		if (!simulationEngine.running()) {
			currentLevel.goal().reset()
			levelInfoMenu.updateProgress(currentLevel.goal())
		}
	}
}
```

Con el nivel completo, la tecla 5 no hace nada: hay que pasar al siguiente (N) o reiniciar (0).

### 3.7 Entregar y ganar

`delivered(item)` se ejecuta **en medio de un paso de simulación** (dentro del `onArrived` del `DeliverySlot`), y en ese mismo paso pueden quedar otras acciones por correr. Si se apagara la simulación ahí mismo, esas acciones correrían sobre máquinas ya reseteadas. Por eso el final se agenda para el paso siguiente:

```wollok
method delivered(item) {
	if (!completed) {
		currentLevel.goal().delivered(item)
		levelInfoMenu.updateProgress(currentLevel.goal())
		if (currentLevel.goal().isMet()) self.won()
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
| 11 | `OBJETIVO` (no se muestra si `progressText()` es `""`) |
| 10 | `goal.progressText()` |
| 8 | Al ganar: `¡Nivel completo!`, o `¡Fin del juego!` si no hay siguiente |
| 7 | Al ganar: `N: siguiente`, o `0: reiniciar` si no hay siguiente |
| 5 a 1 | Reservadas para el mensaje del tutorial (fase 5) |

| Método | Lo llama | Qué hace |
|---|---|---|
| `show(level)` | `levelManager.load` | Borra todo lo que había y dibuja las filas 13 a 10 |
| `updateProgress(goal)` | `levelManager` al entregar y al apagar | Reemplaza sólo el texto de la fila 10 |
| `showCompleted(hasNext)` | `levelManager.finishLevel` | Agrega las filas 8 y 7 |

- **Sólo se actualiza cuando lo llaman**, nunca en cada frame (ver la regla de rendimiento en [`src/README.md`](../src/README.md#convenciones)). `MenuText` tiene el texto fijo: para cambiarlo, se saca el visual y se agrega uno nuevo.
- Wollok no corta el texto en varias líneas: los textos tienen que ser cortos (unos 15 caracteres).
- Con `freePlay` muestra sólo `LIBRE`.

### 3.9 Teclas

Archivo: `src/input/userController.wlk`. Hoy se usan Q, E, P, X, Z, R, W, A, S, D, 1, 2, 3 y 5.

| Tecla | Qué hace |
|---|---|
| 5 | `levelManager.toggleSimulation()` (antes, `simulationEngine.toggle()`) |
| N | `levelManager.next()` |
| 0 | `levelManager.restart()` (la R ya es rotar) |
| L | `levelManager.load(freePlay)`: pasar al modo libre |

### 3.10 Documentación

- Reescribir [`src/levels/README.md`](../src/levels/README.md): `Level`, `levelManager`, el orden de `load`, cómo se gana y **cómo agregar un nivel**.
- [`src/menu/README.md`](../src/menu/README.md): `levelInfoMenu` y `MenuText` en su archivo.
- [`src/input/README.md`](../src/input/README.md) y la sección de teclas de [`README.md`](../README.md).

### 3.11 Tests

En `test/levelManagerTest.wtest` (nuevo):

- `load(level1)`: el catálogo es el de `level1`, `placeMenu` está en la página 0 y la máquina elegida es la cinta.
- `load` con la simulación prendida la apaga y saca items y máquinas; los platitos quedan.
- Entregar una papa cortada actualiza el progreso; una papa entera, no.
- Al entregar la tercera papa cortada, `completed()` es `true`; la simulación sigue prendida en ese paso y se apaga en el siguiente.
- Después de ganar, otra entrega no cambia el progreso y `toggleSimulation()` no prende la simulación.
- Apagar la simulación sin haber ganado vuelve el progreso a cero.
- `next()` sin haber ganado no cambia de nivel.
- `restart()` vuelve el progreso a cero y saca las máquinas que colocó el jugador.
- Con `freePlay`, entregar cualquier cosa nunca completa el nivel, y `hasNext()` es `false`.

**Listo cuando:** al abrir el juego arranca el nivel 1, se ve su objetivo a la izquierda, se puede ganar entregando 3 papas cortadas, y las teclas N, 0 y L funcionan.

---

## Fase 4: Máquinas fijas y parametrizadas

**Para qué:** que un nivel pueda traer máquinas ya colocadas que el jugador no puede mover, y armar su catálogo con máquinas configuradas.
**Depende de:** fase 3.

### 4.1 Máquinas que coloca el nivel

Archivo nuevo: `src/levels/placement.wlk`.

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

- **`Assembler`:** ya tiene `const recipe = burgerRecipe`. Wollok permite pasarlo al crearlo (`new Assembler(recipe = otraReceta)`): **sólo hay que confirmarlo con un test**.
- **`Dispenser`:** agregar `const availableKinds = [lettuce, bun, friedPotato, potato, tomato, meat]` (la lista de hoy) y usarlo en el `ProductSetting` (`kinds = availableKinds`). Ojo: el valor por defecto (`potato`) tiene que estar en la lista; si un nivel pasa una lista sin papa, también tiene que pasar `value`.

### 4.4 Usarlo en `level1`

`level1` pasa a traer el Dispenser colocado y bloqueado, que sólo larga papas, y lo saca del catálogo:

```wollok
object level1 inherits Level(
	name = "Nivel 1",
	availableMachines = [{ => new Belt() }, { => new CuttingMachine() }],
	fixedMachines = [new Placement(position = game.at(5, 7), factory = { => new Dispenser(direction = right, availableKinds = [potato]) })],
	goal = new DeliveryGoal(kind = cutPotato, amount = 3, label = "Papas cortadas")
) {}
```

**Tests:**

- `new Dispenser(direction = up)` queda mirando hacia arriba aunque `toolsManager.currentDirection()` sea otra (por el `initialize` de `MachineSprite`). Ya se sabe que funciona (lo usa el test de la cadena de `assemblerTest` desde la fase 0), pero conviene un test propio.
- Una máquina bloqueada no se borra ni se rota con las herramientas, pero sí se puede editar.
- `load(level1)` coloca el Dispenser fijo en (5, 7), bloqueado.
- `new Assembler(recipe = ...)` usa esa receta.
- Un Dispenser con `availableKinds = [potato]` ofrece sólo la papa en su setting.

**Listo cuando:** el nivel 1 arranca con el Dispenser colocado, que no se puede borrar ni rotar.

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
	// Las líneas que muestra levelInfoMenu en las filas 5 a 1 (cortas: unos 15 caracteres cada una)
	method messageLines() = []
}
```

`Level` recibe `const property tutorial = noTutorial`.

### 5.2 Quién avisa qué

Todos los eventos pasan por `levelManager`, que los reenvía a `currentLevel.tutorial()` y después actualiza el mensaje (`levelInfoMenu.showTutorialMessage(tutorial.messageLines())`).

| Evento | Dónde se llama | Método de `levelManager` | Método del tutorial |
|---|---|---|---|
| Se cargó el nivel | `levelManager.load`, al final | (interno) | `onLevelLoaded(level)` |
| Se eligió una herramienta | `toolsManager.select` | `toolSelected(tool)` | `onToolSelected(tool)` |
| Se colocó una máquina | `place.onClick`, después del `board.push` | `machinePlaced(machine)` | `onMachinePlaced(machine)` |
| Se borró una máquina | `delete.onClick`, antes del `board.pop` (después ya no está) | `machineRemoved(machine)` | `onMachineRemoved(machine)` |
| Se rotó una máquina | `rotate.onClick`, después de rotar | `machineRotated(machine)` | `onMachineRotated(machine)` |
| Se cambió un setting | `editMenu.onClick`, después de `setting.select(option)` | `settingChanged(machine, setting)` | `onSettingChanged(machine, setting)` |
| Se prendió o apagó | `levelManager.toggleSimulation` | (interno) | `onSimulationToggled(running)` |
| Se entregó un item | `levelManager.delivered` | (interno) | `onDelivered(item)` |
| Se ganó | `levelManager.won` | (interno) | `onLevelWon(level)` |

Los métodos de `levelManager` no hacen otra cosa que reenviar. **No se emite nada desde `board` ni desde `simulationEngine`**, para que los tests que los usan directo no dependan de los niveles.

### 5.3 Permisos

- `toolsManager.onClick`: antes de `selectedTool.onClick(pos)`, preguntar `levelManager.allowsTool(selectedTool, pos)`. Si es `false`, no hace nada.
- `levelManager.toggleSimulation()`: si `tutorial.allowsSimulationToggle()` es `false`, no hace nada.

### 5.4 Mensaje

`levelInfoMenu.showTutorialMessage(lines)`: borra las filas 5 a 1 y escribe una línea por fila. Con `[]` (lo que devuelve `noTutorial`) quedan vacías.

**Tests** (`test/tutorialTest.wtest`, nuevo). Usan un tutorial de prueba que guarda los eventos que recibe y no deja usar `delete`:

- Colocar, rotar y borrar una máquina le llega al tutorial, en ese orden.
- Con ese tutorial, `delete` no borra.
- Prender la simulación le llega como `onSimulationToggled(true)`.
- Su `messageLines()` se ve en las filas 5 a 1.

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
| Modo libre | Existe (`freePlay`, tecla L) | Sacarlo | 3 |
| Teclas | N (siguiente), 0 (reiniciar), L (libre) | Otras | 3 |
| ¿Las máquinas fijas se pueden editar? | Sí, pero no borrar ni rotar | No se pueden tocar | 4 |
| ¿Hay límite de energía? | No se implementa hasta decidirlo (fase 6 opcional) | Implementar la fase 6 | 6 |
