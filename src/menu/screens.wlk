// Buffet Albert Einstein - las pantallas del juego: qué hace cada clic y cada tecla en cada una.
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
import cellPosition.*
import menu.screenClasses.*
import menu.screenManager.*
import menu.recipeBook.*
import menu.levelComplete.*
import menu.drawing.visuals.*
import menu.hud.hud.*
import menu.hud.rightPanel.*
import menu.overBoard.tutorialGuide.*
import menu.overBoard.actionsMenu.*
import tools.toolsManager.*
import tools.userTools.*
import simulation.simulationEngine.*
import levels.levelManager.*
import board.*
import directions.*
import sound.sfx.*

// ----------- LAS PANTALLAS DEL MENÚ -----------

// Las imágenes de pantalla completa del menú
const startScreen = new Picture(image = "startScreen.png", position = new CellPosition(x = 0, y = 0))

const menuControlsOverlay = new Picture(image = "menu/menu_controls.png", position = new CellPosition(x = 0, y = 0))

const menuBackground = new Picture(image = "menu/menu_background.png", position = new CellPosition(x = 0, y = 0))

// Una pantalla del menú: el fondo azul queda siempre, también detrás del libro.
class MenuScreen inherits Screen {
	override method show() {
		menuBackground.show()
		super()
	}

	override method hideUnderOverlay() { self.hide() }
	override method showAfterOverlay() { self.show() }
}

// La portada: las opciones se eligen con un clic, o con las flechas (arriba y abajo) y Enter.
object coverScreen inherits MenuScreen {
	override method visuals() = [startScreen, coverMenu]
	override method clickableAreas() = coverMenu.options()

	override method keyActions() = [
		new KeyAction(key = "enter", action = { _ => coverMenu.activate() }),
		new KeyAction(key = "arrow", action = { direction => direction.moveCoverFocus(coverMenu) }),
		new KeyAction(key = "i", action = { _ => screenManager.openInstructions() }),
		new KeyAction(key = "s", action = { _ => game.stop() })
	]
}

// Las opciones de la portada (assets/startScreen.png), de arriba hacia abajo
object coverMenu {
	const options = [startOption, controlsOption, recipeOption, quitOption]
	var focused = 0

	method options() = options
	method focused() = focused
	method focusedOption() = options.get(focused)

	method show() {
		coverFocus.moveTo(focused)
		if (!game.hasVisual(coverFocus)) game.addVisual(coverFocus)
	}

	method hide() { if (game.hasVisual(coverFocus)) game.removeVisual(coverFocus) }

	// Arriba y abajo mueven la marca, sin pasarse de la primera ni de la última
	method move(step) {
		const next = (focused + step).max(0).min(options.size() - 1)
		if (next != focused) {
			focused = next
			coverFocus.moveTo(focused)
			sfx.directionChange()
		}
	}

	method activate() { self.focusedOption().choose() }
}

// Una opción de la portada: un lugar que se clickea (su zona) y lo que hace al elegirla
class CoverOption {
	const zone

	method handlesClick(pos) = zone.contains(pos)
	method onClick(pos) { self.choose() }
	method choose()
}

object startOption inherits CoverOption(zone = rectangle.of(7, 6, 8, 2)) {
	override method choose() { screenManager.play() }
}
object controlsOption inherits CoverOption(zone = rectangle.of(7, 4, 8, 2)) {
	override method choose() { screenManager.openInstructions() }
}
object recipeOption inherits CoverOption(zone = rectangle.of(7, 3, 8, 1)) {
	override method choose() { screenManager.openBook() }
}
object quitOption inherits CoverOption(zone = rectangle.of(7, 1, 8, 2)) {
	override method choose() { game.stop() }
}

// El recuadro de la opción marcada.
object coverFocus {
	const positions = [5.96, 4.4, 3.04, 1.48].map({ y => new CellPosition(x = 6.6, y = y) })
	var position = positions.first()

	method position() = position
	method image() = "menu/cover_focus.png"
	method moveTo(index) { position = positions.get(index) }
}

// Los controles: I, Retroceso, Enter o un clic en "volver al menú" (la fila de abajo) vuelven a la portada
object instructionsScreen inherits MenuScreen {
	const backButton = new CellArea(zone = rectangle.of(0, 0, 22, 1), action = { screenManager.backToCover() })

	override method visuals() = [menuControlsOverlay]
	override method clickableAreas() = [backButton]

	override method keyActions() = ["enter", "back", "i"].map({ key => new KeyAction(key = key, action = { _ => screenManager.backToCover() }) })
}

