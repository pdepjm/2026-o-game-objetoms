// Buffet Albert Einstein - los indicadores del tutorial sobre el tablero (recuadros y flechas).
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
import board.*

// Los indicadores del tutorial sobre el tablero (las imágenes están en assets/tutorial/):
// - un recuadro que late en las celdas donde el jugador tiene que hacer algo (colocar, rotar, editar)
// - una flecha que rebota arriba de la máquina que explica el mensaje ("las papas salen de acá")
// Los dibuja levelManager con cada aviso al tutorial. Sin tutorial no hay ninguno.
object tutorialMarks {
	var marks = []

	method marks() = marks

	method show(targetCells, pointedCells) {
		marks.forEach({ mark => game.removeVisual(mark) })
		marks = targetCells.map({ cell => new TutorialMark(position = new CellPosition(x = cell.x(), y = cell.y()), image = "tutorial/place.gif") })
			+ pointedCells.map({ cell => new TutorialMark(position = self.arrowPosition(cell), image = "tutorial/look.gif") })
		marks.forEach({ mark => game.addVisual(mark) })
	}

	// Arriba de la máquina de esa celda, centrada sobre ella: con una de 2x2, arriba de su fila de
	// arriba y entre sus dos columnas. Si no hay máquina, arriba de la celda.
	method arrowPosition(cell) {
		const machine = board.machineAt(cell)
		if (machine == null) return new CellPosition(x = cell.x(), y = cell.y() + 1)
		const origin = machine.cell()
		// Con decimales (una de 2x2) tiene que ser CellPosition: game.at se redondea a la celda al dibujar
		return new CellPosition(x = origin.x() + (machine.width() - 1) / 2, y = origin.y() + machine.height())
	}
}

class TutorialMark {
	const property position
	const property image
}
