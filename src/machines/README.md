# `machines/`

Las máquinas del juego: qué hacen, cómo se dibujan, qué tipos hay y cuáles aparecen en el menú.

> [!IMPORTANT]
> Este README describe el **contrato de `Machine`**, ya implementado (fases 1 a 7 del [plan de implementación](../../docs/plan-contrato-maquinas.md))

| Archivo | Qué tiene |
|---|---|
| `machineClasses.wlk` | Las clases base de todas las máquinas: `MachineAnimator`, `MachineSprite` y `Machine` |
| `inventory.wlk` | `Inventory`: los items que guarda una máquina y los que esperan que se libere lugar |
| `types/` | Las máquinas concretas, **una por archivo** con el nombre de su clase: `belt.wlk`, `dispenser.wlk`, `automaticArm.wlk`, `assembler.wlk`, `oven.wlk`, `cuttingMachine.wlk`, `fryer.wlk` |
| `machineManager.wlk` | El catálogo de máquinas del menú y cuál está elegida para colocar |

> **Quién conoce las máquinas concretas:** sólo `machineManager` (para el catálogo), `stressTest/stressTestBoard.wlk` (arma un tablero de prueba con cintas y un dispenser) y los tests. El resto del juego (tablero, simulación, herramientas, menú) trabaja con cualquier `Machine` sin saber cuál es. Mantenerlo así: si otra parte necesita algo de una máquina, agregarlo como método de `Machine` y que cada tipo lo sobrescriba.

## Las clases base

Cada capa se ocupa de una cosa, y cada una hereda de la anterior:

```
MachineAnimator   ← reproducir animaciones frame a frame
      ▲
MachineSprite     ← qué imagen muestra y dónde se dibuja
      ▲
   Machine        ← qué hace: dirección, vecina, items, simulación
      ▲
Belt, Dispenser, AutomaticArm, ...
```

**Regla:** si cambia lo que se ve, va en `MachineSprite` (o `MachineAnimator`); si cambia lo que hace, va en `Machine`.

## Cómo piensa una máquina

Una máquina **no tiene un método que se llame en cada paso**. Reacciona a cosas que le pasan, y cada reacción dice qué hace a continuación:

```
receive(item) ──▶ onReceive(item) ──▶ (el item termina de llegar) ──▶ onArrived(item) ──▶ tryPush()
                                                                                          │
                          si la de adelante está llena, espera a que se libere ◀──────────┘
```

Las herramientas para decir "a continuación" son:

| Herramienta | Qué hace |
|---|---|
| `simulationEngine.after(pasos, bloque)` | Ejecuta el bloque dentro de esa cantidad de pasos |
| `maquina.whenFree(bloque)` | Ejecuta el bloque cuando esa máquina libere lugar |
| `play(animación, bloque)` | Reproduce la animación y, al terminar, ejecuta el bloque. **En el bloque se puede hacer cualquier cosa**, incluso mover items |

> [!IMPORTANT]
> **Toda acción agendada revisa el estado antes de actuar.** Entre que se agenda un bloque y que se ejecuta pueden pasar cosas (por ejemplo, otra máquina ocupó el lugar). `tryPush()` ya lo hace: vuelve a preguntar `canReceive(item)` y, si no puede, vuelve a esperar.

## El contrato de `Machine`

Una máquina nueva sobrescribe **sólo lo que la hace distinta**. Todo lo demás tiene un comportamiento por defecto.

### Obligatorio

| Método | Para qué |
|---|---|
| `name()` | La carpeta de sus imágenes (`assets/machines/<name>/`). Es lo único abstracto |

### Opcional: lo que define qué hace

**Entrada**

| Método | Por defecto | Sobrescribirlo cuando… |
|---|---|---|
| `canReceive(item)` | `inventory.hasRoom()` | acepta sólo ciertos items (`super(item) && item.canProcess(cutting)`) o ninguno (`false`) |
| `onReceive(item)` | anima el item hasta su celda y, al llegar, llama a `onArrived(item)` | el item no viaja a su celda (el brazo) |
| `onArrived(item)` | `self.tryPush()`: lo pasa a la siguiente, como una cinta | la máquina hace algo con el item: procesarlo, juntarlo con otros… |

**Almacenamiento**

