// Buffet Albert Einstein - los niveles concretos del juego y el modo libre.
//
// Copyright (C) 2026  grupo objeTOMs (Mateo Bustos, Carlos Aramis Chambi Flores,
// Facundo Ramounat, Federico Scalise Giussani, Mateo Silva)
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

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
) {
    // En el modo libre, la info del nivel muestra cómo volver
    override method showHints(menu) {
        menu.showHint("L: volver")
    }

    // La tecla L en el modo libre vuelve al nivel que toca jugar
    override method toggleFreePlay(manager) {
        manager.load(manager.levelToPlay())
    }
}

// Las celdas del tutorial de papas fritas. Las usan sus máquinas fijas, su zona de construcción y
// sus pasos: para mover el armado, alcanza con cambiarlas acá.
// La línea va por la fila `row` y dobla hacia arriba en la columna del primer platito.
object friesTutorialCells {
	const property row = 5

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
// El brazo inteligente hay que rotarlo para que agarre de la freidora, y editarlo para que deje salir la
// papa frita hacia la cinta (en su panel, clic en la papa frita hasta que vaya →; por defecto no deja salir nada). Como sólo agarra lo que dejó salir, espera a que la papa se fría. Antes de cada máquina que pone el jugador, un ExplainStep señala con la
// flecha la máquina de la que viene (pointsAt) y se sigue con Enter. Después, el paso que la pide
// marca con el recuadro dónde va (cells), y deja colocar, borrar y rotar sólo ahí.
object tutorialLevel inherits Level(
	name = "Tutorial 1",
	availableMachines = [
        machineManager.beltFactory(),
        machineManager.cuttingMachineFactory(),
        machineManager.fryerFactory(),
        machineManager.smartRoboticArmFactory()
    ],
    availableRecipes = [],
	goals = [
        new DeliveryGoal(
            kind = friedPotato,
            amount = 2,
            label = "Papas Fritas"
        )
    ],
    blockedLayer = new BlockedLayer(image = "levels/blocked_tutorial.png"),
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
                lines = ["Las papas salen", "del dispenser", "de la flecha."],
                keys = ["continue"],
                pointsAt = [friesTutorialCells.dispenser()]
            ),
            new MachineStep(
                lines = ["Elegí la cinta", "y ponela en el", "recuadro para", "llevar las papas"],
                keys = ["place"],
                cells = [friesTutorialCells.firstBelt()],
                allowedMachines = [machineManager.beltFactory()],
                condition = { machine => machine.direction() == right }
            ),
            new ExplainStep(
                lines = ["La cinta lleva", "las papas hacia", "donde apunta."],
                keys = ["continue"],
                pointsAt = [friesTutorialCells.firstBelt()]
            ),
            new MachineStep(
                lines = ["Poné la", "cortadora: corta", "las papas que", "le trae la cinta"],
                keys = ["place"],
                cells = [friesTutorialCells.cutter()],
                allowedMachines = [machineManager.cuttingMachineFactory()],
                condition = { machine => machine.direction() == right }
            ),
            new ExplainStep(
                lines = ["Este brazo toma", "las papas de la", "cinta y las deja", "del otro lado."],
                keys = ["continue"],
                pointsAt = [friesTutorialCells.fixedArm()]
            ),
            new MachineStep(
                lines = ["Poné la", "freidora donde", "el brazo deja", "las papas"],
                keys = ["place"],
                cells = [friesTutorialCells.fryer()],
                allowedMachines = [machineManager.fryerFactory()]
            ),
            new ExplainStep(
                lines = ["La freidora no", "larga las papas:", "hay que sacarlas", "con un brazo."],
                keys = ["continue"],
                pointsAt = [friesTutorialCells.fryer()]
            ),
            new MachineStep(
                lines = ["Poné el brazo", "inteligente en", "el recuadro"],
                keys = ["place"],
                cells = [friesTutorialCells.smartArm()],
                allowedMachines = [machineManager.smartRoboticArmFactory()]
            ),
            new MachineStep(
                lines = ["Un brazo agarra", "de donde mira.", "Rotalo hasta que", "mire la freidora"],
                keys = ["rotate"],
                cells = [friesTutorialCells.smartArm()],
                condition = { machine => machine.inputSide() == left }
            ),
            new MachineStep(
                lines = ["Tocá la papa", "frita hasta que", "vaya a la cinta", "de la derecha."],
                keys = ["edit", "choose"],
                cells = [friesTutorialCells.smartArm()],
                // cada clic la manda a otro lado (↑, →, ↓): recién se cumple cuando sale hacia la cinta (→).
                // Si sólo pidiera que la agarre, se cumpliría con el primer clic, que la manda hacia arriba.
                condition = { machine => machine.sideOf(friedPotato) == right }
            ),
            new RunStep(
                lines = ["¡Listo! Ya se", "puede cocinar"],
                keys = ["start"]
            ),
            new TutorialStep(
                lines = ["Las papas fritas", "llegan al", "platito. Esperá", "a que lleguen 2."],
                keys = ["stop"],
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
	const property sausageRow = 7
	const property bunRow = 5

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
//   fila 7:   Dispenser salchichas  cinta  HORNO      BRAZO  ┌ENSAMBLADOR┐ → cintas hasta el platito
//   fila 5:   Dispenser (a panes)   cinta  cortadora  cinta  cinta que sube al ensamblador
//
// En mayúsculas lo que pone el jugador. El Dispenser de abajo arranca largando salchichas: hay
// que editarlo para que largue panes.
object hotDogTutorialLevel inherits Level(
	name = "Tutorial 2",
	availableMachines = [
        machineManager.beltFactory(),
        machineManager.ovenFactory(),
        machineManager.assemblerFactory(),
        machineManager.automaticArmFactory()
    ],
    availableRecipes = [tomatoSoupRecipe, hotDogRecipe],
	goals = [
        new DeliveryGoal(
            kind = hotDog,
            amount = 2,
            label = "Panchos"
        )
    ],
    blockedLayer = new BlockedLayer(image = "levels/blocked_hotdog.png"),
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
                lines = ["Para un pancho", "hacen falta pan", "y salchicha.", "Este dispenser", "larga salchicha"],
                keys = ["continue"],
                pointsAt = [hotDogTutorialCells.bunDispenser()]
            ),
            new MachineStep(
                lines = ["Hacé que el", "dispenser del", "recuadro largue", "pan."],
                keys = ["edit", "choose"],
                cells = [hotDogTutorialCells.bunDispenser()],
                condition = { machine => machine.product() == bun }
            ),
            new ExplainStep(
                lines = ["Las salchichas", "de este otro", "hay que", "cocinarlas."],
                keys = ["continue"],
                pointsAt = [hotDogTutorialCells.sausageDispenser()]
            ),
            new MachineStep(
                lines = ["Poné el horno", "en el recuadro:", "cocina lo que", "le llega"],
                keys = ["place"],
                cells = [hotDogTutorialCells.oven()],
                allowedMachines = [machineManager.ovenFactory()],
                condition = { machine => machine.direction() == right }
            ),
            new ExplainStep(
                lines = ["Esta cinta sube", "los panes", "cortados al", "ensamblador,", "que junta todo."],
                keys = ["continue"],
                pointsAt = [hotDogTutorialCells.bunBeltUp()]
            ),
            new MachineStep(
                lines = ["Poné el", "ensamblador", "apuntando arriba"],
                keys = ["place", "up"],
                cells = hotDogTutorialCells.assemblerCells(),
                allowedMachines = [machineManager.assemblerFactory()],
                condition = { machine => machine.direction() == up }
            ),
            new MachineStep(
                lines = ["Arma la receta", "elegida: elegí", "el pancho."],
                keys = ["edit", "choose"],
                cells = hotDogTutorialCells.assemblerCells(),
                condition = { machine => machine.selectedRecipe() == hotDogRecipe }
            ),
            new ExplainStep(
                lines = ["Un brazo toma", "de cintas, de la", "freidora y de lo", "que le entregan,", "como el horno."],
                keys = ["continue"],
                pointsAt = [hotDogTutorialCells.oven()]
            ),
            new ExplainStep(
                lines = ["Y lo deja en", "cualquier otra", "máquina: como", "el ensamblador."],
                keys = ["continue"],
                pointsAt = [hotDogTutorialCells.assembler()]
            ),
            new MachineStep(
                lines = ["Poné el brazo", "entre el horno", "y el ensamblador"],
                keys = ["place", "left"],
                cells = [hotDogTutorialCells.arm()],
                allowedMachines = [machineManager.automaticArmFactory()],
                condition = { machine => machine.inputSide() == left }
            ),
            new RunStep(
                lines = ["¡Listo! Ya se", "puede cocinar"],
                keys = ["start"]
            ),
            new TutorialStep(
                lines = ["Los panchos", "llegan al", "platito. Esperá", "a que lleguen 2."],
                keys = ["stop"],
                pointsAt = [hotDogTutorialCells.plate()],
                allowsSimulation = true
            )
        ],
        finishedLines = ["¡Panchos", "listos!"]
    )
) {}

