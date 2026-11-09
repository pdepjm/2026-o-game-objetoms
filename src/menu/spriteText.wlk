// Buffet Albert Einstein - textos escritos con una imagen por letra, sin contorno.
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
import menu.spriteFonts.*

// Textos escritos con una imagen por letra, sin el contorno oscuro con el que Wollok dibuja todos sus
// textos (no se puede sacar, y sobre el papel de la info del nivel se ve raro). Las letras y sus anchos
// los genera assets/menu/font/makeFont.py (los anchos quedan en spriteFonts.wlk).
//
// Cada letra es un visual. Se usa sólo para textos cortos que cambian poco (los redibuja levelInfoMenu
// cuando le avisan algo, nunca en cada frame).
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
				const glyph = new Glyph(image = font.image(char), position = new CellPosition(x = x / 50, y = bottom))
				game.addVisual(glyph)
				glyphs.add(glyph)
			}
			x += font.width(char)
		})
		return new SpriteLine(text = text, glyphs = glyphs)
	}

	method charsOf(text) = if (text.isEmpty()) [] else (0 .. text.size() - 1).map({ index => text.charAt(index) })
}

// Un estilo de letra: la carpeta de sus imágenes y el ancho de cada letra, en px, en el orden de
// spriteFontChars. Una letra que no está se escribe como "?".
class SpriteFont {
	const folder
	const widths
	const indexes = new Dictionary()

	override method initialize() {
		const chars = spriteFontChars.chars()
		(0 .. chars.size() - 1).forEach({ index => indexes.put(chars.get(index), index) })
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
	method isText() = true

	method hide() {
		glyphs.forEach({ glyph => game.removeVisual(glyph) })
	}
}

// Una letra. No tiene text(): Wollok la dibujaría con contorno, que es justo lo que se evita.
class Glyph {
	const property image
	const property position
}
