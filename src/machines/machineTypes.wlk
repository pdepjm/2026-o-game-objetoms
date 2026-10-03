// Tipos de máquinas

import machines.machine.*
import simulation.simulationEngine.*
import simulation.animationEngine.*
import simulation.ingredientes.*

// Cinta: lleva de a un item hacia la máquina a la que apunta
class Belt inherits Maquina{
  // el item que tiene encima (null si está vacía)
  var item = null

  override method name() = "Belt"

  // Sólo acepta un item si está vacía
  override method canReceive() = item == null

  // Toma el item, lo anima hacia su celda y pide que la despierten cuando termine de llegar
  override method receive(anItem) {
	item = anItem
	// viene siempre de una celda vecina: ya se sabe cuántos pasos lleva (ver moveInSteps)
	anItem.moveInSteps(position, animationEngine.pasosPorCelda())
	simulationEngine.schedule(animationEngine.pasosPorCelda(), self)
  }

  override method heldItems() = if (item == null) [] else [item]

  override method reset() {
	super()
	item = null
  }

  // Cuando el item terminó de llegar, lo pasa a la siguiente máquina y despierta
  // a las que esperaban para entregarle algo.
  // Si no puede entregarlo, espera a la de adelante (ver waitForNext).
  override method use() {
	if (item != null) {
		if (item.moviendose()) {
			simulationEngine.schedule(1, self)
		} else if (self.canPush()) {
			const outgoing = item
			item = null
			self.push(outgoing)
			self.wakeWaiting()
		} else {
			self.waitForNext()
		}
	}
  }

}

class Oven inherits Maquina{
  override method name() = "Oven"
}

class Fryer inherits Maquina{
  override method name() = "Fryer"

}

class CuttingMachine inherits Maquina{
  override method name() = "CuttingMachine"
}

class Assembler inherits Maquina{
  override method name() = "Assembler"
}

class Dispenser inherits Maquina{
  // Dispensa un item cada un determinado tiempo
  override method name() = "Dispenser"

  var item = { => new Carne() } // item a dispensar, instanciador de clase.

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
	} else {
		self.waitForNext()
	}
  }

  // Crea un item nuevo sobre el dispenser y se lo entrega a la máquina de adelante
  method dispense(){
	const newItem = item.apply()
	newItem.position(self.position())
	simulationEngine.addItem(newItem)
	self.push(newItem)
  }
}
