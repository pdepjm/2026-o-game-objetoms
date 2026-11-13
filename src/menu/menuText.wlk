// Buffet Albert Einstein - los textos de los menús.
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

// Un texto de los menús: el título de una categoría, el nombre de un setting, una opción sin imagen
// o una línea de la información del nivel. Lo usan editMenu y levelInfoMenu.
// El texto es fijo: para cambiarlo, se saca el visual y se agrega uno nuevo.
class MenuText {
    const property text
    const property position
    const property textColor = "FFFFFFFF"

    // Lo que dice (lo entiende también KeyHint, que es una imagen: así se pueden pedir las dos cosas juntas)
    method description() = text

    method isText() = true

    method hide() { game.removeVisual(self) }
}
