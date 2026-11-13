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
	override method baseEnergy() = 1

	override method runningImage() = self.gifImage()

	override method grabbableItem() = self.itemToPush()

		method calculateInputDirection() {
		const myCell = self.cell()
		const myOutput = self.direction()
		
		// 1. Primero buscamos al vecino que está justo de frente (el inverso a nuestra salida).
		// Si existe, es una cinta recta.
		const oppositeDirection = myOutput.invert()
		const oppositeNeighbour = board.machineAt(oppositeDirection.move(myCell))
		
		if (oppositeNeighbour != null && oppositeNeighbour.outputTarget() == myCell) {
			return oppositeDirection
		}
		
		// 2. Si no hay nadie de frente, buscamos a la izquierda (curva left).
		const leftDirection = myOutput.previous()
		const leftNeighbour = board.machineAt(leftDirection.move(myCell))
		
		if (leftNeighbour != null && leftNeighbour.outputTarget() == myCell) {
			return leftDirection
		}
		
		// 3. Si no, buscamos a la derecha (curva right).
		const rightDirection = myOutput.next()
		const rightNeighbour = board.machineAt(rightDirection.move(myCell))
		
		if (rightNeighbour != null && rightNeighbour.outputTarget() == myCell) {
			return rightDirection
		}
		
		return null 
	}

	method updateShape() {
		const myInput = self.calculateInputDirection()
		const myOutput = self.direction()

		if (myInput == null || myInput == myOutput.invert()) {
			shape = straightShape
		} else if (myInput == myOutput.previous()) {
			shape = curveLeftShape
		} else {
			shape = curveRightShape
		}
	}

	method notifyNeighbours() {
		const myCell = self.cell()
		const neighbours = [
			board.machineAt(myCell.left(1)),
			board.machineAt(myCell.right(1)),
			board.machineAt(myCell.up(1)),
			board.machineAt(myCell.down(1))
		]
		neighbours.filter({ neighbour => neighbour != null }).forEach({ neighbour => neighbour.onNeighbourChanged() })
	}

	// Una máquina de al lado cambió (se construyó, se destruyó o rotó): la cinta recalcula su forma
	override method onNeighbourChanged() {
		self.updateShape()
		if (!simulationEngine.running()) self.showStatic()
	}

	override method rotate() {
		super() 
		self.updateShape()
		self.showStatic() 
		self.notifyNeighbours()
	}

	override method start() {
		self.updateShape() 
		super() 
	}

	override method staticImage() = "machines/" + self.name() + "/" + self.direction().name() + shape.imageSuffix() + "_game.png"
	
	override method gifImage() = "machines/" + self.name() + "/" + self.direction().name() + shape.imageSuffix() + ".gif"
}

// Las formas que puede tener una cinta. Cada una sabe cómo se llama su imagen.
object straightShape {
	method imageSuffix() = ""
}

object curveLeftShape {
	method imageSuffix() = "_curve_left"
}

object curveRightShape {
	method imageSuffix() = "_curve_right"
}
