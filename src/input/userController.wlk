// Traduce las entradas del usuario (clicks y teclas) a acciones del juego

import wollok.game.*
import board.*
import menu.menuManager.*
import menu.recipeBook.*
import menu.startMenu.*
import tools.toolsManager.*
import tools.userTools.*
import directions.*
import simulation.simulationEngine.*
import sound.sfx.*

object userController {
	method setUp() {
		//hacer los bindings
		game.onClickDo({ pos => toolsManager.onClick(pos)})


		// VELOCIDAD 
		keyboard.num1().onPressDo({ =>
			simulationEngine.speed(1)
			sfx.speedChange()
		})
		keyboard.num2().onPressDo({ =>
			simulationEngine.speed(2)
			sfx.speedChange()
		})
		keyboard.num3().onPressDo({ =>
			simulationEngine.speed(3)
			sfx.speedChange()
		})

		// ESPACIO: prende/apaga la simulación. Al apagarla se borran los ingredientes.
		keyboard.space().onPressDo({ => simulationEngine.toggle() })

		// PAGES
		keyboard.q().onPressDo({ => menuManager.prevPage() })
		keyboard.e().onPressDo({ => menuManager.nextPage() })

		// TOOLS
		keyboard.z().onPressDo({ => toolsManager.select(place)})
		keyboard.x().onPressDo({ => toolsManager.select(edit)})
		keyboard.c().onPressDo({ => toolsManager.select(rotate)})	// Rotacion una vez ya colocada
		keyboard.v().onPressDo({ => toolsManager.select(delete)})

		// Rotaciones antes de colocar
		keyboard.w().onPressDo({ => toolsManager.currentDirection(up)})
		keyboard.s().onPressDo({ => toolsManager.currentDirection(down)})
		keyboard.a().onPressDo({ => toolsManager.currentDirection(left)})
		keyboard.d().onPressDo({ => toolsManager.currentDirection(right)})

		// RECETARIO
		keyboard.f().onPressDo({ => recipeBook.toggle() })
		keyboard.right().onPressDo({ => recipeBook.nextPage() })
		keyboard.left().onPressDo({ => recipeBook.prevPage() })

		// MENU
		keyboard.m().onPressDo({ => startMenu.backToCover() })
	}
}
