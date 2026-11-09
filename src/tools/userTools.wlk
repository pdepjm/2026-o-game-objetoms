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
	method onClick(pos) {
		editMenu.selectMachine(pos)
	}
}
object rotate {
	method name() = "rotate"

	method onClick(pos) {
		if (board.isThereAMachineUnlocked(pos)) {
			board.machineAt(pos).rotate()
			levelManager.machineRotated(board.machineAt(pos))
		}
	}
}
