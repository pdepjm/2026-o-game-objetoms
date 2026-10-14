import machines.machineClasses.*
import simulation.animationEngine.*
import simulation.simulationEngine.*


class CuttingMachine inherits Machine{
  override method name() = "CuttingMachine"
  override method receive(anItem) {
    super(anItem)
    anItem.moveInSteps(position, animationEngine.pasosPorCelda())
	  simulationEngine.schedule(animationEngine.pasosPorCelda(), self)
  }

  override method use() {
    heldItem.cortar()
  }
}
