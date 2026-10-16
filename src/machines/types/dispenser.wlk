import machines.machineClasses.*
import simulation.simulationEngine.*
import food.foodClasses.*
import food.foodTypes.*

// Dispensa un item cada un determinado tiempo
class Dispenser inherits Machine{
  var item = { => new Item(kind = potato) } // item a dispensar, instanciador de clase.

  override method name() = "Dispenser"

  // tiempo de simulación entre un dispense y el siguiente
  method intervalMs() = 1000

  // el mismo intervalo, medido en pasos de simulación
  method intervalSteps() = simulationEngine.stepsFor(self.intervalMs())

  // Busca a su vecina (super) y agenda el primer dispense
  override method start() {
	  super()
	  simulationEngine.schedule(self.intervalSteps(), self)
  }

  // Se cumplió el intervalo: dispensa y agenda el próximo.
  // Si no puede entregar, espera a la de adelante (ver waitForNext).
  override method use(){
	  if (self.canPush()) {
		  self.dispense()
		  simulationEngine.schedule(self.intervalSteps(), self)
	  } else
		  self.waitForNext()
  }

  // Crea un item nuevo sobre el dispenser y se lo entrega a la máquina de adelante
  method dispense(){
	  const newItem = item.apply()
	  newItem.position(self.position())
	  simulationEngine.addItem(newItem)
	  self.push(newItem)
  }
}
