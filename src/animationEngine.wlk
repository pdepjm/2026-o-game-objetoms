// Acá va todo lo que tiene que ver con mover cosas suavemente entre celdas.
// No tiene reloj propio: el simulationEngine le avisa cuándo avanzar.

import wollok.game.*

class PosicionSuave inherits Position {
	override method round() = self
	override method createPosition(_x, _y) = new PosicionSuave(x = _x, y = _y)
}

object animationEngine {
	const property pasosPorCelda = 5   // pasos de animación que lleva recorrer una celda

	// los objetos que se están moviendo en este momento
	const animados = #{}

	method animar(obj) { animados.add(obj) }
	method terminar(obj) { animados.remove(obj) }
	method tick() { animados.copy().forEach({ o => o.avanzar() }) }
}

mixin Animado {
	var property position = game.origin()
	var origen = null
	var destino = null
	var paso = 0
	var totalPasos = 0

	method moviendose() = destino !== null

	method destinoFinal() = if (self.moviendose()) destino else position

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

	method detener() {
		destino = null
		animationEngine.terminar(self)
	}
}
