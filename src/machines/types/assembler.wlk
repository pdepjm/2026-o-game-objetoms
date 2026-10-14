import machines.machineClasses.*

class Assembler inherits Machine{
  override method name() = "Assembler"
  override method canReceive() = false
  override method receive(_) {}
  override method use() {}
}
