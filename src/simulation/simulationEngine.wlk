// Buffet Albert Einstein - el reloj de la simulación: prender, apagar, velocidad y agenda de acciones.
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

import wollok.game.*
import simulation.animationEngine.*
import sound.sfx.*

object simulationEngine {
	// todas las máquinas que están en el tablero
	const simulatedObjects = []

	// Cantidad de casilleros de la agenda.
	const slotCount = 64

	// La agenda es una lista de casilleros que se usa en ronda
	const agenda = (1 .. slotCount).map({ _ => [] })

	// número del último paso ejecutado.
	var currentStep = 0

	// milisegundos de simulación que avanza cada paso
	const property tickMs = 100

	// cantidad de pasos que se ejecutan por tick (1 = normal, 2 = x2, 3 = x3)
	var property speed = 1

	// el juego arranca en modo construcción, con la simulación apagada
	var property running = false

	// prendida pero congelada
	var property paused = false

	// Engancha el engine al reloj de Wollok Game.
	method start() {
		game.onTick(tickMs, "simulacion", { self.tick() })
	}

	// Lo llama Wollok Game cada tickMs.
	method tick() {
		if (running && !paused) speed.times({ _ => self.step() })
	}

	// Congela la simulación sin borrar nada, y la sigue desde donde estaba.
	method pause() { paused = true }
	method resume() { paused = false }

	// Un paso de simulación: se ejecutan las acciones agendadas y avanzan las animaciones.
	method step() {
		currentStep += 1
		const slot = agenda.get(currentStep % slotCount)
		if (!slot.isEmpty()) {
			// Sólo las que vencen en este paso: las demás son de una vuelta posterior.
			const due = slot.filter({ scheduled => scheduled.dueStep() == currentStep })
			slot.removeAll(due)
			due.forEach({ scheduled => scheduled.action().apply() })
		}
		animationEngine.tick()
	}

	// Agenda una acción (un bloque) para dentro de esa cantidad de pasos.
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
		paused = false
		speed = 1
	}

	// Prende la simulación: cada máquina busca a su vecina y agenda lo que necesite.
	method run() {
		running = true
		simulatedObjects.forEach({ machine => machine.start() })
		sfx.simulationStart()
	}

	// Apaga la simulación y limpia el tablero de items, para construir tranquilo.
	method stop() {
		running = false
		paused = false
		agenda.forEach({ slot => slot.clear() })
		animationEngine.reset()
		self.allItems().forEach({ item =>
			item.halt()
			game.removeVisual(item)
		})
		simulatedObjects.forEach({ machine => machine.reset() })
		sfx.simulationStop()
	}

	// Un item nuevo entra al tablero (lo crea, por ejemplo, un Dispenser).
	method addItem(item) {
		game.addVisual(item)
	}
	// Saca un item del tablero (lo consume una máquina, como el Assembler).
	method removeItem(item) {
		item.halt()
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

// Una acción de la agenda y el paso en el que vence.
class ScheduledAction {
	const property dueStep
	const property action
}
