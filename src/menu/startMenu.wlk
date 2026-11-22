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
import cellPosition.*
import menu.sideButtons.*
import menu.levelInfoMenu.*
import menu.chefGuide.*

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

	// Los clicks y las teclas del juego los resuelve la pantalla activa: la del libro si está abierto, y si no, la del menú
	method onClick(pos) { recipeBook.screenOver(screen).onClick(pos) }

	method whenPlaying(action) { recipeBook.screenOver(screen).whenPlaying(action) }

	method show() {
		screen = coverScreen
		if (!game.hasVisual(menuBackground)) game.addVisual(menuBackground)
		if (!game.hasVisual(startScreen)) game.addVisual(startScreen)
		coverMenu.show()

		// Dejamos SOLO las teclas exclusivas del menú
		keyboard.enter().onPressDo({ self.start() })
		keyboard.i().onPressDo({ self.pressI() })
		keyboard.s().onPressDo({ self.pressS() })
		// (NO PONGAS F NI FLECHAS ACÁ: están en userController)
	}

	// Lo que hace cada tecla depende de la pantalla en la que estemos (ver las pantallas, abajo).
	// Enter, las flechas y Retroceso también le llegan al libro si está abierto (screenOver).
	method start() { recipeBook.screenOver(screen).start() }

	method arrow(direction) { recipeBook.screenOver(screen).arrow(direction) }

	method back() { recipeBook.screenOver(screen).back() }

	method pressI() { screen.pressI() }

	method pressS() { screen.pressS() }

	// Las pantallas le piden al menú que cambie de estado
	method play() {
		sfx.simulationStart()
		recipeBook.close()
		screen = playingScreen
		if (game.hasVisual(startScreen)) game.removeVisual(startScreen)
		if (game.hasVisual(menuBackground)) game.removeVisual(menuBackground)
		coverMenu.hide()
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
		coverMenu.hide()
		game.addVisual(menuControlsOverlay) 
	}

	method backToCover() {
		sfx.menuSelect()
		recipeBook.close()
		screen = coverScreen
		simulationEngine.pause()
		if (game.hasVisual(menuControlsOverlay)) game.removeVisual(menuControlsOverlay)
		if (!game.hasVisual(menuBackground)) game.addVisual(menuBackground) 
		if (!game.hasVisual(startScreen)) game.addVisual(startScreen)
		coverMenu.show()
	}

	// El libro se abre sobre la pantalla actual: ella se oculta al abrirlo y se vuelve a mostrar al cerrarlo
	method toggleRecipeBook() { recipeBook.toggleOver(screen) }

}

// ----------- LAS PANTALLAS DEL MENÚ -----------
// Cada pantalla sabe qué hace cada tecla y qué mostrar alrededor del libro de recetas.

// Aseguramos que el fondo azul esté siempre presente cuando se abre el libro en el menú
object menuScreenSupport {
	method ensureBackground() {
		if (!game.hasVisual(menuBackground)) game.addVisual(menuBackground)
	}
}

// La portada: las opciones se eligen con un clic, o con las flechas (arriba y abajo) y Enter.
// I, F y S siguen siendo atajos de CONTROLES, RECETARIO y SALIR.
object coverScreen {
	method onClick(pos) { coverMenu.clickAt(pos) }
	method whenPlaying(action) {}
	method start() { coverMenu.activate() }
	method arrow(direction) { direction.moveCoverFocus(coverMenu) }
	method back() {}
	method pressI() { startMenu.openInstructions() }
	method pressS() { game.stop() }

	method hideForRecipeBook() {
		if (game.hasVisual(startScreen)) game.removeVisual(startScreen)
		coverMenu.hide()
		menuScreenSupport.ensureBackground()
	}

	method showAfterRecipeBook() {
		game.addVisual(startScreen)
		coverMenu.show()
	}
}

