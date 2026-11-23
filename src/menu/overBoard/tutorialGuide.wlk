// Buffet Albert Einstein - lo que el tutorial dibuja sobre el tablero: el cocinero y las marcas.
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
import board.*
import menu.drawing.visuals.*
import menu.drawing.texts.*
import menu.drawing.spriteFonts.*
import menu.overBoard.bubbleTexts.*
import levels.levelManager.*

// Lo que dice el tutorial lo decide levels/tutorial.wlk: acá sólo se dibuja.

// ----------- EL COCINERO -----------

// El globo del cocinero, como parte clickeable de playingScreen
object chefBubble {
	method handlesClick(pos) = levelManager.tutorial().waitsForContinue() && chefGuide.bubbleContains(pos)
	method onClick(pos) { levelManager.continueTutorial() }
}
object chefGuide {
	// Lo que entra en el globo (no se controla al dibujar: lo revisan los tests).
	const property maxLines = 6
	const property maxLength = 16

	// El cocinero mide 120x160 px; la punta de la cuchara queda 25 px adentro de su borde
	const chefWidth = 2.4
	const chefHeight = 3.2
	// El globo: 200 px de ancho más la cola (14 px).
	const bubbleWidth = 4.28
	const lineHeight = 0.55
	// Hasta dónde puede llegar el globo a la derecha: el borde del panel de la derecha
	const rightLimit = 18
	const topLimit = 12.95
	const errorMillis = 1700

	// Lo que dice el paso (para los tests), y la celda que señala.
	var lines = []
	var stepLabel = ""
	var keys = []
	var focus = new CellPosition(x = 9, y = 5)
	var complaint = []
	// Cada queja tiene un número: la que vence sólo borra la queja si no vino otra después
	var complaintId = 0
	const drawn = new VisualGroup()
	// Mientras se cocina, el cocinero no se ve: sigue sabiendo qué dice
	var silenced = false

	method message() = lines
	method stepLabel() = stepLabel
	// Las teclas que dice, por nombre
	method keys() = keys
	method complaint() = complaint
	// Lo que tiene dibujado (para los tests de rendimiento)
	method drawnVisuals() = drawn.visuals()

	// El mensaje del paso. Si dice lo mismo que ya está diciendo, no redibuja nada
	method say(stepLabels, newLines, newKeys, cells) {
		const newLabel = stepLabels.join("")
		const shownLines = newLines.take(maxLines)
		const shownKeys = newKeys.take(maxLines - shownLines.size())
		const newFocus = if (cells.isEmpty()) focus else cells.first()
		const same = shownLines == lines && shownKeys == keys && newLabel == stepLabel
			&& newFocus.x() == focus.x() && newFocus.y() == focus.y() && !self.isComplaining()
		if (!same) {
			lines = shownLines
			keys = shownKeys
			stepLabel = newLabel
			focus = newFocus
			complaint = []
			self.redraw()
		}
	}

	// El jugador hizo algo que el paso no deja: lo dice un momento y vuelve al mensaje del paso
	method complain(complaintLines) {
		if (!complaintLines.isEmpty() && !lines.isEmpty()) {
			complaint = complaintLines.take(maxLines)
			complaintId += 1
			const id = complaintId
			self.redraw()
			game.schedule(errorMillis, { self.calmDown(id) })
		}
	}

	method calmDown(id) {
		if (id == complaintId && !complaint.isEmpty()) {
			complaint = []
			self.redraw()
		}
	}

	method isComplaining() = !complaint.isEmpty()

	method isSilenced() = silenced

	method silence() {
		if (!silenced) {
			silenced = true
			self.redraw()
		}
	}

	method speak() {
		if (silenced) {
			silenced = false
			self.redraw()
		}
	}

	// ¿El clic cayó en una celda que toca el globo?
	method bubbleContains(pos) = !lines.isEmpty() && !silenced && self.bubbleZone().contains(pos)

