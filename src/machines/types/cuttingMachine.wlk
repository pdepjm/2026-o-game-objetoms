import machines.machineClasses.*
import food.foodClasses.*

// Cortadora: corta el item que recibe.
// EN DESARROLLO: hasta la fase 5 del plan se deja sólo compilando, con el
// comportamiento mínimo (recibe por defecto, corta al llegar si el item se puede cortar).
class CuttingMachine inherits Machine {

	override method name() = "CuttingMachine"

	override method onArrived(item) {
		if (item.canProcess(cutting)) item.process(cutting)
	}
}
