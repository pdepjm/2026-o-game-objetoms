// Traduce las entradas del usuario (clicks y teclas) a acciones del juego

import wollok.game.*
import board.*
import menu.placeMenu.*
import userTools.*

object userController {
	method setUp() {
		//hacer los bindings
		game.onClickDo({ pos => toolsManager.onClick(pos)})

		keyboard.a().onPressDo({ => placeMenu.prev() })
		keyboard.s().onPressDo({ => placeMenu.next() })
		keyboard.r().onPressDo({ => toolsManager.rotate()})
		keyboard.p().onPressDo({ => toolsManager.selectedTool(place)})
		keyboard.d().onPressDo({ => toolsManager.selectedTool(delete)})
	}
}