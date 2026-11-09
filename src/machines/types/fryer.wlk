// Buffet Albert Einstein - la freidora, que sólo trabaja con un brazo.
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
import simulation.simulationEngine.*
import food.foodClasses.*

// Freidora: fríe lo que le entrega un brazo y se lo devuelve a un brazo.
// Es armOnly: no recibe de cintas ni entrega a cintas, sólo trabaja con un brazo.
// Un brazo puede sacarle el item apenas entra, esté listo o no (grabbableItem): el brazo común lo
// saca al toque, y el inteligente puede esperar al ingrediente que quiere con sus filtros.
// Si el item ya frito se queda demasiado tiempo, se quema.
class Fryer inherits ProcessingMachine {
	// Pasos que aguanta un item ya frito antes de quemarse (4 segundos a velocidad normal)
	const burnSteps = 40

	override method name() = "Fryer"
	override method baseEnergy() = 2

	override method foodProcess() = frying

	// Como el horno: quieta cuando está vacía, el GIF sólo mientras fríe
	override method animateWork(steps, afterBlock) {
		self.holdImage(self.gifImage(), steps, afterBlock)
	}

	override method armOnly() = true

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
