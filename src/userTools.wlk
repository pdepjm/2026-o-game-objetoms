import machines.*
import board.*
import menu.menuManager.menuManager


object toolsManager{
	// Manejar las herramientas Place, Delete y Edit
	var currentRotation = 0
	method currentRotation() = currentRotation

	var property selectedTool = place

	method rotate(){
		// al presionar la R, rotar la direccion default
		currentRotation = (currentRotation +1) %4

	}

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
		board.push(pos, machineManager.selectedMachine())
    }
}
object delete {
    method onClick(pos) {
        board.pop(pos)
    }
}
object edit {

}