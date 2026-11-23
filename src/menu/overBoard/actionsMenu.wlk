// Buffet Albert Einstein - el menú de la máquina elegida: ROTAR, EDITAR y BORRAR.
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
import board.*
import cellPosition.*
import machines.machineClasses.*
import tools.userTools.*
import tools.toolsManager.*

// El menú de la máquina elegida: ROTAR (C), EDITAR (X) y BORRAR (V), una celda cada uno
object actionsMenu {
	const actions = [rotate, edit, delete]
	var machine = noMachine
	var shown = false
	var position = new CellPosition(x = 0, y = 0)
	var image = "menu/actions_all.png"
	// Las tres celdas que se clickean (nowhere mientras está escondido)
	var zone = nowhere

	method position() = position
	method image() = image
	method isShown() = shown

	method showFor(aMachine) {
		self.hide()
		machine = aMachine
		if (!machine.asList().isEmpty()) {
			shown = true
			self.refresh()
		}
	}

	// Recalcula dónde va y qué se ve (la máquina pudo rotar o desaparecer), y queda arriba de todo
	method refresh() {
		if (shown) {
			// sigue en el tablero si en su celda está ella (se pudo haber borrado)
			if (board.machineAt(machine.cell()) == machine) {
				position = self.placeFor(machine)
				zone = rectangle.of(position.x(), position.y(), 3, 1)
				image = self.imageFor(machine)
				if (game.hasVisual(self)) game.removeVisual(self)
				game.addVisual(self)
			} else self.hide()
		}
	}

	method hide() {
		shown = false
		zone = nowhere
		machine = noMachine
		if (game.hasVisual(self)) game.removeVisual(self)
	}

	// Tres celdas centradas debajo de la máquina, sin salirse del tablero
	method placeFor(aMachine) {
		const cell = aMachine.cell()
		const left = (cell.x() + (aMachine.width() - 1).div(2) - 1).max(5).min(14)
		const row = if (cell.y() > 1) cell.y() - 1 else cell.y() + aMachine.height()
		return new CellPosition(x = left, y = row)
	}

	method imageFor(aMachine) {
		const canChange = !aMachine.locked()
		const canEdit = !aMachine.settings().isEmpty()
		return "menu/actions_" + (if (canChange && canEdit) "all" else if (canChange) "noedit" else if (canEdit) "editonly" else "none") + ".png"
	}

	// Para playingScreen: está encima del tablero, así que un clic en sus celdas es suyo y no del tablero
	method handlesClick(pos) = zone.contains(pos)
	method onClick(pos) { toolsManager.act(self.actionAt(pos)) }

	method actionAt(pos) = actions.get(pos.x() - position.x())
}
