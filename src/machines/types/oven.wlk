import machines.machineClasses.*
import food.foodClasses.*

// Horno: quieto cuando está vacío, el GIF sólo mientras cocina

class Oven inherits ProcessingMachine {

	override method name() = "Oven"

	override method foodProcess() = cooking

	override method animateWork(steps, afterBlock) {

		self.holdImage(self.gifImage(), steps, afterBlock)
	}
}
