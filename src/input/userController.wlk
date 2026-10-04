// Traduce las entradas del usuario (clicks y teclas) a acciones del juego

import wollok.game.*
import board.*
import menu.menuManager.*
import tools.toolsManager.*
import tools.userTools.*
import directions.*
import simulation.simulationEngine.*
import stressTest.stressMeter.*
import stressTest.stressTestBoard.*

object userController {
	method setUp() {
		//hacer los bindings
		game.onClickDo({ pos => toolsManager.onClick(pos)})


		keyboard.num1().onPressDo({ => simulationEngine.speed(1)})
		keyboard.num2().onPressDo({ => simulationEngine.speed(2) })
		keyboard.num3().onPressDo({ => simulationEngine.speed(3) })

		// 5: prende/apaga la simulación. Al apagarla se borran los ingredientes.
		keyboard.num5().onPressDo({ => simulationEngine.toggle() })

		// PRUEBAS DE CARGA (ver la carpeta stressTest)
		// M: medidor de carga, escribe en la terminal cuánto tarda cada tick
		keyboard.m().onPressDo({ => stressMeter.toggle() })
		// L: llena el tablero con una serpiente de cintas
		keyboard.l().onPressDo({ => stressTestBoard.fill() })

		keyboard.q().onPressDo({ => menuManager.prevPage() })
		keyboard.e().onPressDo({ => menuManager.nextPage() })
		keyboard.p().onPressDo({ => toolsManager.select(place)})
		keyboard.x().onPressDo({ => toolsManager.select(delete)})
		keyboard.z().onPressDo({ => toolsManager.select(edit)})

		// ROTACIONES

		keyboard.r().onPressDo({ => toolsManager.select(rotate)})	// Rotacion una vez ya colocada

		// Rotaciones antes de colocar
		keyboard.w().onPressDo({ => toolsManager.currentDirection(up)})
		keyboard.s().onPressDo({ => toolsManager.currentDirection(down)})
		keyboard.a().onPressDo({ => toolsManager.currentDirection(left)})
		keyboard.d().onPressDo({ => toolsManager.currentDirection(right)})
	}
}
