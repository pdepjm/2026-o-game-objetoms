// Traduce las entradas del usuario (clicks y teclas) a acciones del juego

import wollok.game.*
import tablero.*
import menu.*

object userController {
	method configurar() {
		game.onClickDo({ pos => clickManager.clickHandler(pos) })
		game.onDoubleClickDo({ pos => clickManager.doubleClickHandler(pos) })

		keyboard.a().onPressDo({ => menu.prev() })
		keyboard.s().onPressDo({ => menu.next() })
		keyboard.r().onPressDo({ => toolManager.rotar() })
	}
}

object clickManager {
	// Que hay que hacer en caso de que se haga click en una determinada parte de la pantalla
	method clickHandler(pos){
		if (pos.x().between(21, 24)){
			// Se hizo click en el menú
			toolManager.chooseTool(pos)

		}else{
			orquestador.colocar(pos, toolManager.selectedTool())
		}
	}

	// Manejador del doble click
	method doubleClickHandler(pos){
		orquestador.quitar(pos)
	}
}
