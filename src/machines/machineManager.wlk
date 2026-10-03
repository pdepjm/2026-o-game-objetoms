// Catálogo de máquinas y máquina seleccionada

import machines.machineTypes.*
import menu.placeMenu.*

// Maneja cual es la Machine Seleccionada actual
object machineManager{
	// El orden de la lista define el orden en el menú.
	// Cada elemento es una lambda que crea una máquina nueva.
	const machines = [
		{ => new Belt() },
		{ => new Assembler() },
		{ => new Oven() },
		{ => new CuttingMachine() },
		{ => new Fryer() },
		{ => new Dispenser() }
	]

	var selectedMachine = machines.first()

	// Nueva instancia de la máquina seleccionada
	method createMachine() = selectedMachine.apply()

	// La máquina seleccionada se identifica por su nombre
	method selectedName() = self.createMachine().name()

	// Máquinas que se muestran en una página del menú (4 por página)
	method machinesOfPage(page) = machines.drop(page * 4).take(4)

	// Selecciona la máquina del slot clickeado, si hay una en ese slot
	method chooseMachine(pos){
		const slot = placeMenu.slotAt(pos)
		const pageMachines = self.machinesOfPage(placeMenu.currentPage())

		if (slot > 0 && slot <= pageMachines.size()) {
			selectedMachine = pageMachines.get(slot - 1)
			placeMenu.updateOverlay()
		}
	}
}
