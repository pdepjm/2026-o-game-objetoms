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
import menu.hud.rightPanel.*
import menu.hud.placeMenu.*
import menu.overBoard.actionsMenu.*
import directions.*
import simulation.simulationEngine.*
import tools.userTools.*
import levels.levelManager.*
import sound.sfx.*

object toolsManager {
	// Dirección con la que se colocan las máquinas nuevas
	var currentDirection = right
	// COLOCANDO o EDITANDO
	var mode = placingMode
	// CONSTRUYENDO (se puede tocar el tablero) o COCINANDO (no)
	var kitchen = buildingKitchen

	method currentDirection() = currentDirection
	method mode() = mode
	method isEditing() = mode.isEditing()

	// Al cambiar la dirección se actualizan las imágenes del menú, que la muestran.
	method currentDirection(direction) {
		currentDirection = direction
		sfx.directionChange()
		rightPanel.directionChanged()
	}

	// ----------- CLICS -----------

	// Un clic en una celda del tablero.
	method clickCell(pos) { kitchen.clickCell(pos, self) }

	method placeAt(pos) {
		actionsMenu.hide()
		boardCursor.moveTo(pos)
		self.useAt(place, pos)
		// si el tutorial pasó a pedir algo en otra celda, ésa quedó elegida (jumpTo): no se la pisa
		if (boardCursor.isAt(pos)) actionsMenu.showFor(board.machineAt(pos))
		self.boardChanged()
	}

	// ----------- TECLADO -----------

	// Flechas: con el panel de editar abierto eligen una opción; si no, nada
	method arrow(direction) { mode.arrow(direction, self) }

	// Enter: en el panel de editar aplica la opción marcada; colocando no hace nada
	method enter() { mode.enter(self) }

	// C, X o V: la acción sobre la máquina elegida (la última clickeada)
	method act(tool) {
		self.stopEditing()
		self.useAt(tool, boardCursor.cell())
		self.boardChanged()
	}

	// Con la simulación prendida no se puede colocar, borrar, rotar ni editar nada.
	method useAt(tool, pos) { kitchen.useAt(tool, pos) }

	// ----------- LA MÁQUINA ELEGIDA -----------

	// Elige esa celda y, si hay una máquina, muestra su menú
	method pick(pos) {
		self.stopEditing()
		boardCursor.moveTo(pos)
		actionsMenu.showFor(board.machineAt(pos))
	}

	// El tutorial pide algo en otra celda: queda elegida esa, así C o X actúan ahí
	method jumpTo(pos) {
		if (!boardCursor.isAt(pos)) self.pick(pos)
	}

	// Algo cambió en el tablero (se colocó, borró o rotó una máquina, o se cargó un nivel)
	method boardChanged() { kitchen.boardChanged() }

	// Se prendió la simulación: se cierra el panel de editar y se va el menú de la máquina
	method cookingStarted() {
		kitchen = cookingKitchen
		self.stopEditing()
		actionsMenu.hide()
	}

	// Se apagó la simulación: se vuelve a poder tocar el tablero
	method cookingStopped() { kitchen = buildingKitchen }

	// ----------- LOS MODOS -----------

	// Una máquina pidió que la editen: el panel de la derecha ya eligió cuál mostrar
	method startEditing() {
		// el menú de la máquina se va: el panel de la derecha ya dice qué se edita
		actionsMenu.hide()
		self.changeMode(editingMode)
	}

	// Retroceso (o X otra vez, o tocar el tablero): se cierra el panel de editar
	method stopEditing() { mode.stopEditing(self) }

	method changeMode(newMode) {
		mode = newMode
		sfx.toolSelect()
		rightPanel.modeChanged(mode)
	}

	// X con el panel abierto lo cierra; si no, edita la máquina elegida
	method editKey() { mode.editKey(self) }

	// Vuelve a como arranca un nivel: colocando, hacia la derecha, sin máquina elegida.
	method reset() {
		mode = placingMode
		currentDirection = right
		kitchen = buildingKitchen
		actionsMenu.hide()
		rightPanel.modeChanged(placingMode)
		rightPanel.directionChanged()
	}
}

// COLOCANDO: el panel de colocar a la derecha.
object placingMode {
	method banner() = "menu/mode_placing.png"
	method panelIn(panel) = placeMenu
	method isEditing() = false
	// Ya está colocando: no hay nada que cerrar
	method stopEditing(manager) {}
	method arrow(direction, manager) {}
	method enter(manager) {}
	method editKey(manager) { manager.act(edit) }
}

// EDITANDO: el panel de la máquina a la derecha (el que eligió ella)
object editingMode {
	method banner() = "menu/mode_editing.png"
	method panelIn(panel) = panel.editor()
	method isEditing() = true
	method stopEditing(manager) { manager.changeMode(placingMode) }
	method arrow(direction, manager) { rightPanel.moveFocus(direction) }
	method enter(manager) { rightPanel.chooseFocused() }
	method editKey(manager) { manager.stopEditing() }
}

// La celda elegida: la del último clic en el tablero (o la que marca el tutorial).
object boardCursor {
	var cell = new CellPosition(x = 9, y = 5)

	method cell() = cell
	method isAt(pos) = cell.x() == pos.x() && cell.y() == pos.y()
	method moveTo(pos) { cell = new CellPosition(x = pos.x(), y = pos.y()) }
}

// ----------- LA COCINA: CONSTRUYENDO O COCINANDO -----------

// Construyendo: se puede tocar el tablero
object buildingKitchen {
	method clickCell(pos, manager) {
		manager.stopEditing()
		board.machineAt(pos).clickedAt(pos, manager)
	}

	// El tutorial del nivel puede no dejar usar la acción en esa celda: el cocinero dice por qué
	method useAt(tool, pos) {
		if (levelManager.allowsTool(tool, pos)) tool.onClick(pos)
		else levelManager.toolRejected(tool, pos)
	}

	method boardChanged() { actionsMenu.refresh() }
}

// Cocinando: con la simulación prendida no se puede colocar, borrar, rotar ni editar nada
object cookingKitchen {
	method clickCell(pos, manager) {}
	method useAt(tool, pos) {}
	method boardChanged() {}
}
