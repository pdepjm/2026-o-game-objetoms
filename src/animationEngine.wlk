// Acá va todo lo que tiene que ver con mover cosas suavemente entre celdas.
// No tiene reloj propio: el simulationEngine le avisa cuándo avanzar (una vez por paso),
// así la pausa y la velocidad x2/x3 afectan a las animaciones sin hacer nada extra.

import wollok.game.*

// Posición con decimales, para dibujar un objeto a mitad de camino entre dos celdas.
// Una posición común se redondea a la celda al dibujar; ésta no.
// Es modificable (MutablePosition): se le cambian x e y en vez de crear una posición
// nueva en cada paso, que en Wollok es caro.
class PosicionSuave inherits MutablePosition {
	override method round() = self
	override method createPosition(_x, _y) = new PosicionSuave(x = _x, y = _y)
}

object animationEngine {
	// pasos de simulación que lleva recorrer una celda.
	// Las máquinas también lo usan para saber cuándo termina de llegar un item.
	const property pasosPorCelda = 5

	// Los objetos que se están moviendo en este momento (los que están quietos no están acá).
	// Es una lista y no un conjunto a propósito: copiar o agregar a un conjunto compara
	// cada elemento contra todos los demás, y con muchos items eso era lo más lento del juego.
	var animados = []

	// ¿algún objeto llegó a destino durante este tick?
	var algunoLlego = false

	// Empieza a animar un objeto. Quien llama se asegura de no agregarlo dos veces.
	method animar(obj) { animados.add(obj) }

	// Saca a un objeto que se detuvo antes de llegar (por ejemplo, porque se borró)
	method terminar(obj) { animados.remove(obj) }

	// Un objeto avisa que llegó a destino. No se saca de la lista en el momento,
	// porque se está recorriendo: se limpia al final del tick.
	method avisarLlegada() { algunoLlego = true }

	// Avanza un paso a todos los que se están moviendo y después saca a los que llegaron.
	method tick() {
		animados.forEach({ o => o.avanzar() })
		if (algunoLlego) {
			animados = animados.filter({ o => o.moviendose() })
			algunoLlego = false
		}
	}
}

// Mixin para cualquier objeto visual que se mueva suavemente (hoy, los ingredientes).
mixin Animado {
	// Cada objeto animado tiene su propia posición, que es siempre el mismo objeto:
	// al moverse se le modifican x e y. Nunca se comparte con otro objeto.
	const position = new PosicionSuave()

	var destino = null		// a dónde va (null si está quieto)
	var dx = 0				// cuánto avanza en x en cada paso del movimiento actual
	var dy = 0				// cuánto avanza en y en cada paso del movimiento actual
	var paso = 0			// pasos ya dados del movimiento actual
	var totalPasos = 0		// pasos que lleva el movimiento completo

	method position() = position

	// Se ubica en esa posición. Copia las coordenadas en vez de quedarse con el objeto,
	// porque si no al moverse arrastraría al dueño de esa posición (por ejemplo, una máquina).
	method position(pos) {
		position.x(pos.x())
		position.y(pos.y())
	}

	method moviendose() = destino !== null

	// Dónde va a terminar: el destino si se está moviendo, o donde está parado
	method destinoFinal() = if (self.moviendose()) destino else position

	// Empieza a moverse hacia esa posición. La cantidad de pasos depende de la distancia.
	// El avance por paso (dx, dy) se calcula acá una sola vez, no en cada paso.
	method move(pos) {
		// si ya se estaba moviendo, ya está en la lista de animados: sólo cambia de destino
		if (!self.moviendose()) animationEngine.animar(self)
		destino = new PosicionSuave(x = pos.x(), y = pos.y())
		paso = 0
		totalPasos = (position.distance(destino) * animationEngine.pasosPorCelda()).roundUp().max(1)
		dx = (destino.x() - position.x()) / totalPasos
		dy = (destino.y() - position.y()) / totalPasos
	}

	method moverHacia(direccion) { // toma un  object direction
		self.move(direccion.move(self.destinoFinal()))
	}

	// Un paso de animación: sólo suma el avance ya calculado a la posición.
	// En el último paso se clava en el destino exacto, para no arrastrar error de decimales,
	// y avisa que llegó para que lo saquen de los animados.
	method avanzar() {
		paso += 1
		if (paso == totalPasos) {
			self.position(destino)
			destino = null
			animationEngine.avisarLlegada()
		} else {
			position.x(position.x() + dx)
			position.y(position.y() + dy)
		}
	}

	// Corta el movimiento donde esté (se usa al borrar el item)
	method detener() {
		if (self.moviendose()) animationEngine.terminar(self)
		destino = null
	}
}
