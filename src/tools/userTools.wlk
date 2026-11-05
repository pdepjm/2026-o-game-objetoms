import board.*
import machines.machineManager.*
import menu.editMenu.*
import sound.sfx.*

// HERRAMIENTAS
// Por el momento, todas las herramientas deben contener el metodo onClick

object place {
	method name() = "place"
    // Si no entra (celda ocupada o parte fuera del tablero), no coloca nada
    method onClick(pos) {
		const machine = machineManager.createMachine()
		if (board.canPlace(pos, machine)) {
			board.push(pos, machine)
			sfx.place()
		} else {
			sfx.invalid()
		}
    }
}
object delete {
	method name() = "delete"
    method onClick(pos) {
        if (board.isThereAMachine(pos)) {
            board.pop(pos)
            sfx.delete()
        } else {
            sfx.invalid()
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
		if (board.isThereAMachine(pos)) {
			board.machineAt(pos).rotate()
			sfx.rotate()
		}
	}
}
