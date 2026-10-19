import machines.machineClasses.*

class Fryer inherits Machine {

	override method name() = "Fryer"

	override method canReceive(item) = false
}
