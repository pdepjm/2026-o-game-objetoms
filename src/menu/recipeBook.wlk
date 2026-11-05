import wollok.game.*
import simulation.simulationEngine.*
import sound.sfx.*

class RecipeBookVisual {
	method position() = game.origin()
	method image() = "recipeBook/recetario_page" + recipeBook.currentPage() + ".png"
}

object recipeBook {
	var property currentPage = 0
	const maxPages = 10
	var isOpen = false
	const recipeBookVisual = new RecipeBookVisual()

	method isOpen() = isOpen

	method image() = "recipeBook/recetario_page" + currentPage + ".png"

	method open() {
		if (!isOpen) {
			isOpen = true
			simulationEngine.pause()
			if (!game.hasVisual(recipeBookVisual)) game.addVisual(recipeBookVisual)
			sfx.pageChange()
		}
	}

	method close() {
		if (isOpen) {
			isOpen = false
			if (game.hasVisual(recipeBookVisual)) game.removeVisual(recipeBookVisual)
			simulationEngine.resume()
			sfx.pageChange()
		}
	}

	method toggle() {
		if (isOpen) self.close() else self.open()
	}

	method nextPage() {
		if (currentPage < maxPages) {
			currentPage += 1
			self.updateVisual()
			if (isOpen) sfx.pageChange()
		}
	}

	method prevPage() {
		if (currentPage > 0) {
			currentPage -= 1
			self.updateVisual()
			if (isOpen) sfx.pageChange()
		}
	}

	method updateVisual() {
		if (isOpen) {
			if (game.hasVisual(recipeBookVisual)) game.removeVisual(recipeBookVisual)
			game.addVisual(recipeBookVisual)
		}
	}
}

