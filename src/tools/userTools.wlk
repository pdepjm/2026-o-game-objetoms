// Buffet Albert Einstein - las herramientas del jugador: colocar, quitar, editar y rotar.
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
import machines.machineManager.*
import menu.editMenu.*
import levels.levelManager.*

// HERRAMIENTAS
// Por el momento, todas las herramientas deben contener el metodo onClick

object place {
	method name() = "place"
	// La imagen de la barra de herramientas cuando es la elegida
	method barImage() = "tools/place_selected.png"
	// ¿Cambia el circuito? Las que no (edit) se pueden usar en cualquier celda aunque un tutorial no las pida
	method canUseAnywhere() = false
	// ¿Le sirve esta máquina a un paso que sólo deja construir las de esa lista? (vacía: cualquiera)
	method allowsMachine(allowedMachines) = allowedMachines.isEmpty() || allowedMachines.any({ factory => machineManager.selects(factory) })
    // Si no entra (celda ocupada, parte fuera del tablero o fuera de las zonas donde el nivel deja construir),
    // no coloca nada
    method onClick(pos) {
		const machine = machineManager.createMachine()
		if (board.canBuild(pos, machine)) {
			board.push(pos, machine)
			levelManager.machinePlaced(machine)
		}
    }
}
object delete {
	method name() = "delete"
	// La imagen de la barra de herramientas cuando es la elegida
	method barImage() = "tools/delete_selected.png"
	method canUseAnywhere() = false
	method allowsMachine(allowedMachines) = true
	// Las máquinas bloqueadas (las fijas de un nivel) no se pueden borrar.
	// Se avisa después de sacarla (así el tutorial ve el tablero sin ella), con la máquina que se guardó antes.
    method onClick(pos) {
        if (board.isThereAMachineUnlocked(pos)) {
        	const machine = board.machineAt(pos)
        	board.pop(pos)
        	levelManager.machineRemoved(machine)
        }
    }
}
object edit {
	method name() = "edit"
	// La imagen de la barra de herramientas cuando es la elegida
	method barImage() = "tools/edit_selected.png"
	method canUseAnywhere() = true
	method allowsMachine(allowedMachines) = true
	method onClick(pos) {
		editMenu.selectMachine(pos)
	}
}
object rotate {
	method name() = "rotate"
	// La imagen de la barra de herramientas cuando es la elegida
	method barImage() = "tools/rotate_selected.png"
	method canUseAnywhere() = false
	method allowsMachine(allowedMachines) = true

	method onClick(pos) {
		if (board.isThereAMachineUnlocked(pos)) {
			board.machineAt(pos).rotate()
			levelManager.machineRotated(board.machineAt(pos))
		}
	}
}

// "No hay herramienta": la que está elegida al arrancar y al deseleccionar. No hace nada al clickear.
object noTool {
	method name() = "none"
	method barImage() = "tools/default.png"
	method canUseAnywhere() = false
	method allowsMachine(allowedMachines) = true
	method onClick(pos) {}
}
