import machines.*
import board.*
import menu.menuManager.menuManager
import directions.*


object toolsManager{
	// Manejar las herramientas Place, Delete y Edit
	var property selectedTool = place

	// Direccion con la que se colocan las maquinas nuevas
	var property currentDirection = right

	// Metodo principal
	method onClick(pos) {
		if (board.inBoard(pos))
			selectedTool.onClick(pos)
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