// Buffet Albert Einstein - el horno que cocina los ingredientes.
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

// Horno: quieto cuando está vacío, el GIF sólo mientras cocina

class Oven inherits ProcessingMachine {

	override method name() = "Oven"
	override method baseEnergy() = 2

	override method foodProcess() = cooking

	override method animateWork(steps, afterBlock) {

		self.holdImage(self.gifImage(), steps, afterBlock)
	}
}
