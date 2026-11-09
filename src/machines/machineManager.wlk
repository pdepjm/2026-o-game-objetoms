// Buffet Albert Einstein - el catálogo de máquinas y la máquina seleccionada para colocar.
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
	const allMachines = [
		{ => new Belt() },
		{ => new Assembler() },
		{ => new CuttingMachine() },
		{ => new Oven() },
		{ => new Dispenser()},
		{ => new AutomaticArm()},
		{ => new SmartRoboticArm()},
		{ => new Fryer() }
	]
	var machines = allMachines


	var selectedMachine = machines.first()

	method allMachines() = allMachines

	// Cambia las maquinas disponibles para colocar
	method changeCatalog(factories) {
		machines = factories
		selectedMachine = factories.first()
	}

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
