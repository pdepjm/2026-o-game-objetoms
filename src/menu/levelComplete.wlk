// Buffet Albert Einstein - la comanda que aparece al completar un nivel.
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
import menu.drawing.visuals.*
import menu.screenClasses.*
import menu.screens.*

// La comanda de nivel completo: una imagen ya dibujada por nivel y los botones, zonas sin imagen.
object levelComplete {
	const drawn = new VisualGroup()
	var buttons = []

	method isShown() = !drawn.isEmpty()
	method buttons() = buttons
	// Enter: como un clic en el primer botón
	method pressFirstButton() { buttons.first().onClick(buttons.first().zone().origin()) }
	// La imagen que se ve (para los tests)
	method image() = drawn.visuals().first().image()

	method draw(result) {
		self.hide()
		drawn.add(new Picture(image = result.image(), position = new CellPosition(x = 0, y = 0)))
		result.ending().showButtonsIn(self)
	}

	// Hay otro nivel: SIGUIENTE NIVEL, REPETIR y MENÚ
	method showNextLevelButtons() {
		buttons = [
			new CellArea(zone = rectangle.of(9, 3, 4, 1), action = { levelCompleteScreen.nextLevel() }),
			new CellArea(zone = rectangle.of(9, 2, 2, 1), action = { levelCompleteScreen.restart() }),
			new CellArea(zone = rectangle.of(11, 2, 2, 1), action = { levelCompleteScreen.backToMenu() })
		]
	}

	// Era el último nivel: JUGAR DE NUEVO y MENÚ
	method showPlayAgainButtons() {
		buttons = [
			new CellArea(zone = rectangle.of(9, 3, 4, 1), action = { levelCompleteScreen.restart() }),
			new CellArea(zone = rectangle.of(10, 2, 2, 1), action = { levelCompleteScreen.backToMenu() })
		]
	}

	method hide() {
		drawn.clear()
		buttons = []
	}
}
