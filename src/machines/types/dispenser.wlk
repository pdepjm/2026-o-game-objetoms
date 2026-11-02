import src.directions.*
import machines.machineClasses.*
import machines.settings.*
import simulation.simulationEngine.*
import food.foodClasses.*
import food.foodTypes.*

// Crea un ingrediente cada intervalo y se lo entrega a la máquina de adelante.
// Se configura qué ingrediente larga y a qué velocidad (ver settings.wlk).
class Dispenser inherits Machine {
	// Todos los ingredientes que puede dispensar
	const availableKinds = [lettuce, bun, friedPotato, potato, tomato, meat, cheese, bacon, pizzaDough, egg, salami, sausage, ham]
	
	// Por defecto papa (o, si no la ofrece, el primero de los suyos) y velocidad normal.
	// Los ingredientes son los que ofrece el menú.
	const productSetting = new ProductSetting(
		value = if (availableKinds.contains(potato)) potato else availableKinds.first(),
		kinds = availableKinds
	)
	const speedSetting = new SpeedSetting(value = 1)

	override method name() = "Dispenser"

	override method runningImage() = self.gifImage()
	
	// El ingrediente que larga
	method product() = productSetting.value()

	method product(kind) {
		productSetting.value(kind)
	}

	override method settings() = [productSetting, speedSetting]

	// tiempo de simulación entre un dispense y el siguiente: 5 segundos a velocidad normal
	method intervalMs() = 5000 / speedSetting.value()

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
			const item = new Item(kind = self.product())
			if (target.canReceiveFrom(self, item)) {
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
