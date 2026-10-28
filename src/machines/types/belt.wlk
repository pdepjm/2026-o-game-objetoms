import machines.machineClasses.*
import board.*
import directions.*
import simulation.simulationEngine.*

class Belt inherits Machine {
	
	var shape = "straight" 

	override method name() = "Belt"

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
			shape = "straight"
		} else if (myInput == myOutput.previous()) {
			shape = "curve_left"
		} else {
			shape = "curve_right"
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
		neighbours.forEach({ neighbour => 
			if (neighbour != null && neighbour.name() == "Belt") {
				neighbour.updateShape()
				if (!simulationEngine.running()) neighbour.showStatic() 
			}
		})
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

	override method staticImage() {
		if (shape == "straight") {
			return "machines/" + self.name() + "/" + self.direction().name() + "_game.png"
		} else {
			return "machines/" + self.name() + "/" + self.direction().name() + "_" + shape + "_game.png"
		}
	}
	
	override method gifImage() {
		if (shape == "straight") {
			return "machines/" + self.name() + "/" + self.direction().name() + ".gif"
		} else {
			return "machines/" + self.name() + "/" + self.direction().name() + "_" + shape + ".gif"
		}
	}
}