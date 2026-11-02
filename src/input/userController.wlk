// Traduce las entradas del usuario (clicks y teclas) a acciones del juego

import wollok.game.*
import board.*
import menu.menuManager.*
import menu.recipeBookMenu.*
import menu.startMenu.*
import tools.toolsManager.*
import tools.userTools.*
import directions.*
import simulation.simulationEngine.*
import levels.levelManager.*

object userController {
	method setUp() {
		//hacer los bindings
		game.onClickDo({ pos => self.onClick(pos) })

		// LIBRO DE RECETAS: F abre y cierra, y las flechas pasan las recetas.
		// Es lo único que funciona con el libro abierto, y también en la portada.
		keyboard.f().onPressDo({ => recipeBookMenu.toggle() })
		keyboard.right().onPressDo({ => recipeBookMenu.nextPage() })
		keyboard.left().onPressDo({ => recipeBookMenu.prevPage() })

		// VELOCIDAD
		keyboard.num1().onPressDo({ => self.whenPlaying({ simulationEngine.speed(1) }) })
		keyboard.num2().onPressDo({ => self.whenPlaying({ simulationEngine.speed(2) }) })
		keyboard.num3().onPressDo({ => self.whenPlaying({ simulationEngine.speed(3) }) })

		// 5: prende/apaga la simulación. Al apagarla se borran los ingredientes.
		keyboard.num5().onPressDo({ => self.whenPlaying({ levelManager.toggleSimulation() }) })

		// NIVELES: siguiente (sólo después de ganar), reiniciar (borra lo construido) y modo libre
		keyboard.n().onPressDo({ => self.whenPlaying({ levelManager.loadNext() }) })
		keyboard.num0().onPressDo({ => self.whenPlaying({ levelManager.restart() }) })
		keyboard.l().onPressDo({ => self.whenPlaying({ levelManager.toggleFreePlay() }) })

		// TUTORIAL: seguir después de una explicación
		keyboard.enter().onPressDo({ => self.whenPlaying({ levelManager.continueTutorial() }) })

		// ESPACIO: prende/apaga la simulación. Al apagarla se borran los ingredientes.
		keyboard.space().onPressDo({ => self.whenPlaying({ levelManager.toggleSimulation() }) })

		// PAGES del menú de máquinas
		keyboard.q().onPressDo({ => self.whenPlaying({ menuManager.prevPage() }) })
		keyboard.e().onPressDo({ => self.whenPlaying({ menuManager.nextPage() }) })

		// TOOLS
		keyboard.z().onPressDo({ => self.whenPlaying({ toolsManager.select(place) }) })
		keyboard.x().onPressDo({ => self.whenPlaying({ toolsManager.select(edit) }) })
		keyboard.c().onPressDo({ => self.whenPlaying({ toolsManager.select(rotate) }) })	// Rotacion una vez ya colocada
		keyboard.v().onPressDo({ => self.whenPlaying({ toolsManager.select(delete) }) })

		// Rotaciones antes de colocar
		keyboard.w().onPressDo({ => self.whenPlaying({ toolsManager.currentDirection(up) }) })
		keyboard.s().onPressDo({ => self.whenPlaying({ toolsManager.currentDirection(down) }) })
		keyboard.a().onPressDo({ => self.whenPlaying({ toolsManager.currentDirection(left) }) })
		keyboard.d().onPressDo({ => self.whenPlaying({ toolsManager.currentDirection(right) }) })

		// MENU: volver a la portada
		keyboard.m().onPressDo({ => self.whenPlaying({ startMenu.backToCover() }) })
	}

	// Con el libro abierto, los clicks son del libro. Si no, y se está jugando, el icono lo abre y el
	// resto va a toolsManager. En la portada no hacen nada.
	method onClick(pos) {
		if (recipeBookMenu.isOpen()) recipeBookMenu.onClick(pos)
		else if (startMenu.isPlaying()) {
			if (recipeBookMenu.isIcon(pos)) recipeBookMenu.open() else toolsManager.onClick(pos)
		}
	}

	// Ejecuta la acción sólo si se está jugando: con el libro de recetas abierto o en la portada, el
	// juego de atrás no tiene que cambiar (por ejemplo, reiniciar el nivel con 0 sin verlo)
	method whenPlaying(action) {
		if (!recipeBookMenu.isOpen() && startMenu.isPlaying()) action.apply()
	}
}