// Las celdas del tutorial de energía (ver friesTutorialCells). Una sola línea por la fila de arriba del
// tablero: dispenser, cinta, cortadora y cintas fijas hasta el platito. Las dos del medio las pone el jugador.
object energyTutorialCells {
	const property row = 10

	method at(column) = new CellPosition(x = column, y = row)

	method dispenser() = self.at(8)
	method belt() = self.at(9)           // la pone el jugador
	method cutter() = self.at(10)        // la pone el jugador
	method fixedBelts() = [self.at(11), self.at(12)]
	method lastBelt() = self.at(deliveryPoints.slots().first().cell().x())   // sube al platito

	method plate() = deliveryPoints.slots().first().cell()
}

// El tercer tutorial: la energía. Cada máquina gasta energía y el nivel tiene un límite (energyLimit):
// si se pasa, no se puede prender la simulación. Con todo armado a velocidad normal se gasta 10 y el límite
// es 9, así que hay que bajarle la velocidad al dispenser (x0.5 gasta 1 menos). Las máquinas fijas también gastan.
//
//   fila 10:  Dispenser  cinta    cortadora  cinta  cinta  cinta que sube al platito
//             fijo       JUGADOR  JUGADOR    fija   fija   fija
object energyTutorialLevel inherits Level(
	name = "Tutorial 3",
	availableMachines = [
        machineManager.beltFactory(),
        machineManager.cuttingMachineFactory()
    ],
    availableRecipes = [],
	goals = [
        new DeliveryGoal(
            kind = cutPotato,
            amount = 2,
            label = "Papas Cortadas"
        )
    ],
    energyLimit = new EnergyLimit(max = 9),
    blockedLayer = new BlockedLayer(image = "levels/blocked_energy.png"),
    buildZones = [
        new Zone(
            minX = energyTutorialCells.belt().x(),
            maxX = energyTutorialCells.cutter().x(),
            minY = energyTutorialCells.row(),
            maxY = energyTutorialCells.row()
        )
    ],
    fixedMachines = [
        new Placement(
            position = energyTutorialCells.dispenser(),
            factory = {=> new Dispenser(direction = right, availableKinds = [potato])}
        ),
        new Placement(
            position = energyTutorialCells.lastBelt(),
            factory = {=> new Belt(direction = up)}
        )
    ]
    + energyTutorialCells.fixedBelts().map({ cell => new Placement(position = cell, factory = {=> new Belt(direction = right)}) }),
    tutorial = new StepTutorial(
        steps = [
            new ExplainStep(
                lines = ["Cada máquina", "gasta energía.", "El nivel tiene", "un límite: mirá", "el contador."],
                keys = ["continue"],
                pointsAt = [energyTutorialCells.dispenser()]
            ),
            new MachineStep(
                lines = ["Poné la cinta", "en el recuadro"],
                keys = ["place"],
                cells = [energyTutorialCells.belt()],
                allowedMachines = [machineManager.beltFactory()],
                condition = { machine => machine.direction() == right }
            ),
            new MachineStep(
                lines = ["Ahora la", "cortadora: gasta", "más que la", "cinta"],
                keys = ["place"],
                cells = [energyTutorialCells.cutter()],
                allowedMachines = [machineManager.cuttingMachineFactory()],
                condition = { machine => machine.direction() == right }
            ),
            new MachineStep(
                lines = ["¡Te pasaste del", "límite! Bajá la", "velocidad del", "dispenser: x0.5"],
                keys = ["edit", "choose"],
                cells = [energyTutorialCells.dispenser()],
                condition = { machine => machine.speed() == 0.5 }
            ),
            new RunStep(
                lines = ["¡Listo! Ya se", "puede cocinar"],
                keys = ["start"]
            ),
            new TutorialStep(
                lines = ["Las papas", "cortadas llegan", "al platito.", "Esperá a que", "lleguen 2."],
                keys = ["stop"],
                pointsAt = [energyTutorialCells.plate()],
                allowsSimulation = true
            )
        ],
        finishedLines = ["¡Bien! Ahora", "sabés cuidar", "la energía."]
    )
) {}

