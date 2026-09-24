// Traduce las entradas del usuario (clicks y teclas) a acciones del juego

import wollok.game.*
import board.*
import menu.placeMenu.*
import userTools.*
import src.directions.*

object userController {
	method setUp() {
		//hacer los bindings
		game.onClickDo({ pos => toolsManager.onClick(pos)})

		keyboard.num1().onPressDo({ => placeMenu.prev() })
		keyboard.num2().onPressDo({ => placeMenu.next() })
		keyboard.p().onPressDo({ => toolsManager.selectedTool(place)})
		keyboard.x().onPressDo({ => toolsManager.selectedTool(delete)})


		// ROTACIONES
		
		keyboard.r().onPressDo({ => toolsManager.selectedTool(rotate)})	// Rotacion una vez ya colocada

		// Rotaciones antes de colocar
		keyboard.w().onPressDo({ => toolsManager.currentDirection(up)})
		keyboard.s().onPressDo({ => toolsManager.currentDirection(down)})
		keyboard.a().onPressDo({ => toolsManager.currentDirection(left)})
		keyboard.d().onPressDo({ => toolsManager.currentDirection(right)})
	}
}