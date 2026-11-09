// Buffet Albert Einstein - las cuatro direcciones (derecha, abajo, izquierda y arriba) y cómo rotar entre ellas.
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

// Este archivo maneja las direcciones de las maquinas
import wollok.game.*
object right {
	method name() = "right"		// Este metodo se utiliza para obtener las imagenes de las maquinas rotadas
    method next() = down		// Este metodo se utiliza para rotar las maquinas que ya fueron colocadas
	method previous() = up		// El giro contrario a next
	method move(position) = position.right(1)		// Es metodo esta pensado para dirigir los ingredientes hacia algun lugar
	method invert() = left
	method output(startPoint, width, height) = startPoint.right(width)
}
object down {
	method name() = "down"
    method next() = left
	method previous() = right		// El giro contrario a next
	method move(position) = position.down(1)
	method invert() = up
	method output(startPoint, width, height) = startPoint.down(1)
}
object left {
	method name() = "left"
    method next() = up
	method previous() = down		// El giro contrario a next
	method move(position) = position.left(1)
	method invert() = right
	method output(startPoint, width, height) = startPoint.left(1)
}
object up {
	method name() = "up"
    method next() = right
	method previous() = left		// El giro contrario a next
	method move(position) = position.up(1)
	method invert() = down
	method output(startPoint, width, height) = startPoint.up(height)
}
