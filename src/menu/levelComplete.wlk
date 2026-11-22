// Buffet Albert Einstein - la comanda que aparece al completar un nivel.
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
import board.*
import cellPosition.*
import menu.visuals.*
import menu.texts.*
import menu.spriteFonts.*
import menu.startMenu.*
import levels.levelManager.*

// Al completar un nivel: la pantalla se oscurece y aparece una comanda (un ticket) con lo entregado, el
// tiempo de cocina, la energía usada y las máquinas que puso el jugador, y los botones para seguir.
// Las imágenes (ticket, botones, dim) las genera assets/menu/makeArmAndTicket.py; los textos se escriben con
// las letras del papel (spriteText). Los botones ocupan celdas enteras: Wollok avisa el clic por celda.
//
//   x 7 a 14: el ticket (desde la fila 1.6)
//   [ SIGUIENTE NIVEL  N ]     ← fila 3, x 9 a 12 (en el último nivel: JUGAR DE NUEVO)
//   [ REPETIR 0 ][ MENÚ M ]    ← fila 2, x 9-10 y 11-12
//
// Mientras se ve, se queda con todos los clics: sólo cuentan sus botones (ver playingScreen). Se va al
// cargar otro nivel o reiniciar. RENDIMIENTO: se dibuja una vez al ganar; no se calcula nada en cada frame.
object levelComplete {
	var shown = false
	const drawn = new VisualGroup()
	const texts = new VisualGroup()
	var buttons = []
	const centerX = 11
	// Las filas del ticket, de arriba hacia abajo (entre sus líneas punteadas)
	const rowsY = [8.42, 7.82, 7.22, 6.62, 6.02, 5.42]

	method isShown() = shown
	// Lo que dice (para los tests)
	method lines() = texts.visuals().map({ text => text.description() })

	method show(level, hasNext, cookSeconds) {
		self.hide()
		shown = true
		drawn.add(new Picture(image = "menu/dim.png", position = new CellPosition(x = 0, y = 0)))
		drawn.add(new Picture(image = "menu/ticket.png", position = new CellPosition(x = 7, y = 1.6)))
		drawn.add(new Picture(image = "tutorial/chef_happy_up_left.png", position = new CellPosition(x = 15.2, y = 2.2)))
		texts.keep(spriteText.draw(level.name(), labelFont, centerX, 9.12))
		const rows = level.progressLines()
			+ ["Tiempo de cocina: " + self.clock(cookSeconds),
			   level.energyLimit().usedText(board.totalEnergy()),
			   "Máquinas: " + board.machines().count({ machine => !machine.locked() }),
			   if (hasNext) "PEDIDO COMPLETO" else "¡FIN DEL JUEGO!"]
		(0 .. rows.size().min(rowsY.size()) - 1).forEach({ index =>
			texts.keep(spriteText.draw(rows.get(index), textFont, centerX, rowsY.get(index)))
		})
		buttons = if (hasNext) [
				new Button(image = "menu/btn_next.png", position = new CellPosition(x = 9, y = 3), width = 4, action = { levelManager.loadNext() }),
				new Button(image = "menu/btn_repeat.png", position = new CellPosition(x = 9, y = 2), width = 2, action = { levelManager.restart() }),
				new Button(image = "menu/btn_menu.png", position = new CellPosition(x = 11, y = 2), width = 2, action = { startMenu.backToCover() })
			] else [
				new Button(image = "menu/btn_again.png", position = new CellPosition(x = 9, y = 3), width = 4, action = { levelManager.restart() }),
				new Button(image = "menu/btn_menu.png", position = new CellPosition(x = 10, y = 2), width = 2, action = { startMenu.backToCover() })
			]
		buttons.forEach({ button => drawn.add(button) })
	}

	method hide() {
		drawn.clear()
		texts.clear()
		buttons = []
		shown = false
	}

	// Para playingScreen: mientras se ve, todos los clics son suyos
	method handlesClick(pos) = shown

	// Un clic mientras se ve: sólo cuentan sus botones
	method onClick(pos) {
		buttons.findOrDefault({ button => button.contains(pos) }, noButton).press()
	}

	// Los segundos como minutos:segundos (0:38)
	method clock(seconds) {
		const rest = seconds.rem(60)
		return seconds.div(60).toString() + ":" + (if (rest < 10) "0" else "") + rest.toString()
	}
}
