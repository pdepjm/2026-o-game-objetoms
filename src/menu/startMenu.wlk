import wollok.game.*
import input.userController.*
import menu.menuManager.*
import tools.toolsManager.*
import simulation.simulationEngine.*
import directions.*

// Un texto suelto sobre el fondo (mismo estilo que infoText en editMenu.wlk)
class StartText {
	const property position
	const property text
	const property textColor = "FFFFFFFF"
}

// La portada es una imagen del tamaño del tablero (25x16 celdas de 50 px)
object startScreen {
	method position() = game.origin()
	method image() = "startScreen.png"
}

// Pantalla de inicio: portada, instrucciones y opciones.
// Mientras no se aprieta ENTER no hay herramientas ni teclas del juego:
// userController.setUp() y menuManager.setUp() recién se llaman al empezar a jugar.
//
// Pantallas (screen): "cover" (portada), "instructions", "options" y "playing".
// Cada tecla sólo hace algo en la pantalla que le corresponde: las teclas de acá
// (S, W, A, D, 1, 2, 3...) también se usan dentro del juego.
object startMenu {
	var screen = "cover"

	// Textos que están dibujados ahora, para poder sacarlos al cambiar de pantalla
	const shown = []

	// Instrucciones: cuántas líneas entran en pantalla y cuánto se bajó
	const visibleLines = 13
	var offset = 0

	const instructionLines = [
		"LA HISTORIA",
		"La IA dominó el mundo y echaron a todos los trabajadores del buffet.",
		"Los ingenieros tenemos hambre y tenemos que seguir comiendo.",
		"Es tu tarea automatizar todos los procesos del buffet.",
		"",
		"EL OBJETIVO",
		"El juego tiene distintas tareas. En cada una tenés que preparar una comida",
		"usando las máquinas, sin que nadie las toque: armás la línea de producción,",
		"prendés la simulación y mirás cómo trabaja sola.",
		"",
		"CÓMO SE ARMA UNA COMIDA",
		"Los ingredientes salen de un dispenser, viajan por cintas, se procesan",
		"(cortar, cocinar, freír) y se juntan en el ensamblador, que entrega el plato.",
		"Ejemplo: una hamburguesa necesita pan cortado, lechuga cortada, tomate",
		"cortado y dos carnes cocidas.",
		"",
		"LAS MÁQUINAS",
		"- Dispenser: crea ingredientes.",
		"- Cinta: lleva los ingredientes hacia donde apunta.",
		"- Cortadora: corta los ingredientes.",
		"- Horno: cocina los ingredientes.",
		"- Freidora: fríe los ingredientes (próximamente).",
		"- Ensamblador: junta los ingredientes y entrega el plato.",
		"",
		"LOS BRAZOS",
		"- Brazo básico: agarra el ingrediente que le llega de un lado y lo",
		"  entrega del lado contrario.",
		"- Brazo inteligente: además saca el ingrediente del horno justo antes de",
		"  que se queme. Un brazo básico podría sacarlo crudo.",
		"",
		"CONTROLES",
		"- Mouse: click en el tablero para usar la herramienta elegida, y en el menú",
		"  de la derecha para elegir una máquina.",
		"- Z: elegir máquinas y colocarlas.",
		"- X: modificar una máquina ya colocada.",
		"- C: rotar una máquina ya colocada.",
		"- V: eliminar una máquina.",
		"- W, A, S, D: hacia dónde mira la máquina antes de colocarla.",
		"- Q y E: cambiar de página en el menú de máquinas.",
		"- ESPACIO: prender y apagar la simulación (al apagar, los ingredientes desaparecen).",
		"- 1, 2 y 3: velocidad de la simulación.",
		"Si apretás de nuevo la herramienta elegida, la deseleccionás.",
		"Con la simulación prendida no se puede colocar, borrar ni rotar.",
		"",
		"LA ENERGÍA",
		"Cada nivel tiene su propia cantidad de energía, y esa energía se consume",
		"usando robots. Cuantos más robots uses, más energía gastás: pensá bien",
		"cuáles hacen falta y cuáles no.",
		"",
		"CONSEJOS",
		"- Construí con la simulación apagada y probala cuando esté lista.",
		"- Si un ingrediente se queda trabado, revisá hacia dónde apunta cada máquina.",
		"- Empezá por una línea simple y sumá máquinas de a una."
	]

	// Créditos: agregá acá al resto del equipo
	const credits = [
		"Equipo objeTOM'S",
		"Mateo Bustos",
		"Carlos Aramis Chambi Flores"
	]

