// Buffet Albert Einstein - la cinta transportadora y las formas que puede tener (recta o curva).
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
import board.*
import directions.*
import simulation.simulationEngine.*

class Belt inherits Machine {
	
	var shape = straightShape

	override method name() = "Belt"
	override method label() = "Cinta"
	override method baseEnergy() = 1

	override method runningImage() = self.gifImage()

	override method grabbableItem() = self.itemToPush()

		method calculateInputDirection() {
		const myCell = self.cell()
		const myOutput = self.direction()
		
		const oppositeDirection = myOutput.invert()
		const oppositeNeighbour = board.machineAt(oppositeDirection.move(myCell))
		
		if (oppositeNeighbour.feeds(myCell)) {
			return oppositeDirection
		}
		
		// Si no hay nadie de frente, a la izquierda (curva left)
		const leftDirection = myOutput.previous()
		const leftNeighbour = board.machineAt(leftDirection.move(myCell))
		
		if (leftNeighbour.feeds(myCell)) {
			return leftDirection
		}
		
		// Si no, a la derecha (curva right)
		const rightDirection = myOutput.next()
		const rightNeighbour = board.machineAt(rightDirection.move(myCell))
		
		if (rightNeighbour.feeds(myCell)) {
			return rightDirection
		}
		
		// Si nadie le entrega, es como una cinta recta
		return oppositeDirection
	}

	method updateShape() {
		const myInput = self.calculateInputDirection()
		const myOutput = self.direction()

		if (myInput == myOutput.invert()) {
			shape = straightShape
		} else if (myInput == myOutput.previous()) {
			shape = curveLeftShape
		} else {
			shape = curveRightShape
		}
	}

	// Una máquina de al lado cambió (se construyó, se destruyó o rotó): la cinta recalcula su forma.
	// Como el tablero avisa siempre, al prender la simulación la forma ya está calculada
	override method onNeighbourChanged() {
		self.updateShape()
		if (!simulationEngine.running()) self.showStatic()
	}

	// Al girar cambia también de dónde le llegan las cosas
	override method turn() {
		super()
		self.updateShape()
	}

	override method staticImage() = "machines/" + self.name() + "/" + self.direction().name() + shape.imageSuffix() + "_game.png"
	
	override method gifImage() = "machines/" + self.name() + "/" + self.direction().name() + shape.imageSuffix() + ".gif"
}

// Las formas que puede tener una cinta.
object straightShape {
	method imageSuffix() = ""
}

object curveLeftShape {
	method imageSuffix() = "_curve_left"
}

object curveRightShape {
	method imageSuffix() = "_curve_right"
}
