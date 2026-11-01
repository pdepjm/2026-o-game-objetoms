import levels.levelClasses.*
import food.foodTypes.*
import food.recipes.*
import machines.machineManager.*
import machines.types.belt.*
import machines.types.dispenser.*
import machines.types.automaticArm.*
import machines.types.smartRoboticArm.*
import machines.types.assembler.*
import machines.types.oven.*
import machines.types.cuttingMachine.*
import machines.types.fryer.*
import cellPosition.*
import board.*
import directions.*
import levels.tutorial.*
import machines.types.deliverySlot.*
import wollok.game.*

object freePlay inherits Level(
    name = "Libre", 
    availableMachines = machineManager.allMachines(),
    availableRecipes = recipeBook.all(),
    goals = [noGoal]
) {}

// Las celdas del tutorial de papas fritas. Las usan sus máquinas fijas, su zona de construcción y
// sus pasos: para mover el armado, alcanza con cambiarlas acá.
// La línea va por la fila `row` y dobla hacia arriba en la columna del primer platito.
object friesTutorialCells {
	const property row = 7

	method at(column) = new CellPosition(x = column, y = row)

	method dispenser() = self.at(5)
	method firstBelt() = self.at(6)       // la pone el jugador
	method cutter() = self.at(7)          // la pone el jugador
	method fixedBelt() = self.at(8)
	method fixedArm() = self.at(9)
	method fryer() = self.at(10)          // la pone el jugador
	method smartArm() = self.at(11)       // lo pone el jugador

	method plate() = deliveryPoints.slots().first().cell()
	// Las cintas fijas de después del brazo inteligente: por la fila hasta la columna del platito,
	// y por esa columna hacia arriba hasta llegar a él
	method exitBeltsAlongRow() = (self.smartArm().x() + 1 .. self.plate().x() - 1).map({ column => self.at(column) })
	method exitBeltsUp() = (row .. self.plate().y() - 1).map({ y => new CellPosition(x = self.plate().x(), y = y) })
}

