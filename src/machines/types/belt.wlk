import machines.machineClasses.*
import simulation.simulationEngine.*
import simulation.animationEngine.*

// Cinta: lleva de a un item hacia la máquina a la que apunta
class Belt inherits Machine{

	override method name() = "Belt"

	// Toma el item, lo anima hacia su celda y pide que la despierten cuando termine de llegar
	override method receive(anItem) {
		super(anItem)
		// viene siempre de una celda vecina: ya se sabe cuántos pasos lleva (ver moveInSteps)
		anItem.moveInSteps(position, animationEngine.pasosPorCelda())
		simulationEngine.schedule(animationEngine.pasosPorCelda(), self)
	}

	override method runningImage() = self.gifImage()
  	override method reset() {
		super()
		heldItem = null
  	}

  // Cuando el item terminó de llegar, lo pasa a la siguiente máquina y despierta
  // a las que esperaban para entregarle algo.
  // Si no puede entregarlo, espera a la de adelante (ver waitForNext).
  	override method use() {
		if (heldItem != null)
		  	if (heldItem.moviendose())
		  		simulationEngine.schedule(1, self)
		  	else if (self.canPush()) {
		  		const outgoing = heldItem
		  		heldItem = null
		  		self.push(outgoing)
		  		self.wakeWaiting()
		  	} 
  	    else
		  	self.waitForNext()
  	}
}
