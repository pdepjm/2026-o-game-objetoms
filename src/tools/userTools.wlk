import board.*
import machines.machineManager.*

// HERRAMIENTAS
// Por el momento, todas las herramientas deben contener el metodo onClick

object place {
	method name() = "place"
    method onClick(pos) {
		board.push(pos, machineManager.createMachine())
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
