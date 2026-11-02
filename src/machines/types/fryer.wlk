import machines.machineClasses.*
import simulation.simulationEngine.*
import food.foodClasses.*

// Freidora: fríe lo que le entrega un brazo y se lo devuelve a un brazo.
// Es armOnly: no recibe de cintas ni entrega a cintas, sólo trabaja con un brazo.
// Un brazo puede sacarle el item apenas entra, esté listo o no (grabbableItem): el brazo común lo
// saca al toque, y el inteligente puede esperar al ingrediente que quiere con sus filtros.
// Si el item ya frito se queda demasiado tiempo, se quema.
class Fryer inherits ProcessingMachine {
	// Pasos que aguanta un item ya frito antes de quemarse (4 segundos a velocidad normal)
	const burnSteps = 40

	override method name() = "Fryer"

	override method foodProcess() = frying

	override method armOnly() = true

	override method grabbableItem() = self.itemToPush()

	// Al terminar de freír empieza a correr el tiempo para quemarse (si el item puede quemarse)
	override method onProcessed(item) {
		if (item.canProcess(burning)) simulationEngine.after(burnSteps, { self.burn(item) })
	}

	// SIEMPRE revisa el estado: si en estos pasos se lo llevó un brazo, ya no hay nada que quemar
	method burn(item) {
		if (self.heldItems().contains(item)) {
			item.process(burning)
			self.notifyGrabbers()
		}
	}
}
