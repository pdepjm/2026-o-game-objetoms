// Buffet Albert Einstein - los botones de abajo a la izquierda: recetario, menú, iniciar y velocidad.
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
import menu.startMenu.*
import levels.levelManager.*
import simulation.simulationEngine.*
import sound.sfx.*

// Los botones de abajo a la izquierda (x 0 a 3, y 0 a 3), uno por fila de celdas para que se puedan
// clickear (Wollok avisa el clic por celda). Cada uno hace lo mismo que su tecla:
//
//   [F] RECETARIO           ← fila 3
//   [M] MENÚ                ← fila 2
//   [ESPACIO] INICIAR/PAUSA ← fila 1
//   [1][2][3] VEL.          ← fila 0: una celda por velocidad, con un marco en la elegida (speedFrame)
//
// La imagen (assets/menu/side_buttons.png, ver makeBoardUi.py) tapa las teclas que trae dibujadas el fondo.
object sideButtons {
	method position() = game.origin()
	method image() = "menu/side_buttons.png"

	method show() {
		if (!game.hasVisual(self)) game.addVisual(self)
		if (!game.hasVisual(speedFrame)) game.addVisual(speedFrame)
	}

	method contains(pos) = pos.x().between(0, 3) && pos.y().between(0, 3)

	method onClick(pos) {
		if (pos.y() == 3) startMenu.toggleRecipeBook()
		else if (pos.y() == 2) startMenu.backToCover()
		else if (pos.y() == 1) levelManager.toggleSimulation()
		else if (pos.x() <= 2) self.speed(pos.x() + 1)
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
}
