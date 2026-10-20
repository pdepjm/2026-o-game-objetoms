import machines.machineClasses.*
import food.foodClasses.*

// Cortadora: sus 17 PNG de corte se ajustan al tiempo de cada ingrediente

class CuttingMachine inherits ProcessingMachine {
	override method name() = "CuttingMachine"

	override method foodProcess() = cutting

	override method workImages() = self.actionAnimation("cut", 17).frames()

}
