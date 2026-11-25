// Buffet Albert Einstein - la posición fija en una celda, para las cosas que no se mueven.
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

// Posición fija en una celda (coordenadas enteras), para las cosas que no se mueven
class CellPosition inherits Position {
	override method round() = self
	// las posiciones vecinas (right, up, etc.) también son de celda
	override method createPosition(_x, _y) = new CellPosition(x = _x, y = _y)
}

// Un rectángulo de celdas, de (minX, minY) a (maxX, maxY), con los bordes incluidos.
class Zone {
	const minX
	const maxX
	const minY
	const maxY

	method contains(pos) = pos.x().between(minX, maxX) && pos.y().between(minY, maxY)

	// Posición relativa desde la esquina inferior izquierda
	method at(dx, dy) = new CellPosition(x = minX + dx, y = minY + dy)

	// La esquina inferior izquierda
	method origin() = self.at(0, 0)
}

// Para armar una zona desde su esquina de abajo a la izquierda y su tamaño en celdas
object rectangle {
	method of(x, y, width, height) = new Zone(minX = x, maxX = x + width - 1, minY = y, maxY = y + height - 1)
	method cell(position) = self.of(position.x(), position.y(), 1, 1)
}

// Toda la pantalla: la zona de una pantalla del menú, que recibe todos los clics
object wholeScreen {
	method contains(pos) = true
}

// Ningún lugar: la zona de algo que hoy no se ve
object nowhere {
	method contains(pos) = false
}