| Método | Por defecto | Sobrescribirlo cuando… |
|---|---|---|
| `capacity()` | `1` | guarda varios items (el Assembler) |

**Salida**

| Método | Por defecto | Sobrescribirlo cuando… |
|---|---|---|
| `outputTarget()` | `next` (la máquina hacia la que apunta) | entrega a otro lado (el brazo, según por dónde llegó el item) |
| `itemToPush()` | el primer item del inventario | elige qué entregar (el Assembler entrega el producto, no las entradas) |
| `onPushed(item)` | no hace nada | tiene que enterarse de que entregó (el Dispenser, para agendar el próximo) |

**Ciclo de la simulación**

| Método | Por defecto | Sobrescribirlo cuando… |
|---|---|---|
| `start()` | busca `next` y pasa a `runningImage()` | arranca sola (el Dispenser agenda su primer item). **Siempre llamar a `super()`** |
| `reset()` | vacía el inventario y las esperas, corta la animación y vuelve a la imagen quieta | tiene estado propio (el brazo: `from`, `grabbed` y volver `direction` a `down`). Reiniciar ese estado **antes** de `super()`, que muestra `staticImage()` |

**Dibujo** (en `MachineSprite`)

| Método | Por defecto | Sobrescribirlo cuando… |
|---|---|---|
| `runningImage()` | la imagen quieta | se anima con GIF: `override method runningImage() = self.gifImage()` |
| `staticImage()` | `<direction>_game.png` | su imagen no depende de `direction`. Ninguna máquina lo necesita hoy: el brazo guarda en `direction` hacia dónde mira |
| `offsetX()` / `offsetY()` | `0` | se dibuja corrida (el brazo, que ocupa 3x3 celdas) |
| `rotate()` / `menuImage(dir)` | rota normalmente | no rota (el brazo) |

### No sobrescribir: sólo usar

Son las herramientas que la base les da a las subclases. Si una subclase las reimplementa, rompe el flujo de items:

| Método | Qué hace |
|---|---|
| `receive(item)` | Lo guarda en el inventario y llama a `onReceive(item)`. Lo llaman las otras máquinas |
| `tryPush()` | Le entrega `itemToPush()` a `outputTarget()` si puede (y llama a `onPushed`); si no, espera con `whenFree` y vuelve a intentar |
| `whenFree(bloque)` | Anota el bloque para cuando esta máquina libere lugar |
| `heldItems()` | Los items que tiene encima (para el tablero y el engine) |
| `inventory` | `items()`, `add(item)`, `release(item)`. **`release` despierta solo a las que esperaban**: no hay que acordarse de avisarles |
| `play(animación, bloque)`, `actionAnimation(acción, frames)`, `stopAnimation()` | Animaciones frame a frame (ver `MachineAnimator`) |
| `cell()`, `nextMachine()`, `direction()` | Ubicación en el tablero |

## Máquinas que procesan

Las que transforman un ingrediente (cortadora, horno) heredan de `ProcessingMachine`, que ya sabe aceptar lo que puede procesar, trabajar el tiempo que dice el item (`processTime()`), transformarlo y entregarlo. Cada subclase sólo dice:

| Método | Para qué |
|---|---|
| `foodProcess()` | **Obligatorio.** Qué proceso aplica (`cutting`, `cooking`, `frying`) |
| `workImages()` | Opcional. Las imágenes frame a frame que se ven mientras trabaja. Por defecto, la máquina queda quieta |
| `animateWork(pasos, bloque)` | Opcional. Se sobrescribe con `holdImage` para usar un GIF mientras trabaja (ver `Oven`) |

## Ejemplos

```wollok
// Una cinta: todo es el comportamiento por defecto
class Belt inherits Machine {
	override method name() = "Belt"
	override method runningImage() = self.gifImage()
}
```

```wollok
// Un dispenser: crea un item, lo entrega y, recién al entregarlo, agenda el próximo
class Dispenser inherits Machine {
	const product = { => new Item(kind = potato) }

	override method name() = "Dispenser"
	override method canReceive(item) = false   // guarda el item que crea, pero no recibe

	method intervalSteps() = simulationEngine.stepsFor(1000)

	override method start() {
		super()
		self.scheduleNext()
	}

	method scheduleNext() { simulationEngine.after(self.intervalSteps(), { self.dispense() }) }

	method dispense() {
		const item = product.apply()
		item.position(self.position())
		simulationEngine.addItem(item)
		inventory.add(item)
		self.tryPush()
	}

	override method onPushed(item) { self.scheduleNext() }
}
```

