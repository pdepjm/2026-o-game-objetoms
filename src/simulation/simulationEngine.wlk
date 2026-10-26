// src/simulation/simulationEngine.wlk
// El reloj de la simulación: prender, apagar, velocidad y la agenda de acciones.
//
// CÓMO FUNCIONA
// - Es el único reloj del juego: Wollok Game llama a tick() cada tickMs milisegundos.
// - Cada tick ejecuta uno o más "pasos" (step), según la velocidad elegida.
// - Las máquinas NO se recorren en cada paso (con muchas máquinas eso era muy lento).
//   En cambio, quien necesita hacer algo más adelante agenda la acción con
//   after(pasos, bloque), y cuando llega ese paso el engine ejecuta el bloque.
// - Al final de cada paso avanzan las animaciones de los items (animationEngine).
//
// MODOS
// - Apagada (modo construcción): no corre ningún paso y se puede editar el tablero.
// - Prendida: corre la simulación y el tablero queda bloqueado (ver toolsManager).
//   Por eso las máquinas pueden calcular a su vecina una sola vez, al prender.

import wollok.game.*
import simulation.animationEngine.*

object simulationEngine {
	// todas las máquinas que están en el tablero
	const simulatedObjects = []

	// Cantidad de casilleros de la agenda. NO es un límite: se puede agendar a cualquier
	// cantidad de pasos (cada acción recuerda en qué paso vence, ver ScheduledAction).
	// Sólo conviene que sea mayor que las demoras que se agendan seguido (hoy, la más larga
	// es la del dispenser en velocidad lenta: 100 pasos, y pasa pocas veces): una acción a
	// más pasos se saltea una vuelta antes de vencer.
	const slotCount = 64

	// La agenda es una lista de casilleros que se usa en ronda: una acción que vence en el
	// paso p está en el casillero p % slotCount. Así cada paso revisa un solo casillero,
	// y no todas las acciones pendientes.
	// Es una lista y no un Dictionary porque el Dictionary es mucho más lento.
	const agenda = (1 .. slotCount).map({ _ => [] })

	// número del último paso ejecutado. Nunca se reinicia, sólo crece.
	var currentStep = 0

	// milisegundos de simulación que avanza cada paso
	const property tickMs = 100

	// cantidad de pasos que se ejecutan por tick (1 = normal, 2 = x2, 3 = x3)
	var property speed = 1

	// el juego arranca en modo construcción, con la simulación apagada
	var property running = false

	// Engancha el engine al reloj de Wollok Game. Se llama una sola vez, desde el main.
	method start() {
		game.onTick(tickMs, "simulacion", { self.tick() })
	}

	// Lo llama Wollok Game cada tickMs. A velocidad x2 o x3 ejecuta 2 o 3 pasos seguidos,
	// así el resultado es el mismo que a x1, sólo que llega antes.
	method tick() {
		if (running) speed.times({ _ => self.step() })
	}

	// Un paso de simulación: se ejecutan las acciones agendadas y avanzan las animaciones.
	// Los tests llaman a step() directo para avanzar sin depender del tiempo real.
	method step() {
		currentStep += 1
		const slot = agenda.get(currentStep % slotCount)
		if (!slot.isEmpty()) {
			// Sólo las que vencen en este paso: las demás son de una vuelta posterior.
			// Se sacan del casillero antes de ejecutar, porque una acción puede volver a agendarse.
			const due = slot.filter({ scheduled => scheduled.dueStep() == currentStep })
			slot.removeAll(due)
			due.forEach({ scheduled => scheduled.action().apply() })
		}
		animationEngine.tick()
	}

	// Agenda una acción (un bloque) para dentro de esa cantidad de pasos.
	// Como mínimo es 1: nunca se ejecuta en el mismo paso en que se agenda.
	// IMPORTANTE: toda acción agendada revisa el estado antes de actuar. Entre que se
	// agenda y que se ejecuta pueden pasar cosas (por ejemplo, otra máquina ocupó el lugar).
	method after(steps, action) {
		const dueStep = currentStep + steps.max(1)
		agenda.get(dueStep % slotCount).add(new ScheduledAction(dueStep = dueStep, action = action))
	}

	// Cantidad de pasos de simulación que equivalen a esos milisegundos
	method stepsFor(milliseconds) = (milliseconds / tickMs).roundUp().max(1)

	// Prende o apaga la simulación
	method toggle() {
		if (running) self.stop() else self.run()
		console.println("Simulation: " + running)
	}

	method reset(){
		if(running) self.stop()
		speed = 1
	}

	// Prende la simulación: cada máquina busca a su vecina y agenda lo que necesite.
	// Mientras está prendida no se puede editar el tablero (ver toolsManager).
	method run() {
		running = true
		simulatedObjects.forEach({ machine => machine.start() })
	}

	// Apaga la simulación y limpia el tablero de items, para construir tranquilo.
	// Se vacía la agenda para que nadie se despierte con un item que ya no existe.
	method stop() {
		running = false
		agenda.forEach({ slot => slot.clear() })
		animationEngine.reset()
		self.allItems().forEach({ item =>
			item.detener()
			game.removeVisual(item)
		})
		simulatedObjects.forEach({ machine => machine.reset() })
	}

	// Un item nuevo entra al tablero (lo crea, por ejemplo, un Dispenser).
	// El engine es el que saca los items al apagar la simulación (stop),
	// así que también es el que los pone.
	method addItem(item) {
		game.addVisual(item)
	}
	// Saca un item del tablero (lo consume una máquina, como el Assembler).
	// Es la contraparte de addItem.
	method removeItem(item) {
		item.detener()
		game.removeVisual(item)
	}
	// Todos los items que hay en el tablero (cada uno está en alguna máquina)
	method allItems() = simulatedObjects.flatMap({ machine => machine.heldItems() })

	// Lo llama el board al colocar una máquina
	method addSimulatedObject(thing) {
		simulatedObjects.add(thing)
	}

	// Lo llama el board al quitar una máquina
	method removeSimulatedObject(thing) {
		simulatedObjects.remove(thing)
	}

	// Cantidad de acciones agendadas (para tests)
	method pendingActions() = agenda.sum({ slot => slot.size() })
}

// Una acción de la agenda y el paso en el que vence. Gracias a dueStep se puede agendar a
// cualquier cantidad de pasos: si es a más de slotCount, la acción espera en su casillero
// las vueltas que haga falta.
class ScheduledAction {
	const property dueStep
	const property action
}
