// MANEJA EL DONDE

import wollok.game.*
import elementos.*

object tablero {
	var contenido = new Dictionary()

	method obtenerPosicion(posicion) = contenido.getOrElse(posicion, { => null})

	method quitarPosicion(posicion) = contenido.remove(posicion)
	method establecer(posicion, cosa) {
		contenido.put(posicion, cosa)
	}
}

object orquestador {
	var cosaActual = null

	method actualizarObjeto(posicion) {
		cosaActual = tablero.obtenerPosicion(posicion)
	}

	method colocar(posicion) {
		self.actualizarObjeto(posicion)

		if (cosaActual == null) {
			var cosa = new Personaje(position = posicion)
			game.addVisual(cosa)
			tablero.establecer(posicion, cosa)
		}
	}

	method quitar(posicion) {
		self.actualizarObjeto(posicion)

		if (cosaActual != null) {
			game.removeVisual(cosaActual)
			tablero.quitarPosicion(posicion)
		}
	}
}