```wollok
// Una máquina que procesa: anima, transforma y entrega
class CuttingMachine inherits Machine {
	override method name() = "CuttingMachine"
	override method canReceive(item) = super(item) && item.canProcess(cutting)
	override method onArrived(item) {
		self.play(self.actionAnimation("cut", 17), {
			item.process(cutting)
			self.showRunning()
			self.tryPush()
		})
	}
}
```

**Por dónde empezar:** casi todas las máquinas que procesan algo se resuelven con `onArrived(item)`, y si filtran lo que aceptan, con `canReceive(item)`. El resto, sólo si hace falta.

> Cuando haya dos o más máquinas con un `onArrived` del tipo "animar, transformar y entregar" (cortadora, horno, freidora), ese patrón pasa a una `ProcessingMachine`, y cada una define sólo su animación y su transformación (fase 6 del plan).

## `types/`: las máquinas

| Máquina | Qué hace | Cómo se anima | Sobrescribe |
|---|---|---|---|
| `Belt` | Lleva un item a la máquina a la que apunta | GIF | `name`, `runningImage` |
| `Dispenser` | Crea un ingrediente cada 1 segundo y se lo entrega a la de adelante | Frame a frame (todavía sin animación) | `name`, `canReceive`, `start`, `onPushed` |
| `AutomaticArm` | Agarra el item que le llega de un lado y lo entrega del lado contrario (provisorio). No rota y ocupa 3x3 celdas | Frame a frame (giro y agarre) | `onReceive`, `outputTarget`, `reset` y el dibujo |
| `CuttingMachine` | Corta lo que le llega, tardando lo que dice el ingrediente | Frame a frame (corte) | `name`, `foodProcess`, `workImages` |
| `Assembler` | Junta los ingredientes que pide su receta, los consume y entrega el plato | Sin animación | `name`, `capacity`, `canReceive`, `onArrived`, `itemToPush`, `onPushed`, `heldItems`, `reset` |
| `Oven` | Cocina lo que le llega, tardando lo que dice el ingrediente | GIF, sólo mientras cocina | `name`, `foodProcess`, `animateWork` |
| `Fryer` | Todavía sin lógica: no acepta items | — | `name`, `canReceive` (`false`) |

Por defecto una máquina es **frame a frame**: con la simulación prendida se ve quieta y se anima cuando hace algo. Las imágenes de cada tipo se explican en [`assets/README.md`](../../assets/README.md), y el brazo tiene su propia guía en [`assets/machines/AutomaticArm/README.md`](../../assets/machines/AutomaticArm/README.md).

## `machineManager.wlk`: el catálogo
- `machines`: la lista de máquinas que se pueden colocar. **El orden de la lista es el orden del menú**, de a 4 por página.
- Cada elemento es un bloque que crea una máquina nueva (`{ => new Belt() }`), así cada colocación usa una instancia distinta.
- `select(...)` y `createMachine()`: la máquina elegida en el menú y una instancia nueva de ella para colocar.

## Agregar una máquina nueva
1. Las imágenes en `assets/machines/<Nombre>/` (ver [`assets/README.md`](../../assets/README.md)).
2. La clase en su propio archivo, `types/<nombre>.wlk` (el nombre de la clase empezando en minúscula), heredando de `Machine`, con `override method name() = "<Nombre>"` (el mismo nombre que la carpeta de imágenes). Importar sólo lo que use: como mínimo `machines.machineClasses.*`.
3. Si usa GIF: `override method runningImage() = self.gifImage()`.
4. Su comportamiento: partir del ejemplo más parecido (cinta, dispenser o cortadora) y sobrescribir sólo lo que cambia, según [el contrato](#el-contrato-de-machine).
5. Importar su archivo en `machineManager.wlk` (`import machines.types.<nombre>.*`) y agregarla a la lista. Si cambia la cantidad de máquinas, revisar los tests de páginas de `test/menuManagerTest.wtest`.

