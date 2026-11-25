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
	// Lo que se muestra: no pasa de lo que pide aunque se entregue de más
	method shownDelivered() = delivered.min(amount)

	// Los objetivos que se muestran en la info del nivel: éste, y noGoal ninguno
	method displayed() = [self]
	method reset() { delivered = 0 }

	// La imagen de la info del nivel según cuántos van entregados (assets/levels/makeLevelImages.py)
	method progressImage(prefix) = prefix + self.shownDelivered() + ".png"

	// Lo que dibuja su imagen: texto, cantidad y plato (ver Level.imageSignature)
	method imageSignature() = label + "|" + amount + "|" + kind.image()
}

// Es modo libre, es preferible que entienda los mismos mensajes y nos ahorramos tener que definir sus atributos
object noGoal{
    method isMet() = false
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
}

// El nivel sin límite de energía
object unlimitedEnergy {
	// Sin límite no hay contador que mostrar
	method showIn(menu, total, row) {}
	method allows(total) = true
	method text(total) = ""
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

	// Cómo empiezan los nombres de sus imágenes: "Tutorial 1" -> tutorial_1
	method imageKey() = name.toLowerCase().replace(" ", "_")

	// Lo que dibujan su comanda y sus objetivos: makeLevelImages.py dibuja con esto, y un test lo compara
	method imageSignature() = ([name] + self.shownGoals().map({ goal => goal.imageSignature() })).join(";")
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
// El nivel que se ganó y cómo termina: lo que muestra la comanda
class LevelResult {
	const property level
	const property ending

	// La comanda ya dibujada, con lo entregado y el título del final (assets/levels/makeLevelImages.py)
	method image() = "levels/complete/" + level.imageKey() + ".png"
}

// Hay otro nivel después del que se ganó
object nextLevelEnding {
	method showButtonsIn(ticket) { ticket.showNextLevelButtons() }
}

// Se ganó el último nivel
object lastLevelEnding {
	method showButtonsIn(ticket) { ticket.showPlayAgainButtons() }
}
