// Acá va todo lo que tiene que ver con mover cosas suavemente entre celdas.
// No tiene reloj propio: el simulationEngine le avisa cuándo avanzar (una vez por paso),
// así la pausa y la velocidad x2/x3 afectan a las animaciones sin hacer nada extra.

import wollok.game.*

// Posición con decimales, para dibujar un objeto a mitad de camino entre dos celdas.
// Una Position común se redondea a la celda; ésta no.
class PosicionSuave inherits Position {
	override method round() = self
	override method createPosition(_x, _y) = new PosicionSuave(x = _x, y = _y)
}

object animationEngine {
	// pasos de simulación que lleva recorrer una celda.
	// Las máquinas también lo usan para saber cuándo termina de llegar un item.
	const property pasosPorCelda = 5

	// los objetos que se están moviendo en este momento (los que están quietos no están acá)
	const animados = #{}

	method animar(obj) { animados.add(obj) }
	method terminar(obj) { animados.remove(obj) }

	// Avanza un paso a todos los que se están moviendo.
	// Se recorre una copia porque un objeto que llega a destino se saca del conjunto.
	method tick() { animados.copy().forEach({ o => o.avanzar() }) }
}

// Mixin para cualquier objeto visual que se mueva suavemente (hoy, los ingredientes).
mixin Animado {
	var property position = game.origin()
	var origen = null		// de dónde salió el movimiento actual
	var destino = null		// a dónde va (null si está quieto)
	var paso = 0			// pasos ya dados del movimiento actual
	var totalPasos = 0		// pasos que lleva el movimiento completo

	method moviendose() = destino !== null

	// Dónde va a terminar: el destino si se está moviendo, o donde está parado
	method destinoFinal() = if (self.moviendose()) destino else position

	// Empieza a moverse hacia esa posición. La cantidad de pasos depende de la distancia.
	method move(pos) {
		origen = position
		destino = new PosicionSuave(x = pos.x(), y = pos.y())
		paso = 0
		totalPasos = (origen.distance(destino) * animationEngine.pasosPorCelda()).roundUp().max(1)
		animationEngine.animar(self)
	}

	method moverHacia(direccion) { // toma un  object direction
		self.move(direccion.move(self.destinoFinal()))
	}

	// Un paso de animación: se ubica en el punto intermedio que corresponde entre origen y destino.
	// Al dar el último paso queda exactamente en el destino y deja de estar animado.
	method avanzar() {
		paso += 1
		const t = paso / totalPasos
		position = new PosicionSuave(
			x = origen.x() + (destino.x() - origen.x()) * t,
			y = origen.y() + (destino.y() - origen.y()) * t
		)
		if (paso == totalPasos) {
			position = destino
			destino = null
			animationEngine.terminar(self)
		}
	}

	// Corta el movimiento donde esté (se usa al borrar el item)
	method detener() {
		destino = null
		animationEngine.terminar(self)
	}
}
