// Catálogo de máquinas y máquina seleccionada

import machines.machineTypes.*

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

	// Selecciona una máquina del catálogo (una de las lambdas de machines)
	method select(factory) {
		selectedMachine = factory
	}
}
