import board.*
import machines.machineManager.*
import menu.menuManager.*
import menu.placeMenu.*
import directions.*
import simulation.simulationEngine.*
import tools.userTools.*

object toolsManager{
	// Manejar las herramientas Place, Delete y Edit
	var selectedTool = place

	// Direccion con la que se colocan las maquinas nuevas
	var currentDirection = right

	method currentDirection() = currentDirection

	// Metodo para seleccionar la herramienta que se esta usando
	method select(tool) {selectedTool = tool}

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
