import machines.machineClasses.*
import simulation.simulationEngine.*
import levels.levelManager.*
import directions.*
import board.*

class DeliverySlot inherits Machine {
    override method name() = "DeliverySlot"
	override method nextMachine() = null

	// El plato llegó al platito: sale del juego y cuenta para el nivel
	override method onArrived(item) {
		inventory.release(item)
		simulationEngine.removeItem(item)
		levelManager.delivered(item)
	}
}

// Los platitos del fondo. Sus posiciones están sólo acá.
object deliveryPoints {
	const property slots = [
		new DeliverySlot(position = game.at(16, 14), direction = down),
		new DeliverySlot(position = game.at(17, 14), direction = down)
	]

	// Lo llama main.wpgm al arrancar (y los tests que los necesiten)
	method setUp() {
		slots.forEach({slot => 
            board.addDeliverySlot(slot)
        })
	}
}