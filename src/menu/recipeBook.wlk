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

object recipeBook {
	var property currentPage = 0
	const maxPages = 10
	var isOpen = false
	const recipeBookVisual = new RecipeBookVisual()
	var pausedByBook = false 

	method isOpen() = isOpen

	method open() {
		if (!isOpen) {
			isOpen = true
			pausedByBook = simulationEngine.running() && !simulationEngine.paused()
			if (pausedByBook) simulationEngine.pause()
			if (!game.hasVisual(recipeBookVisual)) game.addVisual(recipeBookVisual)
			sfx.pageChange()
		}
	}

	method close() {
		if (isOpen) {
			isOpen = false
			if (game.hasVisual(recipeBookVisual)) game.removeVisual(recipeBookVisual)
			if (pausedByBook) simulationEngine.resume()
			pausedByBook = false
			sfx.pageChange()
		}
	}

	method toggle() { if (isOpen) self.close() else self.open() }

	method nextPage() {
		if (isOpen && currentPage < maxPages) {
			currentPage += 1
			self.updateVisual()
			sfx.pageChange()
		}
	}

	method prevPage() {
		if (isOpen && currentPage > 0) {
			currentPage -= 1
			self.updateVisual()
			sfx.pageChange()
		}
	}

	method updateVisual() {
		if (isOpen) {
			game.removeVisual(recipeBookVisual)
			game.addVisual(recipeBookVisual)
		}
	}
}