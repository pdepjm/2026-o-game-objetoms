// Buffet Albert Einstein - el panel para editar un brazo: hacia dónde manda cada cosa.
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
import directions.*
import machines.machineClasses.*
import menu.hud.hud.*
import input.clickManager.*
import menu.drawing.texts.*
import menu.hud.editMenu.*
import menu.drawing.visuals.*
import levels.levelManager.*
import sound.sfx.*

// Panel de la zona interactiva (x 18 a 21) mientras se edita un brazo (X sobre él).
object armMenu inherits ClickTargets {
	const columns = 4
	const firstRow = 7
	var arm = noMachine
	var visible = false
	// El panel, y al lado del brazo, en el tablero, lo que sale por cada lado
	const drawn = new VisualGroup()
	const preview = new VisualGroup()
	// El casillero marcado para el teclado (flechas y Enter).
	var focusIndex = 0
	var usingKeyboard = false
	// Lo que se clickea: un lugar por casillero (se arman al dibujar)
	var areas = []

	method arm() = arm

	// ----------- LO QUE LE MANDA rightPanel -----------

	method show() {
		visible = true
		focusIndex = 0
		usingKeyboard = false
		self.render()
	}

	method hide() {
		visible = false
		self.clear()
		arm = noMachine
	}

	// Lo llama rightPanel cuando un brazo pide que lo editen
	method selectMachine(machine) {
		arm = machine
		if (visible) self.render()
	}

	// Los clics del panel: cada casillero sabe cuál es
	override method zones() = [hud.interactiveZone()]
	override method clickTargets() = areas

	// Las flechas mueven la marca por los casilleros, y Enter usa el marcado
	method moveFocus(direction) {
		const size = self.choices().size()
		if (size > 0) {
			usingKeyboard = true
			focusIndex = (focusIndex + direction.listStep() + size).rem(size)
			self.updateFocus()
			sfx.directionChange()
		}
	}

	method chooseFocused() { if (!self.choices().isEmpty()) self.choose(focusIndex) }

	method focusIndex() = focusIndex

	// ----------- LOS CASILLEROS -----------

	method choices() = arm.editChoices()

	method cellOf(index) = hud.interactiveZone().at(index.rem(columns), firstRow - index.div(columns))

	method choose(index) {
		self.choices().get(index).choose()
		focusIndex = index
		sfx.menuSelect()
		self.render()
		// el tutorial se entera (y la energía se actualiza) como con cualquier setting
		levelManager.settingChanged(arm, arm.settings().first())
	}

	// ----------- DIBUJO -----------

	method render() {
		self.clear()
		drawn.add(new MenuText(text = arm.editTitle(), position = hud.interactiveZone().at(1.5, 11), textColor = "FFD700FF"))
		drawn.add(new Picture(image = arm.editBoxImage(), position = hud.interactiveZone().at(0, 9)))
		drawn.add(new Picture(image = "menu/arm_grab_" + arm.inputSide().name() + ".png", position = hud.interactiveZone().at(2, 9)))
		drawn.add(new MenuText(text = arm.editHint(), position = hud.interactiveZone().at(1.5, 8), textColor = "FFD700FF"))
		const choices = self.choices()
		(0 .. choices.size() - 1).forEach({ index =>
			const cell = self.cellOf(index)
			choices.get(index).images().forEach({ image => drawn.add(new Picture(image = image, position = cell)) })
		})
		areas = (0 .. choices.size() - 1).map({ index => new CellArea(zone = rectangle.cell(self.cellOf(index)), action = { self.choose(index) }) })
		self.updateFocus()
		self.drawPreview()
	}

	// La marca del teclado, arriba de los casilleros
	method updateFocus() {
		if (game.hasVisual(optionFocus)) game.removeVisual(optionFocus)
		if (visible && usingKeyboard && !self.choices().isEmpty()) {
			optionFocus.moveTo(self.cellOf(focusIndex.min(self.choices().size() - 1)))
			game.addVisual(optionFocus)
		}
	}

	// Al lado del brazo, en el tablero: una flecha por cada lado por el que sale algo, y qué sale
	method drawPreview() {
		[up, right, down, left].filter({ side => side != arm.inputSide() && arm.sendsTo(side) }).forEach({ side =>
			const cell = side.move(arm.cell())
			preview.add(new Picture(image = "menu/arm_tag_" + side.name() + ".png", position = new CellPosition(x = cell.x() + 0.02, y = cell.y() + 0.36)))
			var x = cell.x() + 0.5
			arm.kindsTo(side).take(2).forEach({ kind =>
				preview.add(new Picture(image = kind.badgeImage(), position = new CellPosition(x = x, y = cell.y() + 0.36)))
				x += 0.6
			})
		})
	}

	method clear() {
		drawn.clear()
		preview.clear()
		areas = []
		if (game.hasVisual(optionFocus)) game.removeVisual(optionFocus)
	}

	// La dirección para colocar no cambia nada acá, pero rightPanel puede avisar igual
	method updateImages() {}
}
