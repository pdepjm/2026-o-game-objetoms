import board.*
import machines.machineManager.*

// HERRAMIENTAS
// Por el momento, todas las herramientas deben contener el metodo onClick

object place {
	method name() = "place"
    // Si no entra (celda ocupada o parte fuera del tablero), no coloca nada
    method onClick(pos) {
		const machine = machineManager.createMachine()
		if (board.canPlace(pos, machine)) board.push(pos, machine)
    }
}
object delete {
	method name() = "delete"
    method onClick(pos) {
        board.pop(pos)
    }
}
object edit {
	method name() = "edit"
	method onClick(pos) {}
}
object rotate {
	method name() = "rotate"
	method onClick(pos) {
		if (board.isThereAMachine(pos))
			board.machineAt(pos).rotate()
	}
}
