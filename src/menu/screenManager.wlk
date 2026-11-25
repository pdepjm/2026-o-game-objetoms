// Buffet Albert Einstein - el que sabe qué pantalla se está viendo y la cambia.
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

import menu.screens.*
import menu.levelComplete.*
import machines.types.deliverySlot.*
import levels.levelManager.*
import sound.sfx.*

// El ÚNICO que cambia de pantalla.
object screenManager {
	var screen = coverScreen
	// La primera vez que se juega se arma todo (los platitos y el primer nivel); las siguientes, se sigue
	var gameStart = newGame

	method screen() = screen

	// La portada, al abrir el juego (main.wpgm)
	method showCover() {
		screen = coverScreen
		coverScreen.show()
	}

	// ----------- CAMBIAR DE PANTALLA -----------

	// Se sale de la actual (y de las que tenga abajo) y se entra en la nueva
	method changeScreen(newScreen) {
		screen.leave()
		screen = newScreen
		screen.show()
	}

	// Una pantalla encima de la actual: la de abajo queda como está, esperando
	method cover(overlay) {
		overlay.under(screen)
		screen.hideUnderOverlay()
		screen = overlay
		overlay.show()
	}

	// Se cierra la de encima y se vuelve a la de abajo.
	method uncover() {
		screen.hide()
		screen = screen.under()
		screen.showAfterOverlay()
	}

	method play() {
		sfx.simulationStart()
		self.changeScreen(playingScreen)
		gameStart.begin(self)
	}

	method gameStarted() { gameStart = resumedGame }

	method openInstructions() {
		sfx.menuSelect()
		self.changeScreen(instructionsScreen)
	}

	method backToCover() {
		sfx.menuSelect()
		self.changeScreen(coverScreen)
	}

	method openBook() { self.cover(bookScreen) }

	method closeBook() { self.uncover() }

	// Se ganó el nivel (levelManager.finishLevel): el ticket, encima del juego
	method showLevelComplete(result) {
		levelComplete.draw(result)
		self.cover(levelCompleteScreen)
	}

	// ----------- LO QUE HACE EL JUGADOR: lo resuelve la pantalla activa -----------

	// CLIC -> screenManager -> la pantalla activa -> la zona clickeada (o nothingClicked)
	method onClick(pos) { screen.onClick(pos) }

	// Cada tecla, por su nombre: la pantalla activa la usa o no hace nada
	method press(key) { self.press(key, key) }
	method press(key, value) { screen.press(key, value) }

	method enter() { self.press("enter") }
	method arrow(direction) { self.press("arrow", direction) }
	method back() { self.press("back") }
	method toggleBook() { self.press("book") }
	method pressI() { self.press("i") }
	method pressS() { self.press("s") }

	method speed(n) { self.press("speed", n) }
	method toggleSimulation() { self.press("simulation") }
	method nextLevel() { self.press("nextLevel") }
	method restart() { self.press("restart") }
	method toggleFreePlay() { self.press("freePlay") }
	method skipTutorial() { self.press("skipTutorial") }
	method chooseMachine(step) { self.press("chooseMachine", step) }
	method rotateMachine() { self.press("rotate") }
	method editMachine() { self.press("edit") }
	method deleteMachine() { self.press("delete") }
	method direction(aDirection) { self.press("direction", aDirection) }
	method backToMenu() { self.press("menu") }
}

// La primera partida: arma los platitos y carga el nivel que toca.
object newGame {
	method begin(manager) {
		deliveryPoints.setUp()
		levelManager.start()
		manager.gameStarted()
	}
}

object resumedGame {
	method begin(manager) {}
}
