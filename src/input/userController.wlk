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
import levels.levelManager.*
import menu.levelInfoMenu.*

object userController {
	method setUp() {
		game.onClickDo({ pos => self.onClick(pos) })

		// --- RECETARIO (Global: anda en menú y en juego) ---
		// Al no tener whenPlaying, funcionan siempre. Y como están en setUp(),
		// solo se bindean UNA vez, evitando el problema de la doble ejecución.
		keyboard.f().onPressDo({ => startMenu.toggleRecipeBook() })
		keyboard.right().onPressDo({ => recipeBook.nextPage() })
		keyboard.left().onPressDo({ => recipeBook.prevPage() })

		// --- TECLAS DEL JUEGO (Protegidas) ---
		keyboard.num1().onPressDo({ => self.whenPlaying({ simulationEngine.speed(1) }) })
		keyboard.num2().onPressDo({ => self.whenPlaying({ simulationEngine.speed(2) }) })
		keyboard.num3().onPressDo({ => self.whenPlaying({ simulationEngine.speed(3) }) })
		keyboard.space().onPressDo({ => self.whenPlaying({ levelManager.toggleSimulation() }) })
		keyboard.num5().onPressDo({ => self.whenPlaying({ levelManager.toggleSimulation() }) })

		keyboard.n().onPressDo({ => self.whenPlaying({ levelManager.loadNext() }) })
		keyboard.num0().onPressDo({ => self.whenPlaying({ levelManager.restart() }) })
		keyboard.l().onPressDo({ => self.whenPlaying({ levelManager.toggleFreePlay() }) })

		keyboard.enter().onPressDo({ => self.whenPlaying({ levelManager.continueTutorial() }) })
		keyboard.t().onPressDo({ => self.whenPlaying({ levelManager.skipTutorial() }) })

		keyboard.q().onPressDo({ => self.whenPlaying({ menuManager.prevPage() }) })
		keyboard.e().onPressDo({ => self.whenPlaying({ menuManager.nextPage() }) })

		keyboard.z().onPressDo({ => self.whenPlaying({ toolsManager.select(place) }) })
		keyboard.x().onPressDo({ => self.whenPlaying({ toolsManager.select(edit) }) })
		keyboard.c().onPressDo({ => self.whenPlaying({ toolsManager.select(rotate) }) })
		keyboard.v().onPressDo({ => self.whenPlaying({ toolsManager.select(delete) }) })

		keyboard.w().onPressDo({ => self.whenPlaying({ toolsManager.currentDirection(up) }) })
		keyboard.s().onPressDo({ => self.whenPlaying({ toolsManager.currentDirection(down) }) })
		keyboard.a().onPressDo({ => self.whenPlaying({ toolsManager.currentDirection(left) }) })
		keyboard.d().onPressDo({ => self.whenPlaying({ toolsManager.currentDirection(right) }) })

		keyboard.m().onPressDo({ => self.whenPlaying({ startMenu.backToCover() }) })
	}

	method onClick(pos) {
		if (recipeBook.isOpen()) {
			// Si querés que la X del libro funcione por click, iría acá
		} else if (startMenu.isPlaying()) {
			toolsManager.onClick(pos) // (o levelInfoMenu.isSkipButton como tenía tu amigo)
		}
	}

	method whenPlaying(action) {
		if (!recipeBook.isOpen() && startMenu.isPlaying()) action.apply()
	}
}