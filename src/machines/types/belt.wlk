import machines.machineClasses.*
import simulation.simulationEngine.*
import simulation.animationEngine.*

// Cinta: lleva de a un item hacia la máquina a la que apunta
class Belt inherits Machine{
  // el item que tiene encima (null si está vacía)
  var item = null

  override method name() = "Belt"

  // Se anima con GIF mientras la simulación está prendida
  override method runningImage() = self.gifImage()

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
	  if (item != null)
	  	if (item.moviendose())
	  		simulationEngine.schedule(1, self)
	  	else if (self.canPush()) {
	  		const outgoing = item
	  		item = null
	  		self.push(outgoing)
	  		self.wakeWaiting()
	  	} 
      else
	  		self.waitForNext()
  }
}
