import machines.machineClasses.*
import food.foodClasses.*

// Cortadora: acepta ingredientes que se pueden cortar, los corta con una animación
// y los entrega a la máquina de adelante.
// Sólo sobrescribe lo que la hace distinta (ver el contrato en src/machines/README.md).
class CuttingMachine inherits Machine {

	// Cantidad de frames de la animación de corte (carpeta <direccion>_cut/)
	const cutFrames = 17

	override method name() = "CuttingMachine"

	// Sólo acepta lo que se puede cortar (y mientras tenga lugar)
	override method canReceive(item) = super(item) && item.canProcess(cutting)

	// Cuando el item llegó a la celda: anima el corte, lo transforma y lo entrega
	override method onArrived(item) {
		self.play(self.actionAnimation("cut", cutFrames), {
			item.process(cutting)
			self.showRunning()
			self.tryPush()
		})
	}
}
