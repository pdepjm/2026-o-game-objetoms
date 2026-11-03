import board.*
import levels.tutorial.*

class DeliveryGoal {
	const kind
	const amount
	const label          // cómo se muestra: "Papas cortadas"
	var delivered = 0

	method delivered(item) { if (kind.accepts(item)) delivered += 1 }
	method isMet() = delivered >= amount
	method progressText() = label + ": " + delivered.min(amount) + "/" + amount
	method reset() { delivered = 0 }

	// Para la info del nivel: la imagen del plato y cuánto falta, en décimos (0 a 10) para la barra
	method image() = kind.image()
	method progressTenths() = (delivered.min(amount) * 10).div(amount)
}

// Es modo libre, es preferible que entienda los mismos mensajes y nos ahorramos tener que definir sus atributos
object noGoal{
    method isMet() = false
    method progressText() = ""
    method delivered(_) {}
    method reset() {}
}

class Level {
	const property name
	const property availableMachines          // Las maquinas disponibles para colocar
	const property availableRecipes			  // Las recetas disponibles para configurar 
	const property fixedMachines = []         // Maquinas colocadas desde el comienzo (No se pueden mover)
	const property goals                      // Lo que hay que cumplir para ganar: TODOS los objetivos
	const property buildZones = [wholeBoard]  // Dónde puede construir el jugador: Zones (ver board.wlk). Por defecto, todo el tablero
	const property tutorial = noTutorial      // El que acompaña al nivel (ver tutorial.wlk). Por defecto, ninguno

	// ¿Es un tutorial? (los que se pueden saltear)
	method hasTutorial() = tutorial != noTutorial

	// Coloca las máquinas que trae el nivel. Con fixedMachines vacío no hace nada.
	method placeFixedMachines() {
		fixedMachines.forEach({ placement => board.push(placement.position(), placement.create()) })
	}

	// ----------- OBJETIVOS -----------
	// levelManager habla con el nivel y el nivel con cada uno de sus objetivos

	method delivered(item) {
		goals.forEach({ goal => goal.delivered(item) })
	}

	// Se gana cuando se cumplen todos (con noGoal, nunca)
	method goalsMet() = goals.all({ goal => goal.isMet() })

	method resetGoals() {
		goals.forEach({ goal => goal.reset() })
	}

	// Los objetivos que se muestran en la info del nivel: noGoal no tiene texto, así que no se muestra
	method shownGoals() = goals.filter({ goal => goal.progressText() != "" })

	// Una línea por objetivo que se muestra
	method progressLines() = self.shownGoals().map({ goal => goal.progressText() })
}

class Placement {
	const property position	// Puede ser game.at() o CellPosition
	const factory
	const locked = true

	method create() {
		const machine = factory.apply()
		machine.locked(locked)
		return machine
	}
}