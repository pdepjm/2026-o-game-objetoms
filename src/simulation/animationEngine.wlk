// Buffet Albert Einstein - las animaciones paso a paso de los objetos y las máquinas.
//
// Copyright (C) 2026  grupo objeTOMs (Mateo Bustos, Carlos Aramis Chambi Flores,
// Facundo Ramounat, Federico Scalise Giussani, Mateo Silva)
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

// Acá va todo lo que se anima paso a paso: objetos que se mueven suavemente entre celdas
// (mixin Animated) y máquinas que cambian de imagen cuadro por cuadro (MachineAnimator,
// en machines/machineClasses.wlk).
// No tiene reloj propio: el simulationEngine le avisa cuándo avanzar (una vez por paso),
// así la pausa y la velocidad x2/x3 afectan a las animaciones sin hacer nada extra.
import wollok.game.*

// Posición con decimales, para dibujar un objeto a mitad de camino entre dos celdas.
// Una posición común se redondea a la celda al dibujar; ésta no.
// Es modificable (MutablePosition): se le cambian x e y en vez de crear una posición
// nueva en cada paso, que en Wollok es caro.
class SmoothPosition inherits MutablePosition {
	override method round() = self

	// Un destino: algo que se está moviendo hacia él (ver noDestination)
	method isMoving() = true
	method orElse(current) = self
	
	override method createPosition(_x, _y) = new SmoothPosition(x = _x, y = _y)
}

// "No va a ningún lado": el destino de lo que está quieto
object noDestination {
	method isMoving() = false
	method orElse(current) = current
}

// "No hay animación": lo que muestra una máquina que no se está animando
object noAnimation {
	method isRunning() = false
}

// "No hay nada que hacer": el bloque del final de una animación que no tiene ninguno
object noAction {
	method apply() {}
}

object animationEngine {
	// pasos de simulación que lleva recorrer una celda.
	// Las máquinas también lo usan para saber cuándo termina de llegar un item.
	const property stepsPerCell = 5
	// Los objetos que se están animando en este momento (los que están quietos no están acá).
	// Cualquier objeto puede estar acá si entiende advance() y animating().
	// Es una lista y no un conjunto a propósito: copiar o agregar a un conjunto compara
	// cada elemento contra todos los demás, y con muchos items eso era lo más lento del juego.
	var animated = []
	// ¿algún objeto terminó su animación durante este tick?
	var anyArrived = false
	var pendingBlocks = []
	// ¿se están avanzando los animados en este momento? (ver play en MachineAnimator)
	var ticking = false
	
	method ticking() = ticking
	
	// Empieza a animar un objeto. Quien llama se asegura de no agregarlo dos veces.
	method animate(obj) {
		animated.add(obj)
	}
	
	// Saca a un objeto que se detuvo antes de llegar (por ejemplo, porque se borró)
	method stopAnimating(obj) {
		animated.remove(obj)
	}
	
	// Un objeto avisa que terminó su animación. No se saca de la lista en el momento,
	// porque se está recorriendo: se limpia al final del tick.
	method notifyArrival() {
		anyArrived = true
	}
	
	method atTickEnd(block) {
		pendingBlocks.add(block)
	}
	
	method reset() {
		pendingBlocks = []
	}
	// Avanza un paso a todos los que se están animando y después saca a los que terminaron.
	method tick() {
		ticking = true
		animated.forEach({ o => o.advance() })
		if (anyArrived) {
			animated = animated.filter({ o => o.animating() })
			anyArrived = false
		}
		if (!pendingBlocks.isEmpty()) {
			const blocks = pendingBlocks
			pendingBlocks = []
			blocks.forEach({ b => b.apply() })
		}
		ticking = false
	}
}
// Mixin para cualquier objeto visual que se mueva suavemente (hoy, los ingredientes).

