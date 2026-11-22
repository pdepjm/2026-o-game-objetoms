// Buffet Albert Einstein - el cursor del tablero y lo que se le hace a la máquina elegida.
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
import machines.machineClasses.*
import cellPosition.*
import menu.menuManager.*
import menu.editMenu.*
import directions.*
import simulation.simulationEngine.*
import tools.userTools.*
import levels.levelManager.*
import sound.sfx.*

// Ya no se elige herramienta. El jugador:
// - hace clic en una celda vacía: coloca la máquina del menú (place);
// - hace clic en una máquina: queda elegida, con su menú abajo;
// - aprieta C, X o V: rota, edita o borra la máquina elegida (rotate, edit, delete).
// En el tablero sólo se usa el mouse: no hay cursor que se mueva con el teclado.
// Las herramientas de userTools siguen siendo las acciones: el tutorial pregunta por ellas (allowsTool).
// Arriba a la derecha, el cartel dice si está COLOCANDO o EDITANDO (ver modeBanner y los modos, abajo).
object toolsManager {
	// Dirección con la que se colocan las máquinas nuevas
	var currentDirection = right
	// COLOCANDO o EDITANDO
	var mode = placingMode

	method currentDirection() = currentDirection
	method mode() = mode
	method isEditing() = mode == editingMode

	// Al cambiar la dirección se actualizan las imágenes del menú, que la muestran.
	// Así el menú no tiene que preguntar la dirección en cada frame (ver MenuItem).
	method currentDirection(direction) {
		currentDirection = direction
		sfx.directionChange()
		menuManager.directionChanged()
	}

	// ----------- CLICS -----------

	// Un clic en el juego: en el menú de la máquina elegida, en el tablero o en la zona interactiva
	method onClick(pos) {
		if (actionsMenu.contains(pos)) self.act(actionsMenu.actionAt(pos))
		else if (board.inBoard(pos)) self.clickCell(pos)
		else if (menuManager.inInteractiveMenu(pos)) menuManager.onClick(pos)
	}

	// En una celda con máquina, la elige (y muestra su menú); en una vacía, coloca ahí y la máquina nueva
	// queda elegida, con su menú (si no se pudo colocar, no hay menú).
	// Mientras se cocina no hace nada: el tablero queda limpio (ver cookingStarted).
	method clickCell(pos) {
		if (!simulationEngine.running()) {
			self.stopEditing()
			if (board.isThereAMachine(pos)) self.pick(pos)
			else self.placeAt(pos)
		}
	}

	method placeAt(pos) {
		actionsMenu.hide()
		boardCursor.moveTo(pos)
		self.useAt(place, pos)
		// si el tutorial pasó a pedir algo en otra celda, ésa quedó elegida (jumpTo): no se la pisa
		if (boardCursor.isAt(pos)) actionsMenu.showFor(board.machineAt(pos))
		self.boardChanged()
	}

	// ----------- TECLADO -----------

	// Flechas: con el panel de editar abierto eligen una opción; si no, nada (el tablero es sólo con el mouse)
	method arrow(direction) { mode.arrow(direction, self) }

	// Enter: en el panel de editar aplica la opción marcada; colocando no hace nada (se coloca con el clic)
	method enter() { mode.enter(self) }

	// C, X o V: la acción sobre la máquina elegida (la última clickeada)
	method act(tool) {
		self.stopEditing()
		self.useAt(tool, boardCursor.cell())
		self.boardChanged()
	}

	// Con la simulación prendida no se puede colocar, borrar, rotar ni editar nada.
	// El tutorial del nivel puede no dejar usar la acción en esa celda: el cocinero dice por qué.
	method useAt(tool, pos) {
		if (!simulationEngine.running()) {
			if (levelManager.allowsTool(tool, pos)) tool.onClick(pos)
			else levelManager.toolRejected(tool, pos)
		}
	}

	// ----------- LA MÁQUINA ELEGIDA -----------

