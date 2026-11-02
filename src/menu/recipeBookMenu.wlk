import wollok.game.*
import cellPosition.*
import food.foodTypes.*
import simulation.simulationEngine.*

// El libro de recetas: un índice y una página por plato (las imágenes están en assets/recipes_book/).
// Se abre con el icono (abajo de todo, en la columna de al lado del + de la barra) o con F, pausa la simulación
// mientras está abierto, y se cierra con la cruz o con F. Q y E pasan las páginas.
//
// Todas las imágenes miden 800x500 (16x10 celdas) y se dibujan desde bookOrigin: ocupan x 5 a 20 e y 2 a 11.
// Wollok avisa los clicks por celda, así que lo clickeable ocupa celdas enteras de la imagen
// (ver docs/Plan-Libro-Recetas.md, fase 0):
// - la cruz: las 4 celdas de arriba a la derecha (x 19 y 20, y 10 y 11)
// - el índice: un plato por fila (y 8 a 4). Hoja izquierda x 7 a 12 (páginas 1 a 5), derecha x 14 a 18 (6 a 10)
object recipeBookMenu {
	// La celda del icono: abajo de todo, en la columna de la izquierda del + de la barra de herramientas
	const property iconCell = new CellPosition(x = 20, y = 0)
	// Dónde se dibuja el libro (la esquina de abajo a la izquierda de la imagen)
	const bookOrigin = new CellPosition(x = 5, y = 2)

	// Las páginas, en orden (el número que tienen dibujado). Las 5 primeras van en la hoja izquierda del índice.
	// Entran hasta 10 (ver entryAt): para más, el índice necesita otra imagen.
	const property pages = [
		new BookPage(dish = friedPotato, image = "recipes_book/recipe_papasFritas.png"),
		new BookPage(dish = burger, image = "recipes_book/recipe_burger.png"),
		new BookPage(dish = cheeseBurger, image = "recipes_book/recipe_cheeseBurger.png"),
		new BookPage(dish = doubleBurger, image = "recipes_book/recipe_dobleBurger.png"),
		new BookPage(dish = pizzaPepperoni, image = "recipes_book/recipe_pizzaPepperoni.png"),
		new BookPage(dish = salad, image = "recipes_book/recipe_ensalada.png"),
		new BookPage(dish = hotDog, image = "recipes_book/recipe_hotDog.png"),
		new BookPage(dish = tomatoSoup, image = "recipes_book/recipe_tomatoSoup.png")
	]
	const indexImage = "recipes_book/index.png"

	var open = false
	// null: se ve el índice. Si no, el número de la página que se ve (0 es la primera).
	var pageIndex = null
	// Si la pausa la puso el libro: así, si la simulación estaba apagada, al cerrar sigue apagada
	var pausedByBook = false
	const sprite = new BookSprite(position = bookOrigin)

	method isOpen() = open
	method pageIndex() = pageIndex
	method showingIndex() = pageIndex == null
	// La imagen que se está viendo (para los tests)
	method image() = sprite.image()

	// Lo llama main.wpgm al arrancar
	method setUp() {
		game.addVisual(bookIcon)
	}

	method toggle() {
		if (open) self.close() else self.open()
	}

	method open() {
		if (!open) {
			open = true
			pausedByBook = simulationEngine.running() && !simulationEngine.paused()
			if (pausedByBook) simulationEngine.pause()
			self.showIndex()
			// Se agrega último, así queda arriba de las máquinas y los items
			game.addVisual(sprite)
		}
	}

	method close() {
		if (open) {
			open = false
			game.removeVisual(sprite)
			if (pausedByBook) simulationEngine.resume()
			pausedByBook = false
		}
	}

	method showIndex() {
		pageIndex = null
		sprite.image(indexImage)
	}

	method showPage(index) {
		pageIndex = index
		sprite.image(pages.get(index).image())
	}

	// Q: la página anterior. El índice está antes de la primera.
	method prevPage() {
		if (pageIndex == 0) self.showIndex()
		else if (!self.showingIndex()) self.showPage(pageIndex - 1)
	}

	// E: la página siguiente. Desde el índice, la primera. En la última no hace nada.
	method nextPage() {
		if (self.showingIndex()) self.showPage(0)
		else if (pageIndex < pages.size() - 1) self.showPage(pageIndex + 1)
	}

	// Lo llama userController con cualquier click mientras el libro está abierto
	method onClick(pos) {
		if (self.isClose(pos)) self.close()
		else if (self.showingIndex()) {
			const index = self.entryAt(pos)
			if (index != null) self.showPage(index)
		}
	}

	method isIcon(pos) = pos.x() == iconCell.x() && pos.y() == iconCell.y()

	// La cruz: las columnas 14 y 15 y las filas 0 y 1 de la imagen
	method isClose(pos) = pos.x().between(19, 20) && pos.y().between(10, 11)

	// El número de página del plato del índice en esa celda (null si no hay ninguno)
	method entryAt(pos) {
		const row = 8 - pos.y()
		const column = if (pos.x().between(7, 12)) 0 else if (pos.x().between(14, 18)) 1 else null
		const index = if (column == null || !row.between(0, 4)) null else column * 5 + row
		return if (index == null || index >= pages.size()) null else index
	}
}

// Una página del libro: de qué plato es y su imagen
class BookPage {
	const property dish
	const property image
}

class BookSprite {
	const property position
	var property image = "recipes_book/index.png"
}

object bookIcon {
	method position() = recipeBookMenu.iconCell()
	method image() = "recipes_book/icon.png"
}
