import board.*
import machines.machineManager.*
import menu.editMenu.*
import levels.levelManager.*

// HERRAMIENTAS
// Por el momento, todas las herramientas deben contener el metodo onClick

object place {
	method name() = "place"
    // Si no entra (celda ocupada, parte fuera del tablero o fuera de las zonas donde el nivel deja construir),
    // no coloca nada
    method onClick(pos) {
		const machine = machineManager.createMachine()
		if (board.canBuild(pos, machine)) {
			board.push(pos, machine)
			levelManager.machinePlaced(machine)
		}
    }
}
object delete {
	method name() = "delete"
	// Las máquinas bloqueadas (las fijas de un nivel) no se pueden borrar.
	// Se avisa después de sacarla (así el tutorial ve el tablero sin ella), con la máquina que se guardó antes.
    method onClick(pos) {
        if (board.isThereAMachineUnlocked(pos)) {
        	const machine = board.machineAt(pos)
        	board.pop(pos)
        	levelManager.machineRemoved(machine)
        }
    }
}
object edit {
	method name() = "edit"
	method onClick(pos) {
		editMenu.selectMachine(pos)
	}
}
object rotate {
	method name() = "rotate"

	method onClick(pos) {
		if (board.isThereAMachineUnlocked(pos)) {
			board.machineAt(pos).rotate()
			levelManager.machineRotated(board.machineAt(pos))
		}
	}
}
