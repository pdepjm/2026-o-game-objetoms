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
import menu.hud.*
import menu.levelInfoMenu.*
import menu.tutorialGuide.*
import menu.levelComplete.*
import menu.visuals.*

// Las imágenes de pantalla completa del menú
object startScreen inherits Picture(image = "startScreen.png", position = new CellPosition(x = 0, y = 0)) {}

object menuControlsOverlay inherits Picture(image = "menu/menu_controls.png", position = new CellPosition(x = 0, y = 0)) {}

object menuBackground inherits Picture(image = "menu/menu_background.png", position = new CellPosition(x = 0, y = 0)) {}

object startMenu {
	var screen = coverScreen
	var initialized = false

	// Los clicks y las teclas del juego los resuelve la pantalla activa: la del libro si está abierto, y si no, la del menú
	method onClick(pos) { recipeBook.screenOver(screen).onClick(pos) }

	method whenPlaying(action) { recipeBook.screenOver(screen).whenPlaying(action) }

	method show() {
		screen = coverScreen
		menuBackground.show()
		startScreen.show()
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
		startScreen.hide()
		menuBackground.hide()
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
		startScreen.hide()
		coverMenu.hide()
		menuControlsOverlay.show()
	}

	method backToCover() {
		sfx.menuSelect()
		recipeBook.close()
		screen = coverScreen
		simulationEngine.pause()
		menuControlsOverlay.hide()
		menuBackground.show()
		startScreen.show()
		coverMenu.show()
	}

	// El libro se abre sobre la pantalla actual: ella se oculta al abrirlo y se vuelve a mostrar al cerrarlo
	method toggleRecipeBook() { recipeBook.toggleOver(screen) }

}

// ----------- LAS PANTALLAS DEL MENÚ -----------
// Cada pantalla sabe qué hace cada tecla y qué mostrar alrededor del libro de recetas.

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

	// El fondo azul queda detrás del libro
	method hideForRecipeBook() {
		startScreen.hide()
		coverMenu.hide()
		menuBackground.show()
	}

	method showAfterRecipeBook() {
		startScreen.show()
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
		menuControlsOverlay.hide()
		menuBackground.show()
	}

	method showAfterRecipeBook() { menuControlsOverlay.show() }
}

// Jugando: cada clic es del primero que lo quiere (handlesClick), en este orden: la comanda del nivel
// completo (mientras se ve, todos son suyos), los botones de abajo a la izquierda, el de saltear el
// tutorial, el globo del cocinero y, si no, toolsManager (el tablero y el panel de la derecha).
// Enter sigue el tutorial si está esperando que lo lea; si no, aplica la opción marcada si está editando.
// En el tablero se usa sólo el mouse: las flechas sólo eligen opciones del panel de editar. Retroceso deja
// de editar.
object playingScreen {
	const clickTargets = [levelComplete, sideButtons, skipTutorialButton, chefBubble, toolsManager]

	method onClick(pos) {
		clickTargets.find({ target => target.handlesClick(pos) }).onClick(pos)
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

// El botón de saltear el tutorial, en la info del nivel (ver levelInfoMenu)
object skipTutorialButton {
	method handlesClick(pos) = levelInfoMenu.isSkipButton(pos)
	method onClick(pos) { levelManager.skipTutorial() }
}

// Mientras el cocinero explica algo y espera que el jugador siga, tocar su globo es seguir (como Enter)
object chefBubble {
	method handlesClick(pos) = levelManager.tutorial().waitsForContinue() && chefGuide.bubbleContains(pos)
	method onClick(pos) { levelManager.continueTutorial() }
}
