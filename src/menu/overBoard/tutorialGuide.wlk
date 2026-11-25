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
import levels.levelManager.*
import levels.tutorial.*

// Lo que dice el tutorial lo decide levels/tutorial.wlk: acá sólo se dibuja.

// ----------- EL COCINERO -----------

// El globo del cocinero, como parte clickeable de playingScreen
object chefBubble {
	method handlesClick(pos) = levelManager.tutorial().waitsForContinue() && chefGuide.bubbleContains(pos)
	method onClick(pos) { levelManager.continueTutorial() }
}

// El cocinero y su globo: UNA imagen ya dibujada por mensaje (assets/tutorial/steps/, ver el README)
object chefGuide {
	// Lo que entra en el globo (no se controla al dibujar: lo revisan los tests).
	const property maxLines = 6
	const property maxLength = 16
	const errorMillis = 1700

	var speech = noSpeech
	// Las líneas de la queja (para los tests): se dibuja siempre la misma imagen de error
	var complaint = []
	// Cada queja tiene un número: la que vence sólo borra la queja si no vino otra después
	var complaintId = 0
	const drawn = new VisualGroup()
	// Mientras se cocina, el cocinero no se ve: sigue sabiendo qué dice
	var silenced = false

	method message() = speech.lines()
	method stepLabel() = speech.label()
	// Las teclas que dice, por nombre
	method keys() = speech.keys()
	method complaint() = complaint
	// Lo que tiene dibujado (para los tests de rendimiento)
	method drawnVisuals() = drawn.visuals()

	method layout() = self.layoutOf(speech)

	method layoutOf(aSpeech) = new ChefLayout(focus = aSpeech.focus(), rows = aSpeech.lines().size() + aSpeech.keys().size())

	// Lo que tiene que tener dibujado la imagen de ese mensaje (makeSteps.py la dibuja con esto, y un test lo compara)
	method signatureOf(aSpeech) = self.layoutOf(aSpeech).signatureOf(aSpeech)

	// El mensaje del paso. Si dice lo mismo que ya está diciendo, no redibuja nada
	method say(newSpeech) {
		const same = newSpeech.image() == speech.image() && newSpeech.lines() == speech.lines() && !self.isComplaining()
		if (!same) {
			speech = newSpeech
			complaint = []
			self.redraw()
		}
	}

