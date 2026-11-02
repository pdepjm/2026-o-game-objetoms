// Traduce las entradas del usuario (clicks y teclas) a acciones del juego

import wollok.game.*
import board.*
import menu.menuManager.*
import menu.recipeBookMenu.*
import tools.toolsManager.*
import tools.userTools.*
import directions.*
import simulation.simulationEngine.*
import levels.levelManager.*

object userController {
	method setUp() {
		//hacer los bindings
		game.onClickDo({ pos => self.onClick(pos) })

		// LIBRO DE RECETAS: abre y cierra. Es lo único que funciona con el libro abierto (además de Q y E)
		keyboard.f().onPressDo({ => recipeBookMenu.toggle() })

		// VELOCIDAD
		keyboard.num1().onPressDo({ => self.unlessBookOpen({ simulationEngine.speed(1) }) })
		keyboard.num2().onPressDo({ => self.unlessBookOpen({ simulationEngine.speed(2) }) })
		keyboard.num3().onPressDo({ => self.unlessBookOpen({ simulationEngine.speed(3) }) })

		// 5: prende/apaga la simulación. Al apagarla se borran los ingredientes.
		keyboard.num5().onPressDo({ => self.unlessBookOpen({ levelManager.toggleSimulation() }) })

		// NIVELES: siguiente (sólo después de ganar), reiniciar (borra lo construido) y modo libre
		keyboard.n().onPressDo({ => self.unlessBookOpen({ levelManager.loadNext() }) })
		keyboard.num0().onPressDo({ => self.unlessBookOpen({ levelManager.restart() }) })
		keyboard.l().onPressDo({ => self.unlessBookOpen({ levelManager.toggleFreePlay() }) })

		// TUTORIAL: seguir después de una explicación
		keyboard.enter().onPressDo({ => self.unlessBookOpen({ levelManager.continueTutorial() }) })

		// ESPACIO: prende/apaga la simulación. Al apagarla se borran los ingredientes.
		keyboard.space().onPressDo({ => self.unlessBookOpen({ levelManager.toggleSimulation() }) })

		// PAGES: las del libro de recetas si está abierto, si no las del menú de máquinas
		keyboard.q().onPressDo({ => self.prevPage() })
		keyboard.e().onPressDo({ => self.nextPage() })

		// TOOLS
		keyboard.z().onPressDo({ => self.unlessBookOpen({ toolsManager.select(place) }) })
		keyboard.x().onPressDo({ => self.unlessBookOpen({ toolsManager.select(edit) }) })
		keyboard.c().onPressDo({ => self.unlessBookOpen({ toolsManager.select(rotate) }) })	// Rotacion una vez ya colocada
		keyboard.v().onPressDo({ => self.unlessBookOpen({ toolsManager.select(delete) }) })

		// Rotaciones antes de colocar
		keyboard.w().onPressDo({ => self.unlessBookOpen({ toolsManager.currentDirection(up) }) })
		keyboard.s().onPressDo({ => self.unlessBookOpen({ toolsManager.currentDirection(down) }) })
		keyboard.a().onPressDo({ => self.unlessBookOpen({ toolsManager.currentDirection(left) }) })
		keyboard.d().onPressDo({ => self.unlessBookOpen({ toolsManager.currentDirection(right) }) })
	}

	// Con el libro abierto, los clicks son del libro. Si no, el icono lo abre, y el resto va a toolsManager.
	method onClick(pos) {
		if (recipeBookMenu.isOpen()) recipeBookMenu.onClick(pos)
		else if (recipeBookMenu.isIcon(pos)) recipeBookMenu.open()
		else toolsManager.onClick(pos)
	}

	method prevPage() {
		if (recipeBookMenu.isOpen()) recipeBookMenu.prevPage() else menuManager.prevPage()
	}

	method nextPage() {
		if (recipeBookMenu.isOpen()) recipeBookMenu.nextPage() else menuManager.nextPage()
	}

	// Ejecuta la acción sólo si el libro de recetas está cerrado: con el libro abierto, el juego
	// de atrás no tiene que cambiar (por ejemplo, reiniciar el nivel con 0 sin verlo)
	method unlessBookOpen(action) {
		if (!recipeBookMenu.isOpen()) action.apply()
	}
}
