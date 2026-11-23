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
import menu.drawing.texts.*
import menu.drawing.spriteFonts.*
import menu.screens.*
import levels.levelManager.*

object levelComplete {
	const drawn = new VisualGroup()
	const texts = new VisualGroup()
	var buttons = []
	const centerX = 11
	// Las filas del ticket, de arriba hacia abajo (entre sus líneas punteadas)
	const rowsY = [8.42, 7.82, 7.22, 6.62, 6.02, 5.42]

	method isShown() = !drawn.isEmpty()
	method buttons() = buttons
	// Lo que dice (para los tests)
	method lines() = texts.visuals().map({ text => text.description() })

	method draw(result) {
		self.hide()
		drawn.add(new Picture(image = "menu/dim.png", position = new CellPosition(x = 0, y = 0)))
		drawn.add(new Picture(image = "menu/ticket.png", position = new CellPosition(x = 7, y = 1.6)))
		drawn.add(new Picture(image = "tutorial/chef_happy_up_left.png", position = new CellPosition(x = 15.2, y = 2.2)))
		texts.keep(spriteText.draw(result.level().name(), labelFont, centerX, 9.12))
		const rows = result.lines()
		rows.size().min(rowsY.size()).times({ row =>
			texts.keep(spriteText.draw(rows.get(row - 1), textFont, centerX, rowsY.get(row - 1)))
		})
		result.ending().showButtonsIn(self)
	}

	// Hay otro nivel: SIGUIENTE NIVEL, REPETIR y MENÚ
	method showNextLevelButtons() {
		self.showButtons([
			new Button(image = "menu/btn_next.png", zone = rectangle.of(9, 3, 4, 1), action = { levelCompleteScreen.nextLevel() }),
			new Button(image = "menu/btn_repeat.png", zone = rectangle.of(9, 2, 2, 1), action = { levelCompleteScreen.restart() }),
			new Button(image = "menu/btn_menu.png", zone = rectangle.of(11, 2, 2, 1), action = { levelCompleteScreen.backToMenu() })
		])
	}

	// Era el último nivel: JUGAR DE NUEVO y MENÚ
	method showPlayAgainButtons() {
		self.showButtons([
			new Button(image = "menu/btn_again.png", zone = rectangle.of(9, 3, 4, 1), action = { levelCompleteScreen.restart() }),
			new Button(image = "menu/btn_menu.png", zone = rectangle.of(10, 2, 2, 1), action = { levelCompleteScreen.backToMenu() })
		])
	}

	method showButtons(newButtons) {
		buttons = newButtons
		buttons.forEach({ button => drawn.add(button) })
	}

	method hide() {
		drawn.clear()
		texts.clear()
		buttons = []
	}
}
