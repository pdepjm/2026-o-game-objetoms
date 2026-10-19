import machines.machineClasses.*
import food.foodClasses.*

class Oven inherits Machine {

	override method name() = "Oven"

	override method canReceive(item) = super(item) && item.canProcess(cooking)

	override method runningImage() = self.gifImage()

	override method onArrived(item) {
		item.process(cooking)
		self.tryPush()
	}
}
