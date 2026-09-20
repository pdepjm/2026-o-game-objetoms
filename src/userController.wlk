// Traduce las entradas del usuario (clicks y teclas) a acciones del juego

import wollok.game.*
import tablero.*
import menu.*
import maquinas.*

object userController {

	

	method configurar() {
		//hacer los bindings
		game.onClickDo({ pos => clickManager.clickHandler(pos) })

		keyboard.a().onPressDo({ => menu.prev() })
		keyboard.s().onPressDo({ => menu.next() })
		keyboard.r().onPressDo({ => Tools.rotate()})
		keyboard.p().onPressDo({ => Tools.selectPlace()})
		keyboard.d().onPressDo({ => Tools.selectDelete()})
	}
}

object clickManager {
	// Que hay que hacer en caso de que se haga click en una determinada parte de la pantalla
	method clickHandler(pos){

		// obetener herramienta activa
		const selectedTool = Tools.selectedTool()

		if(selectedTool == "place"){

			if (pos.x().between(21, 24)){
				// Se hizo click en el menú
				MachineManager.chooseMachine(pos)

			}else{
				tablero.colocar(pos, MachineManager.selectedTool())
			}
		}

		if (selectedTool == "delete"){
			tablero.quitar(pos)
		}
	}


}


object Tools{
	// Manejar las herramientas Place, Delete y Edit

	var currentRotation = 0
	method currentRotation() = currentRotation

	var property selectedTool = "place"

	method rotate(){
		// al presionar la R, rotar la direccion default
		currentRotation = (currentRotation +1) %4

	}
	method selectPlace(){
		self.selectedTool("place")

	}
	method selectDelete(){
		self.selectedTool("delete")
	}

	method selectEdit(){
		self.selectedTool("edit")
	}

}