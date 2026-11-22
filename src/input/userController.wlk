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
import sound.sfx.*
import menu.hud.*

object userController {
	method setUp() {
		game.onClickDo({ pos => self.onClick(pos) })

		// --- RECETARIO, FLECHAS Y RETROCESO (Globales: andan en menú y en juego) ---
		// Al no tener whenPlaying, funcionan siempre. Y como están en setUp(),
		// solo se bindean UNA vez, evitando el problema de la doble ejecución.
		// Lo que hace cada flecha lo decide la pantalla: en la portada mueven la opción marcada, jugando
		// eligen la opción del panel de editar (el tablero es sólo con el mouse) y con el libro abierto pasan
		// de página.
		keyboard.f().onPressDo({ => startMenu.toggleRecipeBook() })
		keyboard.right().onPressDo({ => startMenu.arrow(right) })
		keyboard.left().onPressDo({ => startMenu.arrow(left) })
		keyboard.up().onPressDo({ => startMenu.arrow(up) })
		keyboard.down().onPressDo({ => startMenu.arrow(down) })
		// Retroceso (Backspace): volver (deja de editar, cierra el libro o los controles). Wollok no le pasa
		// Esc al juego: su página sólo manda letras, números, flechas, Enter, Espacio, Retroceso y pocas más.
		keyboard.backspace().onPressDo({ => startMenu.back() })

		// --- TECLAS DEL JUEGO (Protegidas) ---
		keyboard.num1().onPressDo({ => self.whenPlaying({ sideButtons.speed(1) }) })
		keyboard.num2().onPressDo({ => self.whenPlaying({ sideButtons.speed(2) }) })
		keyboard.num3().onPressDo({ => self.whenPlaying({ sideButtons.speed(3) }) })
		keyboard.space().onPressDo({ => self.whenPlaying({ levelManager.toggleSimulation() }) })
		keyboard.num5().onPressDo({ => self.whenPlaying({ levelManager.toggleSimulation() }) })

		keyboard.n().onPressDo({ => self.whenPlaying({ levelManager.loadNext() }) })
		keyboard.num0().onPressDo({ => self.whenPlaying({ levelManager.restart() }) })
		keyboard.l().onPressDo({ => self.whenPlaying({ levelManager.toggleFreePlay() }) })

		// Enter lo resuelve la pantalla (ver startMenu.show y playingScreen.start)
		keyboard.t().onPressDo({ => self.whenPlaying({ levelManager.skipTutorial() }) })

		// Q y E: la máquina anterior o la siguiente del menú de colocar
		keyboard.q().onPressDo({ => self.whenPlaying({ menuManager.chooseMachine(-1) }) })
		keyboard.e().onPressDo({ => self.whenPlaying({ menuManager.chooseMachine(1) }) })

		// C, X y V: rotar, editar o borrar la máquina elegida (la del cursor). X otra vez deja de editar.
		keyboard.c().onPressDo({ => self.whenPlaying({ toolsManager.act(rotate) }) })
		keyboard.x().onPressDo({ => self.whenPlaying({ toolsManager.editKey() }) })
		keyboard.v().onPressDo({ => self.whenPlaying({ toolsManager.act(delete) }) })

		keyboard.w().onPressDo({ => self.whenPlaying({ toolsManager.currentDirection(up) }) })
		keyboard.s().onPressDo({ => self.whenPlaying({ toolsManager.currentDirection(down) }) })
		keyboard.a().onPressDo({ => self.whenPlaying({ toolsManager.currentDirection(left) }) })
		keyboard.d().onPressDo({ => self.whenPlaying({ toolsManager.currentDirection(right) }) })

		keyboard.m().onPressDo({ => self.whenPlaying({ startMenu.backToCover() }) })
	}

	// Qué hace cada click o tecla lo decide la pantalla activa del menú (ver startMenu)
	method onClick(pos) { startMenu.onClick(pos) }

	method whenPlaying(action) { startMenu.whenPlaying(action) }
}