// NIVEL 1: ensaladas. El primero sin tutorial, y el más simple: dos ingredientes que sólo hay que
// cortar. Los Dispensers ya largan lo que hace falta; el jugador arma todo lo demás, incluido el
// ensamblador (y tiene que elegirle la receta: también ofrece la sopa de tomate).
object level1 inherits Level(
	name = "Nivel 1",
	availableMachines = [
        machineManager.beltFactory(),
        machineManager.cuttingMachineFactory(),
        machineManager.assemblerFactory()
    ],
    availableRecipes = [saladRecipe, tomatoSoupRecipe],
	goals = [
        new DeliveryGoal(
            kind = salad,
            amount = 3,
            label = "Ensaladas"
        )
    ],
    fixedMachines = [
        new Placement(
            position = new CellPosition(x=5, y=8),
            factory = {=> new Dispenser(direction = right, availableKinds = [lettuce])}
        ),
        new Placement(
            position = new CellPosition(x=5, y=3),
            factory = {=> new Dispenser(direction = right, availableKinds = [tomato])}
        )
    ]
) {}

// NIVEL 2: hamburguesas. Cuatro ingredientes con dos procesos (cortar el pan, la lechuga y el tomate;
// cocinar la carne) que tienen que llegar al ensamblador cada uno por su lado (si no, el que sobra traba
// al resto). Los cuatro Dispensers ofrecen todo: hay que elegir qué larga cada uno.
object level2 inherits Level(
	name = "Nivel 2",
	availableMachines = [
        machineManager.beltFactory(),
        machineManager.cuttingMachineFactory(),
        machineManager.ovenFactory(),
        machineManager.assemblerFactory()
    ],
    availableRecipes = [cheeseBurgerRecipe, burgerRecipe, doubleBurgerRecipe],
	goals = [
        new DeliveryGoal(
            kind = burger,
            amount = 3,
            label = "Hamburguesas"
        )
    ],
    fixedMachines = [
        new Placement(
            position = new CellPosition(x=5, y=8),
            factory = {=> new Dispenser(direction = right, availableKinds = [bun, lettuce, tomato, meat])}
        ),
        new Placement(
            position = new CellPosition(x=5, y=7),
            factory = {=> new Dispenser(direction = right, availableKinds = [bun, lettuce, tomato, meat])}
        ),
        new Placement(
            position = new CellPosition(x=5, y=4),
            factory = {=> new Dispenser(direction = right, availableKinds = [bun, lettuce, tomato, meat])}
        ),
        new Placement(
            position = new CellPosition(x=5, y=2),
            factory = {=> new Dispenser(direction = right, availableKinds = [bun, lettuce, tomato, meat])}
        )
    ]
) {}

