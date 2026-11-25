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
import wollok.game.*

// Posición con decimales, para dibujar un objeto a mitad de camino entre dos celdas.
class SmoothPosition inherits MutablePosition {
	override method round() = self

	// Un destino: algo que se está moviendo hacia él
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
	const property stepsPerCell = 5
	// Los objetos que se están animando en este momento (los que están quietos no están acá).
	var animated = []
	// ¿algún objeto terminó su animación durante este tick?
	var anyArrived = false
	var pendingBlocks = []
	// ¿se están avanzando los animados en este momento?
	var ticking = false
	
	method ticking() = ticking
	
	// Empieza a animar un objeto.
	method animate(obj) {
		animated.add(obj)
	}
	
	// Saca a un objeto que se detuvo antes de llegar (por ejemplo, porque se borró)
	method stopAnimating(obj) {
		animated.remove(obj)
	}
	
	// Un objeto avisa que terminó su animación.
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
	// Cada objeto animado tiene su propia posición, que es siempre el mismo objeto
	const position = new SmoothPosition()
	var destination = noDestination
	var dx = 0
	// cuánto avanza en x en cada paso del movimiento actual
	var dy = 0
	// cuánto avanza en y en cada paso del movimiento actual
	var step = 0
	// pasos ya dados del movimiento actual
	var totalSteps = 0
	
	// pasos que lleva el movimiento completo
	method position() = position
	
	// Se ubica en esa posición.
	method position(pos) {
		position.x(pos.x())
		position.y(pos.y())
	}
	
	method moving() = destination.isMoving()
	// Lo pregunta el animationEngine para saber si sigue en la lista de animados
	
	method animating() = self.moving()
	
	// Dónde va a terminar: el destino si se está moviendo, o donde está parado
	method finalDestination() = destination.orElse(position)
	
	// Empieza a moverse hacia esa posición.
	method move(pos) {
		self.moveInSteps(
			pos,
			(position.distance(pos) * animationEngine.stepsPerCell()).roundUp().max(1)
		)
	}
	
	// Igual que move, pero quien llama ya sabe cuántos pasos lleva el movimiento
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
	method advance() {
		step += 1
		if (step == totalSteps) {
			self.position(destination)
			destination = noDestination
			animationEngine.notifyArrival()
		} else {
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

// Los frames son PNG numerados dentro de una carpeta (path/0.png, path/1.png, ...)
class FrameAnimation {
	method isRunning() = true

	const path
	// carpeta de los frames, por ejemplo "machines/AutomaticArm/down_to_up_catch"
	const frameCount // cantidad de PNG que hay en la carpeta
	// Cuántos pasos dura (0, por defecto: uno por PNG).
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
class TimedAnimation {
	method isRunning() = true

	const images

	const steps

	const laps = (steps / images.size()).round().max(1)

	const property frames = (0 .. (steps - 1)).map({ i =>

		images.get((i * images.size() * laps).div(steps) % images.size())

	})

	method size() = steps

}