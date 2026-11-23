// Buffet Albert Einstein - lo que tienen en común las imágenes y los botones de los menús.
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
import input.clickManager.*

// Wollok le pide position() e image() a cada visual en cada frame

// Una imagen en un lugar fijo de la pantalla.
class Picture {
	var image
	const property position

	method image() = image
	method show() { if (!game.hasVisual(self)) game.addVisual(self) }
	method hide() { if (game.hasVisual(self)) game.removeVisual(self) }
}

// Un botón: un lugar que se clickea (CellArea, input/clickManager.wlk), con su imagen.
class Button inherits CellArea {
	var image
	var position = new CellPosition(x = 0, y = 0)

	override method initialize() {
		super()
		position = zone.origin()
	}

	method position() = position
	method image() = image
	method show() { if (!game.hasVisual(self)) game.addVisual(self) }
	method hide() { if (game.hasVisual(self)) game.removeVisual(self) }
}

// Lo que dibujó un panel, para poder sacarlo todo junto.
class VisualGroup {
	var visuals = []

	method visuals() = visuals
	method isEmpty() = visuals.isEmpty()

	// La agrega a la pantalla y se acuerda de ella
	method add(visual) {
		game.addVisual(visual)
		visuals.add(visual)
		return visual
	}

	// Se acuerda de algo que ya se dibujó solo (un texto con una imagen por letra, el botón de saltear)
	method keep(drawing) {
		visuals.add(drawing)
		return drawing
	}

	method clear() {
		visuals.forEach({ visual => visual.hide() })
		visuals = []
	}
}
