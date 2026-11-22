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
// Si el jugador hace algo que el paso no deja, el recuadro se pone rojo un momento (flashError).
object tutorialMarks {
	var marks = []
	const errorMillis = 600
	// Mientras se cocina no se ven (ver levelManager._cookingChanged): se siguen anotando, y vuelven a
	// aparecer al apagar la simulación
	var hidden = false

	method marks() = marks

	method show(targetCells, pointedCells) {
		self.removeVisuals()
		marks = targetCells.map({ cell => new TutorialMark(position = new CellPosition(x = cell.x(), y = cell.y()), normalImage = "tutorial/place.gif", errorImage = "tutorial/place_error.gif") })
			+ pointedCells.map({ cell => new TutorialMark(position = self.arrowPosition(cell), normalImage = "tutorial/look.gif", errorImage = "tutorial/look.gif") })
		if (!hidden) marks.forEach({ mark => game.addVisual(mark) })
	}

	method hide() {
		hidden = true
		self.removeVisuals()
	}

	method reveal() {
		if (hidden) {
			hidden = false
			marks.forEach({ mark => game.addVisual(mark) })
		}
	}

	method removeVisuals() {
		marks.forEach({ mark => if (game.hasVisual(mark)) game.removeVisual(mark) })
	}

	// Arriba de la máquina de esa celda, centrada sobre ella: con una de 2x2, arriba de su fila de
	// arriba y entre sus dos columnas. Si no hay máquina, arriba de la celda.
	method arrowPosition(cell) = board.machineAt(cell).arrowPosition(cell)

	// Los recuadros que se ven se ponen rojos y, un momento después, vuelven a la normalidad
	// (si para entonces ya son otros, éstos ya no se ven y no pasa nada)
	method flashError() {
		const flashed = marks
		flashed.forEach({ mark => mark.showError() })
		game.schedule(errorMillis, { flashed.forEach({ mark => mark.showNormal() }) })
	}
}

class TutorialMark {
	const property position
	const normalImage
	const errorImage
	var showingError = false

	method image() = if (showingError) errorImage else normalImage
	method showError() { showingError = true }
	method showNormal() { showingError = false }
}