// NIVEL 3: desayunos y pizzas, a la vez. Dos ensambladores, cada uno a su platito. El desayuno lleva un
// huevo frito (la freidora sólo trabaja con brazos: uno que se lo lleve y uno inteligente que espere a que
// se fría) y panceta cocinada; la pizza, masa cocinada, queso cortado una sola vez y salame cortado.
// Cinco Dispensers que ofrecen todo. El tablero está limitado: arriba se arma la pizza (filas 7 a 9, y las
// columnas 12 y 13 hasta la fila 10, para llegar a su platito) y abajo el desayuno (filas 2 a 4, y una sola
// columna, la 14, hasta el suyo). Las filas 5 y 6 las separan, y la fila de arriba a la izquierda no se usa.
object level3 inherits Level(
	name = "Nivel 3",
	availableMachines = [
        machineManager.beltFactory(),
        machineManager.cuttingMachineFactory(),
        machineManager.ovenFactory(),
        machineManager.fryerFactory(),
        machineManager.automaticArmFactory(),
        machineManager.smartRoboticArmFactory(),
        machineManager.assemblerFactory()
    ],
    availableRecipes = [toastRecipe, pizzaPepperoniRecipe, breakfastRecipe],
    blockedLayer = new BlockedLayer(image = "levels/blocked_level3.png"),
    buildZones = [
        new Zone(minX = 6, maxX = 11, minY = 7, maxY = 9),
        new Zone(minX = 12, maxX = 13, minY = 7, maxY = 10),
        new Zone(minX = 6, maxX = 15, minY = 2, maxY = 4),
        new Zone(minX = 14, maxX = 14, minY = 5, maxY = 10)
    ],
	goals = [
        new DeliveryGoal(
            kind = breakfast,
            amount = 2,
            label = "Desayunos"
        ),
        new DeliveryGoal(
            kind = pizzaPepperoni,
            amount = 2,
            label = "Pizzas"
        )
    ],
    fixedMachines = [
        new Placement(
            position = new CellPosition(x=5, y=9),
            factory = {=> new Dispenser(direction = right, availableKinds = [pizzaDough, cheese, salami, egg, bacon])}
        ),
        new Placement(
            position = new CellPosition(x=5, y=8),
            factory = {=> new Dispenser(direction = right, availableKinds = [pizzaDough, cheese, salami, egg, bacon])}
        ),
        new Placement(
            position = new CellPosition(x=5, y=7),
            factory = {=> new Dispenser(direction = right, availableKinds = [pizzaDough, cheese, salami, egg, bacon])}
        ),
        new Placement(
            position = new CellPosition(x=5, y=4),
            factory = {=> new Dispenser(direction = right, availableKinds = [pizzaDough, cheese, salami, egg, bacon])}
        ),
        new Placement(
            position = new CellPosition(x=5, y=2),
            factory = {=> new Dispenser(direction = right, availableKinds = [pizzaDough, cheese, salami, egg, bacon])}
        )
    ]
) {}