mixin Animated {
	// Cada objeto animado tiene su propia posición, que es siempre el mismo objeto:
	// al moverse se le modifican x e y. Nunca se comparte con otro objeto.
	const position = new SmoothPosition()
	var destination = noDestination // a dónde va (noDestination si está quieto)
	var dx = 0
	// cuánto avanza en x en cada paso del movimiento actual
	var dy = 0
	// cuánto avanza en y en cada paso del movimiento actual
	var step = 0
	// pasos ya dados del movimiento actual
	var totalSteps = 0
	
	// pasos que lleva el movimiento completo
	method position() = position
	
	// Se ubica en esa posición. Copia las coordenadas en vez de quedarse con el objeto,
	// porque si no al moverse arrastraría al dueño de esa posición (por ejemplo, una máquina).
	method position(pos) {
		position.x(pos.x())
		position.y(pos.y())
	}
	
	method moving() = destination.isMoving()
	// Lo pregunta el animationEngine para saber si sigue en la lista de animados
	
	method animating() = self.moving()
	
	// Dónde va a terminar: el destino si se está moviendo, o donde está parado
	method finalDestination() = destination.orElse(position)
	
	// Empieza a moverse hacia esa posición. La cantidad de pasos depende de la distancia.
	method move(pos) {
		self.moveInSteps(
			pos,
			(position.distance(pos) * animationEngine.stepsPerCell()).roundUp().max(1)
		)
	}
	
	// Igual que move, pero quien llama ya sabe cuántos pasos lleva el movimiento
	// (por ejemplo, una cinta le pasa un item a la vecina: siempre es una celda).
	// RENDIMIENTO: calcular la distancia (con raíz cuadrada) era ~1/3 del costo de move,
	// y move se llama en cada entrega entre cintas.
	// El avance por paso (dx, dy) se calcula acá una sola vez, no en cada paso.
	method moveInSteps(pos, steps) {
		// si ya se estaba moviendo, ya está en la lista de animados: sólo cambia de destino
		if (!self.moving()) animationEngine.animate(self)
		destination = new SmoothPosition(x = pos.x(), y = pos.y())
		step = 0
		totalSteps = steps
		dx = (destination.x() - position.x()) / totalSteps
		dy = (destination.y() - position.y()) / totalSteps
	}
	
	method moveTowards(direction) {
		// toma un  object direction
		self.move(direction.move(self.finalDestination()))
	}
	
	// Un paso de animación: sólo suma el avance ya calculado a la posición.
	// En el último paso se clava en el destino exacto, para no arrastrar error de decimales,
	// y avisa que llegó para que lo saquen de los animados.
	method advance() {
		step += 1
		if (step == totalSteps) {
			self.position(destination)
			destination = noDestination
			animationEngine.notifyArrival()
		} else {
			// RENDIMIENTO: goRight/goUp (de MutablePosition) suman directo sobre x e y.
			// Son 2 mensajes en vez de 6 (leer x, sumar, guardar x, lo mismo con y),
			// y esto se ejecuta para cada item que se mueve, en cada paso.
			position.goRight(dx)
			position.goUp(dy)
		}
	}
	
	// Corta el movimiento donde esté (se usa al borrar el item)
	method halt() {
		if (self.moving()) animationEngine.stopAnimating(self)
		destination = noDestination
	}
}
// Una animación cuadro por cuadro: la lista de imágenes que se muestran, una por paso.

// Los frames son PNG numerados dentro de una carpeta (path/0.png, path/1.png, ...),
// y se generan desde un GIF con assets/machines/gifToFrames.py.
// Las rutas se arman una sola vez al crearla, no en cada paso.
class FrameAnimation {
	method isRunning() = true

	const path
	// carpeta de los frames, por ejemplo "machines/AutomaticArm/down_to_up_catch"
	const frameCount // cantidad de PNG que hay en la carpeta
	// Cuántos pasos dura (0, por defecto: uno por PNG). Con más pasos que PNG, cada uno se ve más de un
	// paso: así una animación con la mitad de los cuadros dura lo mismo (el navegador carga todas las
	// imágenes de assets/ al arrancar, y con demasiadas no llega a cargarlas: ver assets/README.md)
	const steps = 0
	var frames = []

	method size() = if (steps > 0) steps else frameCount

	// Las rutas se arman la primera vez que se piden, no en cada paso
	method frames() {
		if (frames.isEmpty())
			frames = (0 .. (self.size() - 1)).map({ i => path + "/" + (i * frameCount).div(self.size()) + ".png" })
		return frames
	}
}

// Una animación que dura exactamente `steps` pasos, armada con una lista de imágenes.

// Muestra siempre vueltas completas (tantas como entren, al menos una) y ajusta

// apenas la velocidad para que cierren justo: nunca termina a mitad de una vuelta.

// Con más imágenes que pasos, saltea (una vuelta rápida); con menos, repite.

class TimedAnimation {
	method isRunning() = true


	const images    // rutas de los PNG, por ejemplo las frames() de una FrameAnimation

	const steps

	const laps = (steps / images.size()).round().max(1)

	const property frames = (0 .. (steps - 1)).map({ i =>

		images.get((i * images.size() * laps).div(steps) % images.size())

	})

 

	method size() = steps

}