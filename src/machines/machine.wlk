// Maneja el que es cada cosa

import wollok.game.*
import tools.toolsManager.*
import board.*
import simulation.simulationEngine.*

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
//
// Cuando la de adelante está llena, una máquina no pregunta en cada paso: se anota
// (waitForNext) y se duerme. Por eso TODA máquina que se libere tiene que llamar a
// wakeWaiting(), o las que esperan no se despiertan nunca.
class Maquina {
	// Máquinas que quisieron entregarle un item y no pudieron porque estaba llena.
	// Se quedan dormidas hasta que esta máquina se libere y las despierte.
	const waiting = []

	// Otra máquina se anota para que la despierten cuando haya lugar.
	// No hace falta revisar repetidos: una máquina anotada no hace nada hasta que la despierten.
	method addWaiting(machine) { waiting.add(machine) }

	// Se llama cuando la máquina se libera: despierta a todas las que esperaban.
	method wakeWaiting() {
		if (!waiting.isEmpty()) {
			waiting.forEach({ machine => simulationEngine.schedule(1, machine) })
			waiting.clear()
		}
	}

	// Sirven para desplazar la imagen antes de colocarla (Por ahora solo para el Automatic Arm, ver implementacion en Board)
	method offsetX() = 0
	method offsetY() = 0

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

	// OJO: Wollok inicializa los atributos recién la primera vez que se leen, no al crear
	// el objeto. Sin esto, una máquina toma la dirección que esté seleccionada cuando alguien
	// la lee por primera vez, y no la que había al crearla. Calcular la imagen acá lee
	// direction, y así queda fijada en el momento de crear la máquina.
	override method initialize() {
		super()
		image = self.buildImage()
	}

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
	method reset() {
		waiting.clear()
	}

	// ¿Hay una máquina adelante y puede recibir?
	method canPush() = next != null && next.canReceive()

	// Le entrega el item a la máquina de adelante. Sólo se llama si canPush() dio true.
	method push(anItem) {
		next.receive(anItem)
	}

	// No pudo entregar: se anota en la de adelante para que la despierte cuando se libere.
	// Si no hay máquina adelante, no hay a quién esperar: se queda dormida sin gastar nada.
	method waitForNext() {
		if (next != null) next.addWaiting(self)
	}

}
