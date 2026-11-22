// Buffet Albert Einstein - el cartel COLOCANDO / EDITANDO, arriba a la derecha.
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
import menu.menuManager.*

// El cartel de arriba a la derecha (bannerZone): dice si el jugador está COLOCANDO o EDITANDO.
// Guarda la imagen: sólo cambia cuando cambia el modo (menuManager.modeChanged).
object modeBanner {
    var image = "menu/mode_placing.png"
    const zone = menuManager.bannerZone()

    method position() = zone.origin()
    method image() = image
    method change(mode) { image = mode.banner() }
    method show() { if (!game.hasVisual(self)) game.addVisual(self) }
}
