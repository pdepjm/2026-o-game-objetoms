import src.directions.*
import machines.machineClasses.*
import simulation.simulationEngine.*
import food.foodClasses.*
import food.foodTypes.*

// Crea un ingrediente cada intervalo y se lo entrega a la máquina de adelante.
class Dispenser inherits Machine {
	// item a dispensar, instanciador de clase. Por defecto papa; el menú le pasa otro.
	const product = { => new Item(kind = potato) }

	override method name() = "Dispenser"

	// tiempo de simulación entre un dispense y el siguiente
	method intervalMs() = 5000

	// el mismo intervalo, medido en pasos de simulación
	method intervalSteps() = simulationEngine.stepsFor(self.intervalMs())

	// Busca a su vecina (super) y agenda el primer intento de dispensar
	override method start() {
		super()
		self.scheduleNext()
	}

	method scheduleNext() {
		simulationEngine.after(self.intervalSteps(), { self.tryDispense() })
	}

	// Intenta crear un item y pasarlo a la de adelante.
	// Pregunta ANTES de crear: si la de adelante está llena no se crea ningún item
	// (el item recién se hace cuando hay a dónde mandarlo). Si está llena, se anota
	// para reintentar apenas se libere: no espera al próximo intervalo.
	method tryDispense() {
		const target = next
		if (target != null) {
			const item = product.apply()
			if (target.canReceive(item)) {
				item.position(self.position())
				simulationEngine.addItem(item)
				inventory.add(item)
				self.tryPush()
			} else {
				target.whenFree({ self.tryDispense() })
			}
		}
	}

	// No recibe items: sólo los crea
	override method canReceive(item) = false

	// Recién cuando el item se entregó se agenda el próximo
	override method onPushed(item) {
		self.scheduleNext()
	}
}
