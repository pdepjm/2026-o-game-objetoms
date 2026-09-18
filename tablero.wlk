// MANEJA EL DONDE

import wollok.game.*
import elementos.*

object orquestador {
	// FILAS - COLUMNAS
	var tablero = new List()

	method initialize() {
		13.times({ i =>
			const fila = new List()
			25.times({ j => fila.add(null) })
			tablero.add(fila)
		})
	}

	method obtenerPosicion(fila, columna) = tablero.get(fila).get(columna)

	method establecer(fila, columna, cosa) {
		tablero[fila][columna].add(cosa)
	}

	method click(posicion) {
		const columna = posicion.x()
		const fila = posicion.y()

		const cosaActual = self.obtenerPosicion(fila, columna)

		if (cosaActual == 0) {
			const cosa = new Personaje(position = posicion)
			game.addVisual(cosa)
			self.establecer(fila, columna, cosa)
		} else {
			game.removeVisual(cosaActual)
			self.establecer(fila, columna, null)
		}
	}
}