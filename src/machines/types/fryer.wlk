import machines.machineClasses.*

class Fryer inherits Machine{
  override method name() = "Fryer"
  override method canReceive() = false
  override method receive(_) {}
  override method use() {}
}
