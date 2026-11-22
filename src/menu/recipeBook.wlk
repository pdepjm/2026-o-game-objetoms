// Buffet Albert Einstein - el recetario que se puede abrir y hojear durante el juego.
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
import simulation.simulationEngine.*
import sound.sfx.*
import cellPosition.*
import menu.visuals.*

// La página que se ve: guarda su imagen, que cambia sólo al pasar de página (no se arma en cada frame)
object recipePage inherits Picture(image = "recipes_book/recetario_page0.png", position = new CellPosition(x = 0, y = 0)) {
	method showPage(page) { image = "recipes_book/recetario_page" + page + ".png" }
}

// El recetario es una máquina de estados: cerrado (closedBook) o abierto (openBook). Cada estado sabe
// qué pasa con cada mensaje (abrir, cerrar, pasar de página) y qué pantalla ve el jugador mientras está
// en ese estado (screenOver), así nadie tiene que preguntar si está abierto.
object recipeBook {
	var property currentPage = 0
	const maxPages = 10
	var state = closedBook
	var pausedByBook = false 

	// Sólo para consultar (los tests): nadie decide nada con esto, los estados resuelven solos
	method isOpen() = state.isOpen()

	method currentPageNumber() = currentPage
	method isFirstPage() = currentPage == 0
	method isLastPage() = currentPage == maxPages

	// La pantalla que recibe los clicks y las teclas: la de abajo si el libro está cerrado, la del libro si está abierto
	method screenOver(screen) = state.screenOver(screen)

	// Un clic con el libro abierto: la cruz lo cierra (y vuelve a mostrar la pantalla de abajo), las flechas
	// y las mitades del libro pasan de página (ver bookButtons)
	method clickAt(pos, screen) {
		if (bookButtons.isClose(pos)) self.toggleOver(screen)
		else if (pos.x().between(0, 10)) self.prevPage()
		else if (pos.x().between(11, 21)) self.nextPage()
	}

	// La tecla F: abre o cierra el libro, y la pantalla de abajo se oculta o se vuelve a mostrar
	method toggleOver(screen) { state.toggleOver(self, screen) }

	method open() { state.open(self) }

	method close() { state.close(self) }

	method toggle() { state.toggle(self) }

	method nextPage() { state.nextPage(self) }

	method prevPage() { state.prevPage(self) }

	// Lo que cambia al pasar de un estado a otro (lo llaman los estados)
	method opened() {
		state = openBook
		pausedByBook = simulationEngine.running() && !simulationEngine.paused()
		if (pausedByBook) simulationEngine.pause()
		recipePage.showPage(currentPage)
		recipePage.show()
		bookButtons.show()
		sfx.pageChange()
	}

	method closed() {
		state = closedBook
		recipePage.hide()
		bookButtons.hide()
		if (pausedByBook) simulationEngine.resume()
		pausedByBook = false
		sfx.pageChange()
	}

	method turnForward() {
		if (currentPage < maxPages) self.turnTo(currentPage + 1)
	}

	method turnBack() {
		if (currentPage > 0) self.turnTo(currentPage - 1)
	}

	method turnTo(page) {
		currentPage = page
		self.updateVisual()
		sfx.pageChange()
	}

	// La página nueva, y los botones arriba de ella
	method updateVisual() {
		recipePage.showPage(currentPage)
		bookButtons.show()
	}
}

object closedBook {
	method isOpen() = false
	method screenOver(screen) = screen
	method toggleOver(book, screen) {
		screen.hideForRecipeBook()
		book.open()
	}
	method open(book) { book.opened() }
	method close(book) {}
	method toggle(book) { self.open(book) }
	method nextPage(book) {}
	method prevPage(book) {}
}

object openBook {
	method isOpen() = true
	method screenOver(screen) = new BookScreen(under = screen)
	method toggleOver(book, screen) {
		book.close()
		screen.showAfterRecipeBook()
	}
	method open(book) {}
	method close(book) { book.closed() }
	method toggle(book) { self.close(book) }
	method nextPage(book) { book.turnForward() }
	method prevPage(book) { book.turnBack() }
}

// Con el libro abierto no se juega: se tapa todo. Las teclas del juego no hacen nada; los clics y las
// flechas pasan de página, y Retroceso, F o la cruz lo cierran (y vuelve a mostrarse la pantalla de abajo: under).
class BookScreen {
	const under

	method onClick(pos) { recipeBook.clickAt(pos, under) }
	method whenPlaying(action) {}
	method start() {}
	method arrow(direction) { direction.turnPage(recipeBook) }
	method back() { recipeBook.toggleOver(under) }
}

// Los botones del libro abierto (assets/menu/book_*.png, ver makeBoardUi.py): las flechas a los costados
// (con su tecla abajo) y la cruz arriba a la derecha, encima de la que traen dibujada las recetas.
// Sólo cambian al pasar de página (las flechas se apagan en la primera y en la última).
object bookButtons {
	const prev = new BookButton(position = new CellPosition(x = 0, y = 5.4), name = "book_prev")
	const next = new BookButton(position = new CellPosition(x = 21, y = 5.4), name = "book_next")
	const close = new BookButton(position = new CellPosition(x = 18.82, y = 10.46), name = "book_close")

	// La cruz ocupa x 19 y 20, filas 10 y 11
	method isClose(pos) = pos.x().between(19, 20) && pos.y().between(10, 11)

	method show() {
		prev.update(recipeBook.isFirstPage())
		next.update(recipeBook.isLastPage())
		[prev, next, close].forEach({ button =>
			if (game.hasVisual(button)) game.removeVisual(button)
			game.addVisual(button)
		})
	}

	method hide() {
		[prev, next, close].forEach({ button => if (game.hasVisual(button)) game.removeVisual(button) })
	}
}

class BookButton inherits Picture(image = "menu/book_close.png") {
	const name

	override method initialize() {
		super()
		image = "menu/" + name + ".png"
	}

	// Apagado en la primera página (la flecha de volver) o en la última (la de avanzar)
	method update(off) { image = "menu/" + name + (if (off) "_off" else "") + ".png" }
}
