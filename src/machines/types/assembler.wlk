import src.directions.*
import machines.machineClasses.*
import simulation.simulationEngine.*
import food.recipes.*
import cellPosition.*

// Ensamblador: junta los ingredientes que pide su receta y entrega el plato armado.
// Sólo acepta lo que la receta todavía necesita, así que nunca tiene items de más:
// cuando la receta se puede armar, lo que tiene es justo lo que hace falta y se consume todo.
class Assembler inherits Machine {
	// La receta que arma (por ahora fija: sólo existe burgerRecipe)
	const recipe = breakfastRecipe

	// El plato armado, a la espera de ser entregado. No está en el inventario
	// (ahí sólo van los ingredientes), por eso se guarda aparte.
	var dish = null
	override method name() = "Assembler"

	// Imagenes que va a utilizar para animar
	override method workImages() = self.actionAnimation("assemble", 22).frames()

	// Ocupa 2x2 celdas, desde la celda donde se colocó (abajo a la izquierda)
	override method width() = 2
	override method height() = 2

	// Guarda tantos ingredientes como pide la receta
	override method capacity() = recipe.totalItems()

	// Acepta lo que la receta todavía necesita, y sólo si no tiene un plato esperando salir
	override method canReceive(item) =
		super(item) && dish == null && recipe.stillNeeds(item, inventory.items())

	// Hay que ver si hay una forma de implementar polymorfismo
	override method outputTarget() = 
		if(direction == left || direction == right)
			super().up(1)
		else if (direction == down)
			super().right(1)
		else super()

	// Cuando el ingrediente llegó: si ya está todo, arma el plato y lo entrega
	override method onArrived(item) {
		simulationEngine.removeItem(item)
		if (recipe.canBeMadeWith(inventory.items())) {
			self.animateWork(recipe.assembleTime(), {
				self.assemble()
				self.tryPush()
			})
		}
	}

	// Consume los ingredientes y crea el plato en la posición del ensamblador
	method assemble() {
		const ingredients = inventory.items().copy()
		ingredients.forEach({ ingredient =>
			inventory.release(ingredient)
		})
		dish = recipe.prepare()
		dish.position(self.outputTarget())
		simulationEngine.addItem(dish)
	}

	// Lo que se entrega es el plato, no un ingrediente
	override method itemToPush() = dish

	// Cuando se entregó el plato, queda libre para armar otro
	override method onPushed(item) {
		dish = null
	}

	// El plato también cuenta como item de la máquina: así el engine lo saca al apagar la simulación
	override method heldItems() = if (dish == null) inventory.items() else inventory.items() + [dish]

	// Su estado propio se reinicia ANTES de llamar a super()
	override method reset() {
		dish = null
		super()
	}
}
