// Acá va todo lo que se anima paso a paso: objetos que se mueven suavemente entre celdas
// (mixin Animado) y máquinas que cambian de imagen cuadro por cuadro (MachineAnimator,
// en machines/machineClasses.wlk).
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
	// Los objetos que se están animando en este momento (los que están quietos no están acá).
	// Cualquier objeto puede estar acá si entiende avanzar() y animando().
	// Es una lista y no un conjunto a propósito: copiar o agregar a un conjunto compara
	// cada elemento contra todos los demás, y con muchos items eso era lo más lento del juego.
	var animados = []
	// ¿algún objeto terminó su animación durante este tick?
	var algunoLlego = false
	var bloquesPendientes = []
	// ¿se están avanzando los animados en este momento? (ver play en MachineAnimator)
	var ticking = false
	
	method ticking() = ticking
	
	// Empieza a animar un objeto. Quien llama se asegura de no agregarlo dos veces.
	method animar(obj) {
		animados.add(obj)
	}
	
	// Saca a un objeto que se detuvo antes de llegar (por ejemplo, porque se borró)
	method terminar(obj) {
		animados.remove(obj)
	}
	
	// Un objeto avisa que terminó su animación. No se saca de la lista en el momento,
	// porque se está recorriendo: se limpia al final del tick.
	method avisarLlegada() {
		algunoLlego = true
	}
	
	method alTerminar(bloque) {
		bloquesPendientes.add(bloque)
	}
	
	method reset() {
		bloquesPendientes = []
	}
	// Avanza un paso a todos los que se están animando y después saca a los que terminaron.
	method tick() {
		ticking = true
		animados.forEach({ o => o.avanzar() })
		if (algunoLlego) {
			animados = animados.filter({ o => o.animando() })
			algunoLlego = false
		}
		if (!bloquesPendientes.isEmpty()) {
			const bloques = bloquesPendientes
			bloquesPendientes = []
			bloques.forEach({ b => b.apply() })
		}
		ticking = false
	}
}
// Mixin para cualquier objeto visual que se mueva suavemente (hoy, los ingredientes).

mixin Animado {
	// Cada objeto animado tiene su propia posición, que es siempre el mismo objeto:
	// al moverse se le modifican x e y. Nunca se comparte con otro objeto.
	const position = new PosicionSuave()
	var destino = null // a dónde va (null si está quieto)
	var dx = 0
	// cuánto avanza en x en cada paso del movimiento actual
	var dy = 0
	// cuánto avanza en y en cada paso del movimiento actual
	var paso = 0
	// pasos ya dados del movimiento actual
	var totalPasos = 0
	
	// pasos que lleva el movimiento completo
	method position() = position
	
	// Se ubica en esa posición. Copia las coordenadas en vez de quedarse con el objeto,
	// porque si no al moverse arrastraría al dueño de esa posición (por ejemplo, una máquina).
	method position(pos) {
		position.x(pos.x())
		position.y(pos.y())
	}
	
	method moviendose() = destino !== null
	// Lo pregunta el animationEngine para saber si sigue en la lista de animados
	
	method animando() = self.moviendose()
	
	// Dónde va a terminar: el destino si se está moviendo, o donde está parado
	method destinoFinal() = if (self.moviendose()) destino else position
	
	// Empieza a moverse hacia esa posición. La cantidad de pasos depende de la distancia.
	method move(pos) {
		self.moveInSteps(
			pos,
			(position.distance(pos) * animationEngine.pasosPorCelda()).roundUp().max(1)
		)
	}
	
	// Igual que move, pero quien llama ya sabe cuántos pasos lleva el movimiento
	// (por ejemplo, una cinta le pasa un item a la vecina: siempre es una celda).
	// RENDIMIENTO: calcular la distancia (con raíz cuadrada) era ~1/3 del costo de move,
	// y move se llama en cada entrega entre cintas.
	// El avance por paso (dx, dy) se calcula acá una sola vez, no en cada paso.
	method moveInSteps(pos, steps) {
		// si ya se estaba moviendo, ya está en la lista de animados: sólo cambia de destino
		if (!self.moviendose()) animationEngine.animar(self)
		destino = new PosicionSuave(x = pos.x(), y = pos.y())
		paso = 0
		totalPasos = steps
		dx = (destino.x() - position.x()) / totalPasos
		dy = (destino.y() - position.y()) / totalPasos
	}
	
	method moverHacia(direccion) {
		// toma un  object direction
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
			// RENDIMIENTO: goRight/goUp (de MutablePosition) suman directo sobre x e y.
			// Son 2 mensajes en vez de 6 (leer x, sumar, guardar x, lo mismo con y),
			// y esto se ejecuta para cada item que se mueve, en cada paso.
			position.goRight(dx)
			position.goUp(dy)
		}
	}
	
	// Corta el movimiento donde esté (se usa al borrar el item)
	method detener() {
		if (self.moviendose()) animationEngine.terminar(self)
		destino = null
	}
}
// Una animación cuadro por cuadro: la lista de imágenes que se muestran, una por paso.

// Los frames son PNG numerados dentro de una carpeta (path/0.png, path/1.png, ...),
// y se generan desde un GIF con assets/machines/gifToFrames.py.
// Las rutas se arman una sola vez al crearla, no en cada paso.
class FrameAnimation {
	const path
	// carpeta de los frames, por ejemplo "machines/AutomaticArm/down_to_up_catch"
	const frameCount // cantidad de PNG que hay en la carpeta
	const property frames = (0 .. (frameCount - 1)).map(
		{ i => ((path + "/") + i) + ".png" }
	)
	
	method size() = frameCount
}

// Una animación que dura exactamente `steps` pasos, armada con una lista de imágenes.

// Muestra siempre vueltas completas (tantas como entren, al menos una) y ajusta

// apenas la velocidad para que cierren justo: nunca termina a mitad de una vuelta.

// Con más imágenes que pasos, saltea (una vuelta rápida); con menos, repite.

class TimedAnimation {

	const images    // rutas de los PNG, por ejemplo las frames() de una FrameAnimation

	const steps

	const laps = (steps / images.size()).round().max(1)

	const property frames = (0 .. (steps - 1)).map({ i =>

		images.get((i * images.size() * laps).div(steps) % images.size())

	})

 

	method size() = steps

}