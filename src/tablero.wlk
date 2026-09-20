// MANEJA EL DONDE

import wollok.game.*
import maquinas.*

object tablero {
	var contenido = new Dictionary()

	// métodos privados
	method obtenerPosicion(posicion) = contenido.getOrElse(posicion, { => null})

	method quitarPosicion(posicion) = contenido.remove(posicion)
	method establecer(posicion, cosa) {
		contenido.put(posicion, cosa)
	}

	// métodos públicos
	method colocar(posicion, elemento) {

		if (self.obtenerPosicion(posicion) == null) {
			elemento.position(posicion)
			game.addVisual(elemento)
			self.establecer(posicion, elemento)
		}
	}

	method quitar(posicion) {
		const cosaActual = self.obtenerPosicion(posicion)
		if (cosaActual != null) {
			game.removeVisual(cosaActual)
			self.quitarPosicion(posicion)
		}
	}
}
