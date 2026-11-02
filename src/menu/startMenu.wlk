import wollok.game.*
import input.userController.*
import menu.menuManager.*
import menu.recipeBookMenu.*
import tools.toolsManager.*
import simulation.simulationEngine.*
import machines.types.deliverySlot.*
import levels.levelManager.*
import directions.*

// ¡OJO ACÁ! Agregamos "menu/" al principio de la ruta.
object startScreen {
	method position() = game.origin()
	method image() = "startScreen.png" 
}

object menuControlsOverlay {
	method position() = game.origin()
	method image() = "menu/menu_controls.png" 
}

object menuBackground {
	method position() = game.origin()
	method image() = "menu/menu_background.png" 
}

object startMenu {
	// Hasta que main.wpgm llama a show(), se está jugando: así los tests, que no pasan por la portada,
	// pueden usar las teclas y los clicks del juego
	var screen = "playing"
	var initialized = false

	// ¿Se está jugando? (y no en la portada ni en las instrucciones). Mientras no, las teclas y los
	// clicks del juego no hacen nada (ver userController.whenPlaying)
	method isPlaying() = screen == "playing"

	method show() {
		screen = "cover"
		// 1. El fondo va SIEMPRE primero y no se saca nunca
		if (!game.hasVisual(menuBackground)) game.addVisual(menuBackground) 
		// 2. La portada encima
		if (!game.hasVisual(startScreen)) game.addVisual(startScreen)

		keyboard.enter().onPressDo({ self.start() })
		keyboard.i().onPressDo({ self.pressI() })
		// El libro de recetas, antes de empezar a jugar. Después lo maneja userController (F y las flechas).
		keyboard.f().onPressDo({ if (!initialized) recipeBookMenu.toggle() })
		keyboard.right().onPressDo({ if (!initialized) recipeBookMenu.nextPage() })
		keyboard.left().onPressDo({ if (!initialized) recipeBookMenu.prevPage() })
		keyboard.s().onPressDo({ self.pressS() })
	}

	method start() {
		if (screen == "cover") {
			recipeBookMenu.close()
			screen = "playing"
			// Al empezar a jugar, ocultamos TODO el menú (fondo incluido)
			if (game.hasVisual(startScreen)) game.removeVisual(startScreen)
			if (game.hasVisual(menuBackground)) game.removeVisual(menuBackground)
			simulationEngine.resume()
			// La primera vez se arma el juego: las teclas, los menús, el libro, los platitos y el primer
			// nivel (después de los menús: los usa para mostrar el catálogo y la info)
			if (!initialized) {
				initialized = true
				userController.setUp()
				menuManager.setUp()
				recipeBookMenu.setUp()
				deliveryPoints.setUp()
				levelManager.start()
			}
		}
	}

	method pressI() {
		if (screen == "cover") self.openInstructions()
		else if (screen == "instructions") self.backToCover()
	}

	method pressS() {
		if (screen == "cover") game.stop()
	}

	method openInstructions() {
		screen = "instructions"
		if (game.hasVisual(startScreen)) game.removeVisual(startScreen)
		game.addVisual(menuControlsOverlay) 
	}

	method backToCover() {
		recipeBookMenu.close()
		screen = "cover"
		simulationEngine.pause()
		if (game.hasVisual(menuControlsOverlay)) game.removeVisual(menuControlsOverlay)
		if (!game.hasVisual(startScreen)) game.addVisual(startScreen)
	}
}