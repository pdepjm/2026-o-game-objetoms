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

import wollok.game.*
import src.directions.*
import machines.machineClasses.*
import machines.settings.*
import simulation.simulationEngine.*
import food.foodClasses.*
import food.foodTypes.*
import cellPosition.*

// Crea un ingrediente cada intervalo y se lo entrega a la máquina de adelante.
// Se configura qué ingrediente larga y a qué velocidad (ver settings.wlk).
class Dispenser inherits Machine {
	// Todos los ingredientes que puede dispensar
	const availableKinds = [lettuce, bun, friedPotato, potato, tomato, meat, cheese, bacon, pizzaDough, egg, salami, sausage, ham]
	
	// Por defecto papa (o, si no la ofrece, el primero de los suyos) y velocidad normal.
	// Los ingredientes son los que ofrece el menú.
	const productSetting = new ProductSetting(
		value = if (availableKinds.contains(potato)) potato else availableKinds.first(),
		kinds = availableKinds
	)
	const speedSetting = new SpeedSetting(value = 1)
	// Una insignia con el ingrediente que larga, en una esquina de arriba (ver DispenserBadge)
	const badge = new DispenserBadge(dispenser = self)

	override method name() = "Dispenser"
	override method label() = "Dispenser"
	override method article() = "el"
	override method baseEnergy() = 1

	override method runningImage() = self.gifImage()
	
	// El ingrediente que larga
	method product() = productSetting.value()

	method product(kind) {
		productSetting.value(kind)
	}

	override method settings() = [productSetting, speedSetting]

	method badge() = badge

	// La insignia se dibuja encima del dispenser mientras está en el tablero, y se mueve al rotarlo
	override method addedToBoard() { badge.show() }
	override method removedFromBoard() { badge.hide() }
	override method rotate() {
		super()
		badge.update()
	}

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
	// Pregunta ANTES de crear: si la de adelante está llena no se crea ningún item
	// (el item recién se hace cuando hay a dónde mandarlo). Si está llena, se anota
	// para reintentar apenas se libere: no espera al próximo intervalo.
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

// La insignia del dispenser: un círculo con el ingrediente que larga (assets/machines/Dispenser/badge/,
// ver makeBadges.py), en la esquina de arriba del lado contrario a la salida, así no tapa la flecha.
// Mide 30x30 px y sobresale un poco de la celda.
// RENDIMIENTO: la posición se calcula sólo al colocarlo o rotarlo; la imagen es la del ingrediente elegido,
// que la arma una vez (IngredientKind.badgeImage).
class DispenserBadge {
	const dispenser
	var position = new CellPosition(x = 0, y = 0)

	method position() = position
	method image() = dispenser.product().badgeImage()

	method update() {
		const cell = dispenser.cell()
		// mirando a la derecha, la esquina de la izquierda; si no, la de la derecha
		const left = if (dispenser.direction() == right) cell.x() - 0.1 else cell.x() + 0.58
		position = new CellPosition(x = left, y = cell.y() + 0.6)
	}

	method show() {
		self.update()
		if (!game.hasVisual(self)) game.addVisual(self)
	}

	method hide() { if (game.hasVisual(self)) game.removeVisual(self) }
}