// El tutorial: se arman unas papas fritas paso a paso. El nivel trae la línea armada salvo
// cuatro máquinas, que pone el jugador (las celdas están en friesTutorialCells):
//
//   Dispenser  cinta    cortadora  cinta  brazo común  freidora  brazo inteligente  cintas hasta el platito
//   fijo       JUGADOR  JUGADOR    fija   fijo         JUGADOR   JUGADOR            fijas
//
// El brazo inteligente hay que rotarlo (que agarre de la freidora) y editarlo (que no saque la papa
// cortada antes de freírla). Antes de cada máquina que pone el jugador, un ExplainStep señala con la
// flecha la máquina de la que viene (pointsAt) y se sigue con Enter. Después, el paso que la pide
// marca con el recuadro dónde va (cells), y deja colocar, borrar y rotar sólo ahí.
object tutorialLevel inherits Level(
	name = "Tutorial 1",
	availableMachines = [
        { => new Belt() },
        { => new CuttingMachine() },
        { => new Fryer() },
        { => new SmartRoboticArm() }
    ],
    availableRecipes = [],
	goals = [
        new DeliveryGoal(
            kind = friedPotato,
            amount = 2,
            label = "Papas Fritas"
        )
    ],
    buildZones = [
        new Zone(
            minX = friesTutorialCells.firstBelt().x(),
            maxX = friesTutorialCells.smartArm().x(),
            minY = friesTutorialCells.row(),
            maxY = friesTutorialCells.row()
        )
    ],
    fixedMachines = [
        new Placement(
            position = friesTutorialCells.dispenser(),
            factory = {=> new Dispenser(direction = right, availableKinds = [potato])}
        ),
        new Placement(
            position = friesTutorialCells.fixedBelt(),
            factory = {=> new Belt(direction = right)}
        ),
        new Placement(
            position = friesTutorialCells.fixedArm(),
            factory = {=> new AutomaticArm(direction = left)}
        )
    ]
    + friesTutorialCells.exitBeltsAlongRow().map({ cell => new Placement(position = cell, factory = {=> new Belt(direction = right)}) })
    + friesTutorialCells.exitBeltsUp().map({ cell => new Placement(position = cell, factory = {=> new Belt(direction = up)}) }),
    tutorial = new StepTutorial(
        steps = [
            new ExplainStep(
                lines = ["Las papas salen", "del dispenser", "de la flecha.", "", "Enter: seguir"],
                pointsAt = [friesTutorialCells.dispenser()]
            ),
            new MachineStep(
                lines = ["Z: colocar.", "Elegí la cinta", "y ponela en el", "recuadro para", "llevar las papas"],
                cells = [friesTutorialCells.firstBelt()],
                condition = { machine => machine.name() == "Belt" && machine.direction() == right }
            ),
            new ExplainStep(
                lines = ["La cinta lleva", "las papas hacia", "donde apunta.", "", "Enter: seguir"],
                pointsAt = [friesTutorialCells.firstBelt()]
            ),
            new MachineStep(
                lines = ["Poné la", "cortadora en el", "recuadro: corta", "las papas que", "le trae la", "cinta"],
                cells = [friesTutorialCells.cutter()],
                condition = { machine => machine.name() == "CuttingMachine" && machine.direction() == right }
            ),
            new ExplainStep(
                lines = ["Este brazo toma", "las papas de la", "cinta y las deja", "del otro lado.", "", "Enter: seguir"],
                pointsAt = [friesTutorialCells.fixedArm()]
            ),
            new MachineStep(
                lines = ["Poné la", "freidora en el", "recuadro, donde", "el brazo deja", "las papas"],
                cells = [friesTutorialCells.fryer()],
                condition = { machine => machine.name() == "Fryer" }
            ),
            new ExplainStep(
                lines = ["La freidora no", "larga las papas:", "hay que sacarlas", "con un brazo.", "", "Enter: seguir"],
                pointsAt = [friesTutorialCells.fryer()]
            ),
            new MachineStep(
                lines = ["Poné el brazo", "inteligente en", "el recuadro"],
                cells = [friesTutorialCells.smartArm()],
                condition = { machine => machine.name() == "AutomaticArm" }
            ),
            new MachineStep(
                lines = ["Un brazo agarra", "de donde mira.", "C: rotalo hasta", "que mire a la", "freidora"],
                cells = [friesTutorialCells.smartArm()],
                condition = { machine => machine.inputSide() == left }
            ),
            new MachineStep(
                lines = ["Así saca las", "papas sin freír.", "X: tocá el brazo", "y en Recto", "sacá la papa", "cortada"],
                cells = [friesTutorialCells.smartArm()],
                condition = { machine => machine.exitSideFor(cutPotato) == null && machine.exitSideFor(friedPotato) == right }
            ),
            new RunStep(
                lines = ["¡Listo! Apretá", "5 para cocinar"]
            ),
            new TutorialStep(
                lines = ["Las papas fritas", "llegan al", "platito. Esperá", "a que lleguen 2.", "5: apagar"],
                pointsAt = [friesTutorialCells.plate()],
                allowsSimulation = true
            )
        ],
        finishedLines = ["¡Papas fritas", "listas!"]
    )
) {}

// Las celdas del tutorial de panchos (ver friesTutorialCells). Dos líneas que llegan al ensamblador:
// las salchichas por la fila `sausageRow` (dispenser, cinta, horno, brazo) y los panes por la fila
// `bunRow` (dispenser, cinta, cortadora, cintas que suben al ensamblador). El plato sale por arriba
// del ensamblador y va por la fila de arriba del tablero hasta el platito.
object hotDogTutorialCells {
	const property sausageRow = 10
	const property bunRow = 8

	method sausageDispenser() = new CellPosition(x = 5, y = sausageRow)
	method sausageBelt() = new CellPosition(x = 6, y = sausageRow)
	method oven() = new CellPosition(x = 7, y = sausageRow)      // lo pone el jugador
	method arm() = new CellPosition(x = 8, y = sausageRow)       // lo pone el jugador

	method bunDispenser() = new CellPosition(x = 5, y = bunRow)
	method bunBelt() = new CellPosition(x = 6, y = bunRow)
	method cutter() = new CellPosition(x = 7, y = bunRow)
	method bunBeltAfterCutter() = new CellPosition(x = 8, y = bunRow)
	// La cinta que sube al ensamblador, debajo de su columna izquierda
	method bunBeltUp() = new CellPosition(x = self.assembler().x(), y = bunRow)

