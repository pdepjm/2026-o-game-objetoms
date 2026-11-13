// Buffet Albert Einstein - la barra que muestra la herramienta activa.
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
import tools.toolsManager.*
import menu.menuManager.*

object toolBar {
    var image = "tools/default.png"
    const zone = menuManager.toolBarZone()

    method position() = zone.origin()
    method image() = image
    method refresh() {
        if (toolsManager.selectedTool() != null)
            image = "tools/" + toolsManager.selectedTool().name() + "_selected.png"
        else
            image = "tools/default.png"
    }
    method show() {game.addVisual(self)}
}
