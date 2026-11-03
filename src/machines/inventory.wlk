// src/machines/inventory.wlk
// Los items que guarda una máquina y las acciones que esperan a que se libere lugar.
//
// El inventario es el único que sabe cuándo despertar a las que esperan: al liberar
// un item (release) agenda las acciones pendientes. Así ninguna máquina se olvida
// de avisar (antes era la regla wakeWaiting(), que había que recordar).

import simulation.simulationEngine.*

class Inventory {
	var capacity
	const items = []
	const waiting = []

	method changeCapacity(newCapacity) {
		capacity = newCapacity
	}

	// ¿Entra un item más?
	method hasRoom() = items.size() < capacity

	method add(item) {
		items.add(item)
	}

	method items() = items

	method isEmpty() = items.isEmpty()

	method first() = items.first()

	// Saca un item del inventario y despierta a los que esperaban lugar
	method release(item) {
		items.remove(item)
		self.wakeWaiting()
	}

	// Anota una acción para cuando esta máquina libere lugar.
	// No hace falta revisar repetidos: una acción anotada no hace nada hasta que la despierten.
	method whenFree(action) {
		waiting.add(action)
	}

	// Despierta a los que esperaban. Cada acción se agenda para el paso siguiente,
	// así ninguna corre en medio del proceso que la liberó.
	method wakeWaiting() {
		if (!waiting.isEmpty()) {
			const actions = waiting.copy()
			waiting.clear()
			actions.forEach({ action => simulationEngine.after(1, action) })
		}
	}

	// Vacía items y esperas (al apagar la simulación)
	method clear() {
		items.clear()
		waiting.clear()
	}
}
