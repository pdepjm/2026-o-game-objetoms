// MANEJA EL DONDE

import wollok.game.*
import machines.*

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

	//pushear elemento al tablero
	method push(position, element) {
		if (!self.isThereAMachine(position)) {
			element.position(position)
			game.addVisual(element)
			self.setPosition(position, element)
		}
	}

	// quitar elemento del tablero
	method pop(position) {
		if (self.isThereAMachine(position)) {
			game.removeVisual(self.machineAt(position))
			self.removePosition(position)
		}
	}

	// Dentro del area de juego
	method inBoard(pos) = pos.x().between(6, 20) && pos.y().between(1, 14)
	method isThereAMachine(pos) = self.machineAt(pos) != null
}