// NIVEL 4: hamburguesas con la energía justa. El mismo plato que el nivel 2, pero con un límite de energía
// (energyLimit): armado a lo grande, con las máquinas desparramadas y todo a velocidad normal, se gasta
// de más y no se puede prender la simulación. Hay que armar compacto (las cintas gastan 1 cada una, y son
// las que más pesan) y bajar velocidades donde convenga (x0.5 gasta 1 menos que x1, a costa de tardar el doble).
// Los Dispensers fijos también gastan: cuatro, que ofrecen todo (hay que elegir qué larga cada uno).
object level4 inherits Level(
	name = "Nivel 4",
	availableMachines = [
        machineManager.beltFactory(),
        machineManager.cuttingMachineFactory(),
        machineManager.ovenFactory(),
        machineManager.assemblerFactory()
    ],
    availableRecipes = [burgerRecipe, cheeseBurgerRecipe],
	goals = [
        new DeliveryGoal(
            kind = burger,
            amount = 3,
            label = "Hamburguesas"
        )
    ],
    energyLimit = new EnergyLimit(max = 40),
    fixedMachines = [
        new Placement(
            position = new CellPosition(x=5, y=8),
            factory = {=> new Dispenser(direction = right, availableKinds = [bun, lettuce, tomato, meat])}
        ),
        new Placement(
            position = new CellPosition(x=5, y=7),
            factory = {=> new Dispenser(direction = right, availableKinds = [bun, lettuce, tomato, meat])}
        ),
        new Placement(
            position = new CellPosition(x=5, y=5),
            factory = {=> new Dispenser(direction = right, availableKinds = [bun, lettuce, tomato, meat])}
        ),
        new Placement(
            position = new CellPosition(x=5, y=4),
            factory = {=> new Dispenser(direction = right, availableKinds = [bun, lettuce, tomato, meat])}
        )
    ]
) {}
