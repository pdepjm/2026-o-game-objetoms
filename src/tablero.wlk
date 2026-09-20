// MANEJA EL DONDE

import wollok.game.*
import maquinas.*

object tablero {
	var contenido = new Dictionary()

	method obtenerPosicion(posicion) = contenido.getOrElse(posicion, { => null})

	method quitarPosicion(posicion) = contenido.remove(posicion)
	method establecer(posicion, cosa) {
		contenido.put(posicion, cosa)
	}
}

object orquestador {

	method colocar(posicion, elemento) {

		if (tablero.obtenerPosicion(posicion) == null) {
			elemento.position(posicion)
			game.addVisual(elemento)
			tablero.establecer(posicion, elemento)
		}
	}

	method quitar(posicion) {
		const cosaActual = tablero.obtenerPosicion(posicion)
		if (cosaActual != null) {
			game.removeVisual(cosaActual)
			tablero.quitarPosicion(posicion)
		}
	}
}