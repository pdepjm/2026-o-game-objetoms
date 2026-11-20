// Buffet Albert Einstein - la cortadora de ingredientes.
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

// Cortadora: sus 17 PNG de corte se ajustan al tiempo de cada ingrediente

class CuttingMachine inherits ProcessingMachine {
	override method name() = "CuttingMachine"
	override method baseEnergy() = 1

	override method foodProcess() = cutting

	override method workImages() = self.actionAnimation("cut", 17).frames()

}
