// Buffet Albert Einstein - lo común de los clics: los moldes para que algo se pueda clickear.
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

import cellPosition.*

// Un grupo de cosas clickeables (una pantalla, el HUD, un panel).
class ClickTargets {
	// Dónde está el grupo en la pantalla (una lista de Zone)
	method zones()
	// Sus partes, de la que se ve más arriba a la de más abajo
	method clickTargets()

	method handlesClick(pos) = self.zones().any({ zone => zone.contains(pos) })

	method onClick(pos) {
		self.clickTargets().findOrDefault({ target => target.handlesClick(pos) }, nothingClicked).onClick(pos)
	}
}

// Un lugar que se clickea: una zona y lo que hace al clickearla (action).
class CellArea {
	const property zone
	const action = {}

	method handlesClick(pos) = zone.contains(pos)
	method onClick(pos) { self.press() }
	// Lo mismo que clickearlo (por ejemplo, Enter en el ticket aprieta su primer botón)
	method press() { action.apply() }
}

// "Nadie": lo que recibe un clic que no es de ninguna de las partes.
object nothingClicked {
	method handlesClick(pos) = false
	method onClick(pos) {}
	method press() {}
}
