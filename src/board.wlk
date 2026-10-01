// MANEJA EL DONDE

import wollok.game.*
import machines.*
import simulationEngine.*

object board {
	const content = new Dictionary()

	// métodos privados

	//sacar elemento del diccionario
	method removePosition(position) = content.remove(position)

	//establecer contenido del diccionario
	method setPosition(position, cosa) {
		content.put(position, cosa)
	}

	// métodos públicos

	//obtener la máquina de una posición (null si no hay)
	method machineAt(position) = content.getOrElse(position, { => null})

	//pushear elemento al tablero. La máquina queda registrada en el simulationEngine.
	// OJO: push y pop no se deben usar con la simulación prendida, porque las máquinas
	// ya calcularon a sus vecinas. El bloqueo de los clicks está en toolsManager.
	method push(position, element) {
		if (!self.isThereAMachine(position)) {
			element.position(position)
			game.addVisual(element)
			self.setPosition(position, element)
			simulationEngine.addSimulatedObject(element)
		}
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
			self.removePosition(position)
		}
	}

	// Verifica si el click esta dentro del tablero
	method inBoard(pos) = pos.x().between(5, 19) && pos.y().between(1, 13)

	// Verificar si hay una maquina en la posicion clickeada
	method isThereAMachine(pos) = self.machineAt(pos) != null
}
