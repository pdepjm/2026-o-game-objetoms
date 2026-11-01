import wollok.game.*
import cellPosition.*
import board.*

// Los indicadores del tutorial sobre el tablero (las imágenes están en assets/tutorial/):
// - un recuadro que late en las celdas donde el jugador tiene que hacer algo (colocar, rotar, editar)
// - una flecha que rebota arriba de la máquina que explica el mensaje ("las papas salen de acá")
// Los dibuja levelManager con cada aviso al tutorial. Sin tutorial no hay ninguno.
object tutorialMarks {
	var marks = []

	method marks() = marks

	method show(targetCells, pointedCells) {
		marks.forEach({ mark => game.removeVisual(mark) })
		marks = targetCells.map({ cell => new TutorialMark(position = new CellPosition(x = cell.x(), y = cell.y()), image = "tutorial/place.gif") })
			+ pointedCells.map({ cell => new TutorialMark(position = self.arrowPosition(cell), image = "tutorial/look.gif") })
		marks.forEach({ mark => game.addVisual(mark) })
	}

	// Arriba de la máquina de esa celda, centrada sobre ella: con una de 2x2, arriba de su fila de
	// arriba y entre sus dos columnas. Si no hay máquina, arriba de la celda.
	method arrowPosition(cell) {
		const machine = board.machineAt(cell)
		if (machine == null) return new CellPosition(x = cell.x(), y = cell.y() + 1)
		const origin = machine.cell()
		// Con decimales (una de 2x2) no puede ser CellPosition: ver cellPosition.wlk
		return game.at(origin.x() + (machine.width() - 1) / 2, origin.y() + machine.height())
	}
}

class TutorialMark {
	const property position
	const property image
}
