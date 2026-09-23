// MANEJA EL DONDE

import wollok.game.*
import machines.*

object board {
	const content = new Dictionary()

	// métodos privados

	//obtener contenido del diccionario
	method getPosition(position) = content.getOrElse(position, { => null})

	//sacar elemento del diccionario
	method removePosition(position) = content.remove(position)

	//establecer contenido del diccionario
	method setPosition(position, cosa) {
		content.put(position, cosa)
	}

	// métodos públicos

	//pushear elemento al tablero
	method push(position, element) {

		if (self.getPosition(position) == null) {
			element.position(position)
			game.addVisual(element)
			self.setPosition(position, element)
		}
	}

	// quitar elemento del tablero
	method pop(position) {
		const selectedItem = self.getPosition(position)
		if (selectedItem != null) {
			game.removeVisual(selectedItem)
			self.removePosition(position)
		}
	}
}
