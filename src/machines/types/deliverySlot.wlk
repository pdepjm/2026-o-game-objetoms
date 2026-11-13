// Buffet Albert Einstein - los platitos de entrega, donde llegan los platos terminados.
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
import levels.levelManager.*
import directions.*
import board.*

class DeliverySlot inherits Machine {
    override method name() = "DeliverySlot"
	override method nextMachine() = null

	// El plato llegó al platito: sale del juego y cuenta para el nivel
	override method onArrived(item) {
		inventory.release(item)
		simulationEngine.removeItem(item)
		levelManager.delivered(item)
	}
}

// Los platitos del fondo. Sus posiciones están sólo acá.
object deliveryPoints {
	const property slots = [
		new DeliverySlot(position = game.at(16, 14), direction = down),
		new DeliverySlot(position = game.at(17, 14), direction = down)
	]

	// Lo llama main.wpgm al arrancar (y los tests que los necesiten)
	method setUp() {
		slots.forEach({slot => 
            board.addDeliverySlot(slot)
        })
	}
}