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
import input.clickManager.*
import menu.screenManager.*
import menu.recipeBook.*
import menu.levelComplete.*
import menu.drawing.visuals.*
import menu.hud.hud.*
import menu.hud.levelInfoMenu.*
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

// Lo que entiende cualquier pantalla.
class Screen inherits ClickTargets {
	// Una pantalla recibe todos los clics
	override method zones() = [wholeScreen]

	// Al entrar y al salir (screenManager.changeScreen)
	method show() {}
	method hide() {}
	method leave() { self.hide() }

	// Cuando se abre o se cierra encima el libro o el ticket (screenManager.cover y uncover)
	method hideUnderOverlay() {}
	method showAfterOverlay() {}

	// Las teclas del menú
	method enter() {}
	method arrow(direction) {}
	method back() {}
	method toggleBook() { screenManager.openBook() }
	method pressI() {}
	method pressS() {}

	// Las teclas del juego
	method speed(n) {}
	method toggleSimulation() {}
	method nextLevel() {}
	method restart() {}
	method toggleFreePlay() {}
	method skipTutorial() {}
	method chooseMachine(step) {}
	method rotateMachine() {}
	method editMachine() {}
	method deleteMachine() {}
	method direction(aDirection) {}
	method backToMenu() {}
}

// Una pantalla que se abre encima de otra: recuerda cuál quedó abajo.
class OverlayScreen inherits Screen {
	var under = coverScreen

	method under() = under
	method under(screen) { under = screen }

	override method leave() {
		self.hide()
		under.leave()
	}
}

// ----------- LA PORTADA -----------

// Las imágenes de pantalla completa del menú
const startScreen = new Picture(image = "startScreen.png", position = new CellPosition(x = 0, y = 0))

const menuControlsOverlay = new Picture(image = "menu/menu_controls.png", position = new CellPosition(x = 0, y = 0))

const menuBackground = new Picture(image = "menu/menu_background.png", position = new CellPosition(x = 0, y = 0))

// La portada: las opciones se eligen con un clic, o con las flechas (arriba y abajo) y Enter.
object coverScreen inherits Screen {
	override method clickTargets() = coverMenu.options()

	override method show() {
		menuBackground.show()
		startScreen.show()
		coverMenu.show()
	}

	override method hide() {
		startScreen.hide()
		coverMenu.hide()
	}

	// El fondo azul queda detrás del libro
	override method hideUnderOverlay() {
		self.hide()
		menuBackground.show()
	}

	override method showAfterOverlay() {
		startScreen.show()
		coverMenu.show()
	}

	override method enter() { coverMenu.activate() }
	override method arrow(direction) { direction.moveCoverFocus(coverMenu) }
	override method pressI() { screenManager.openInstructions() }
	override method pressS() { game.stop() }
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

// ----------- LOS CONTROLES -----------

// I, Retroceso, Enter o un clic en "volver al menú" (la fila de abajo) vuelven a la portada
object instructionsScreen inherits Screen {
	const backButton = new CellArea(zone = rectangle.of(0, 0, 22, 1), action = { screenManager.backToCover() })

	override method clickTargets() = [backButton]

	override method show() {
		menuBackground.show()
		menuControlsOverlay.show()
	}

	override method hide() { menuControlsOverlay.hide() }

	override method hideUnderOverlay() {
		menuControlsOverlay.hide()
		menuBackground.show()
	}

	override method showAfterOverlay() { menuControlsOverlay.show() }

	override method enter() { screenManager.backToCover() }
	override method back() { screenManager.backToCover() }
	override method pressI() { screenManager.backToCover() }
}

// ----------- JUGANDO -----------

// Los clics van por capas, de la que se ve más arriba a la de más abajo
object playingScreen inherits Screen {
	override method clickTargets() = [chefBubble, actionsMenu, hud, boardArea]

	// El HUD queda dibujado al volver a la portada (lo tapa el fondo del menú)
	override method show() {
		menuBackground.hide()
		hud.show()
		simulationEngine.resume()
	}

	override method hide() { simulationEngine.pause() }

	override method enter() {
		if (levelManager.tutorial().waitsForContinue()) levelManager.continueTutorial()
		else toolsManager.enter()
	}
	override method arrow(direction) { toolsManager.arrow(direction) }
	override method back() { toolsManager.stopEditing() }
	// S es mirar hacia abajo, como W, A y D (en la portada, S es salir)
	override method pressS() { self.direction(down) }

	override method speed(n) { sideButtons.speed(n) }
	override method toggleSimulation() { levelManager.toggleSimulation() }
	override method nextLevel() { levelManager.loadNext() }
	override method restart() { levelManager.restart() }
	override method toggleFreePlay() { levelManager.toggleFreePlay() }
	override method skipTutorial() { levelManager.skipTutorial() }
	override method chooseMachine(step) { rightPanel.chooseMachine(step) }
	override method rotateMachine() { toolsManager.act(rotate) }
	override method editMachine() { toolsManager.editKey() }
	override method deleteMachine() { toolsManager.act(delete) }
	override method direction(aDirection) { toolsManager.currentDirection(aDirection) }
	override method backToMenu() { screenManager.backToCover() }
}

// El tablero, como parte clickeable de playingScreen
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

	override method clickTargets() = [closeButton, leftHalf, rightHalf]

	override method show() { recipeBook.open() }
	override method hide() { recipeBook.close() }

	override method arrow(direction) { direction.turnPage(recipeBook) }
	override method back() { screenManager.closeBook() }
	override method toggleBook() { screenManager.closeBook() }
}

// ----------- EL TICKET DE NIVEL COMPLETO (encima del juego) -----------

// Mientras se ve, sólo cuentan sus botones (el resto de los clics no hace nada).
object levelCompleteScreen inherits OverlayScreen {
	override method clickTargets() = levelComplete.buttons()

	// Lo dibuja screenManager.showLevelComplete, que sabe qué decir
	override method hide() { levelComplete.hide() }

	override method enter() { levelComplete.buttons().first().press() }

	override method nextLevel() {
		screenManager.uncover()
		levelManager.loadNext()
	}

	override method restart() {
		screenManager.uncover()
		levelManager.restart()
	}

	override method backToMenu() { screenManager.backToCover() }
}
