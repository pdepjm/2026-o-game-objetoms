// Traduce las entradas del usuario (clicks y teclas) a acciones del juego

import wollok.game.*
import board.*
import menu.menuManager.*
import tools.toolsManager.*
import tools.userTools.*
import directions.*
import simulation.simulationEngine.*
import levels.levelManager.*

object userController {
	method setUp() {
		//hacer los bindings
		game.onClickDo({ pos => toolsManager.onClick(pos)})


		// VELOCIDAD 
		keyboard.num1().onPressDo({ => simulationEngine.speed(1)})
		keyboard.num2().onPressDo({ => simulationEngine.speed(2) })
		keyboard.num3().onPressDo({ => simulationEngine.speed(3) })

		// 5: prende/apaga la simulación. Al apagarla se borran los ingredientes.
		keyboard.num5().onPressDo({ => levelManager.toggleSimulation() })

		// NIVELES: siguiente (sólo después de ganar), reiniciar (borra lo construido) y modo libre
		keyboard.n().onPressDo({ => levelManager.loadNext() })
		keyboard.num0().onPressDo({ => levelManager.restart() })
		keyboard.l().onPressDo({ => levelManager.loadFreePlay() })
		
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
	}
}
