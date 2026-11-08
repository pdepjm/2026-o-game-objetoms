import wollok.game.*
import simulation.simulationEngine.*

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
		}
	}

	method close() {
		if (isOpen) {
			isOpen = false
			if (game.hasVisual(recipeBookVisual)) game.removeVisual(recipeBookVisual)
			if (pausedByBook) simulationEngine.resume()
			pausedByBook = false
		}
	}

	method toggle() { if (isOpen) self.close() else self.open() }

	method nextPage() {
		if (isOpen && currentPage < maxPages) {
			currentPage += 1
			self.updateVisual()
		}
	}

	method prevPage() {
		if (isOpen && currentPage > 0) {
			currentPage -= 1
			self.updateVisual()
		}
	}

	method updateVisual() {
		if (isOpen) {
			game.removeVisual(recipeBookVisual)
			game.addVisual(recipeBookVisual)
		}
	}
}