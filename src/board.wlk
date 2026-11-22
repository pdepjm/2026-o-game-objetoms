// Buffet Albert Einstein - el tablero: sus casillas, las máquinas colocadas y las zonas donde se puede construir.
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

// MANEJA EL DONDE

import wollok.game.*
import simulation.simulationEngine.*
import cellPosition.*
import machines.machineClasses.*

// Una casilla del tablero. Guarda la máquina que está ahí (noMachine si está vacía).
class Cell {
	var property machine = noMachine
}

object board {
	const maxColumn = 16
	const maxRow = 10
	const deliverySlots = []
	// Dónde puede construir el jugador (ver "ZONAS DONDE SE PUEDE CONSTRUIR", al final)
	var buildZones = [wholeBoard]
	var blockedLayer = noBlockedLayer
	//
	const grid = (0..maxColumn).map({ x => (0..maxRow).map({ y => new Cell(machine = noMachine) }) })

	// métodos privados

	method cellAt(position) = grid.get(position.x()).get(position.y())

	method removeFromGrid(position) {
		const machine = self.machineAt(position)

		self.cellsFor(machine.cell(), machine).forEach({
			pos => self.cellAt(pos).machine(noMachine)
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

	method machines() = grid.flatMap({ column => column.flatMap({ cell => cell.machine().asList() }) }).asSet().asList()

	// La energía que gastan todas las máquinas colocadas (las fijas del nivel también)
	method totalEnergy() = self.machines().sum({ machine => machine.energyConsumption() })

	// Avisa a la máquina colocada y a las de al lado que algo cambió en su entorno (las cintas recalculan su forma)
	method updateNeighbourBelts(position, placedElement) {
		placedElement.onNeighbourChanged()

		const neighbours = [
			self.machineAt(position.left(1)),
			self.machineAt(position.right(1)),
			self.machineAt(position.up(1)),
			self.machineAt(position.down(1))
		]

		neighbours.forEach({ neighbour => neighbour.onNeighbourChanged() })
	}

	// métodos públicos
	method addDeliverySlot(slot) {
		deliverySlots.add(slot)
		simulationEngine.addSimulatedObject(slot)
	}

	method clear() {
		self.machines().forEach({machine => self.pop(machine.cell())})
	}

	method machineAt(position) =
		if (self.inBoard(position)) self.cellAt(position).machine() 
		else deliverySlots.findOrDefault({ slot => slot.cell() == position }, noMachine)

	//pushear elemento al tablero. La máquina queda registrada en el simulationEngine.
	// OJO: push y pop no se deben usar con la simulación prendida, porque las máquinas
	// ya calcularon a sus vecinas. El bloqueo de los clicks está en toolsManager.
	method push(position, element) {
		if (!self.canPlace(position, element))
			self.error("No se puede colocar la máquina en " + position)

		element.position(new CellPosition(
			x = position.x() + element.drawOffsetX(), 
			y = position.y() + element.drawOffsetY())
		)
		game.addVisual(element)
		self.addToGrid(position, element)
		// lo que la máquina dibuja aparte (la insignia del dispenser), encima de ella
		element.addedToBoard()
		simulationEngine.addSimulatedObject(element)
		
		// NUEVO: Al colocar una máquina, actualizamos las cintas de al lado
		self.updateNeighbourBelts(position, element)
	}

	// Saca la máquina de esa posición, aunque esté bloqueada: el bloqueo es para el jugador
	// (lo controlan las acciones delete y rotate), no para el juego. Así board.clear()
	// también se lleva las máquinas fijas de un nivel al reiniciarlo o cambiar de nivel.
	method pop(position) {
		if (self.isThereAMachine(position)) {
			const machine = self.machineAt(position)
			machine.heldItems().forEach({ item =>
				item.detener()
				game.removeVisual(item)
			})
			simulationEngine.removeSimulatedObject(machine)
			machine.removedFromBoard()
			game.removeVisual(machine)
			self.removeFromGrid(position)
			
			// NUEVO: Al quitar una máquina, actualizamos las cintas de al lado
			self.updateNeighbourBelts(position, noMachine) 
		}
	}

	method inBoard(pos) = pos.x().between(5, maxColumn) && pos.y().between(1, maxRow)

	method isThereAMachine(pos) = !self.machineAt(pos).asList().isEmpty()

	method isThereAMachineUnlocked(pos) = self.isThereAMachine(pos) && !self.machineAt(pos).locked()

	method canPlace(pos, machine) = self.cellsFor(pos, machine).all({ c => self.inBoard(c) && !self.isThereAMachine(c) })

	// ----------- ZONAS DONDE SE PUEDE CONSTRUIR -----------
	// Dónde puede colocar máquinas el JUGADOR. Las define el nivel (Level.buildZones, ver levelManager.load);
	// por defecto, todo el tablero. Las máquinas fijas del nivel no tienen esta restricción (usan push).

	// ¿Puede el jugador construir en esa celda? Tiene que estar en el tablero y en alguna de las zonas.
	method isBuildable(pos) = self.inBoard(pos) && buildZones.any({ zone => zone.contains(pos) })

	// ¿Puede el jugador colocar esa máquina ahí? Como canPlace, y además todas sus celdas tienen que
	// estar en alguna zona (una de 2x2 puede quedar repartida entre dos zonas pegadas).
	method canBuild(pos, machine) = self.canPlace(pos, machine) && self.cellsFor(pos, machine).all({ c => self.isBuildable(c) })

	method buildZones() = buildZones

	// Cambia las zonas y dibuja la capa que oscurece las celdas donde no se puede construir (la del nivel,
	// ya hecha: ver BlockedLayer). Sin capa, no se marca nada.
	// RENDIMIENTO: es UN solo visual y se cambia sólo al cargar un nivel, no en cada frame.
	method buildZones(zones) {
		self.buildZones(zones, noBlockedLayer)
	}

	method buildZones(zones, layer) {
		buildZones = zones
		blockedLayer.hide()
		blockedLayer = layer
		blockedLayer.show()
	}

	// La capa que se ve sobre las celdas donde no se puede construir
	method blockedLayer() = blockedLayer

	// Todas las celdas del tablero
	method boardCells() = (5..maxColumn).flatMap({ x => (1..maxRow).map({ y => new CellPosition(x = x, y = y) }) })
}

// Un rectángulo de celdas, de (minX, minY) a (maxX, maxY), con los bordes incluidos.
// El tablero lo usa para saber dónde se puede construir (las zonas de un nivel, ver buildZones);
// los menús, para ubicar sus zonas en la pantalla (menuManager).
class Zone {
	const minX
	const maxX
	const minY
	const maxY

	method contains(pos) = pos.x().between(minX, maxX) && pos.y().between(minY, maxY)

	// Posicion relativa desde la esquina inferior izquierda
	method at(dx, dy) = new CellPosition(x= minX + dx, y= minY + dy)

	// Getter de posicion inicial
	method origin() = self.at(0, 0)
}

// Todo el tablero: la zona donde se puede construir si el nivel no dice otra cosa
object wholeBoard {
	method contains(pos) = true
}

// La capa de celdas bloqueadas de un nivel: UNA imagen del tamaño de la pantalla, transparente salvo en las
// celdas donde no se puede construir (se genera con assets/levels/makeBlockedOverlays.py).
class BlockedLayer {
	const property image
	const property position = new CellPosition(x = 0, y = 0)

	method show() {
		if (!game.hasVisual(self)) game.addVisual(self)
	}

	method hide() {
		if (game.hasVisual(self)) game.removeVisual(self)
	}
}

// Un nivel sin celdas bloqueadas: no dibuja nada
object noBlockedLayer {
	method show() {}

	method hide() {}
}