	// ----------- ARRANQUE -----------
	// Lo llama main: dibuja la portada y engancha las teclas (una sola vez)
	method show() {
		screen = "cover"
		game.addVisual(startScreen)

		keyboard.enter().onPressDo({ self.start() })
		keyboard.i().onPressDo({ self.pressI() })
		keyboard.o().onPressDo({ self.pressO() })
		keyboard.s().onPressDo({ self.pressS() })
		keyboard.up().onPressDo({ self.scroll(-1) })
		keyboard.down().onPressDo({ self.scroll(1) })
		keyboard.num1().onPressDo({ self.setSpeed(1) })
		keyboard.num2().onPressDo({ self.setSpeed(2) })
		keyboard.num3().onPressDo({ self.setSpeed(3) })
		keyboard.w().onPressDo({ self.setDirection(up) })
		keyboard.a().onPressDo({ self.setDirection(left) })
		keyboard.d().onPressDo({ self.setDirection(right) })
	}

	// Sólo hace algo desde la portada: ENTER no vuelve a armar todo en medio del juego
	method start() {
		if (screen == "cover") {
			screen = "playing"
			game.removeVisual(startScreen)
			userController.setUp()
			menuManager.setUp()
		}
	}

	// ----------- TECLAS -----------
	method pressI() {
		if (screen == "cover") self.openInstructions()
		else if (screen == "instructions") self.backToCover()
	}

	method pressO() {
		if (screen == "cover") self.openOptions()
		else if (screen == "options") self.backToCover()
	}

	// En la portada cierra el juego; en las opciones es la dirección hacia abajo
	method pressS() {
		if (screen == "cover") game.stop()
		else self.setDirection(down)
	}

	// ----------- PANTALLAS -----------
	method backToCover() {
		self.clearTexts()
		screen = "cover"
		game.addVisual(startScreen)
	}

	method openInstructions() {
		game.removeVisual(startScreen)
		screen = "instructions"
		offset = 0
		self.renderInstructions()
	}

	method openOptions() {
		game.removeVisual(startScreen)
		screen = "options"
		self.renderOptions()
	}

	// Baja o sube las instrucciones, sin pasarse del principio ni del final
	method scroll(amount) {
		if (screen == "instructions") {
			offset = (offset + amount).max(0).min(self.maxOffset())
			self.renderInstructions()
		}
	}

	method maxOffset() = (instructionLines.size() - visibleLines).max(0)

	method renderInstructions() {
		const lines = instructionLines.drop(offset).take(visibleLines)
		const body = (0 .. (lines.size() - 1)).map({ i =>
			new StartText(position = game.at(2, 13 - i), text = lines.get(i))
		})
		self.draw(body + [
			new StartText(position = game.at(2, 15), text = "COMO JUGAR", textColor = "FFD54FFF"),
			new StartText(position = game.at(2, 14), text = "Flechas arriba y abajo para leer (" + (offset + 1) + "/" + (self.maxOffset() + 1) + ")", textColor = "FFD54FFF"),
			new StartText(position = game.at(2, 0), text = "I: volver", textColor = "FFD54FFF")
		])
	}

	// ----------- OPCIONES -----------
	method setSpeed(value) {
		if (screen == "options") {
			simulationEngine.speed(value)
			self.renderOptions()
		}
	}

	method setDirection(direction) {
		if (screen == "options") {
			toolsManager.currentDirection(direction)
			self.renderOptions()
		}
	}

	method directionLabel(direction) =
		if (direction.name() == "up") "arriba"
		else if (direction.name() == "down") "abajo"
		else if (direction.name() == "left") "izquierda"
		else "derecha"

	method renderOptions() {
		const creditTexts = (0 .. (credits.size() - 1)).map({ i =>
			new StartText(position = game.at(2, 5 - i), text = credits.get(i))
		})
		self.draw(creditTexts + [
			new StartText(position = game.at(2, 15), text = "OPCIONES", textColor = "FFD54FFF"),
			new StartText(position = game.at(2, 12), text = "Velocidad inicial: x" + simulationEngine.speed() + "   (teclas 1, 2 y 3)"),
			new StartText(position = game.at(2, 10), text = "Dirección inicial de las máquinas: " + self.directionLabel(toolsManager.currentDirection()) + "   (teclas W, A, S y D)"),
			new StartText(position = game.at(2, 7), text = "CRÉDITOS", textColor = "FFD54FFF"),
			new StartText(position = game.at(2, 0), text = "O: volver", textColor = "FFD54FFF")
		])
	}

	// ----------- DIBUJO -----------
	// Se sacan los textos de la pantalla anterior y se dibujan los nuevos.
	// Se recrean en vez de modificarlos, así los cambios (velocidad, línea) se ven seguro.
	method draw(texts) {
		self.clearTexts()
		texts.forEach({ text =>
			game.addVisual(text)
			shown.add(text)
		})
	}

	method clearTexts() {
		shown.forEach({ text => game.removeVisual(text) })
		shown.clear()
	}
}