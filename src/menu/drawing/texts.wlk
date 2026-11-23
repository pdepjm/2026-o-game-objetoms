// Buffet Albert Einstein - los textos de los menús: los de Wollok y los escritos con una imagen por letra.
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
import menu.drawing.spriteFonts.*
import menu.drawing.visuals.*

// Un texto de los menús: el título de una categoría, el nombre de un setting
class MenuText {
    const property text
    const property position
    const property textColor = "FFFFFFFF"

    // Lo que dice
    method description() = text

    method textLines() = [text]
    method barImages() = []

    method hide() { if (game.hasVisual(self)) game.removeVisual(self) }
}

// Textos escritos con una imagen por letra
object spriteText {
	// Escribe el texto centrado en ese punto (en celdas: el centro de la celda x, y es x + 0.5, y + 0.5)
	method draw(text, font, centerX, centerY) {
		const chars = self.charsOf(text)
		var x = centerX * 50 - chars.sum({ char => font.width(char) }) / 2
		// la letra mide 20 px de alto: su borde de abajo queda 10 px debajo del centro
		const bottom = centerY - 0.2
		const glyphs = []
		chars.forEach({ char =>
			if (char != " ") {
				// una letra es una imagen sin text(): así Wollok no la dibuja con contorno
				const glyph = new Picture(image = font.image(char), position = new CellPosition(x = x / 50, y = bottom))
				game.addVisual(glyph)
				glyphs.add(glyph)
			}
			x += font.width(char)
		})
		return new SpriteLine(text = text, glyphs = glyphs)
	}

	method charsOf(text) = if (text.isEmpty()) [] else (0 .. text.size() - 1).map({ index => text.charAt(index) })
}

// Un estilo de letra: la carpeta de sus imágenes y el ancho de cada letra, en px
class SpriteFont {
	const folder
	const widths
	const indexes = new Dictionary()

	override method initialize() {
		(0 .. spriteFontChars.size() - 1).forEach({ index => indexes.put(spriteFontChars.get(index), index) })
	}

	method indexOf(char) = indexes.getOrElse(char, { => indexes.get("?") })
	method width(char) = widths.get(self.indexOf(char))
	method image(char) = folder + self.indexOf(char) + ".png"
}

// Un texto ya escrito: sus letras, y lo que dice (para los tests)
class SpriteLine {
	const property text
	const glyphs

	method description() = text
	method textLines() = [text]
	method barImages() = []

	method hide() {
		glyphs.forEach({ glyph => glyph.hide() })
	}
}
