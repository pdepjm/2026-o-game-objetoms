import wollok.game.*
import cellPosition.*
import food.foodTypes.*
import simulation.simulationEngine.*

// El libro de recetas: una página por plato (las imágenes están en assets/recipes_book/).
// Se abre con el icono (abajo de todo, en la columna de al lado del + de la barra) o con F, pausa la simulación
// mientras está abierto, y se cierra con la cruz o con F. Las flechas (izquierda y derecha) pasan las recetas.
//
// Todas las imágenes miden 800x500 (16x10 celdas) y se dibujan desde bookOrigin: ocupan x 5 a 20 e y 2 a 11.
// Wollok avisa los clicks por celda, así que la cruz ocupa celdas enteras de la imagen: las 4 de arriba
// a la derecha (x 19 y 20, y 10 y 11). Ver docs/Plan-Libro-Recetas.md, fase 0.
object recipeBookMenu {
	// La celda del icono: abajo de todo, en la columna de la izquierda del + de la barra de herramientas
	const property iconCell = new CellPosition(x = 20, y = 0)
	// Dónde se dibuja el libro (la esquina de abajo a la izquierda de la imagen)
	const bookOrigin = new CellPosition(x = 5, y = 2)

	// Las páginas, en orden (el número que tienen dibujado)
	const property pages = [
		new BookPage(dish = friedPotato, image = "recipes_book/recipe_papasFritas.png"),
		new BookPage(dish = burger, image = "recipes_book/recipe_burger.png"),
		new BookPage(dish = cheeseBurger, image = "recipes_book/recipe_cheeseBurger.png"),
		new BookPage(dish = doubleBurger, image = "recipes_book/recipe_dobleBurger.png"),
		new BookPage(dish = pizzaPepperoni, image = "recipes_book/recipe_pizzaPepperoni.png"),
		new BookPage(dish = salad, image = "recipes_book/recipe_ensalada.png"),
		new BookPage(dish = hotDog, image = "recipes_book/recipe_hotDog.png"),
		new BookPage(dish = tomatoSoup, image = "recipes_book/recipe_tomatoSoup.png"),
		new BookPage(dish = toast, image = "recipes_book/recipe_toast.png"),
		new BookPage(dish = breakfast, image = "recipes_book/recipe_breakfast.png")
	]

	var open = false
	// La página que se ve (0 es la primera). Al cerrar y volver a abrir, sigue en la misma.
	var property pageIndex = 0
	// Si la pausa la puso el libro: así, si la simulación estaba apagada, al cerrar sigue apagada
	var pausedByBook = false
	const sprite = new BookSprite(position = bookOrigin, image = pages.first().image())

	method isOpen() = open
	// La imagen que se está viendo (para los tests)
	method image() = sprite.image()

	// Lo llama startMenu al empezar a jugar
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

	method showPage(index) {
		pageIndex = index
		sprite.image(pages.get(index).image())
	}

	// Flecha izquierda: la receta anterior. En la primera, o con el libro cerrado, no hace nada.
	method prevPage() {
		if (open && pageIndex > 0) self.showPage(pageIndex - 1)
	}

	// Flecha derecha: la receta siguiente. En la última, o con el libro cerrado, no hace nada.
	method nextPage() {
		if (open && pageIndex < pages.size() - 1) self.showPage(pageIndex + 1)
	}

	// Lo llama userController con cualquier click mientras el libro está abierto: sólo la cruz hace algo
	method onClick(pos) {
		if (self.isClose(pos)) self.close()
	}

	method isIcon(pos) = pos.x() == iconCell.x() && pos.y() == iconCell.y()

	// La cruz: las columnas 14 y 15 y las filas 0 y 1 de la imagen
	method isClose(pos) = pos.x().between(19, 20) && pos.y().between(10, 11)
}

// Una página del libro: de qué plato es y su imagen
class BookPage {
	const property dish
	const property image
}

class BookSprite {
	const property position
	var property image
}

object bookIcon {
	method position() = recipeBookMenu.iconCell()
	method image() = "recipes_book/icon.png"
}
