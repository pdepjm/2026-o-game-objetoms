// Buffet Albert Einstein - el ensamblador: junta los ingredientes de una receta y entrega el plato armado.
//
// Copyright (C) 2026  grupo objeTOMs (Mateo Bustos, Carlos Aramis Chambi Flores,
// Facundo Ramounat, Federico Scalise Giussani, Mateo Silva)
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

import src.directions.*
import machines.machineClasses.*
import simulation.simulationEngine.*
import food.recipes.*
import cellPosition.*
import machines.settings.*

// Ensamblador: junta los ingredientes que pide su receta y entrega el plato armado.
// Sólo acepta lo que la receta todavía necesita, así que nunca tiene items de más:
// cuando la receta se puede armar, lo que tiene es justo lo que hace falta y se consume todo.
class Assembler inherits Machine {
	// La receta que eligió el jugador. Arranca con la primera del nivel (noRecipe si el nivel no tiene).
	const recipeSetting = new RecipeSetting(value = recipeBook.firstAvailable())

	var recipe = recipeSetting.value()

	var dish = null
	

	// Qué tan rápido arma el plato (se cambia con la herramienta edit)
	const speedSetting = new SpeedSetting(value = 1)

	override method settings() = [recipeSetting, speedSetting]

	override method speed() = speedSetting.value()

	// La receta elegida en el panel de edit (la que va a usar al prender la simulación)
	method selectedRecipe() = recipeSetting.value()
	override method name() = "Assembler"
	override method baseEnergy() = 1

	// Imagenes que va a utilizar para animar
	override method workImages() = self.actionAnimation("assemble", 22).frames()

	// Ocupa 2x2 celdas, desde la celda donde se colocó (abajo a la izquierda)
	override method width() = 2
	override method height() = 2

	// Al prender, toma la receta elegida y ajusta el inventario a lo que pide
	override method start() {
		recipe = recipeSetting.value()
		inventory.changeCapacity(recipe.totalItems())
		super()
	}

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
			self.animateWork(self.workSteps(recipe.assembleTime()), {
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
