// Buffet Albert Einstein - la columna de la izquierda: la info del nivel y los botones.
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

import menu.screenClasses.*
import menu.hud.hud.*
import menu.hud.levelInfoMenu.*

// La columna de la izquierda (x 0 a 4): arriba la info del nivel
object leftPanel {
	// Un clic en la columna que no es de ningún botón no hace nada
	const wholeColumn = new CellArea(zone = hud.leftZone())

	method clickableAreas() = [skipTutorialButton] + sideButtons.clickableAreas() + [wholeColumn]

	method show() { sideButtons.show() }
}
