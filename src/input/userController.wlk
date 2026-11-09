// Buffet Albert Einstein - traduce las teclas y los clicks del jugador a acciones del juego.
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

// Traduce las entradas del usuario (clicks y teclas) a acciones del juego

import wollok.game.*
import board.*
import menu.menuManager.*
import menu.recipeBook.*
import menu.startMenu.*
import tools.toolsManager.*
import tools.userTools.*
import directions.*
import simulation.simulationEngine.*
import levels.levelManager.*
import menu.levelInfoMenu.*

object userController {
	method setUp() {
		game.onClickDo({ pos => self.onClick(pos) })

		// --- RECETARIO (Global: anda en menú y en juego) ---
		// Al no tener whenPlaying, funcionan siempre. Y como están en setUp(),
		// solo se bindean UNA vez, evitando el problema de la doble ejecución.
		keyboard.f().onPressDo({ => startMenu.toggleRecipeBook() })
		keyboard.right().onPressDo({ => recipeBook.nextPage() })
		keyboard.left().onPressDo({ => recipeBook.prevPage() })

		// --- TECLAS DEL JUEGO (Protegidas) ---
		keyboard.num1().onPressDo({ => self.whenPlaying({ simulationEngine.speed(1) }) })
		keyboard.num2().onPressDo({ => self.whenPlaying({ simulationEngine.speed(2) }) })
		keyboard.num3().onPressDo({ => self.whenPlaying({ simulationEngine.speed(3) }) })
		keyboard.space().onPressDo({ => self.whenPlaying({ levelManager.toggleSimulation() }) })
		keyboard.num5().onPressDo({ => self.whenPlaying({ levelManager.toggleSimulation() }) })

		keyboard.n().onPressDo({ => self.whenPlaying({ levelManager.loadNext() }) })
		keyboard.num0().onPressDo({ => self.whenPlaying({ levelManager.restart() }) })
		keyboard.l().onPressDo({ => self.whenPlaying({ levelManager.toggleFreePlay() }) })

		keyboard.enter().onPressDo({ => self.whenPlaying({ levelManager.continueTutorial() }) })
		keyboard.t().onPressDo({ => self.whenPlaying({ levelManager.skipTutorial() }) })

		keyboard.q().onPressDo({ => self.whenPlaying({ menuManager.prevPage() }) })
		keyboard.e().onPressDo({ => self.whenPlaying({ menuManager.nextPage() }) })

		keyboard.z().onPressDo({ => self.whenPlaying({ toolsManager.select(place) }) })
		keyboard.x().onPressDo({ => self.whenPlaying({ toolsManager.select(edit) }) })
		keyboard.c().onPressDo({ => self.whenPlaying({ toolsManager.select(rotate) }) })
		keyboard.v().onPressDo({ => self.whenPlaying({ toolsManager.select(delete) }) })

		keyboard.w().onPressDo({ => self.whenPlaying({ toolsManager.currentDirection(up) }) })
		keyboard.s().onPressDo({ => self.whenPlaying({ toolsManager.currentDirection(down) }) })
		keyboard.a().onPressDo({ => self.whenPlaying({ toolsManager.currentDirection(left) }) })
		keyboard.d().onPressDo({ => self.whenPlaying({ toolsManager.currentDirection(right) }) })

		keyboard.m().onPressDo({ => self.whenPlaying({ startMenu.backToCover() }) })
	}

	method onClick(pos) {
		if (recipeBook.isOpen()) {
			// Si querés que la X del libro funcione por click, iría acá
		} else if (startMenu.isPlaying()) {
			toolsManager.onClick(pos) // (o levelInfoMenu.isSkipButton como tenía tu amigo)
		}
	}

	method whenPlaying(action) {
		if (!recipeBook.isOpen() && startMenu.isPlaying()) action.apply()
	}
}