// Buffet Albert Einstein - la insignia de una máquina: lo que tiene seleccionado, arriba a la derecha.
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

// La insignia de una máquina: un círculo con lo que tiene seleccionado, en su esquina de arriba a la derecha
class Badge {
	const machine
	var image = ""
	var position = new CellPosition(x = 0, y = 0)

	method image() = image
	method position() = position

	// Le pregunta a la máquina qué tiene seleccionado y busca su insignia
	method update() {
		image = machine.selectedFood().badgeImage()
	}

	// Se ubica arriba a la derecha de la máquina (según su tamaño), busca su imagen y se dibuja
	method show() {
		const cell = machine.cell()
		position = new CellPosition(x = cell.x() + machine.width() - 0.42, y = cell.y() + machine.height() - 0.4)
		self.update()
		if (!game.hasVisual(self)) game.addVisual(self)
	}

	method hide() { if (game.hasVisual(self)) game.removeVisual(self) }
}