	// El jugador hizo algo que el paso no deja: lo dice un momento y vuelve al mensaje del paso
	method complain(complaintLines) {
		if (!complaintLines.isEmpty() && !self.message().isEmpty()) {
			complaint = complaintLines
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
	method bubbleContains(pos) = !self.message().isEmpty() && !silenced && self.layout().bubbleZone().contains(pos)

	method redraw() {
		drawn.clear()
		if (!self.message().isEmpty() && !silenced) drawn.add(self.picture())
	}

	method picture() = if (self.isComplaining()) self.layout().errorPicture() else self.layout().pictureOf(speech)
}

// Dónde se paran el cocinero y su globo para señalar una celda, en celdas (makeSteps.py dibuja con estas medidas)
class ChefLayout {
	const focus
	// Las líneas del globo más una por tecla
	const rows
	// El cocinero mide 120x160 px; la punta de la cuchara queda 25 px adentro de su borde
	const chefWidth = 2.4
	const chefHeight = 3.2
	// El globo: 200 px de ancho más la cola (14 px), separado del cocinero
	const bubbleWidth = 4.28
	const gap = 0.05
	// Hasta dónde puede llegar el globo a la derecha: el borde del panel de la derecha
	const rightLimit = 18
	const topLimit = 12.95

	// Arriba de la celda si hay lugar; si no, abajo
	method pose() = if (focus.y() + 1 + chefHeight <= topLimit) aboveCell else belowCell

	// En las primeras columnas no entra a la izquierda de la celda: se para a su derecha
	method facing() = if (focus.x() <= 6) facingLeft else facingRight

	// La punta de la cuchara cae en el medio de la celda
	method chefLeft() = self.facing().chefLeft(focus, chefWidth)

	method chefBottom() = self.pose().chefBottom(focus, chefHeight)

	method chefTop() = self.chefBottom() + chefHeight

	// A la derecha del cocinero si entra antes del panel de la derecha
	method bubbleSide() = if (self.chefLeft() + chefWidth + gap + bubbleWidth <= rightLimit) bubbleOnRight else bubbleOnLeft

	method bubbleLeft() = self.bubbleSide().bubbleLeft(self.chefLeft(), chefWidth, bubbleWidth, gap)

	// 16 px arriba de la etiqueta del paso, 25 por la primera fila, 27.5 por cada otra y 18 abajo
	method bubbleHeight() = (16 + 25 + (rows - 1) * 27.5 + 18).round() / 50

	// El globo arranca a la altura de la cabeza del cocinero, sin salirse de la pantalla
	method bubbleTop() = self.chefTop().min(topLimit).max(self.bubbleHeight() + 0.1)

	// La caja que ocupan el cocinero y el globo juntos: la imagen se dibuja en su esquina de abajo a la izquierda
	method left() = self.chefLeft().min(self.bubbleLeft())
	method top() = self.chefTop().max(self.bubbleTop())
	method bottom() = self.chefBottom().min(self.bubbleTop() - self.bubbleHeight())

	method pictureOf(speech) = new Picture(image = "tutorial/steps/" + speech.image() + ".png", position = new CellPosition(x = self.left(), y = self.bottom()))

	// La queja: el cocinero en el mismo lugar, con el globo de error del mismo lado
	method errorPicture() = new Picture(image = "tutorial/steps/oops_" + self.bubbleSide().name() + ".png", position = new CellPosition(x = self.left(), y = self.chefBottom()))

	// Las celdas que toca el globo (tiene decimales: se cuentan las celdas que pisa aunque sea un poco)
	method bubbleZone() = new Zone(
		minX = self.bubbleLeft().truncate(0), maxX = (self.bubbleLeft() + bubbleWidth).roundUp() - 1,
		minY = (self.bubbleTop() - self.bubbleHeight()).truncate(0), maxY = self.bubbleTop().roundUp() - 1
	)

	// En px desde la esquina de arriba a la izquierda de la imagen
	method px(cells) = (cells * 50).round().toString()

	// imagen;paso;líneas;teclas;cara;pose;mira;lado del globo;cocinero x;y;globo x;y;ancho;alto
	method signatureOf(speech) = [
		speech.image(), speech.label(), speech.lines().join("|"), speech.keys().join(","), speech.mood(),
		self.pose().name(), self.facing().name(), self.bubbleSide().name(),
		self.px(self.chefLeft() - self.left()), self.px(self.top() - self.chefTop()),
		self.px(self.bubbleLeft() - self.left()), self.px(self.top() - self.bubbleTop()),
		self.px(chefWidth + gap + bubbleWidth), self.px(self.top() - self.bottom())
	].join(";")
}

// Parado arriba de la celda, la señala hacia abajo (el nombre es el de sus imágenes)
object aboveCell {
	method name() = "down"
	method chefBottom(focus, chefHeight) = focus.y() + 0.9
}

// Parado abajo de la celda, la señala hacia arriba
object belowCell {
	method name() = "up"
	method chefBottom(focus, chefHeight) = focus.y() + 0.1 - chefHeight
}

// A la izquierda de la celda, mirando a la izquierda
object facingLeft {
	method name() = "left"
	method chefLeft(focus, chefWidth) = focus.x()
}

// A la derecha de la celda, mirando a la derecha
object facingRight {
	method name() = "right"
	method chefLeft(focus, chefWidth) = focus.x() + 0.5 - (chefWidth - 0.5)
}

// El globo a la derecha del cocinero
object bubbleOnRight {
	method name() = "right"
	method bubbleLeft(chefLeft, chefWidth, bubbleWidth, gap) = chefLeft + chefWidth + gap
}

// El globo a la izquierda del cocinero
object bubbleOnLeft {
	method name() = "left"
	method bubbleLeft(chefLeft, chefWidth, bubbleWidth, gap) = chefLeft - bubbleWidth - gap
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