// ----------- JUGANDO -----------

// Los clics van por capas, de la que se ve más arriba a la de más abajo
object playingScreen inherits Screen {
	override method clickableAreas() = [chefBubble, actionsMenu] + hud.clickableAreas() + [boardArea]

	override method keyActions() = [
		new KeyAction(key = "enter", action = { _ => self.enter() }),
		new KeyAction(key = "arrow", action = { direction => toolsManager.arrow(direction) }),
		new KeyAction(key = "back", action = { _ => toolsManager.stopEditing() }),
		// S es mirar hacia abajo, como W, A y D (en la portada, S es salir)
		new KeyAction(key = "s", action = { _ => toolsManager.currentDirection(down) }),
		new KeyAction(key = "direction", action = { direction => toolsManager.currentDirection(direction) }),
		new KeyAction(key = "speed", action = { n => sideButtons.speed(n) }),
		new KeyAction(key = "simulation", action = { _ => levelManager.toggleSimulation() }),
		new KeyAction(key = "nextLevel", action = { _ => levelManager.loadNext() }),
		new KeyAction(key = "restart", action = { _ => levelManager.restart() }),
		new KeyAction(key = "freePlay", action = { _ => levelManager.toggleFreePlay() }),
		new KeyAction(key = "skipTutorial", action = { _ => levelManager.skipTutorial() }),
		new KeyAction(key = "chooseMachine", action = { step => rightPanel.chooseMachine(step) }),
		new KeyAction(key = "rotate", action = { _ => toolsManager.act(rotate) }),
		new KeyAction(key = "edit", action = { _ => toolsManager.editKey() }),
		new KeyAction(key = "delete", action = { _ => toolsManager.act(delete) }),
		new KeyAction(key = "menu", action = { _ => screenManager.backToCover() })
	]

	// El HUD queda dibujado al volver a la portada (lo tapa el fondo del menú)
	override method show() {
		menuBackground.hide()
		hud.show()
		simulationEngine.resume()
	}

	override method hide() { simulationEngine.pause() }

	// Enter sigue el tutorial si el cocinero espera, si no es para las herramientas
	method enter() {
		if (levelManager.tutorial().waitsForContinue()) levelManager.continueTutorial()
		else toolsManager.enter()
	}
}

// El tablero, como zona clickeable de playingScreen
object boardArea {
	method handlesClick(pos) = board.inBoard(pos)
	method onClick(pos) { toolsManager.clickCell(pos) }
}

// ----------- EL RECETARIO (encima de otra pantalla) -----------

// Con el libro abierto no se juega: tapa todo.
object bookScreen inherits OverlayScreen {
	const closeButton = new CellArea(zone = rectangle.of(19, 10, 2, 2), action = { screenManager.closeBook() })
	const leftHalf = new CellArea(zone = rectangle.of(0, 0, 11, 13), action = { recipeBook.prevPage() })
	const rightHalf = new CellArea(zone = rectangle.of(11, 0, 11, 13), action = { recipeBook.nextPage() })

	override method clickableAreas() = [closeButton, leftHalf, rightHalf]

	override method keyActions() = [
		new KeyAction(key = "arrow", action = { direction => direction.turnPage(recipeBook) }),
		new KeyAction(key = "back", action = { _ => screenManager.closeBook() }),
		new KeyAction(key = "book", action = { _ => screenManager.closeBook() })
	]

	override method show() { recipeBook.open() }
	override method hide() { recipeBook.close() }
}

// ----------- EL TICKET DE NIVEL COMPLETO (encima del juego) -----------

// Mientras se ve, sólo cuentan sus botones (el resto de los clics no hace nada).
object levelCompleteScreen inherits OverlayScreen {
	override method clickableAreas() = levelComplete.buttons()

	override method keyActions() = [
		new KeyAction(key = "enter", action = { _ => levelComplete.pressFirstButton() }),
		new KeyAction(key = "nextLevel", action = { _ => self.nextLevel() }),
		new KeyAction(key = "restart", action = { _ => self.restart() }),
		new KeyAction(key = "menu", action = { _ => self.backToMenu() })
	]

	// Lo dibuja screenManager.showLevelComplete, que sabe qué decir
	override method hide() { levelComplete.hide() }

	method nextLevel() {
		screenManager.uncover()
		levelManager.loadNext()
	}

	method restart() {
		screenManager.uncover()
		levelManager.restart()
	}

	method backToMenu() { screenManager.backToCover() }
}