// Las opciones de la portada (assets/startScreen.png, ver assets/makeCover.py), de arriba hacia abajo, y la
// marcada para el teclado (con un recuadro amarillo: coverFocus). Cada opción ocupa unas filas del cartel
// (Wollok avisa el clic por celda): INICIAR 6 y 7, CONTROLES 4 y 5, RECETARIO 3, SALIR 1 y 2.
object coverMenu {
	const options = [startOption, controlsOption, recipeOption, quitOption]
	var focused = 0

	method focused() = focused
	method focusedOption() = options.get(focused)

	method show() {
		coverFocus.moveTo(focused)
		if (!game.hasVisual(coverFocus)) game.addVisual(coverFocus)
	}

	method hide() { if (game.hasVisual(coverFocus)) game.removeVisual(coverFocus) }

	// Arriba y abajo mueven la marca, sin pasarse de la primera ni de la última (ver moveCoverFocus)
	method move(step) {
		const next = (focused + step).max(0).min(options.size() - 1)
		if (next != focused) {
			focused = next
			coverFocus.moveTo(focused)
			sfx.directionChange()
		}
	}

	method activate() { self.focusedOption().choose() }

	method clickAt(pos) {
		if (pos.x().between(7, 14)) options.findOrDefault({ each => each.rows().contains(pos.y()) }, noOption).choose()
	}
}

object startOption {
	method rows() = [6, 7]
	method choose() { startMenu.play() }
}
object controlsOption {
	method rows() = [4, 5]
	method choose() { startMenu.openInstructions() }
}
object recipeOption {
	method rows() = [3]
	method choose() { startMenu.toggleRecipeBook() }
}
object quitOption {
	method rows() = [1, 2]
	method choose() { game.stop() }
}
object noOption {
	method choose() {}
}

// El recuadro de la opción marcada. Las posiciones se arman una vez (van entre celdas).
object coverFocus {
	const positions = [5.96, 4.4, 3.04, 1.48].map({ y => new CellPosition(x = 6.6, y = y) })
	var position = positions.first()

	method position() = position
	method image() = "menu/cover_focus.png"
	method moveTo(index) { position = positions.get(index) }
}

// Los controles: I, Retroceso, Enter o un clic en "volver al menú" (la fila de abajo) vuelven a la portada
object instructionsScreen {
	method onClick(pos) { if (pos.y() == 0) startMenu.backToCover() }
	method whenPlaying(action) {}
	method start() { startMenu.backToCover() }
	method arrow(direction) {}
	method back() { startMenu.backToCover() }
	method pressI() { startMenu.backToCover() }
	method pressS() {}

	method hideForRecipeBook() {
		if (game.hasVisual(menuControlsOverlay)) game.removeVisual(menuControlsOverlay)
		menuScreenSupport.ensureBackground()
	}

	method showAfterRecipeBook() { game.addVisual(menuControlsOverlay) }
}

// Jugando: los botones de abajo a la izquierda, el de saltear el tutorial, el globo del cocinero, y el
// resto va a toolsManager.
// Enter sigue el tutorial si está esperando que lo lea; si no, aplica la opción marcada si está editando.
// En el tablero se usa sólo el mouse: las flechas sólo eligen opciones del panel de editar. Retroceso deja
// de editar.
object playingScreen {
	// Mientras el cocinero explica, tocar su globo es seguir (como Enter)
	method onClick(pos) {
		if (sideButtons.contains(pos)) sideButtons.onClick(pos)
		else if (levelInfoMenu.isSkipButton(pos)) levelManager.skipTutorial()
		else if (levelManager.tutorial().waitsForContinue() && chefGuide.bubbleContains(pos)) levelManager.continueTutorial()
		else toolsManager.onClick(pos)
	}
	method whenPlaying(action) { action.apply() }
	method start() {
		if (levelManager.tutorial().waitsForContinue()) levelManager.continueTutorial()
		else toolsManager.enter()
	}
	method arrow(direction) { toolsManager.arrow(direction) }
	method back() { toolsManager.stopEditing() }
	method pressI() {}
	method pressS() {}
	method hideForRecipeBook() {}
	method showAfterRecipeBook() {}
}
