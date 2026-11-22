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

// Wollok le pide position() e image() a cada visual en cada frame: por eso acá la posición es una
// constante (se arma una vez, al crearla) y la imagen se guarda (sólo cambia cuando alguien la cambia).
// Las posiciones son CellPosition: no crean nada al dibujarse (ver cellPosition.wlk).

// Una imagen en un lugar fijo de la pantalla. Las subclases pueden cambiar la imagen (image = ...).
class Picture {
	var image
	const property position

	method image() = image
	method show() { if (!game.hasVisual(self)) game.addVisual(self) }
	method hide() { if (game.hasVisual(self)) game.removeVisual(self) }
}

// Un lugar que se clickea: celdas enteras, porque Wollok avisa el clic por celda. Al clickearlo hace su
// acción (action). No se dibuja: para eso está Button.
class CellArea {
	// La celda de abajo a la izquierda
	const property position
	const width = 1
	const height = 1
	const action = {}

	method contains(pos) =
		pos.x().between(position.x(), position.x() + width - 1) && pos.y().between(position.y(), position.y() + height - 1)
	method press() { action.apply() }
}

// Un botón: un lugar que se clickea, con su imagen. Las subclases pueden cambiar la imagen (image = ...).
class Button inherits CellArea {
	var image

	method image() = image
	method show() { if (!game.hasVisual(self)) game.addVisual(self) }
	method hide() { if (game.hasVisual(self)) game.removeVisual(self) }
}

// "Ningún botón": lo que se clickeó cuando el clic no cayó en ninguno
object noButton {
	method contains(pos) = false
	method press() {}
}

// Lo que dibujó un panel, para poder sacarlo todo junto. Cada cosa sabe sacarse (hide): una imagen, un
// texto de Wollok o un texto escrito con una imagen por letra (SpriteLine).
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
