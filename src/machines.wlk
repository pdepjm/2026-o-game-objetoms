// Maneja el que es cada cosa

import wollok.game.*
import userTools.toolsManager
import menu.placeMenu.*
import ingredientes.*
import board.*
import simulationEngine.*

// Clase de máquina
// Hay que agregar los métodos de rotar, de procesar, etc.
// Las máquinas se pasan los items de mano en mano: cada una le pregunta a la
// siguiente si puede recibir (canReceive) y se lo entrega (receive).
// Cuántos items guarda cada máquina es asunto de cada subclase.
class Maquina {

	method use() {}
  	var property position = game.origin()

  	method name() = "Maquina"

	// Cada máquina guarda su propia dirección (un objeto de directions.wlk).
	// Nace con la dirección seleccionada al momento de colocarla.
	var direction = toolsManager.currentDirection()

	// La imagen se calcula sólo cuando cambia la dirección, no en cada frame
	var property image = self.buildImage()

	method buildImage() = "machines/"+self.name()+"/"+direction.name() + ".gif"

	method rotate() {
		direction = direction.next()
		image = self.buildImage()
	}

	// La máquina hacia la que apunta (null si no hay ninguna)
	method nextMachine() = board.machineAt(direction.move(position))

	// Por defecto una máquina no acepta items
	method canReceive() = false

	method receive(anItem) {}

	// Items que tiene encima la máquina en este momento
	method heldItems() = []

	// Vuelve la máquina a su estado inicial (sin items), al apagar la simulación
	method reset() {}

	method canPush() = self.nextMachine() != null && self.nextMachine().canReceive()

	method push(anItem) {
		self.nextMachine().receive(anItem)
	}

}

class Belt inherits Maquina{
  var item = null

  override method name() = "Belt"

  override method canReceive() = item == null

  // Toma el item y lo anima hacia su celda
  override method receive(anItem) {
	item = anItem
	anItem.move(position)
  }

  override method heldItems() = if (item == null) [] else [item]

  override method reset() {
	item = null
  }

  // Cuando el item terminó de llegar, lo pasa a la siguiente máquina.
  // Si la siguiente no puede recibir, el item espera acá.
  override method use() {
	if (item != null && !item.moviendose() && self.canPush()) {
		const outgoing = item
		item = null
		self.push(outgoing)
	}
  }

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

  var elapsed = 0 // milisegundos de simulación desde el último dispense
  var item = { => new Carne() } // item a dispensar, instanciador de clase.

  method intervalMs() = 1000

  override method reset() {
	elapsed = 0
  }

  // Si se cumplió el intervalo pero no hay a quién entregarle, espera sin perder el turno
  override method use(){
	elapsed = (elapsed + simulationEngine.tickMs()).min(self.intervalMs())
	if (elapsed >= self.intervalMs() && self.canPush()) {
		elapsed = 0
		self.dispense()
	}
  }

  method dispense(){
	const newItem = item.apply()
	newItem.position(self.position())
	game.addVisual(newItem)
	self.push(newItem)
  }
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
