// Maneja el que es cada cosa

import wollok.game.*
import userTools.toolsManager
import menu.placeMenu.*

// Clase de máquina
// Hay que agregar los métodos de rotar, de procesar, etc.
// Tiene que haber una position de salida. Un "item actual" para tener el objeto que le toca procesar.
class Maquina {
  var property position = game.origin()

  method name() = "Maquina"

  // Cada máquina guarda su propia dirección (un objeto de directions.wlk).
  // Nace con la dirección seleccionada al momento de colocarla.
  var direction = toolsManager.currentDirection()

  method rotate() {
    direction = direction.next()
  }

  method image() = "machines/"+self.name()+"/"+direction.name() + ".gif"

}

class Belt inherits Maquina{
  override method name() = "Belt"

}

class Oven inherits Maquina{
  override method name() = "Oven"
}

class Fryer inherits Maquina{
  override method name() = "Fryer"

}

class CuttingMachine inherits Maquina{
  override method name() = "CuttingMachine"
}

class Assembler inherits Maquina{
  override method name() = "Assembler"
}

class Dispenser inherits Maquina{
  // Dispensa un item cada un determinado tiempo
  override method name() = "Dispenser"
}


// Maneja cual es la Machine Seleccionada actual
object machineManager{
	// El orden de la lista define el orden en el menú.
	// Cada elemento es una lambda que crea una máquina nueva.
	const machines = [
		{ => new Belt() },
		{ => new Assembler() },
		{ => new Oven() },
		{ => new CuttingMachine() },
		{ => new Fryer() },
		{ => new Dispenser() }
	]

	var selectedMachine = machines.first()

	// Nueva instancia de la máquina seleccionada
	method createMachine() = selectedMachine.apply()

	// La máquina seleccionada se identifica por su nombre
	method selectedName() = self.createMachine().name()

	// Máquinas que se muestran en una página del menú (4 por página)
	method machinesOfPage(page) = machines.drop(page * 4).take(4)

	// Selecciona la máquina del slot clickeado, si hay una en ese slot
	method chooseMachine(pos){
		const slot = placeMenu.slotAt(pos)
		const pageMachines = self.machinesOfPage(placeMenu.currentPage())

		if (slot > 0 && slot <= pageMachines.size()) {
			selectedMachine = pageMachines.get(slot - 1)
			placeMenu.updateOverlay()
		}
	}
}
