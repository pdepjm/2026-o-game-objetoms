import src.food.foodClasses.*
import src.food.foodTypes.*
// Catálogo de máquinas y máquina seleccionada

import machines.types.belt.*
import machines.types.dispenser.*
import machines.types.automaticArm.*
import machines.types.smartRoboticArm.*
import machines.types.assembler.*
import machines.types.oven.*
import machines.types.cuttingMachine.*
import machines.types.fryer.*

// Maneja cual es la Machine Seleccionada actual
object machineManager{
	// El orden de la lista define el orden en el menú.
	// Cada elemento es una lambda que crea una máquina nueva.
	const machines = [
		{ => new Belt() },
		{ => new Assembler() },
		{ => new CuttingMachine() },
		{ => new Oven() },
		{ => new Dispenser()},
		{ => new AutomaticArm()},
		{ => new SmartRoboticArm()},
		{ => new Fryer() }
	]

	var selectedMachine = machines.first()

	// Nueva instancia de la máquina seleccionada
	method createMachine() = selectedMachine.apply()

	// La máquina seleccionada se identifica por su nombre
	method selectedName() = self.createMachine().name()

	// Máquinas que se muestran en una página del menú (4 por página)
	method machinesOfPage(page) = machines.drop(page * 4).take(4)

	// Cuántas páginas ocupa el catálogo en el menú
	method pageCount() = (machines.size() / 4).roundUp()

	// Selecciona una máquina del catálogo (una de las lambdas de machines)
	method select(factory) {
		selectedMachine = factory
	}
}
