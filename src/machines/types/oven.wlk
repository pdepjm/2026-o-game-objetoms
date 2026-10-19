import machines.machineClasses.*

class Oven inherits Machine {

	override method name() = "Oven"

	override method canReceive(item) = false
}
