import board.*
import menu.menuManager.*
import directions.*
import simulation.simulationEngine.*
import tools.userTools.*

object toolsManager{
	// Manejar las herramientas Place, Delete, Edit y Rotate
	var selectedTool = place

	method selectedTool() = selectedTool

	// Único punto de entrada para cambiar de herramienta (teclas de userController).
	// Los menús se enteran por menuManager.
	method select(tool) {
		selectedTool = tool
		menuManager.toolChanged(tool)
	}

	// Direccion con la que se colocan las maquinas nuevas
	var currentDirection = right

	method currentDirection() = currentDirection

	// Al cambiar la dirección se actualizan las imágenes del menú, que la muestran.
	// Así el menú no tiene que preguntar la dirección en cada frame (ver MenuItem).
	method currentDirection(direction) {
		currentDirection = direction
		menuManager.directionChanged()
	}

	// Metodo principal
	// Con la simulación prendida no se puede colocar, borrar ni rotar nada
	method onClick(pos) {
		if (board.inBoard(pos) && selectedTool != null) {
			if (!simulationEngine.running()) selectedTool.onClick(pos)
		}
		else if (menuManager.inInteractiveMenu(pos))
			menuManager.onClick(pos)
	}
}