	// Las celdas que toca el globo (tiene decimales: se cuentan las celdas que pisa aunque sea un poco)
	method bubbleZone() {
		const rows = lines.size() + keys.size()
		const top = self.bubbleTop(rows)
		const left = self.bubbleLeft()
		const bottom = top - self.bubbleHeight(rows)
		return new Zone(minX = left.truncate(0), maxX = (left + bubbleWidth).roundUp() - 1, minY = bottom.truncate(0), maxY = top.roundUp() - 1)
	}

	// ----------- DIBUJO -----------

	method redraw() {
		drawn.clear()
		if (!lines.isEmpty() && !silenced) {
			drawn.add(new Picture(image = self.chefImage(), position = new CellPosition(x = self.chefLeft(), y = self.chefBottom())))
			// al quejarse dice sólo la queja, sin las teclas del paso
			if (self.isComplaining()) self.drawBubble(complaint, []) else self.drawBubble(lines, keys)
		}
	}

	method mood() = if (self.isComplaining()) "oops" else if (stepLabel.isEmpty()) "happy" else "talk"

	// ¿Hay lugar arriba de la celda?
	method pose() = if (focus.y() + 1 + chefHeight <= topLimit) "down" else "up"

	// En las primeras columnas no entra a la izquierda de la celda: se para a su derecha
	method facing() = if (focus.x() <= 6) "left" else "right"

	method chefImage() = "tutorial/chef_" + self.mood() + "_" + self.pose() + "_" + self.facing() + ".png"

	// La punta de la cuchara cae en el medio de la celda (de arriba o de abajo, según la pose)
	method chefLeft() = if (self.facing() == "right") focus.x() + 0.5 - (chefWidth - 0.5) else focus.x()

	method chefBottom() = if (self.pose() == "down") focus.y() + 0.9 else focus.y() + 0.1 - chefHeight

	method chefTop() = self.chefBottom() + chefHeight

	// ¿El globo va a la derecha del cocinero?
	method bubbleOnRight() = self.chefLeft() + chefWidth + 0.05 + bubbleWidth <= rightLimit

	method bubbleLeft() = if (self.bubbleOnRight()) self.chefLeft() + chefWidth + 0.05 else self.chefLeft() - bubbleWidth - 0.05

	// El alto del globo, como en makeChef.py: 16 px arriba de la etiqueta del paso
	method bubbleHeight(lineCount) = (16 + 25 + (lineCount - 1) * lineHeight * 50 + 18) / 50

	// El globo arranca a la altura de la cabeza del cocinero, sin salirse de la pantalla
	method bubbleTop(lineCount) = self.chefTop().min(topLimit).max(self.bubbleHeight(lineCount) + 0.1)

	// Las líneas y, debajo, una fila por tecla: el globo es el de tantas líneas como las dos cosas juntas
	method drawBubble(shown, shownKeys) {
		const rows = shown.size() + shownKeys.size()
		const top = self.bubbleTop(rows)
		const side = if (self.bubbleOnRight()) "left" else "right"
		const kind = if (self.isComplaining()) "error_" else ""
		drawn.add(new Picture(
			image = "tutorial/bubble_" + side + "_" + kind + rows + ".png",
			position = new CellPosition(x = self.bubbleLeft(), y = top - self.bubbleHeight(rows))
		))
		// el cuerpo del globo mide 4 celdas: con la cola a la izquierda, empieza 14 px más adentro
		const centerX = self.bubbleLeft() + 2 + (if (side == "left") 0.28 else 0)
		const label = if (self.isComplaining()) "¡UY!" else stepLabel
		if (!label.isEmpty()) drawn.keep(spriteText.draw(label, labelFont, centerX, top - 0.32))
		const firstLineY = top - 0.82
		bubbleMessages.draw(shown, centerX, firstLineY, lineHeight, drawn)
		// la fila de la tecla mide 200x25 px, como el cuerpo del globo: centrada en el lugar de una línea
		var lineY = firstLineY - shown.size() * lineHeight
		shownKeys.forEach({ key =>
			drawn.add(new Picture(image = "tutorial/key_" + key + ".png", position = new CellPosition(x = centerX - 2, y = lineY - 0.25)))
			lineY -= lineHeight
		})
	}
}

