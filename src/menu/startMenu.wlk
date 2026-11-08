import wollok.game.*
import input.userController.*
import menu.menuManager.*
import menu.recipeBook.*
import tools.toolsManager.*
import simulation.simulationEngine.*
import machines.types.deliverySlot.*
import levels.levelManager.*
import directions.*

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

	method isPlaying() = screen == "playing"

	method show() {
		screen = "cover"
		if (!game.hasVisual(menuBackground)) game.addVisual(menuBackground)
		if (!game.hasVisual(startScreen)) game.addVisual(startScreen)

		// Dejamos SOLO las teclas exclusivas del menú
		keyboard.enter().onPressDo({ self.start() })
		keyboard.i().onPressDo({ self.pressI() })
		keyboard.s().onPressDo({ self.pressS() })
		// (NO PONGAS F NI FLECHAS ACÁ)
	}

	method start() {
		if (screen == "cover") {
			recipeBook.close()
			screen = "playing"
			if (game.hasVisual(startScreen)) game.removeVisual(startScreen)
			if (game.hasVisual(menuBackground)) game.removeVisual(menuBackground)
			simulationEngine.resume()
			if (!initialized) {
				initialized = true
				menuManager.setUp()
				// AGREGÁ ESTAS DOS LÍNEAS QUE FALTABAN:
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
		if (recipeBook.isOpen()) recipeBook.close()
		screen = "cover"
		simulationEngine.pause()
		if (game.hasVisual(menuControlsOverlay)) game.removeVisual(menuControlsOverlay)
		if (!game.hasVisual(menuBackground)) game.addVisual(menuBackground) 
		if (!game.hasVisual(startScreen)) game.addVisual(startScreen)
	}

	method toggleRecipeBook() {
		if (!recipeBook.isOpen()) {
			// --- ABRIR EL LIBRO ---
			// Si no estamos jugando (estamos en el menú), ocultamos la portada o los controles
			if (!self.isPlaying()) {
				if (game.hasVisual(startScreen)) game.removeVisual(startScreen)
				if (game.hasVisual(menuControlsOverlay)) game.removeVisual(menuControlsOverlay)
				// Aseguramos que el fondo azul esté siempre presente
				if (!game.hasVisual(menuBackground)) game.addVisual(menuBackground)
			}
			recipeBook.open()
		} else {
			// --- CERRAR EL LIBRO ---
			recipeBook.close()
			// Si estábamos en el menú, volvemos a mostrar la pantalla que correspondía
			if (!self.isPlaying()) {
				if (screen == "cover") game.addVisual(startScreen)
				if (screen == "instructions") game.addVisual(menuControlsOverlay)
			}
		}
	}

}