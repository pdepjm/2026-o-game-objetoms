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
import directions.*
import menu.screenManager.*

// Recibe los clics y las teclas de Wollok y se los pasa a screenManager
object userController {
	method setUp() {
		game.onClickDo({ pos => screenManager.onClick(pos) })

		keyboard.enter().onPressDo({ => screenManager.enter() })
		keyboard.right().onPressDo({ => screenManager.arrow(right) })
		keyboard.left().onPressDo({ => screenManager.arrow(left) })
		keyboard.up().onPressDo({ => screenManager.arrow(up) })
		keyboard.down().onPressDo({ => screenManager.arrow(down) })
		// Retroceso: volver (deja de editar, cierra el libro o los controles)
		keyboard.backspace().onPressDo({ => screenManager.back() })
		keyboard.f().onPressDo({ => screenManager.toggleBook() })
		keyboard.i().onPressDo({ => screenManager.pressI() })
		keyboard.s().onPressDo({ => screenManager.pressS() })

		keyboard.num1().onPressDo({ => screenManager.speed(1) })
		keyboard.num2().onPressDo({ => screenManager.speed(2) })
		keyboard.num3().onPressDo({ => screenManager.speed(3) })
		keyboard.space().onPressDo({ => screenManager.toggleSimulation() })
		keyboard.num5().onPressDo({ => screenManager.toggleSimulation() })

		keyboard.n().onPressDo({ => screenManager.nextLevel() })
		keyboard.num0().onPressDo({ => screenManager.restart() })
		keyboard.l().onPressDo({ => screenManager.toggleFreePlay() })
		keyboard.t().onPressDo({ => screenManager.skipTutorial() })

		// Q y E: la máquina anterior o la siguiente del menú de colocar
		keyboard.q().onPressDo({ => screenManager.chooseMachine(-1) })
		keyboard.e().onPressDo({ => screenManager.chooseMachine(1) })

		// C, X y V: rotar, editar o borrar la máquina elegida.
		keyboard.c().onPressDo({ => screenManager.rotateMachine() })
		keyboard.x().onPressDo({ => screenManager.editMachine() })
		keyboard.v().onPressDo({ => screenManager.deleteMachine() })

		// W, A y D: hacia dónde miran las máquinas nuevas (S está arriba: en la portada es salir)
		keyboard.w().onPressDo({ => screenManager.direction(up) })
		keyboard.a().onPressDo({ => screenManager.direction(left) })
		keyboard.d().onPressDo({ => screenManager.direction(right) })

		keyboard.m().onPressDo({ => screenManager.backToMenu() })
	}
}
