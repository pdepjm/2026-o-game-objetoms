// MANEJA EL DONDE

import wollok.game.*
import simulation.simulationEngine.*
import cellPosition.*

// Una casilla del tablero. Guarda la máquina que está ahí (null si está vacía).
class Cell {
	var property machine = null
}

object board {
	const maxColumn = 19
	const maxRow = 13
	const deliverySlots = []
	//
	// OJO: el machine = null explícito es necesario. Por un bug de Wollok, un objeto creado
	// mientras se inicializa otro objeto (como acá, dentro de board) no toma bien el valor
	// por defecto null: machine() devuelve algo que se muestra como "null" pero no es == null.
	// Pasándolo al crear la casilla, sí queda el null de verdad.
	const grid = (0..maxColumn).map({ x => (0..maxRow).map({ y => new Cell(machine = null) }) })

	// métodos privados

	// La casilla de esa posición. OJO: sólo para posiciones dentro del tablero;
	// fuera de rango, get() da error (por eso machineAt revisa inBoard antes).
	method cellAt(position) = grid.get(position.x()).get(position.y())

	// Saca una maquina de sus casillas
	method removeFromGrid(position) {
		const machine = self.machineAt(position)

		self.cellsFor(machine.cell(), machine).forEach({
			pos => self.cellAt(pos).machine(null)
		})
	}

	// Guarda una maquina en sus casillas
	method addToGrid(startPosition, machine) {
		self.cellsFor(startPosition, machine).forEach({
			pos => self.cellAt(pos).machine(machine)
		})
	}


	// Calculo de celdas que ocupa una maquina
	method cellsFor(startPoint, machine) = (0 .. machine.width() - 1).flatMap({
		dx => (0 .. machine.height() - 1).map({
			dy =>  startPoint.right(dx).up(dy)
		})
	})

	method machines() = grid.flatMap({ column => column.map({ cell => cell.machine()})}).filter({machine => machine != null}).asSet().asList()


	// métodos públicos
	method addDeliverySlot(slot) {
		deliverySlots.add(slot)
		simulationEngine.addSimulatedObject(slot)
	}

	method clear() {
		self.machines().forEach({machine => self.pop(machine.cell())})
	}

	//obtener la máquina de una posición (null si no hay, o si está fuera del tablero).
	// Fuera del tablero pasa, por ejemplo, con una cinta del borde que apunta hacia afuera.
	method machineAt(position) =
		if (self.inBoard(position)) self.cellAt(position).machine() 
		else deliverySlots.findOrDefault({ slot => slot.cell() == position }, null)

	//pushear elemento al tablero. La máquina queda registrada en el simulationEngine.
	// OJO: push y pop no se deben usar con la simulación prendida, porque las máquinas
	// ya calcularon a sus vecinas. El bloqueo de los clicks está en toolsManager.
	method push(position, element) {
		// Quien coloca pregunta antes con canPlace (ver place): llegar acá sin lugar es un bug
		if (!self.canPlace(position, element))
			self.error("No se puede colocar la máquina en " + position)

		// se guarda como CellPosition para que dibujarla sea barato (ver CellPosition)
		element.position(new CellPosition(
			x = position.x() + element.drawOffsetX(), 	// Mueve el dibujo de lugar (Es para el Automatic Arm que es mas grande)
			y = position.y() + element.drawOffsetY())
		)
		game.addVisual(element)
		self.addToGrid(position, element)
		simulationEngine.addSimulatedObject(element)
	}

	// quitar elemento del tablero
	method pop(position) {
		if (self.isThereAMachine(position)) {
			const machine = self.machineAt(position)
			// los items que tenía encima la máquina se van con ella
			machine.heldItems().forEach({ item =>
				item.detener()
				game.removeVisual(item)
			})
			simulationEngine.removeSimulatedObject(machine)
			game.removeVisual(machine)
			self.removeFromGrid(position)
		}
	}

	// Verifica si el click esta dentro del tablero
	method inBoard(pos) = pos.x().between(5, 19) && pos.y().between(1, 13)

	// Verificar si hay una maquina en la posicion clickeada
	method isThereAMachine(pos) = self.machineAt(pos) != null

	method canPlace(pos, machine) = self.cellsFor(pos, machine).all({ c => self.inBoard(c) && !self.isThereAMachine(c) })
}
