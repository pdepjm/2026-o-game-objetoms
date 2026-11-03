import board.*
import menu.menuManager.*
import directions.*
import simulation.simulationEngine.*
import tools.userTools.*
import levels.levelManager.*

object toolsManager{
	// Manejar las herramientas Place, Delete, Edit y Rotate
	// Arranca sin ninguna herramienta elegida (null): hay que elegir una con P, Z, X o R
	var selectedTool = null

	method selectedTool() = selectedTool

	// Único punto de entrada para cambiar de herramienta (teclas de userController).
	// Los menús se enteran por menuManager.
	method select(tool) {
		if (tool != selectedTool)
			selectedTool = tool
		else
			selectedTool = null
		menuManager.toolChanged(selectedTool)
		levelManager.toolSelected(selectedTool)
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
	// Con la simulación prendida no se puede colocar, borrar ni rotar nada.
	// El tutorial del nivel puede no dejar usar la herramienta en esa celda.
	method onClick(pos) {
		if (board.inBoard(pos)) {
			if (selectedTool != null && !simulationEngine.running() && levelManager.allowsTool(selectedTool, pos)) selectedTool.onClick(pos)
		}
		else if (menuManager.inInteractiveMenu(pos))
			menuManager.onClick(pos)
	}

	method reset() {
		selectedTool = null
		currentDirection = right
		menuManager.toolChanged(null)
		menuManager.directionChanged()
	}
}
