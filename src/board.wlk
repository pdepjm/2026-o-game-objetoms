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

	const grid = (0..maxColumn).map({ x => (0..maxRow).map({ y => new Cell(machine = null) }) })

	// métodos privados

	method cellAt(position) = grid.get(position.x()).get(position.y())

	method removeFromGrid(position) {
		const machine = self.machineAt(position)

		self.cellsFor(machine.cell(), machine).forEach({
			pos => self.cellAt(pos).machine(null)
		})
	}

	method addToGrid(startPosition, machine) {
		self.cellsFor(startPosition, machine).forEach({
			pos => self.cellAt(pos).machine(machine)
		})
	}

	method cellsFor(startPoint, machine) = (0 .. machine.width() - 1).flatMap({
		dx => (0 .. machine.height() - 1).map({
			dy =>  startPoint.right(dx).up(dy)
		})
	})

	// NUEVO: Avisa a las cintas que recalculen su forma al construir o destruir
	method updateNeighbourBelts(position, placedElement) {
		if (placedElement != null && placedElement.name() == "Belt") {
			placedElement.updateShape()
			if (!simulationEngine.running()) placedElement.showStatic()
		}

		const neighbours = [
			self.machineAt(position.left(1)),
			self.machineAt(position.right(1)),
			self.machineAt(position.up(1)),
			self.machineAt(position.down(1))
		]
		
		neighbours.forEach({ neighbour =>
			if (neighbour != null && neighbour.name() == "Belt") {
				neighbour.updateShape()
				if (!simulationEngine.running()) neighbour.showStatic()
			}
		})
	}

	// métodos públicos

	method machineAt(position) =
		if (self.inBoard(position)) self.cellAt(position).machine() else null

	method push(position, element) {
		if (!self.canPlace(position, element))
			self.error("No se puede colocar la máquina en " + position)

		element.position(new CellPosition(
			x = position.x() + element.drawOffsetX(), 
			y = position.y() + element.drawOffsetY())
		)
		game.addVisual(element)
		self.addToGrid(position, element)
		simulationEngine.addSimulatedObject(element)
		
		// NUEVO: Al colocar una máquina, actualizamos las cintas de al lado
		self.updateNeighbourBelts(position, element)
	}

	method pop(position) {
		if (self.isThereAMachine(position)) {
			const machine = self.machineAt(position)
			machine.heldItems().forEach({ item =>
				item.detener()
				game.removeVisual(item)
			})
			simulationEngine.removeSimulatedObject(machine)
			game.removeVisual(machine)
			self.removeFromGrid(position)
			
			// NUEVO: Al quitar una máquina, actualizamos las cintas de al lado
			self.updateNeighbourBelts(position, null) 
		}
	}

	method inBoard(pos) = pos.x().between(5, 19) && pos.y().between(1, 13)

	method isThereAMachine(pos) = self.machineAt(pos) != null

	method canPlace(pos, machine) = self.cellsFor(pos, machine).all({ c => self.inBoard(c) && !self.isThereAMachine(c) })
}