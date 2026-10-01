// Maneja el que es cada cosa

import wollok.game.*
import userTools.toolsManager
import menu.placeMenu.*
import ingredientes.*
import board.*
import simulationEngine.*
import animationEngine.*

// Clase de máquina
// Hay que agregar los métodos de rotar, de procesar, etc.
// Las máquinas se pasan los items de mano en mano: cada una le pregunta a la
// siguiente si puede recibir (canReceive) y se lo entrega (receive).
// Cuántos items guarda cada máquina es asunto de cada subclase.
//
// Ciclo de vida de una máquina en la simulación:
// - start(): al prender la simulación. Busca a su vecina y agenda lo que necesite.
// - use(): cuando llega el paso que ella misma agendó en el simulationEngine.
// - reset(): al apagar la simulación. Suelta los items que tenía.
class Maquina {

	// El simulationEngine la llama cuando llega el paso que la máquina agendó.
	// Por defecto no hace nada: una máquina que nunca agenda, nunca se despierta.
	method use() {}

	// La máquina hacia la que apunta (null si no hay ninguna).
	// Se calcula una sola vez al prender la simulación: con la simulación prendida
	// no se puede editar el tablero, así que no cambia.
	var next = null

	// Se llama al prender la simulación
	method start() {
		next = self.nextMachine()
	}
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

	// Busca en el tablero la máquina hacia la que apunta (null si no hay ninguna).
	// Es una consulta cara con muchas máquinas: durante la simulación se usa next.
	method nextMachine() = board.machineAt(direction.move(position))

	// ¿Puede aceptar un item más? Por defecto una máquina no acepta items
	method canReceive() = false

	// Otra máquina le entrega un item. Sólo se llama si canReceive() dio true.
	method receive(anItem) {}

	// Items que tiene encima la máquina en este momento
	method heldItems() = []

	// Vuelve la máquina a su estado inicial (sin items), al apagar la simulación
	method reset() {}

	// ¿Hay una máquina adelante y puede recibir?
	method canPush() = next != null && next.canReceive()

	// Le entrega el item a la máquina de adelante. Sólo se llama si canPush() dio true.
	method push(anItem) {
		next.receive(anItem)
	}

}

// Cinta: lleva de a un item hacia la máquina a la que apunta
class Belt inherits Maquina{
  // el item que tiene encima (null si está vacía)
  var item = null

  override method name() = "Belt"

  // Sólo acepta un item si está vacía
  override method canReceive() = item == null

  // Toma el item, lo anima hacia su celda y pide que la despierten cuando termine de llegar
  override method receive(anItem) {
	item = anItem
	anItem.move(position)
	simulationEngine.schedule(animationEngine.pasosPorCelda(), self)
  }

  override method heldItems() = if (item == null) [] else [item]

  override method reset() {
	item = null
  }

  // Cuando el item terminó de llegar, lo pasa a la siguiente máquina.
  // Si todavía no puede, el item espera acá y la cinta reintenta en el próximo paso.
  override method use() {
	if (item != null) {
		if (!item.moviendose() && self.canPush()) {
			const outgoing = item
			item = null
			self.push(outgoing)
		} else {
			simulationEngine.schedule(1, self)
		}
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

  var item = { => new Carne() } // item a dispensar, instanciador de clase.

  // tiempo de simulación entre un dispense y el siguiente
  method intervalMs() = 1000

  // el mismo intervalo, medido en pasos de simulación
  method intervalSteps() = simulationEngine.stepsFor(self.intervalMs())

  // Busca a su vecina (super) y agenda el primer dispense
  override method start() {
	super()
	simulationEngine.schedule(self.intervalSteps(), self)
  }

  // Se cumplió el intervalo: dispensa y agenda el próximo.
  // Si no hay a quién entregarle, espera sin perder el turno y reintenta en el próximo paso.
  override method use(){
	if (self.canPush()) {
		self.dispense()
		simulationEngine.schedule(self.intervalSteps(), self)
	} else {
		simulationEngine.schedule(1, self)
	}
  }

  // Crea un item nuevo sobre el dispenser y se lo entrega a la máquina de adelante
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
