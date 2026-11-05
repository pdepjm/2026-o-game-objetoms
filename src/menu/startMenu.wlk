import wollok.game.*
import input.userController.*
import menu.menuManager.*
import menu.recipeBook.*
import tools.toolsManager.*
import simulation.simulationEngine.*
import directions.*
import sound.sfx.*

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
	var screen = "cover"
	var initialized = false

	method show() {
		screen = "cover"
		// 1. El fondo va SIEMPRE primero y no se saca nunca
		if (!game.hasVisual(menuBackground)) game.addVisual(menuBackground) 
		// 2. La portada encima
		if (!game.hasVisual(startScreen)) game.addVisual(startScreen)

		keyboard.enter().onPressDo({ self.start() })
		keyboard.i().onPressDo({ self.pressI() })
		keyboard.f().onPressDo({ self.toggleRecipeBook() })
		keyboard.right().onPressDo({ if (screen != "playing") recipeBook.nextPage() })
		keyboard.left().onPressDo({ if (screen != "playing") recipeBook.prevPage() })
		keyboard.s().onPressDo({ self.pressS() })
	}

	method start() {
		if (screen == "cover") {
			sfx.simulationStart()
			if (recipeBook.isOpen()) recipeBook.close()
			screen = "playing"
			// Al empezar a jugar, ocultamos TODO el menú (fondo incluido)
			if (game.hasVisual(startScreen)) game.removeVisual(startScreen)
			if (game.hasVisual(menuBackground)) game.removeVisual(menuBackground)
			simulationEngine.resume()
			if (!initialized) {
				initialized = true
				userController.setUp()
				menuManager.setUp()
			}
		}
	}

	method pressI() {
		if (screen == "cover") {
			sfx.menuSelect()
			self.openInstructions()
		} else if (screen == "instructions") {
			sfx.menuSelect()
			self.backToCover()
		}
	}

	method pressS() {
		if (screen == "cover") game.stop()
	}

	// Lógica para abrir/cerrar el recetario desde el menú
	method toggleRecipeBook() {
		if (screen != "playing") {
			if (!recipeBook.isOpen()) {
				// Al abrir, ocultamos la portada o los controles
				if (game.hasVisual(startScreen)) game.removeVisual(startScreen)
				if (game.hasVisual(menuControlsOverlay)) game.removeVisual(menuControlsOverlay)
				recipeBook.open()
			} else {
				// Al cerrar, volvemos a mostrar lo que estábamos viendo
				recipeBook.close()
				if (screen == "cover") game.addVisual(startScreen)
				if (screen == "instructions") game.addVisual(menuControlsOverlay)
			}
		}
	}

	method openInstructions() {
		screen = "instructions"
		if (game.hasVisual(startScreen)) game.removeVisual(startScreen)
		game.addVisual(menuControlsOverlay) 
	}

	method backToCover() {
		if (recipeBook.isOpen()) recipeBook.close()
		screen = "cover"
		simulationEngine.pause()
		if (game.hasVisual(menuControlsOverlay)) game.removeVisual(menuControlsOverlay)
		if (!game.hasVisual(startScreen)) game.addVisual(startScreen)
	}
}