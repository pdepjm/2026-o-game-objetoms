// Buffet Albert Einstein - las clases de los niveles, sus objetivos de entrega y las máquinas que traen colocadas.
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
import levels.tutorial.*

class DeliveryGoal {
	const kind
	const amount
	const label          // cómo se muestra: "Papas cortadas"
	var delivered = 0

	method delivered(item) { if (kind.accepts(item)) delivered += 1 }
	method isMet() = delivered >= amount
	method progressText() = label + ": " + delivered.min(amount) + "/" + amount

	// Los objetivos que se muestran en la info del nivel: éste, y noGoal ninguno
	method displayed() = [self]
	method reset() { delivered = 0 }

	// Para la info del nivel: la imagen del plato y cuánto falta, en décimos (0 a 10) para la barra
	method image() = kind.image()
	method progressTenths() = (delivered.min(amount) * 10).div(amount)
}

// Es modo libre, es preferible que entienda los mismos mensajes y nos ahorramos tener que definir sus atributos
object noGoal{
    method isMet() = false
    method progressText() = ""
    method displayed() = []
    method delivered(_) {}
    method reset() {}
}

// Cuánta energía deja gastar un nivel entre todas sus máquinas (las fijas también).
class EnergyLimit {
	const property max

	method allows(total) = total <= max

	// Muestra el contador en el menú de info del nivel (rojo si se pasó del límite)
	method showIn(menu, total, row) {
		menu.showEnergy(self.text(total), row, self.allows(total))
	}
	method text(total) = if (self.allows(total)) "Energía: " + total + "/" + max else "SIN ENERGÍA: " + total + "/" + max
	// Lo que dice la comanda del nivel completo
	method usedText(total) = "Energía usada: " + total + "/" + max
}

// El nivel sin límite de energía
object unlimitedEnergy {
	// Sin límite no hay contador que mostrar
	method showIn(menu, total, row) {}
	method allows(total) = true
	method text(total) = ""
	method usedText(total) = "Energía usada: " + total
}

class Level {
	const property name
	const property availableMachines          // Las maquinas disponibles para colocar
	const property availableRecipes			  // Las recetas disponibles para configurar 
	const property fixedMachines = []
	const property goals
	const property buildZones = [wholeBoard]
	const property blockedLayer = noBlockedLayer
	const property tutorial = noTutorial
	const property energyLimit = unlimitedEnergy

	// Lo que la info del nivel muestra al cargarlo, además de lo de siempre
	method showHints(menu) {}

	// La tecla L en este nivel: ir al modo libre
	method toggleFreePlay(manager) {
		manager.loadFreePlay()
	}

	// Coloca las máquinas que trae el nivel.
	method placeFixedMachines() {
		fixedMachines.forEach({ placement => board.push(placement.position(), placement.create()) })
	}

	// ----------- OBJETIVOS -----------

	method delivered(item) {
		goals.forEach({ goal => goal.delivered(item) })
	}

	// Se gana cuando se cumplen todos (con noGoal, nunca)
	method goalsMet() = goals.all({ goal => goal.isMet() })

	method resetGoals() {
		goals.forEach({ goal => goal.reset() })
	}

	// Los objetivos que se muestran en la info del nivel: noGoal no tiene texto, así que no se muestra
	method shownGoals() = goals.flatMap({ goal => goal.displayed() })

	// Una línea por objetivo que se muestra
	method progressLines() = self.shownGoals().map({ goal => goal.progressText() })
}

class Placement {
	const property position	// Puede ser game.at() o CellPosition
	const factory
	const locked = true

	method create() {
		const machine = factory.apply()
		machine.locked(locked)
		return machine
	}
}
// Cómo le fue al jugador en el nivel que ganó: lo que dice el ticket
class LevelResult {
	const property level
	const cookSeconds
	const property ending

	method lines() = level.progressLines() + [
		"Tiempo de cocina: " + self.clock(),
		level.energyLimit().usedText(board.totalEnergy()),
		"Máquinas: " + board.machines().count({ machine => !machine.locked() }),
		ending.title()
	]

	// Los segundos como minutos:segundos (0:38)
	method clock() {
		const rest = cookSeconds.rem(60)
		return cookSeconds.div(60).toString() + ":" + (if (rest < 10) "0" else "") + rest.toString()
	}
}

// Hay otro nivel después del que se ganó
object nextLevelEnding {
	method title() = "PEDIDO COMPLETO"
	method showButtonsIn(ticket) { ticket.showNextLevelButtons() }
	method showIn(levelInfo) { levelInfo.showNextLevelHint() }
}

// Se ganó el último nivel
object lastLevelEnding {
	method title() = "¡FIN DEL JUEGO!"
	method showButtonsIn(ticket) { ticket.showPlayAgainButtons() }
	method showIn(levelInfo) { levelInfo.showGameOverHint() }
}
