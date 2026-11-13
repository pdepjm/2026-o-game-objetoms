// Buffet Albert Einstein - la portada, las instrucciones y el paso al juego.
//
// Copyright (C) 2026  grupo objeTOMs (Mateo Bustos, Carlos Aramis Chambi Flores,
// Facundo Ramounat, Federico Scalise Giussani, Mateo Silva)
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

import wollok.game.*
import input.userController.*
import menu.menuManager.*
import menu.recipeBook.*
import tools.toolsManager.*
import simulation.simulationEngine.*
import machines.types.deliverySlot.*
import levels.levelManager.*
import directions.*
import sound.sfx.*

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
	var screen = coverScreen
	var initialized = false

	method isPlaying() = screen.isPlaying()

	method show() {
		screen = coverScreen
		if (!game.hasVisual(menuBackground)) game.addVisual(menuBackground)
		if (!game.hasVisual(startScreen)) game.addVisual(startScreen)

		// Dejamos SOLO las teclas exclusivas del menú
		keyboard.enter().onPressDo({ self.start() })
		keyboard.i().onPressDo({ self.pressI() })
		keyboard.s().onPressDo({ self.pressS() })
		// (NO PONGAS F NI FLECHAS ACÁ)
	}

	// Lo que hace cada tecla depende de la pantalla en la que estemos (ver las pantallas, abajo)
	method start() { screen.start() }

	method pressI() { screen.pressI() }

	method pressS() { screen.pressS() }

	// Las pantallas le piden al menú que cambie de estado
	method play() {
		sfx.simulationStart()
		recipeBook.close()
		screen = playingScreen
		if (game.hasVisual(startScreen)) game.removeVisual(startScreen)
		if (game.hasVisual(menuBackground)) game.removeVisual(menuBackground)
		simulationEngine.resume()
		if (!initialized) {
			initialized = true
			menuManager.setUp()
			deliveryPoints.setUp()
			levelManager.start()
		}
	}

	method openInstructions() {
		sfx.menuSelect()
		screen = instructionsScreen
		if (game.hasVisual(startScreen)) game.removeVisual(startScreen)
		game.addVisual(menuControlsOverlay) 
	}

	method backToCover() {
		sfx.menuSelect()
		if (recipeBook.isOpen()) recipeBook.close()
		screen = coverScreen
		simulationEngine.pause()
		if (game.hasVisual(menuControlsOverlay)) game.removeVisual(menuControlsOverlay)
		if (!game.hasVisual(menuBackground)) game.addVisual(menuBackground) 
		if (!game.hasVisual(startScreen)) game.addVisual(startScreen)
	}

	method toggleRecipeBook() {
		if (!recipeBook.isOpen()) {
			// --- ABRIR EL LIBRO ---
			// Si estamos en el menú, la pantalla le deja lugar al libro (si se está jugando, no hace nada)
			screen.hideForRecipeBook()
			recipeBook.open()
		} else {
			// --- CERRAR EL LIBRO ---
			recipeBook.close()
			// Si estábamos en el menú, volvemos a mostrar la pantalla que correspondía
			screen.showAfterRecipeBook()
		}
	}

}

// ----------- LAS PANTALLAS DEL MENÚ -----------
// Cada pantalla sabe qué hace cada tecla y qué mostrar alrededor del libro de recetas.

// Aseguramos que el fondo azul esté siempre presente cuando se abre el libro en el menú
object menuScreenSupport {
	method ensureBackground() {
		if (!game.hasVisual(menuBackground)) game.addVisual(menuBackground)
	}
}

object coverScreen {
	method isPlaying() = false
	method start() { startMenu.play() }
	method pressI() { startMenu.openInstructions() }
	method pressS() { game.stop() }

	method hideForRecipeBook() {
		if (game.hasVisual(startScreen)) game.removeVisual(startScreen)
		menuScreenSupport.ensureBackground()
	}

	method showAfterRecipeBook() { game.addVisual(startScreen) }
}

object instructionsScreen {
	method isPlaying() = false
	method start() {}
	method pressI() { startMenu.backToCover() }
	method pressS() {}

	method hideForRecipeBook() {
		if (game.hasVisual(menuControlsOverlay)) game.removeVisual(menuControlsOverlay)
		menuScreenSupport.ensureBackground()
	}

	method showAfterRecipeBook() { game.addVisual(menuControlsOverlay) }
}

object playingScreen {
	method isPlaying() = true
	method start() {}
	method pressI() {}
	method pressS() {}
	method hideForRecipeBook() {}
	method showAfterRecipeBook() {}
}
