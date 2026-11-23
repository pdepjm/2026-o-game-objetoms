// Buffet Albert Einstein - la columna derecha del HUD: el cartel y el panel de colocar o de editar.
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

import input.clickManager.*
import menu.hud.hud.*
import menu.hud.placeMenu.*
import menu.hud.editMenu.*
import menu.hud.armMenu.*
import tools.toolsManager.*
import sound.sfx.*

// La columna de la derecha: arriba el cartel COLOCANDO / EDITANDO
object rightPanel inherits ClickTargets {
	// El panel que se ve (noPanel antes de empezar a jugar)
	var activePanel = noPanel
	// El panel de la máquina que se está editando: lo elige la máquina al abrirse
	var editor = editMenu

	method activePanel() = activePanel
	method editor() = editor

	override method zones() = [hud.interactiveZone(), hud.bannerZone()]
	override method clickTargets() = [activePanel]

	method show() {
		modeBanner.show()
		self.modeChanged(toolsManager.mode())
	}

	// ----------- LO QUE LE AVISA toolsManager -----------

	// Cambió el modo: el cartel y el panel
	method modeChanged(mode) {
		modeBanner.change(mode)
		const newPanel = mode.panelIn(self)
		if (newPanel != activePanel) {
			activePanel.hide()
			activePanel = newPanel
			activePanel.show()
		}
	}

	// Cambió la dirección con la que se colocan las máquinas: el menú de colocar la muestra
	method directionChanged() { placeMenu.updateImages() }

	// Q y E: la máquina anterior o la siguiente del menú de colocar (si estaba editando, vuelve a colocar)
	method chooseMachine(step) {
		toolsManager.stopEditing()
		placeMenu.chooseNext(step)
	}

	// Editando: las flechas y Enter van al panel de la máquina
	method moveFocus(direction) { activePanel.moveFocus(direction) }
	method chooseFocused() { activePanel.chooseFocused() }

	// ----------- EDITAR UNA MÁQUINA (doble despacho) -----------

	method edit(machine) { machine.openEditorIn(self) }

	// Una máquina con ajustes (horno, dispenser, ensamblador...)
	method editSettings(machine) { self.startEditing(editMenu, machine) }

	// Un brazo: se eligen sus lados (o sus ingredientes)
	method editArm(arm) { self.startEditing(armMenu, arm) }

	// Una máquina sin nada para ajustar (la cinta, el platito) o una celda vacía
	method nothingToEdit() { sfx.invalid() }

	method startEditing(panel, machine) {
		panel.selectMachine(machine)
		editor = panel
		toolsManager.startEditing()
	}
}

// "Ningún panel": el que hay antes de empezar a jugar
object noPanel inherits ClickTargets {
	override method zones() = []
	override method clickTargets() = []
	method show() {}
	method hide() {}
	method moveFocus(direction) {}
	method chooseFocused() {}
}
