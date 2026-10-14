# Plan: contrato de las máquinas

Objetivo: que crear una máquina nueva sea **elegir qué la hace distinta** (qué acepta, qué guarda, qué le hace al item, a quién se lo da) y no reescribir el flujo de la simulación. El contrato final está en [`src/machines/README.md`](../src/machines/README.md#el-contrato-de-machine).

## Por qué

Hoy el engine sólo sabe despertar a una máquina, y lo hace siempre con `use()`, sin decirle por qué. Una máquina se despierta por cuatro motivos distintos (pasó un tiempo, llegó un item, terminó una animación, se liberó la de adelante), así que cada `use()` deduce el motivo por su estado. Eso hace que:

- no se pueda leer qué hace una máquina sin seguir quién agenda qué;
- cada máquina nueva repita el mismo despacho (`if` sobre su estado);
- haya reglas que el código no garantiza: llamar a `wakeWaiting()` al liberarse, vaciar `heldItem` en `reset()` y no mover items en el bloque de `play()`;
- las máquinas que no manejan items repitan `canReceive() = false`, `receive(_) {}` y `use() {}`.

## Cómo usar este plan

- **Cada fase deja el juego andando y los tests en verde.** Hacer un commit por fase (o por paso, si la fase es grande).
- Las fases 1 a 3 se pueden hacer ya. Las 4 a 7 conviene encararlas cuando la cortadora esté terminada: diseñarlas antes es adivinar.
- La cortadora está en desarrollo: **no tocarla** hasta la fase 5. Mientras tanto, si una fase rompe su código, alcanza con dejarla compilando.
- Al terminar cada fase, borrar su fila de la tabla "Estado actual" de [`src/machines/README.md`](../src/machines/README.md#estado-actual-mientras-dura-la-migración) y de [`src/simulation/README.md`](../src/simulation/README.md#estado-actual-mientras-dura-la-migración).

Para medir rendimiento (fases 0, 2 y 3): correr el juego, tocar **M** y **L**, esperar que `tick` baje a ~100 ms, tocar **5** y anotar `items`, `tick` y `max` a los 30 segundos (ver el [README principal](../README.md#pruebas-de-carga)).

## ROADMAP
- [X] [Fase 0: Preliminar](#fase-0-preliminar)
- [ ] [Fase 1: bloques de fin de animación seguros](#fase-1-bloques-de-fin-de-animación-seguros)
- [ ] [Fase 2: agendar acciones en vez de máquinas](#fase-2-agendar-acciones-en-vez-de-máquinas)
- [ ] [Fase 3: `Inventory` y el contrato de items](#fase-3-inventory-y-el-contrato-de-items)
- [ ] [Fase 4: contrato de los ingredientes](#fase-4-contrato-de-los-ingredientes)
- [ ] [Fase 5: la cortadora con el contrato](#fase-5-la-cortadora-con-el-contrato)
- [ ] [Fase 6: `ProcessingMachine` (cuando haya 2 máquinas que procesan)](#fase-6-processingmachine-cuando-haya-2-máquinas-que-procesan)
- [ ] [Fase 7: recetas y Assembler](#fase-7-recetas-y-assembler)

---

## Fase 0: Preliminar

Antes de cambiar el diseño, los tests tienen que pasar. Hoy fallan 23, todos por el refactor en curso y no por bugs del juego.

| Falla | Arreglo |
|---|---|
| `Could not resolve reference to instantiated module Carne` (8 tests) | En `test/animationTest.wtest:9`, cambiar `import src.simulation.ingredientes.*` por `import src.food.ingredientes.*` |
| `a Sprite does not understand play(...)` (9) y `a Sink does not understand offsetX()` (4) | `use()` pasó a ser abstracto en `Machine`, así que `Sprite` y `Sink` (las máquinas de prueba de `test/animationTest.wtest`) quedaron abstractas. Agregarles `override method use() {}` |
| `menuManagerTest`: la última página (2 tests) | El catálogo pasó de 6 a 7 máquinas (se agregó `Fryer`). Actualizar lo que esperan: la última página ahora tiene 3 máquinas (`[1, 1, 1, 0]`), y el test "clickear un slot libre…" hace click en `game.at(22, 4)`, que ahora es el slot de `Fryer`: cambiarlo por la celda del slot 4, que es el que queda libre |

También:
- [X] **AutomaticArm: usar `direction` en vez de `facing`.** En el refactor se borró su `staticImage()`, y desde entonces, al terminar de agarrar un item, el brazo se ve mirando hacia abajo en vez de hacia donde quedó. En lugar de volver a sobrescribir `staticImage()`, que el brazo guarde hacia dónde mira en `direction`: como no rota, `direction` está libre, y la base ya arma con ella `staticImage()` y las animaciones.
  - Borrar `var facing = down` y reemplazar `facing` por `direction` en `continueWork`, `turnToItem`, `carry` y `deliver`.
  - En `reset()`, `direction = down` (antes de `super()`, que muestra la imagen quieta con la `direction` de ese momento).
  - Dejar `rotate()` sobrescrito vacío: si no, la herramienta de rotar le cambiaría la dirección.
  - En el comentario de `next` en `Machine` (`machineClasses.wlk`), aclarar que el brazo es la única máquina cuya dirección cambia con la simulación prendida, y que por eso no usa `next`.
  - Test: después de agarrar un item que viene de un lado, `image()` es el `_game.png` del lado contrario.

**Listo cuando:** `wollok test --skipValidations` da 0 fallas.

---

## Fase 1: bloques de fin de animación seguros

**Qué resuelve:** hoy el bloque de `play(animación, bloque)` corre dentro de `animationEngine.tick()`, mientras se recorre la lista de animados, y ahí no se puede mover items. Por eso existe `playThenWake` y el brazo termina cada animación con `schedule(1, self)`.

**Cambio:** que el `animationEngine` junte los bloques de las animaciones que terminaron y los ejecute **después** de recorrer y limpiar la lista.

1. En `animationEngine` (`src/simulation/animationEngine.wlk`):
   - Agregar `var pendientes = []` y `method alTerminar(bloque) { pendientes.add(bloque) }`.
   - En `tick()`, después del `filter`, ejecutar los pendientes **con `ticking` todavía en `true`** (así `play()` encadenado arranca en el frame 0 y no repite el primero, como hoy):
     ```wollok
     method tick() {
         ticking = true
         animados.forEach({ o => o.avanzar() })
         if (algunoLlego) {
             animados = animados.filter({ o => o.animando() })
             algunoLlego = false
         }
         if (!pendientes.isEmpty()) {
             const bloques = pendientes
             pendientes = []
             bloques.forEach({ b => b.apply() })
         }
         ticking = false
     }
     ```
   - Agregar un `method reset() { pendientes = [] }` y llamarlo desde `simulationEngine.stop()`, para que no corra un bloque de una animación cortada.
2. En `MachineAnimator.avanzar()` (`src/machines/machineClasses.wlk`): en vez de `afterBlock.apply()`, hacer `animationEngine.alTerminar(afterBlock)`. Simplificar el final: la animación termina siempre (`animation = null` y `avisarLlegada()`), porque si el bloque encadena otra, `play()` vuelve a anotar a la máquina (ya no está "animando").
3. Revisar que `play()` siga funcionando llamado desde el bloque: como la máquina ya salió de la lista, `animando()` es false y se vuelve a agregar con `animar(self)`. Eso es lo correcto.
4. **AutomaticArm:** en los bloques de `turnToItem` y `carry`, reemplazar `simulationEngine.schedule(1, self)` por la llamada directa (`self.continueWork()`). Ojo con el tiempo: hoy el paso siguiente arranca un paso después. Si algún test de `animationTest` mide pasos exactos, ajustarlo o confirmar que el cambio de un paso es aceptable.
5. Borrar `playThenWake` de `Machine` (hoy no lo usa nadie) y el "OJO" de los comentarios de `play()` y del brazo.

**Tests:** `test/animationTest.wtest`. Agregar uno que mueva un item desde el bloque de `play()` y verifique que llega.

**Listo cuando:** en ningún bloque de `play()` hay un `schedule(1, self)`.

---

## Fase 2: agendar acciones en vez de máquinas

**Qué resuelve:** `use()` deduce por qué la despertaron. Con `after(pasos, bloque)` el motivo queda escrito en el bloque, y `use()` desaparece.

1. En `simulationEngine`:
   - Agregar `method after(steps, action)`: igual que `schedule`, pero guarda el bloque. En `step()`, `due.forEach({ action => action.apply() })`.
   - Durante la migración pueden convivir: `schedule(steps, machine)` puede pasar a ser `self.after(steps, { machine.use() })`.
   - `pendingWakeUps()` sigue funcionando (cuenta bloques). Renombrarlo a `pendingActions()` cuando ya no haya `use()`.
2. En `Machine`, reemplazar la espera por máquinas por una espera por bloques:
   - `waiting` guarda bloques. `method whenFree(action) { waiting.add(action) }`.
   - `wakeWaiting()` agenda cada bloque: `waiting.forEach({ action => simulationEngine.after(1, action) })`.
   - Borrar `addWaiting` y `waitForNext` cuando nadie los use.
3. Migrar los tipos, de a uno, corriendo los tests después de cada uno:
   - **Belt:** `receive` agenda `after(pasosPorCelda, { self.tryPush() })`. `tryPush()`: si `canPush()`, entrega y `wakeWaiting()`; si no, `next.whenFree({ self.tryPush() })`. El chequeo `if (heldItem.moviendose()) schedule(1)` ya no hace falta: el bloque se agenda exactamente para cuando llega.
   - **Dispenser:** `start` agenda `after(intervalSteps, { self.tryDispense() })`. `tryDispense()`: si puede, dispensa y agenda el próximo; si no, `next.whenFree({ self.tryDispense() })`. **No usar un `every`**: el dispenser frenado tiene que dispensar apenas se libera la cinta (lo prueba "un dispenser frenado dispensa apenas se libera la belt"), y no en el próximo intervalo.
   - **AutomaticArm:** `deliver()` usa `target.whenFree({ self.deliver() })` en vez de `addWaiting(self)`. Con la fase 1, sus bloques de animación ya llaman directo a lo que sigue. `use()` y `continueWork()` desaparecen.
   - **Oven, Fryer, Assembler, CuttingMachine:** borrar su `use() {}` cuando `use()` deje de ser abstracto.
4. Borrar `use()` de `Machine` y `schedule` del engine.
5. Revisar que **toda acción agendada revise el estado** (por ejemplo, `tryPush` vuelve a preguntar `canPush()`).

**Tests:** `test/simulationTest.wtest` y `test/animationTest.wtest`. Los que prueban `use()` directamente se reescriben con `step()`.

**Rendimiento:** cada `after` crea un bloque. Medir con el stress test y comparar con la fase 0. Si empeora mucho, la alternativa es guardar en la agenda pares (máquina, acción) con objetos de acción reusables, en vez de bloques nuevos.

**Listo cuando:** no queda ningún `use()` ni `schedule(` en `src/`.

---

## Fase 3: `Inventory` y el contrato de items

**Qué resuelve:** cada tipo reimplementa recibir, guardar, entregar y liberar, y las que no manejan items repiten el código de relleno.

1. Crear `src/machines/inventory.wlk` con `class Inventory`:
   - `const capacity`, `const items = []`, `const waiting = []`.
   - `hasRoom() = items.size() < capacity`, `add(item)`, `items()`, `isEmpty()`, `first()`.
   - `release(item)`: lo saca de `items` y agenda los bloques de `waiting` (lo que hoy hace `wakeWaiting`). **Así nadie se olvida de despertar a las que esperan.**
   - `whenFree(action)` y `clear()` (vacía items y esperas).
2. En `Machine`:
   - Reemplazar `heldItem` por `const inventory = new Inventory(capacity = self.capacity())` y `method capacity() = 1`. Ojo: Wollok inicializa los atributos la primera vez que se leen, así que si hace falta, crearlo en `initialize()` (como hace `MachineSprite` con la imagen).
   - `heldItems() = inventory.items()`. Actualizar `simulationEngine.allItems()` y `board.pop()`, que ya usan `heldItems()`.
   - `canReceive(item) = inventory.hasRoom()`. **Cambiar todas las llamadas** a `canReceive()` para que pasen el item (`canPush` también lo recibe).
   - `receive(item)`: `inventory.add(item)` y `self.onReceive(item)`. No se sobrescribe.
   - `onReceive(item)`: anima el item hasta la celda y `after(pasosPorCelda, { self.onArrived(item) })`.
   - `onArrived(item) { self.tryPush() }`.
   - `outputTarget() = next`, `itemToPush() = inventory.first()`, `onPushed(item) {}`.
   - `tryPush()`: si hay `outputTarget()` y `itemToPush()`, y el destino puede recibirlo, `inventory.release(item)`, `target.receive(item)` y `self.onPushed(item)`; si no puede, `target.whenFree({ self.tryPush() })`.
   - `whenFree(action) { inventory.whenFree(action) }`.
   - `reset()`: agregar `inventory.clear()`.
3. Migrar los tipos:
   - **Belt:** queda en `name()` y `runningImage()`.
   - **Dispenser:** como el ejemplo de [`src/machines/README.md`](../src/machines/README.md#ejemplos): `canReceive(item) = false`, guarda en el inventario el item que crea y agenda el próximo en `onPushed`. **Cambia un comportamiento:** mientras está frenado, el item queda visible sobre el dispenser (hoy no se crea hasta que hay lugar). Decidir si está bien; si no, que `dispense()` pregunte antes de crear.
   - **AutomaticArm:** sobrescribe `onReceive(item)` (gira y lo agarra, sin animarlo hasta su celda) y `outputTarget()` (la máquina del lado `direction`, que después de agarrar el item apunta hacia donde lo entrega). `deliver()` pasa a ser `tryPush()`. Su `reset()` sólo reinicia `from`, `grabbed` y `direction`.
   - **Oven, Fryer, Assembler:** `canReceive(item) = false` y borrar su `receive(_) {}`. Si no, actuarían como cintas.
4. Borrar del código lo que ya no se usa: `heldItem`, `canPush`, `push`, `wakeWaiting`, `waiting` de `Machine`.

**Tests:** los de simulación y animación. Agregar uno de `Inventory` (capacidad, `release` despierta a las que esperan, `clear`). La máquina de prueba `Sink` de `animationTest` se simplifica (`canReceive(item) = accepting`).

**Listo cuando:** Belt tiene sólo `name()` y `runningImage()`, y la tabla "Estado actual" del README de máquinas está vacía.

---

## Fase 4: contrato de los ingredientes

Cuando la cortadora defina lo que necesita.

1. Pasar a `Ingrediente` (`src/food/ingredientes.wlk`) lo que se le puede hacer a cualquier ingrediente: `puedeCortarse()`, `cortar()`, `puedeCocinarse()`, `cocinar(tiempo)`, `estado()`. Ver la tabla de [`src/food/README.md`](../src/food/README.md#contrato-de-un-ingrediente-a-implementar-fase-4-del-plan).
2. La imagen sale del estado: `food/<ingredients>/<ingredient>_<state>.png` (ver [`assets/README.md`](../assets/README.md#food)).
3. Que `Carne` herede de verdad de `Ingrediente` y sólo diga lo que tiene de distinto.

**Listo cuando:** ninguna máquina le manda a un item un mensaje que no esté en `Ingrediente`.

---

## Fase 5: la cortadora con el contrato

1. `CuttingMachine` con `canReceive(item) = super(item) && item.puedeCortarse()` y `onArrived(item)` que anima, corta y hace `tryPush()` (ver el ejemplo del README de máquinas).
2. Renombrar sus carpetas de animación a la convención `<direccion>_<accion>/`: `down/` → `down_cut/`, etc. Así funciona `actionAnimation("cut", 17)`.

**Listo cuando:** una cadena dispenser → cinta → cortadora → cinta entrega carne cortada, con un test que lo pruebe.

---

## Fase 6: `ProcessingMachine` (cuando haya 2 máquinas que procesan)

Si Oven o Fryer repiten el `onArrived` de la cortadora ("animar, transformar, entregar"), extraer el patrón:

```wollok
class ProcessingMachine inherits Machine {
	method processAnimation()      // abstracto: la animación del proceso
	method process(item)           // abstracto: lo que le hace al item
	override method onArrived(item) {
		self.play(self.processAnimation(), {
			self.process(item)
			self.tryPush()
		})
	}
}
```

No hacerlo antes: con una sola máquina no se sabe qué parte es común.

---

## Fase 7: recetas y Assembler

1. Una `Receta` con sus entradas (clase de ingrediente y estado) y su producto.
2. `Assembler`: `capacity()` igual a la cantidad de entradas, `canReceive(item)` sólo si la receta todavía lo necesita, `onArrived` arma el producto cuando están todas, y `itemToPush()` devuelve el producto.

---

## Pendientes sueltos

- [ ] `Oven`: sólo tiene `up_game.png` y `up.gif` en `assets/machines/Oven/`. Faltan las otras direcciones y los `_menu.png` (se pueden generar con `assetGenerator.py`).
- [ ] `Fryer`: no tiene carpeta en `assets/machines/`.
- [ ] El comentario "METODOS A REESCRIBIR PARA INSTANCIAR MAQUINA" al principio de `src/machines/machineClasses.wlk` queda obsoleto en la fase 3: reemplazarlo por un link al contrato del README.
