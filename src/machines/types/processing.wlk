// Buffet Albert Einstein - las máquinas que procesan un ingrediente: horno, freidora y cortadora.
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

import machines.machineClasses.*
import food.foodClasses.*
import simulation.simulationEngine.*
import machines.settings.*

// Una máquina que procesa items: acepta los que puede procesar, los transforma y los entrega
class ProcessingMachine inherits Machine {

	// Qué tan rápido procesa (se cambia con X, editando la máquina)
	const speedSetting = new SpeedSetting(value = 1)

	override method settings() = [speedSetting]

	// Se edita por sus ajustes (la velocidad)
	override method openEditorIn(panel) { panel.editSettings(self) }

	override method speed() = speedSetting.value()

	method foodProcess()    // abstracto: cutting, cooking, frying…

	override method canReceive(item) = super(item) && item.canProcess(self.foodProcess())

	// Se llama cuando terminó de procesar un item (por defecto, no hace nada).
	method onProcessed(item) {}

	override method onArrived(item) {

		self.animateWork(self.workSteps(item.processTime()), {

			// Un brazo pudo haberse llevado el item mientras trabajaba: entonces ya no es de esta máquina
			if (self.heldItems().contains(item)) {
				item.process(self.foodProcess())
				self.tryPush()
				self.notifyGrabbers()
				self.onProcessed(item)
			}

		})

	}

}

// Horno: quieto cuando está vacío, el GIF sólo mientras cocina
class Oven inherits ProcessingMachine {

	override method name() = "Oven"
	override method label() = "Horno"
	override method article() = "el"
	override method baseEnergy() = 2

	override method foodProcess() = cooking

	override method animateWork(steps, afterBlock) {

		self.holdImage(self.gifImage(), steps, afterBlock)
	}
}

// Cortadora: sus 17 PNG de corte se ajustan al tiempo de cada ingrediente
class CuttingMachine inherits ProcessingMachine {
	override method name() = "CuttingMachine"
	override method label() = "Cortadora"
	override method baseEnergy() = 1

	override method foodProcess() = cutting

	override method workImages() = self.actionAnimation("cut", 9).frames()

}

// Freidora: fríe lo que le entrega un brazo y se lo devuelve a un brazo.
class Fryer inherits ProcessingMachine {
	// Pasos que aguanta un item ya frito antes de quemarse (4 segundos a velocidad normal)
	const burnSteps = 40

	override method name() = "Fryer"
	override method label() = "Freidora"
	override method baseEnergy() = 2

	override method foodProcess() = frying

	// Como el horno: quieta cuando está vacía, el GIF sólo mientras fríe
	override method animateWork(steps, afterBlock) {
		self.holdImage(self.gifImage(), steps, afterBlock)
	}

	override method worksWith(neighbour) = neighbour.worksWithArmOnlyMachines()

	override method grabbableItem() = self.itemToPush()

	// Al terminar de freír empieza a correr el tiempo para quemarse (si el item puede quemarse)
	override method onProcessed(item) {
		if (item.canProcess(burning)) simulationEngine.after(burnSteps, { self.burn(item) })
	}

	// SIEMPRE revisa el estado: si en estos pasos se lo llevó un brazo, ya no hay nada que quemar
	method burn(item) {
		if (self.heldItems().contains(item)) {
			item.process(burning)
			self.notifyGrabbers()
		}
	}
}
