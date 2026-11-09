# `machines/`

Las máquinas del juego: qué hacen, cómo se dibujan, qué tipos hay y cuáles aparecen en el menú.

| Archivo | Qué tiene |
|---|---|
| `machineClasses.wlk` | Las clases base de todas las máquinas: `MachineAnimator`, `MachineSprite` y `Machine` |
| `settings.wlk` | Las configuraciones de las máquinas: `Setting`, sus opciones y categorías (ver [Configuración](#configuración-settings)) |
| `inventory.wlk` | `Inventory`: los items que guarda una máquina y los que esperan que se libere lugar |
| `types/` | Las máquinas concretas, **una por archivo** con el nombre de su clase: `belt.wlk`, `dispenser.wlk`, `automaticArm.wlk`, `smartRoboticArm.wlk`, `assembler.wlk`, `oven.wlk`, `cuttingMachine.wlk`, `fryer.wlk`, `deliverySlot.wlk` |
| `machineManager.wlk` | El catálogo de máquinas del menú y cuál está elegida para colocar |

> **Quién conoce las máquinas concretas:** sólo `machineManager` (para el catálogo), `main.wpgm` (para crear los puntos de entrega con `deliveryPoints.setUp()`), `levels/levelsTypes.wlk` (cada nivel arma su catálogo) y los tests. El resto del juego (tablero, simulación, herramientas, menú) trabaja con cualquier `Machine` sin saber cuál es. Mantenerlo así: si otra parte necesita algo de una máquina, agregarlo como método de `Machine` y que cada tipo lo sobrescriba.

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
> **Toda acción agendada revisa el estado antes de actuar.** Entre que se agenda un bloque y que se ejecuta pueden pasar cosas (por ejemplo, otra máquina ocupó el lugar). `tryPush()` ya lo hace: vuelve a preguntar `canReceiveFrom(self, item)` y, si no puede, vuelve a esperar. Lo mismo con los items: un brazo puede llevarse uno mientras viaja o mientras se procesa, así que antes de hacer algo con un item hay que revisar que siga siendo de esta máquina (`self.heldItems().contains(item)`).

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
| `canReceive(item)` | `inventory.hasRoom()` | acepta sólo ciertos items (el Assembler: `super(item) && recipe.stillNeeds(item, inventory.items())`) o ninguno (`false`). Las que procesan ya lo tienen resuelto en `ProcessingMachine` |
| `acceptsSource(source)` | de cualquiera, salvo que sea `armOnly()` (entonces sólo de un brazo) | acepta items sólo de ciertas máquinas (el brazo: sólo de la que está en su entrada). Quien entrega pregunta `canReceiveFrom(source, item)`, que junta `acceptsSource` y `canReceive`: no se sobrescribe |
| `grabbableItem()` | `null` | un brazo puede agarrar el item que tiene, aunque no le apunte (la cinta: `itemToPush()`). Para sacárselo, el brazo usa `surrender(item)` |
| `armOnly()` | `false` | sólo trabaja con un brazo: sólo recibe de un brazo y sólo entrega a un brazo (la freidora) |
| `onReceive(item)` | anima el item hasta su celda y, al llegar, llama a `onArrived(item)` | el item no viaja a su celda (el brazo) |
| `onArrived(item)` | si el item sigue en el inventario (un brazo pudo habérselo llevado en camino), `self.tryPush()`: lo pasa a la siguiente, como una cinta | la máquina hace algo con el item: procesarlo, juntarlo con otros… Si un brazo puede agarrarle items (`grabbableItem`), revisar también que el item siga ahí |

**Almacenamiento y tamaño**

| Método | Por defecto | Sobrescribirlo cuando… |
|---|---|---|
| `capacity()` | `1` | guarda varios items. Se usa para crear el inventario; si después tiene que cambiar (el Assembler, al cambiar de receta), se usa `inventory.changeCapacity(n)` |
| `width()` / `height()` | `1` | ocupa varias celdas del tablero (el Assembler: 2x2). `outputTarget()` ya tiene en cuenta el tamaño |

**Configuración** (ver [Configuración](#configuración-settings))

| Método | Por defecto | Sobrescribirlo cuando… |
|---|---|---|
| `settings()` | `[]` | acepta configuraciones: devuelve sus settings (el Dispenser: ingrediente y velocidad; el brazo: hacia dónde entrega; el Assembler: su receta) |
| `baseEnergy()` | `0` | consume energía aunque no tenga ningún setting (ver la [tabla de energía](#energía)). `energyConsumption()` suma ésta más la de cada setting |

**Salida**

| Método | Por defecto | Sobrescribirlo cuando… |
|---|---|---|
| `outputTarget()` | la **celda** pegada a su borde de adelante (`direction.output(...)`). Al prender, la máquina que está ahí se guarda en `next` | el dibujo marca la salida en otra celda de ese borde |
| `itemToPush()` | el primer item del inventario | elige qué entregar (el Assembler entrega el producto, no las entradas) |
| `onPushed(item)` | no hace nada | tiene que enterarse de que entregó (el Dispenser, para agendar el próximo) |

**Ciclo de la simulación**

| Método | Por defecto | Sobrescribirlo cuando… |
|---|---|---|
| `start()` | busca `next` y pasa a `runningImage()` | arranca sola (el Dispenser agenda su primer item). **Siempre llamar a `super()`** |
| `reset()` | vacía el inventario, las esperas y los brazos anotados (`grabbers`), corta la animación y vuelve a la imagen quieta | tiene estado propio (el brazo: `from`, `grabbed` y volver `direction` a su entrada). Reiniciar ese estado **antes** de `super()`, que muestra `staticImage()` |

**Dibujo** (en `MachineSprite`)

| Método | Por defecto | Sobrescribirlo cuando… |
|---|---|---|
| `runningImage()` | la imagen quieta | se anima con GIF: `override method runningImage() = self.gifImage()` |
| `staticImage()` | `<direction>_game.png` | su imagen no depende de `direction`. El brazo lo sobrescribe: su `direction` es hacia dónde mira la pinza, no hacia dónde está rotado |
| `drawOffsetX()` / `drawOffsetY()` | `0` | se dibuja corrida (el brazo, que ocupa 3x3 celdas) |
| `rotate()` / `menuImage(dir)` | rota normalmente | rota distinto (el brazo: mueve su entrada) o el menú muestra otra cosa |
| `workImages()` | `[self.runningImage()]`: se ve quieta mientras trabaja | se anima frame a frame mientras trabaja (la cortadora: `self.actionAnimation("cut", 17).frames()`) |
| `animateWork(pasos, bloque)` | reproduce `workImages()` ajustadas a `pasos` (con `TimedAnimation`), vuelve a la imagen andando y ejecuta el bloque | usa un GIF mientras trabaja: `self.holdImage(self.gifImage(), pasos, bloque)` (el horno) |

### No sobrescribir: sólo usar

Son las herramientas que la base les da a las subclases. Si una subclase las reimplementa, rompe el flujo de items:

| Método | Qué hace |
|---|---|
| `receive(item)` | Lo guarda en el inventario, llama a `onReceive(item)` y avisa a los brazos que la miran (`notifyGrabbers`). Lo llaman las otras máquinas |
| `canReceiveFrom(source, item)` | Lo que pregunta quien entrega: junta `acceptsSource(source)` y `canReceive(item)` |
| `tryPush()` | Le entrega `itemToPush()` a `next` si `canReceiveFrom` lo permite (y llama a `onPushed`); si no, espera con `whenFree` y vuelve a intentar |
| `notifyGrabbers()` | Avisa a los brazos que tienen a esta máquina como entrada que hay algo para agarrar (lo llaman `receive` y `ProcessingMachine` al terminar de procesar) |
| `surrender(item)` | Un brazo se llevó el item: lo saca del inventario y despierta a las que esperaban lugar |
| `addGrabber(brazo)` | Anota un brazo que mira a esta máquina como su entrada (lo hace el brazo al prender la simulación) |
| `whenFree(bloque)` | Anota el bloque para cuando esta máquina libere lugar |
| `heldItems()` | Los items que tiene encima (para el tablero y el engine) |
| `inventory` | `items()`, `add(item)`, `release(item)`, `changeCapacity(n)`. **`release` despierta solo a las que esperaban**: no hay que acordarse de avisarles |
| `locked` | Si la máquina está bloqueada (`false` por defecto). La bloquea un nivel al colocarla como máquina fija (`Placement`). Una máquina bloqueada no se puede borrar ni rotar con las herramientas, pero sí editar. **El juego sí la saca** (`board.pop` y `board.clear()` no miran el bloqueo) |
| `play(animación, bloque)`, `actionAnimation(acción, frames)`, `stopAnimation()` | Animaciones frame a frame (ver `MachineAnimator`) |
| `animateWork(pasos, bloque)` | Se ve trabajando durante `pasos` y después ejecuta el bloque. Sirve para cualquier máquina que tarde, no sólo las que procesan |
| `playTimed(imágenes, pasos, bloque)`, `holdImage(ruta, pasos, bloque)` | Lo que usa `animateWork` por dentro: frames ajustados a una duración, o una imagen fija (un GIF) durante esos pasos |
| `cell()`, `nextMachine()`, `direction()` | Ubicación en el tablero |

## Configuración (settings)

Lo que se cambia con la herramienta edit. Cada máquina declara los settings que acepta en `settings()`, y el menú los dibuja sin saber de qué máquina se trata (ver [`menu/README.md`](../menu/README.md)).

Un `Setting` (en `settings.wlk`) guarda el valor elegido para **esa máquina** y dice:

| Método | Qué es |
|---|---|
| `name()` | Cómo se llama en el menú ("Velocidad") |
| `category()` | En qué grupo va en el menú (`production`, `movement`). Los settings de una misma categoría se muestran bajo un mismo título |
| `options()` | Las opciones que ofrece, cada una con su `value`, su `image` o `label` y su `energyCost` |
| `value()` | El valor elegido. Es lo que lee la máquina |
| `energyCost()` | La energía de la opción elegida (la suma `energyConsumption()` de la máquina) |

Hay settings genéricos para reutilizar: `ProductSetting` (qué ingrediente), `SpeedSetting` (multiplicador de ritmo: `0.5`, `1` o `2`), `OutputSideSetting` (hacia dónde entrega, relativo a la entrada: `straightOut`, `leftOut` o `rightOut`) y `RecipeSetting` (qué receta arma: las opciones son las recetas del nivel, `recipeBook.available()`, con la imagen de su plato).

Para que una máquina acepte una configuración:

1. Declarar el setting como atributo: `const speedSetting = new SpeedSetting(value = 1)`.
2. Devolverlo en `settings()`.
3. Leer `speedSetting.value()` donde la máquina lo necesite (el Dispenser: `intervalMs() = 5000 / speedSetting.value()`).

> [!IMPORTANT]
> **La configuración no es estado de la simulación**: `reset()` no la toca. Si una máquina necesita guardar algo que SÍ cambia mientras corre, va en otro atributo (el brazo guarda su entrada en `inputSide`, hacia dónde mira la pinza en `direction`, y hacia dónde entrega en su setting).

## Máquinas que procesan

Las que transforman un ingrediente (cortadora, horno, freidora) heredan de `ProcessingMachine`, que ya sabe aceptar lo que puede procesar, trabajar el tiempo que dice el item (`processTime()`), transformarlo y entregarlo. Cada subclase sólo dice:

| Método | Para qué |
|---|---|
| `foodProcess()` | **Obligatorio.** Qué proceso aplica (`cutting`, `cooking`, `frying`) |
| `workImages()` | Opcional. Las imágenes frame a frame que se ven mientras trabaja. Por defecto, la máquina queda quieta |
| `animateWork(pasos, bloque)` | Opcional. Se sobrescribe con `holdImage` para usar un GIF mientras trabaja (ver `Oven`) |
| `onProcessed(item)` | Opcional. Se llama después de procesar y entregar (o intentar entregar) el item; por defecto no hace nada. La freidora lo usa para empezar a contar el tiempo hasta que se queme |

Si un brazo se llevó el item mientras trabajaba, `ProcessingMachine` no lo procesa: ya no es suyo.

## Ejemplos

```wollok
// Una cinta: todo es el comportamiento por defecto
class Belt inherits Machine {
	override method name() = "Belt"
	override method runningImage() = self.gifImage()
}
```

```wollok
// Un dispenser configurable: crea un item, lo entrega y, recién al entregarlo, agenda el próximo
class Dispenser inherits Machine {
	const productSetting = new ProductSetting(value = potato, kinds = [lettuce, bun, friedPotato, potato, tomato, meat])
	const speedSetting = new SpeedSetting(value = 1)

	override method name() = "Dispenser"
	override method settings() = [productSetting, speedSetting]
	override method canReceive(item) = false   // guarda el item que crea, pero no recibe

	method intervalSteps() = simulationEngine.stepsFor(5000 / speedSetting.value())

	override method start() {
		super()
		self.scheduleNext()
	}

	method scheduleNext() { simulationEngine.after(self.intervalSteps(), { self.tryDispense() }) }

	// Pregunta ANTES de crear el item: si la de adelante está llena, reintenta cuando se libere
	method tryDispense() {
		const target = next
		if (target != null) {
			const item = new Item(kind = productSetting.value())
			if (target.canReceiveFrom(self, item)) {
				item.position(self.position())
				simulationEngine.addItem(item)
				inventory.add(item)
				self.tryPush()
			} else {
				target.whenFree({ self.tryDispense() })
			}
		}
	}

	override method onPushed(item) { self.scheduleNext() }
}
```

```wollok
// Una máquina que procesa con frames: sus 17 PNG de corte se ajustan al tiempo de cada ingrediente
class CuttingMachine inherits ProcessingMachine {
	override method name() = "CuttingMachine"
	override method foodProcess() = cutting
	override method workImages() = self.actionAnimation("cut", 17).frames()
}
```

```wollok
// Una máquina que procesa con GIF: quieta cuando está vacía, el GIF sólo mientras cocina
class Oven inherits ProcessingMachine {
	override method name() = "Oven"
	override method foodProcess() = cooking
	override method animateWork(steps, afterBlock) {
		self.holdImage(self.gifImage(), steps, afterBlock)
	}
}
```

**Por dónde empezar:** si la máquina transforma un ingrediente, heredar de `ProcessingMachine` y definir `foodProcess()` (y, si se anima, `workImages()` o `animateWork`). Si hace otra cosa con el item (juntarlo con otros, como el Assembler), sobrescribir `onArrived(item)`, y si filtra lo que acepta, `canReceive(item)`. El resto, sólo si hace falta.

## Energía

Cada máquina gasta **energía** mientras está colocada: `energyConsumption()` = `baseEnergy()` + lo que suma la opción elegida de cada setting. Un nivel puede limitar el total (ver [Energía en `levels/`](../levels/README.md#energía)).

| Máquina | `baseEnergy()` | Settings que suman energía |
|---|:---:|---|
| `Belt` | 1 | — |
| `Dispenser` | 1 | Velocidad: x0.5 suma 1, x1 suma 2, x2 suma 4 (a velocidad normal gasta 3 en total) |
| `AutomaticArm` | 2 | — |
| `SmartRoboticArm` | 3 | — |
| `CuttingMachine` | 1 | Velocidad (igual que el Dispenser: gasta 3 a velocidad normal) |
| `Oven` | 2 | Velocidad (gasta 4 a velocidad normal) |
| `Fryer` | 2 | Velocidad (gasta 4 a velocidad normal) |
| `Assembler` | 1 | Velocidad (gasta 3 a velocidad normal) |
| `DeliverySlot` | 0 | — (no está en el tablero: no cuenta) |

**Velocidad** (`SpeedSetting`, en el panel de edit): la tienen el `Dispenser`, la `CuttingMachine`, el `Oven`, la `Fryer` y el `Assembler`. Es un multiplicador (`0.5`, `1` o `2`). En el `Dispenser` cambia cada cuánto crea un ingrediente; en las demás, el tiempo que tardan en trabajar: `workSteps(baseSteps)` divide el tiempo del ingrediente (o de la receta) por la velocidad, redondea y nunca baja de un paso. Más velocidad es más rápido pero gasta más energía; menos velocidad ahorra energía pero tarda el doble. Las máquinas sin velocidad responden `speed()` = 1. La `Fryer` no cambia el tiempo que tarda en quemar lo frito.

Una máquina nueva que no sobrescriba `baseEnergy()` no gasta nada. Los números definen la dificultad de los niveles con límite: si se cambian, revisar el límite de `energyTutorialLevel` (9) y los tests de `test/energyTest.wtest`.

## `types/`: las máquinas

| Máquina | Qué hace | Cómo se anima | Sobrescribe |
|---|---|---|---|
| `Belt` | Lleva un item a la máquina a la que apunta | GIF | `name`, `baseEnergy`, `runningImage` |
| `Dispenser` | Crea un ingrediente y se lo entrega a la de adelante. Se configura qué ingrediente (papa por defecto, o el primero de los que ofrece si no ofrece papa) y a qué velocidad (un item cada 5 segundos a velocidad normal). Los ingredientes que ofrece salen de `availableKinds`, que un nivel puede limitar al crearlo (`new Dispenser(availableKinds = [potato, tomato])`) | Frame a frame (todavía sin animación) | `name`, `baseEnergy`, `settings`, `canReceive`, `start`, `onPushed` |
| `AutomaticArm` | Agarra el item que le llega por su única entrada y lo entrega recto, a la izquierda o a la derecha de su recorrido, según su configuración: al girar vuelve a calcular `next`. La entrada es la dirección elegida al colocarlo y rotar la mueve; sólo recibe de la máquina que está ahí, y además agarra los items que pasan por una cinta ahí, aunque la cinta no le apunte. Ocupa 1 celda y se dibuja en 3x3 | Frame a frame (giro y agarre) | `name`, `baseEnergy`, `settings`, `onReceive`, `onPushed`, `acceptsSource`, `isArm`, `start`, `rotate`, `reset` y el dibujo |
| `SmartRoboticArm` | Un brazo con tres salidas (izquierda, recta y derecha), cada una con los ingredientes que deja salir (una columna en el panel de edit; sin ingredientes, esa salida no se usa). Entrega cada item por la primera salida que lo acepta (recta, izquierda, derecha) y no toma los que ninguna acepta | Los de `AutomaticArm` (en el menú, su propia imagen) | `name`, `baseEnergy`, `settings`, `canReceive`, `outputSideFor`, `menuImage` |
| `CuttingMachine` | Corta lo que le llega, tardando lo que dice el ingrediente | Frame a frame (corte) | `name`, `baseEnergy`, `foodProcess`, `workImages` |
| `Assembler` | Junta los ingredientes que pide su receta, los consume y entrega el plato. La receta se elige en el panel de edit (`RecipeSetting`) entre las del nivel; arranca con la primera, o con `noRecipe` si el nivel no tiene. **La toma al prender la simulación** (`start`), y ahí ajusta el inventario a lo que pide: si se cambia con la simulación prendida, se usa desde la próxima vez que se prende | Frame a frame (al armar) | `name`, `baseEnergy`, `settings`, `start`, `canReceive`, `onArrived`, `itemToPush`, `onPushed`, `heldItems`, `reset` y el tamaño (`width`, `height`, `outputTarget`) |
| `Oven` | Cocina lo que le llega, tardando lo que dice el ingrediente | GIF, sólo mientras cocina | `name`, `baseEnergy`, `foodProcess`, `animateWork` |
| `Fryer` | Fríe lo que le entrega un brazo: es `armOnly`, no recibe de cintas ni entrega a cintas. Un brazo puede sacarle el item apenas entra (el común lo saca al toque; el inteligente puede filtrar para esperar al frito). Si el item frito se queda 4 segundos, se quema (`burntPotato`) | GIF, sólo mientras fríe | `name`, `baseEnergy`, `foodProcess`, `animateWork`, `armOnly`, `grabbableItem`, `onProcessed` |
| `DeliverySlot` | Un platito del fondo, donde se entrega la comida. El item viaja hasta él y, al llegar, sale del juego y se le avisa a `levelManager.delivered(item)`, que lo cuenta para el objetivo del nivel. No entrega a nadie. **No lo coloca el jugador ni está en el menú**: los crea `deliveryPoints` (en el mismo archivo), que tiene sus dos posiciones, (16, 14) y (17, 14), y en `setUp()` se los pasa al `board` (lo llama `main.wpgm`) | No se dibuja: el fondo ya muestra los platitos | `name`, `nextMachine`, `onArrived` |

Por defecto una máquina es **frame a frame**: con la simulación prendida se ve quieta y se anima cuando hace algo. Las imágenes de cada tipo se explican en [`assets/README.md`](../../assets/README.md), y el brazo tiene su propia guía en [`assets/machines/AutomaticArm/README.md`](../../assets/machines/AutomaticArm/README.md).

## `machineManager.wlk`: el catálogo
- `allMachines`: todas las máquinas del juego. **El orden de la lista es el orden del menú**, de a 4 por página.
- `machines`: las que se pueden colocar ahora. Al arrancar, todas (`allMachines`).
- Cada elemento es un bloque que crea una máquina nueva (`{ => new Belt() }`), así cada colocación usa una instancia distinta.
- `changeCatalog(bloques)`: cambia las máquinas que se pueden colocar (por ejemplo, las de un nivel) y elige la primera, así no queda elegida una que el catálogo nuevo no tiene. **No redibuja el menú**: quien lo llama tiene que llamar también a `placeMenu.resetPage()`.
- `select(...)` y `createMachine()`: la máquina elegida en el menú y una instancia nueva de ella para colocar.

## Agregar una máquina nueva
1. Las imágenes en `assets/machines/<Nombre>/` (ver [`assets/README.md`](../../assets/README.md)).
2. La clase en su propio archivo, `types/<nombre>.wlk` (el nombre de la clase empezando en minúscula), heredando de `Machine`, con `override method name() = "<Nombre>"` (el mismo nombre que la carpeta de imágenes). Importar sólo lo que use: como mínimo `machines.machineClasses.*`.
3. Si usa GIF: `override method runningImage() = self.gifImage()`.
4. Su comportamiento: partir del ejemplo más parecido (cinta, dispenser o cortadora) y sobrescribir sólo lo que cambia, según [el contrato](#el-contrato-de-machine).
5. Importar su archivo en `machineManager.wlk` (`import machines.types.<nombre>.*`) y agregarla a la lista. Si cambia la cantidad de máquinas, revisar los tests de páginas de `test/menuManagerTest.wtest`.
6. Documentarla: agregarla a la tabla de [`types/`](#types-las-máquinas) y a la lista de archivos de arriba, y su carpeta a la tabla de [`assets/README.md`](../../assets/README.md#machines).

