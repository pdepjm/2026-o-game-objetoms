// Buffet Albert Einstein - el dispenser: crea ingredientes cada cierto intervalo.
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
import machines.badge.*
import machines.settings.*
import simulation.simulationEngine.*
import food.foodClasses.*
import food.foodTypes.*

// Crea un ingrediente cada intervalo y se lo entrega a la máquina de adelante.
class Dispenser inherits Machine {
	// Todos los ingredientes que puede dispensar
	const availableKinds = [lettuce, bun, friedPotato, potato, tomato, meat, cheese, bacon, pizzaDough, egg, salami, sausage, ham]
	
	// Por defecto papa (o, si no la ofrece, el primero de los suyos) y velocidad normal.
	const productSetting = new ProductSetting(
		value = if (availableKinds.contains(potato)) potato else availableKinds.first(),
		kinds = availableKinds
	)
	const speedSetting = new SpeedSetting(value = 1)
	// Una insignia con el ingrediente que larga
	const badge = new Badge(machine = self)

	override method name() = "Dispenser"
	override method label() = "Dispenser"
	override method article() = "el"
	override method baseEnergy() = 1

	override method runningImage() = self.gifImage()
	
	// El ingrediente que larga
	method product() = productSetting.value()

	method product(kind) {
		productSetting.value(kind)
		self.settingChanged()
	}

	// Lo que muestra su insignia: el ingrediente que larga
	method selectedFood() = self.product()

	override method settings() = [productSetting, speedSetting]

	// Se edita por sus ajustes (el producto y la velocidad)
	override method openEditorIn(panel) { panel.editSettings(self) }

	method badge() = badge

	// La insignia está en el tablero mientras el dispenser está, y cambia al editarlo
	override method addedToBoard() { badge.show() }
	override method removedFromBoard() { badge.hide() }
	override method settingChanged() { badge.update() }

	// El multiplicador de velocidad elegido (0.5, 1 o 2)
	override method speed() = speedSetting.value()

	// tiempo de simulación entre un dispense y el siguiente: 5 segundos a velocidad normal
	method intervalMs() = 5000 / speedSetting.value()

	// el mismo intervalo, medido en pasos de simulación
	method intervalSteps() = simulationEngine.stepsFor(self.intervalMs())

	// Busca a su vecina (super) y agenda el primer intento de dispensar
	override method start() {
		super()
		self.scheduleNext()
	}

	method scheduleNext() {
		simulationEngine.after(self.intervalSteps(), { self.tryDispense() })
	}

	// Intenta crear un item y pasarlo a la de adelante.
	method tryDispense() {
		const target = next
		const item = new Item(kind = self.product())
		if (target.canReceiveFrom(self, item)) {
			item.position(self.position())
			simulationEngine.addItem(item)
			inventory.add(item)
			self.tryPush()
		} else {
			target.whenFree({ self.tryDispense() })
		}
	}

	// No recibe items: sólo los crea
	override method canReceive(item) = false

	// Recién cuando el item se entregó se agenda el próximo
	override method onPushed(item) {
		self.scheduleNext()
	}
}
