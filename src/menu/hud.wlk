// Buffet Albert Einstein - el cartel COLOCANDO / EDITANDO y los botones de abajo a la izquierda.
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
import menu.visuals.*
import menu.startMenu.*
import levels.levelManager.*
import simulation.simulationEngine.*
import sound.sfx.*

// Lo que se ve siempre mientras se juega, alrededor del tablero (lo muestra menuManager.setUp).

// El cartel de arriba a la derecha (x 18, fila 12): dice si el jugador está COLOCANDO o EDITANDO.
// Guarda la imagen: sólo cambia cuando cambia el modo (menuManager.modeChanged).
object modeBanner inherits Picture(image = "menu/mode_placing.png", position = new CellPosition(x = 18, y = 12)) {
    method change(mode) { image = mode.banner() }
}

// Los botones de abajo a la izquierda (x 0 a 3, y 0 a 3), uno por fila de celdas para que se puedan
// clickear (Wollok avisa el clic por celda). Cada uno hace lo mismo que su tecla:
//
//   [F] RECETARIO           ← fila 3
//   [M] MENÚ                ← fila 2
//   [ESPACIO] INICIAR/PAUSA ← fila 1
//   [1][2][3] VEL.          ← fila 0: una celda por velocidad, con un marco en la elegida (speedFrame)
//
// La imagen (assets/menu/side_buttons.png, ver makeBoardUi.py) tapa las teclas que trae dibujadas el fondo
// y ya tiene dibujados los botones: cada uno es sólo un lugar que se clickea (CellArea).
object sideButtons inherits Picture(image = "menu/side_buttons.png", position = new CellPosition(x = 0, y = 0)) {
	const buttons = [
		new CellArea(position = new CellPosition(x = 0, y = 3), width = 4, action = { startMenu.toggleRecipeBook() }),
		new CellArea(position = new CellPosition(x = 0, y = 2), width = 4, action = { startMenu.backToCover() }),
		new CellArea(position = new CellPosition(x = 0, y = 1), width = 4, action = { levelManager.toggleSimulation() })
	] + [1, 2, 3].map({ speed => new CellArea(position = new CellPosition(x = speed - 1, y = 0), action = { sideButtons.speed(speed) }) })

	override method show() {
		super()
		speedFrame.show()
	}

	// Para playingScreen: un clic en estas celdas es de los botones (aunque caiga en la celda libre de la
	// fila de abajo)
	method handlesClick(pos) = pos.x().between(0, 3) && pos.y().between(0, 3)

	method onClick(pos) {
		buttons.findOrDefault({ button => button.contains(pos) }, noButton).press()
	}

	// Las teclas 1, 2 y 3 y los botones de la fila de abajo
	method speed(n) {
		simulationEngine.speed(n)
		sfx.speedChange()
	}
}

// El marco de la velocidad elegida. La posición sale de una lista armada una vez: dibujarlo no crea nada.
object speedFrame {
	const positions = [new CellPosition(x = 0, y = 0), new CellPosition(x = 1, y = 0), new CellPosition(x = 2, y = 0)]

	method position() = positions.get(simulationEngine.speed() - 1)
	method image() = "menu/speed_selected.png"
	method show() { if (!game.hasVisual(self)) game.addVisual(self) }
}