	// Elige esa celda y, si hay una máquina, muestra su menú
	method pick(pos) {
		self.stopEditing()
		boardCursor.moveTo(pos)
		actionsMenu.showFor(board.machineAt(pos))
	}

	// El tutorial pide algo en otra celda: queda elegida esa (ver levelManager), así C o X actúan ahí
	method jumpTo(pos) {
		if (!boardCursor.isAt(pos)) self.pick(pos)
	}

	// Algo cambió en el tablero (se colocó, borró o rotó una máquina, o se cargó un nivel):
	// el menú de la máquina queda arriba de todo y muestra lo que se puede hacer
	method boardChanged() {
		if (!simulationEngine.running()) actionsMenu.refresh()
	}

	// Se prendió la simulación: se cierra el panel de editar y se va el menú de la máquina,
	// para que se vea sólo la cocina (ver levelManager._cookingChanged)
	method cookingStarted() {
		self.stopEditing()
		actionsMenu.hide()
	}

	// ----------- LOS MODOS -----------

	// La herramienta edit abrió el panel de una máquina (ver userTools)
	method startEditing() { self.changeMode(editingMode) }

	// Retroceso (o X otra vez, o tocar el tablero): se cierra el panel de editar
	method stopEditing() { if (self.isEditing()) self.changeMode(placingMode) }

	method changeMode(newMode) {
		mode = newMode
		sfx.toolSelect()
		menuManager.modeChanged(mode)
	}

	// X con el panel abierto lo cierra; si no, edita la máquina elegida
	method editKey() { mode.editKey(self) }

	// Vuelve a como arranca un nivel: colocando, hacia la derecha, sin máquina elegida.
	// Al cerrarse el panel de edit, editMenu olvida la máquina elegida: por eso, al reiniciar,
	// se llama después de board.clear().
	method reset() {
		mode = placingMode
		currentDirection = right
		actionsMenu.hide()
		menuManager.modeChanged(placingMode)
		menuManager.directionChanged()
	}
}

// COLOCANDO: el panel de colocar a la derecha. Las flechas y Enter no hacen nada: el tablero es con el mouse
object placingMode {
	method banner() = "menu/mode_placing.png"
	method arrow(direction, manager) {}
	method enter(manager) {}
	method editKey(manager) { manager.act(edit) }
}

// EDITANDO: el panel de editar a la derecha; las flechas eligen una opción y Enter la aplica
object editingMode {
	method banner() = "menu/mode_editing.png"
	method arrow(direction, manager) { editMenu.moveFocus(direction) }
	method enter(manager) { editMenu.chooseFocused() }
	method editKey(manager) { manager.stopEditing() }
}

// La celda elegida: la del último clic en el tablero (o la que marca el tutorial). No se dibuja: la máquina
// elegida se nota por su menú (actionsMenu). C, X y V actúan sobre ella.
object boardCursor {
	var cell = new CellPosition(x = 9, y = 5)

	method cell() = cell
	method isAt(pos) = cell.x() == pos.x() && cell.y() == pos.y()
	method moveTo(pos) { cell = new CellPosition(x = pos.x(), y = pos.y()) }
}

// El menú de la máquina elegida: ROTAR (C), EDITAR (X) y BORRAR (V), una celda cada uno, debajo de la
// máquina (o arriba, si está en la fila de abajo). Lo que no se puede hacer se ve apagado. Clickear una de
// sus celdas es usar esa acción. Aparece al elegir una máquina y también al colocarla (la nueva queda elegida).
object actionsMenu {
	const actions = [rotate, edit, delete]
	var machine = noMachine
	var shown = false
	var position = new CellPosition(x = 0, y = 0)
	var image = "menu/actions_all.png"

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
				image = self.imageFor(machine)
				if (game.hasVisual(self)) game.removeVisual(self)
				game.addVisual(self)
			} else self.hide()
		}
	}

	method hide() {
		shown = false
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

	method contains(pos) = shown && pos.y() == position.y() && pos.x().between(position.x(), position.x() + 2)

	method actionAt(pos) = actions.get(pos.x() - position.x())
}
