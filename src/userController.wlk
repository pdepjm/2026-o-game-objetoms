// Traduce las entradas del usuario (clicks y teclas) a acciones del juego

import wollok.game.*
import board.*
import menu.placeMenu.*
import userTools.*
import src.directions.*
import src.simulationEngine.*

object userController {
	method setUp() {
		//hacer los bindings
		game.onClickDo({ pos => toolsManager.onClick(pos)})


		keyboard.num1().onPressDo({ => simulationEngine.speed(1)})
		keyboard.num2().onPressDo({ => simulationEngine.speed(2) })
		keyboard.num3().onPressDo({ => simulationEngine.speed(3) })

		keyboard.q().onPressDo({ => placeMenu.prev() })
		keyboard.e().onPressDo({ => placeMenu.next() })
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