// Los mensajes del globo ya escritos, una imagen por mensaje (assets/tutorial/messages/<número>.png)
object bubbleMessages {
	// El número de imagen de cada mensaje (sus líneas unidas con "|")
	const indexes = new Dictionary()

	override method initialize() {
		(0 .. bubbleTexts.size() - 1).forEach({ index => indexes.put(bubbleTexts.get(index), index) })
	}

	method has(lines) = indexes.containsKey(lines.join("|"))

	method imageOf(lines) = "tutorial/messages/" + indexes.get(lines.join("|")) + ".png"

	// Las líneas, centradas en centerX, con la primera centrada en firstLineY.
	method draw(lines, centerX, firstLineY, lineHeight, group) {
		if (self.has(lines)) {
			const height = ((lines.size() - 1) * lineHeight * 50).roundUp() + 20
			group.add(new Picture(image = self.imageOf(lines), position = new CellPosition(x = centerX - 2, y = firstLineY + 0.2 - height / 50)))
		} else {
			var lineY = firstLineY
			lines.forEach({ line =>
				group.keep(spriteText.draw(line, textFont, centerX, lineY))
				lineY -= lineHeight
			})
		}
	}
}

// ----------- LAS MARCAS SOBRE EL TABLERO -----------

// Los indicadores del tutorial sobre el tablero (las imágenes están en assets/tutorial/)
object tutorialMarks {
	var marks = []
	const errorMillis = 600
	// Mientras se cocina no se ven: se siguen anotando, y vuelven a aparecer al apagar la simulación
	var hidden = false

	method marks() = marks

	// Si las marcas nuevas quedan en los mismos lugares que las que hay, no hace nada
	method show(targetCells, pointedCells) {
		const newMarks = targetCells.map({ cell => new TutorialMark(position = new CellPosition(x = cell.x(), y = cell.y()), normalImage = "tutorial/place.gif", errorImage = "tutorial/place_error.gif") })
			+ pointedCells.map({ cell => new TutorialMark(position = self.arrowPosition(cell), normalImage = "tutorial/look.gif", errorImage = "tutorial/look.gif") })
		if (self.placesOf(newMarks) != self.placesOf(marks)) {
			self.removeVisuals()
			marks = newMarks
			if (!hidden) marks.forEach({ mark => mark.show() })
		}
	}

	// Dónde está y qué es cada marca, para comparar
	method placesOf(someMarks) = someMarks.map({ mark => mark.place() })

	method hide() {
		hidden = true
		self.removeVisuals()
	}

	method reveal() {
		if (hidden) {
			hidden = false
			marks.forEach({ mark => mark.show() })
		}
	}

	method removeVisuals() {
		marks.forEach({ mark => mark.hide() })
	}

	// Arriba de la máquina de esa celda, centrada sobre ella: con una de 2x2
	method arrowPosition(cell) = board.machineAt(cell).arrowPosition(cell)

	// Los recuadros que se ven se ponen rojos y, un momento después, vuelven a la normalidad
	method flashError() {
		const flashed = marks
		flashed.forEach({ mark => mark.showError() })
		game.schedule(errorMillis, { flashed.forEach({ mark => mark.showNormal() }) })
	}
}

class TutorialMark inherits Picture(image = "tutorial/place.gif") {
	const normalImage
	const errorImage

	override method initialize() {
		super()
		image = normalImage
	}

	method showError() { image = errorImage }
	method showNormal() { image = normalImage }
	method place() = normalImage + position.x() + "," + position.y()
}
