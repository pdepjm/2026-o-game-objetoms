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

class RecipeBookVisual {
	method position() = game.origin()
	// Acordate de usar el nombre exacto de tu carpeta (recipes_book)
	method image() = "recipes_book/recetario_page" + recipeBook.currentPage() + ".png"
}

// El recetario es una máquina de estados: cerrado (closedBook) o abierto (openBook). Cada estado sabe
// qué pasa con cada mensaje (abrir, cerrar, pasar de página) y qué pantalla ve el jugador mientras está
// en ese estado (screenOver), así nadie tiene que preguntar si está abierto.
object recipeBook {
	var property currentPage = 0
	const maxPages = 10
	var state = closedBook
	const recipeBookVisual = new RecipeBookVisual()
	var pausedByBook = false 

	// Sólo para consultar (los tests): nadie decide nada con esto, los estados resuelven solos
	method isOpen() = state.isOpen()

	// La pantalla que recibe los clicks y las teclas: la de abajo si el libro está cerrado, la del libro si está abierto
	method screenOver(screen) = state.screenOver(screen)

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
		if (!game.hasVisual(recipeBookVisual)) game.addVisual(recipeBookVisual)
		sfx.pageChange()
	}

	method closed() {
		state = closedBook
		if (game.hasVisual(recipeBookVisual)) game.removeVisual(recipeBookVisual)
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

	method updateVisual() {
		game.removeVisual(recipeBookVisual)
		game.addVisual(recipeBookVisual)
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
	method screenOver(screen) = bookScreen
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

// Con el libro abierto no se juega: se tapa todo, así que no hace nada con los clicks ni con las teclas del juego
object bookScreen {
	method onClick(pos) {}
	method whenPlaying(action) {}
}
