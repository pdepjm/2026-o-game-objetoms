// Buffet Albert Einstein - las acciones del jugador: colocar, quitar, editar y rotar.
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
import sound.sfx.*
import tools.toolsManager.*

// LAS ACCIONES (antes, herramientas que se elegían con una tecla)
// place: clic en una celda vacía. rotate, edit y delete: C, X y V sobre la máquina elegida
// (ver toolsManager). Todas entienden onClick(celda); el tutorial pregunta por ellas (allowsTool).

object place {
	method name() = "place"
	// ¿Cambia el circuito? Las que no (edit) se pueden usar en cualquier celda aunque un tutorial no las pida
	method canUseAnywhere() = false
	// ¿Le sirve esta máquina a un paso que sólo deja construir las de esa lista? (vacía: cualquiera)
	method allowsMachine(allowedMachines) = allowedMachines.isEmpty() || allowedMachines.any({ factory => machineManager.selects(factory) })
	// Lo que dice el cocinero si el paso del tutorial no la deja usar ahí (ver Tutorial.complaintFor)
	method complaintIn(step, pos) = step.complaintFor(self, pos)
    // Si no entra (celda ocupada, parte fuera del tablero o fuera de las zonas donde el nivel deja construir),
    // no coloca nada
    method onClick(pos) {
		const machine = machineManager.createMachine()
		if (board.canBuild(pos, machine)) {
			board.push(pos, machine)
			levelManager.machinePlaced(machine)
			sfx.place()
		} else {
			sfx.invalid()
		}
    }
}
object delete {
	method name() = "delete"
	method complaintIn(step, pos) = step.complaintFor(self, pos)
	method canUseAnywhere() = false
	method allowsMachine(allowedMachines) = true
	// Las máquinas bloqueadas (las fijas de un nivel) no se pueden borrar.
	// Se avisa después de sacarla (así el tutorial ve el tablero sin ella), con la máquina que se guardó antes.
    method onClick(pos) {
        if (board.isThereAMachineUnlocked(pos)) {
        	const machine = board.machineAt(pos)
        	board.pop(pos)
        	levelManager.machineRemoved(machine)
            sfx.delete()
        } else {
            sfx.invalid()
        }
    }
}
object edit {
	method name() = "edit"
	method complaintIn(step, pos) = step.complaintFor(self, pos)
	method canUseAnywhere() = true
	method allowsMachine(allowedMachines) = true
	// Abre el panel de editar de esa máquina (EDITANDO). Si no tiene nada para ajustar, no hace nada.
	method onClick(pos) {
		if (board.machineAt(pos).settings().isEmpty()) sfx.invalid()
		else {
			editMenu.selectMachine(pos)
			toolsManager.startEditing()
		}
	}
}
object rotate {
	method name() = "rotate"
	method complaintIn(step, pos) = step.complaintFor(self, pos)
	method canUseAnywhere() = false
	method allowsMachine(allowedMachines) = true

	method onClick(pos) {
		if (board.isThereAMachineUnlocked(pos)) {
			board.machineAt(pos).rotate()
			levelManager.machineRotated(board.machineAt(pos))
			sfx.rotate()
		} else {
			sfx.invalid()
		}
	}
}
