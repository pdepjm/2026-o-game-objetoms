// Buffet Albert Einstein - lo que rodea al tablero mientras se juega: las dos columnas de los costados.
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
import cellPosition.*
import input.clickManager.*
import menu.screenManager.*
import menu.drawing.visuals.*
import menu.hud.leftPanel.*
import menu.hud.rightPanel.*
import levels.levelManager.*
import simulation.simulationEngine.*
import sound.sfx.*

// El HUD: lo fijo alrededor del tablero (lo muestra playingScreen).
object hud inherits ClickTargets {
	// La columna izquierda entera, y la parte de arriba con la info del nivel
	const leftZone = new Zone(minX = 0, maxX = 4, minY = 0, maxY = 12)
	const levelInfoZone = new Zone(minX = 0, maxX = 4, minY = 1, maxY = 11)
	// El cartel COLOCANDO / EDITANDO
	const bannerZone = new Zone(minX = 18, maxX = 21, minY = 12, maxY = 12)
	// El panel de colocar o de editar
	const interactiveZone = new Zone(minX = 18, maxX = 21, minY = 0, maxY = 11)

	method leftZone() = leftZone
	method levelInfoZone() = levelInfoZone
	method bannerZone() = bannerZone
	method interactiveZone() = interactiveZone

	override method zones() = leftPanel.zones() + rightPanel.zones()
	override method clickTargets() = [leftPanel, rightPanel]

	// Mostrarlo otra vez no duplica nada: cada parte se agrega sólo si no está
	method show() {
		leftPanel.show()
		rightPanel.show()
	}
}

// El cartel de arriba a la derecha (bannerZone): dice si el jugador está COLOCANDO o EDITANDO.
object modeBanner inherits Picture(image = "menu/mode_placing.png", position = hud.bannerZone().origin()) {
	method change(mode) { image = mode.banner() }
}

// Los botones de abajo a la izquierda (x 0 a 3, y 0 a 3)
object sideButtons inherits ClickTargets {
	const zone = new Zone(minX = 0, maxX = 3, minY = 0, maxY = 3)
	const position = new CellPosition(x = 0, y = 0)
	const buttons = [
		new CellArea(zone = rectangle.of(0, 3, 4, 1), action = { screenManager.openBook() }),
		new CellArea(zone = rectangle.of(0, 2, 4, 1), action = { screenManager.backToCover() }),
		new CellArea(zone = rectangle.of(0, 1, 4, 1), action = { levelManager.toggleSimulation() })
	] + [1, 2, 3].map({ speed => new CellArea(zone = rectangle.of(speed - 1, 0, 1, 1), action = { self.speed(speed) }) })

	method position() = position
	method image() = "menu/side_buttons.png"

	// Un clic en estas celdas es de los botones (aunque caiga en la celda libre de la fila de abajo)
	override method zones() = [zone]
	override method clickTargets() = buttons

	method show() {
		if (!game.hasVisual(self)) game.addVisual(self)
		speedFrame.show()
	}

	// Las teclas 1, 2 y 3 y los botones de la fila de abajo
	method speed(n) {
		simulationEngine.speed(n)
		sfx.speedChange()
	}
}

// El marco de la velocidad elegida.
object speedFrame {
	const positions = [new CellPosition(x = 0, y = 0), new CellPosition(x = 1, y = 0), new CellPosition(x = 2, y = 0)]

	method position() = positions.get(simulationEngine.speed() - 1)
	method image() = "menu/speed_selected.png"
	method show() { if (!game.hasVisual(self)) game.addVisual(self) }
}
