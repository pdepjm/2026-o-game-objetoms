import machines.machineClasses.*

class Assembler inherits Machine {

	override method name() = "Assembler"

	override method canReceive(item) = false
}
