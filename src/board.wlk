// MANEJA EL DONDE

import wollok.game.*
import simulation.simulationEngine.*
import cellPosition.*

// Una casilla del tablero. Guarda la máquina que está ahí (null si está vacía).
class Cell {
	var property machine = null
}

object board {
	// El tablero es una grilla de casillas: grid.get(x).get(y) es la casilla de la columna x, fila y.
	//
	// POR QUÉ UNA GRILLA Y NO UN DICTIONARY
	// En Wollok, buscar en un Dictionary compara contra todas las claves una por una:
	// con el tablero lleno (195 máquinas) cada búsqueda tardaba ~6 ms, y al prender la
	// simulación (cada máquina busca a su vecina) el juego se congelaba ~4 segundos.
	// En la grilla, buscar es ir directo a la posición: no depende de cuántas máquinas haya.
	//
	// CÓMO SE MODIFICA
	// Las listas de Wollok no permiten reemplazar un elemento en su lugar (no hay set(i, valor)).
	// Por eso la grilla se arma UNA SOLA VEZ y nunca cambia: lo que cambia es la máquina
	// que guarda cada casilla (cell.machine(...)).
	//
	// Va de 0 a maxColumn en x y de 0 a maxRow en y, para que el índice sea directamente la
	// coordenada (las columnas y filas fuera del tablero existen pero no se usan).
	const maxColumn = 19
	const maxRow = 13
	//
	// OJO: el machine = null explícito es necesario. Por un bug de Wollok, un objeto creado
	// mientras se inicializa otro objeto (como acá, dentro de board) no toma bien el valor
	// por defecto null: machine() devuelve algo que se muestra como "null" pero no es == null.
	// Pasándolo al crear la casilla, sí queda el null de verdad.
	const grid = (0..maxColumn).map({ x => (0..maxRow).map({ y => new Cell(machine = null) }) })

	// métodos privados

	// La casilla de esa posición. OJO: sólo para posiciones dentro del tablero;
	// fuera de rango, get() da error (por eso machineAt revisa inBoard antes).
	method cellAt(position) = grid.get(position.x()).get(position.y())

	//sacar la máquina de una casilla
	method removePosition(position) {
		self.cellAt(position).machine(null)
	}

	//guardar una máquina en una casilla
	method setPosition(position, cosa) {
		self.cellAt(position).machine(cosa)
	}

	// métodos públicos

	//obtener la máquina de una posición (null si no hay, o si está fuera del tablero).
	// Fuera del tablero pasa, por ejemplo, con una cinta del borde que apunta hacia afuera.
	method machineAt(position) =
		if (self.inBoard(position)) self.cellAt(position).machine() else null

	//pushear elemento al tablero. La máquina queda registrada en el simulationEngine.
	// OJO: push y pop no se deben usar con la simulación prendida, porque las máquinas
	// ya calcularon a sus vecinas. El bloqueo de los clicks está en toolsManager.
	method push(position, element) {
		if (!self.inBoard(position))
			self.error("No se puede colocar una máquina fuera del tablero: " + position)

		if (!self.isThereAMachine(position)) {
			// se guarda como CellPosition para que dibujarla sea barato (ver CellPosition)
			element.position(new CellPosition(
				x = position.x() + element.offsetX(), 	// Mueve el dibujo de lugar (Es para el Automatic Arm que es mas grande)
				y = position.y() + element.offsetY())
			)
			game.addVisual(element)
			self.setPosition(position, element)
			simulationEngine.addSimulatedObject(element)
		}
	}

	// quitar elemento del tablero
	method pop(position) {
		if (self.isThereAMachine(position)) {
			const machine = self.machineAt(position)
			// los items que tenía encima la máquina se van con ella
			machine.heldItems().forEach({ item =>
				item.detener()
				game.removeVisual(item)
			})
			simulationEngine.removeSimulatedObject(machine)
			game.removeVisual(machine)
			self.removePosition(position)
		}
	}

	// Verifica si el click esta dentro del tablero
	method inBoard(pos) = pos.x().between(5, 19) && pos.y().between(1, 13)

	// Verificar si hay una maquina en la posicion clickeada
	method isThereAMachine(pos) = self.machineAt(pos) != null
}
