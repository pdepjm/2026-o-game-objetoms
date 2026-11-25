// Buffet Albert Einstein - los moldes de las pantallas y de lo que se clickea en ellas.
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

import menu.screenManager.*
import menu.screens.*

// Una pantalla: declara sus zonas clickeables y sus teclas; lo demás lo hace igual que todas.
class Screen {
	// Lo que se clickea, de lo que se ve más arriba a lo de más abajo
	method clickableAreas()
	// Las teclas propias (las de todas las pantallas van después: sharedKeys)
	method keyActions()
	// Lo que se agrega al entrar y se saca al salir
	method visuals() = []

	method sharedKeys() = [new KeyAction(key = "book", action = { _ => screenManager.openBook() })]

	method onClick(pos) {
		self.clickableAreas().findOrDefault({ area => area.handlesClick(pos) }, nothingClicked).onClick(pos)
	}

	method press(key, value) {
		(self.keyActions() + self.sharedKeys()).findOrDefault({ keyAction => keyAction.is(key) }, noKeyAction).run(value)
	}

	method show() { self.visuals().forEach({ visual => visual.show() }) }
	method hide() { self.visuals().forEach({ visual => visual.hide() }) }
	method leave() { self.hide() }

	// Con otra pantalla encima, queda como está
	method hideUnderOverlay() {}
	method showAfterOverlay() {}
}

// Una pantalla que se abre encima de otra: recuerda cuál quedó abajo.
class OverlayScreen inherits Screen {
	var under = coverScreen

	method under() = under
	method under(screen) { under = screen }

	override method leave() {
		self.hide()
		under.leave()
	}
}

// Un lugar que se clickea: una zona y lo que hace al clickearla.
class CellArea {
	const property zone
	const action = {}

	method handlesClick(pos) = zone.contains(pos)
	method onClick(pos) { action.apply() }
}

// Una tecla que entiende una pantalla y lo que hace (recibe el valor de la tecla: una dirección, un número).
class KeyAction {
	const key
	const action

	method is(aKey) = key == aKey
	method run(value) { action.apply(value) }
}

// "Nadie": lo que recibe un clic que no es de ninguna zona.
object nothingClicked {
	method handlesClick(pos) = false
	method onClick(pos) {}
}

// Lo que hace una tecla que la pantalla no usa: nada.
object noKeyAction {
	method run(value) {}
}