	// El ensamblador (2x2): su celda de abajo a la izquierda, a la derecha del brazo. Lo pone el jugador.
	method assembler() = new CellPosition(x = 9, y = bunRow + 1)
	method assemblerCells() = [0, 1].flatMap({ dx => [0, 1].map({ dy => new CellPosition(x = self.assembler().x() + dx, y = self.assembler().y() + dy) }) })

	method plate() = deliveryPoints.slots().first().cell()
	method topRow() = self.plate().y() - 1
	// Las cintas fijas de la salida: suben desde arriba del ensamblador hasta la fila de arriba, van
	// por ella hasta la columna del platito, y suben al platito
	method exitBeltsUp() = (self.assembler().y() + 2 .. self.topRow() - 1).map({ y => new CellPosition(x = self.assembler().x(), y = y) })
	method exitBeltsAlongTop() = (self.assembler().x() .. self.plate().x() - 1).map({ x => new CellPosition(x = x, y = self.topRow()) })
	method lastBelt() = new CellPosition(x = self.plate().x(), y = self.topRow())
}

// El segundo tutorial: panchos. Enseña a configurar un Dispenser, el horno, el ensamblador (y a
// elegirle la receta) y con qué cosas trabaja un brazo. No se parece al nivel 1 (cheeseburgers y
// papas fritas): otro plato, el ensamblador lo pone el jugador y el brazo es el común.
//
//   fila 10:  Dispenser salchichas  cinta  HORNO      BRAZO  ┌ENSAMBLADOR┐ → cintas hasta el platito
//   fila 8:   Dispenser (a panes)   cinta  cortadora  cinta  cinta que sube al ensamblador
//
// En mayúsculas lo que pone el jugador. El Dispenser de abajo arranca largando salchichas: hay
// que editarlo para que largue panes.
object hotDogTutorialLevel inherits Level(
	name = "Tutorial 2",
	availableMachines = [
        { => new Belt() },
        { => new Oven() },
        { => new Assembler() },
        { => new AutomaticArm() }
    ],
    availableRecipes = [tomatoSoupRecipe, hotDogRecipe],
	goals = [
        new DeliveryGoal(
            kind = hotDog,
            amount = 2,
            label = "Panchos"
        )
    ],
    buildZones = [
        new Zone(
            minX = hotDogTutorialCells.oven().x(),
            maxX = hotDogTutorialCells.assembler().x() + 1,
            minY = hotDogTutorialCells.assembler().y(),
            maxY = hotDogTutorialCells.sausageRow()
        )
    ],
    fixedMachines = [
        new Placement(
            position = hotDogTutorialCells.sausageDispenser(),
            factory = {=> new Dispenser(direction = right, availableKinds = [sausage])}
        ),
        new Placement(
            position = hotDogTutorialCells.sausageBelt(),
            factory = {=> new Belt(direction = right)}
        ),
        new Placement(
            position = hotDogTutorialCells.bunDispenser(),
            factory = {=> new Dispenser(direction = right, availableKinds = [sausage, bun])}
        ),
        new Placement(
            position = hotDogTutorialCells.bunBelt(),
            factory = {=> new Belt(direction = right)}
        ),
        new Placement(
            position = hotDogTutorialCells.cutter(),
            factory = {=> new CuttingMachine(direction = right)}
        ),
        new Placement(
            position = hotDogTutorialCells.bunBeltAfterCutter(),
            factory = {=> new Belt(direction = right)}
        ),
        new Placement(
            position = hotDogTutorialCells.bunBeltUp(),
            factory = {=> new Belt(direction = up)}
        ),
        new Placement(
            position = hotDogTutorialCells.lastBelt(),
            factory = {=> new Belt(direction = up)}
        )
    ]
    + hotDogTutorialCells.exitBeltsUp().map({ cell => new Placement(position = cell, factory = {=> new Belt(direction = up)}) })
    + hotDogTutorialCells.exitBeltsAlongTop().map({ cell => new Placement(position = cell, factory = {=> new Belt(direction = right)}) }),
    tutorial = new StepTutorial(
        steps = [
            new ExplainStep(
                lines = ["Para un pancho", "hacen falta pan", "y salchicha.", "Este dispenser", "larga salchicha", "Enter: seguir"],
                pointsAt = [hotDogTutorialCells.bunDispenser()]
            ),
            new MachineStep(
                lines = ["X: tocá el", "dispenser del", "recuadro y", "elegí el pan"],
                cells = [hotDogTutorialCells.bunDispenser()],
                condition = { machine => machine.product() == bun }
            ),
            new ExplainStep(
                lines = ["Las salchichas", "de este otro", "hay que", "cocinarlas.", "", "Enter: seguir"],
                pointsAt = [hotDogTutorialCells.sausageDispenser()]
            ),
            new MachineStep(
                lines = ["Z: colocar.", "Poné el horno", "en el recuadro:", "cocina lo que", "le llega"],
                cells = [hotDogTutorialCells.oven()],
                condition = { machine => machine.name() == "Oven" && machine.direction() == right }
            ),
            new ExplainStep(
                lines = ["Esta cinta sube", "los panes", "cortados al", "ensamblador,", "que junta todo.", "Enter: seguir"],
                pointsAt = [hotDogTutorialCells.bunBeltUp()]
            ),
            new MachineStep(
                lines = ["W: que apunte", "arriba. Poné el", "ensamblador en", "el recuadro"],
                cells = hotDogTutorialCells.assemblerCells(),
                condition = { machine => machine.name() == "Assembler" && machine.direction() == up }
            ),
            new MachineStep(
                lines = ["Arma la receta", "elegida. X: tocá", "el ensamblador", "y elegí el", "pancho"],
                cells = hotDogTutorialCells.assemblerCells(),
                condition = { machine => machine.selectedRecipe() == hotDogRecipe }
            ),
            new ExplainStep(
                lines = ["Un brazo toma", "de cintas, de la", "freidora y de lo", "que le entregan,", "como el horno.", "Enter: seguir"],
                pointsAt = [hotDogTutorialCells.oven()]
            ),
            new ExplainStep(
                lines = ["Y lo deja en", "cualquier otra", "máquina: como", "el ensamblador.", "", "Enter: seguir"],
                pointsAt = [hotDogTutorialCells.assembler()]
            ),
            new MachineStep(
                lines = ["A: que mire a", "la izquierda.", "Poné el brazo", "entre el horno", "y el", "ensamblador"],
                cells = [hotDogTutorialCells.arm()],
                condition = { machine => machine.name() == "AutomaticArm" && machine.inputSide() == left }
            ),
            new RunStep(
                lines = ["¡Listo! Apretá", "5 para cocinar"]
            ),
            new TutorialStep(
                lines = ["Los panchos", "llegan al", "platito. Esperá", "a que lleguen 2.", "5: apagar"],
                pointsAt = [hotDogTutorialCells.plate()],
                allowsSimulation = true
            )
        ],
        finishedLines = ["¡Panchos", "listos!"]
    )
) {}

