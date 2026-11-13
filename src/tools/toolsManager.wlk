// Buffet Albert Einstein - maneja las herramientas del jugador (colocar, quitar, editar y rotar).
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

import board.*
import menu.menuManager.*
import directions.*
import simulation.simulationEngine.*
import tools.userTools.*
import levels.levelManager.*
import sound.sfx.*

object toolsManager{
	// Manejar las herramientas Place, Delete, Edit y Rotate
	// Arranca sin ninguna herramienta elegida (null): hay que elegir una con P, Z, X o R
	var selectedTool = null

	method selectedTool() = selectedTool

	// Único punto de entrada para cambiar de herramienta (teclas de userController).
	// Los menús se enteran por menuManager.
	method select(tool) {
		if (tool != selectedTool)
			selectedTool = tool
		else
			selectedTool = null
		sfx.toolSelect()
		menuManager.toolChanged(selectedTool)
		levelManager.toolSelected(selectedTool)
	}

	// Direccion con la que se colocan las maquinas nuevas
	var currentDirection = right

	method currentDirection() = currentDirection

	// Al cambiar la dirección se actualizan las imágenes del menú, que la muestran.
	// Así el menú no tiene que preguntar la dirección en cada frame (ver MenuItem).
	method currentDirection(direction) {
		currentDirection = direction
		sfx.directionChange()
		menuManager.directionChanged()
	}

	// Metodo principal
	// Con la simulación prendida no se puede colocar, borrar ni rotar nada.
	// El tutorial del nivel puede no dejar usar la herramienta en esa celda.
	method onClick(pos) {
		if (board.inBoard(pos)) {
			if (selectedTool != null && !simulationEngine.running() && levelManager.allowsTool(selectedTool, pos)) selectedTool.onClick(pos)
		}
		else if (menuManager.inInteractiveMenu(pos))
			menuManager.onClick(pos)
	}

	method reset() {
		selectedTool = null
		currentDirection = right
		menuManager.toolChanged(null)
		menuManager.directionChanged()
	}
}
