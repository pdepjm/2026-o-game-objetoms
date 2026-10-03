import machines.*
import board.*
import menu.menuManager.menuManager
import menu.placeMenu.placeMenu
import directions.*
import simulationEngine.*


object toolsManager{
	// Manejar las herramientas Place, Delete y Edit
	var property selectedTool = place

	// Direccion con la que se colocan las maquinas nuevas
	var currentDirection = right

	method currentDirection() = currentDirection

	// Al cambiar la dirección se actualizan las imágenes del menú, que la muestran.
	// Así el menú no tiene que preguntar la dirección en cada frame (ver MenuItem).
	method currentDirection(direction) {
		currentDirection = direction
		placeMenu.updateImages()
	}

	// Metodo principal
	// Con la simulación prendida no se puede colocar, borrar ni rotar nada
	method onClick(pos) {
		if (board.inBoard(pos)) {
			if (!simulationEngine.running()) selectedTool.onClick(pos)
		}
		else if (menuManager.inToolsMenu(pos))
			machineManager.chooseMachine(pos)
	}
}

// HERRAMIENTAS
// Por el momento, todas las herramientas deben contener el metodo onClick

object place {
    method onClick(pos) {
		board.push(pos, machineManager.createMachine())
    }
}
object delete {
    method onClick(pos) {
        board.pop(pos)
    }
}
object edit {

}
object rotate {
	method onClick(pos) {
		if (board.isThereAMachine(pos))
			board.machineAt(pos).rotate()
	}
}