// El primer nivel después de los tutoriales
object level1 inherits Level(
	name = "Nivel 1",
	availableMachines = [
        { => new Belt() }, 
        { => new CuttingMachine() },
        { => new Fryer()},
        { => new Oven()},
        { => new SmartRoboticArm() }
    ],
    availableRecipes = [cheeseBurgerRecipe, doubleBurgerRecipe],
	goals = [
        new DeliveryGoal(
            kind = cheeseBurger, 
            amount = 3, 
            label = "Cheeseburgers"
        ),
        new DeliveryGoal(
            kind = friedPotato, 
            amount = 3, 
            label = "Papas fritas"
        )
    ],
    buildZones = [
        new Zone(
            minX = 11,
            maxX = 19,
            minY = 9,
            maxY = 13
        )
    ],
    fixedMachines = [
        new Placement(
            position = new CellPosition(x=11, y=13),
            factory = {=> new Dispenser(direction = right, availableKinds = [meat, bun, potato, cheese])}
        ),
        new Placement(
            position = new CellPosition(x=11, y=12),
            factory = {=> new Dispenser(direction = right, availableKinds = [meat, bun, potato, cheese])}
        ),
        new Placement(
            position = new CellPosition(x=11, y=11),
            factory = {=> new Dispenser(direction = right, availableKinds = [meat, bun, potato, cheese])}
        ),
        new Placement(
            position = new CellPosition(x=11, y=10),
            factory = {=> new Dispenser(direction = right, availableKinds = [meat, bun, potato, cheese])}
        ),
        new Placement(
            position = new CellPosition(x=17, y=11),
            factory = {=> new Assembler(direction = up)}
        )
    ]
) {}