// Buffet Albert Einstein - el brazo inteligente, con tres salidas filtradas por ingrediente.
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

import machines.types.automaticArm.*
import machines.settings.*
import food.foodTypes.*
import food.foodClasses.*
import directions.*

// Una de las tres salidas del brazo inteligente: hacia dónde va (relativo a la entrada) y qué deja salir
class ArmRoute {
	const property output
	const property filter

	method accepts(item) = filter.accepts(item)

	// El lado del tablero por el que sale, para un brazo que agarra de inputSide
	method sideFor(inputSide) = output.sideFor(inputSide)
}

// "Ninguna salida": la de un ingrediente que el brazo no agarra
object noRoute {
	method sideFor(inputSide) = noSide
	method filter() = noFilter
}

object noFilter {
	method contains(kind) = false
	method add(kind) {}
	method remove(kind) {}
}

// Brazo inteligente: igual que el automático, pero tiene tres salidas (izquierda, recta y derecha)
// y cada una deja salir sólo los ingredientes que se eligieron para ella (una columna en el panel de edit).
// Una salida sin ingredientes no usa: por ahí no sale nada.
// Entrega cada item por la primera salida que lo acepta, en el orden recta, izquierda, derecha.
// Si ninguna lo acepta, no lo toma: se queda donde está.
// Por defecto no deja salir nada por ninguna salida: hay que elegir qué ingredientes salen por cuál.
// (Si arrancara dejando pasar todo, dos brazos sobre la misma máquina se pelearían los items
// y uno le sacaría al otro lo que tiene que sacar.)
class SmartRoboticArm inherits AutomaticArm {
	// Los ingredientes que se pueden elegir en cada salida (hasta 13 para no salirse de la pantalla)
	const kinds = [
		friedPotato, burntPotato,
		eggFryed,
		cookedMeat,
		sausageCooked
	]

	// En el orden de prioridad: recta, izquierda, derecha
	const routes = [
		new ArmRoute(output = straightOut, filter = new ItemSetSetting(outputName = "Recto", columnIndex = 1, kinds = kinds, value = [])),
		new ArmRoute(output = leftOut, filter = new ItemSetSetting(outputName = "Izq.", columnIndex = 0, kinds = kinds, value = [])),
		new ArmRoute(output = rightOut, filter = new ItemSetSetting(outputName = "Der.", columnIndex = 2, kinds = kinds, value = []))
	]

	override method name() = "AutomaticArm"
	override method label() = "Brazo intel."
	override method baseEnergy() = 3

	// Las mismas imágenes del automático, recoloreadas en naranja (assets/machines/recolor.ps1)
	override method assetFolder() = "machines/SmartRoboticArm/"

	override method settings() = routes.map({ route => route.filter() })

	// La salida que deja pasar a ese item (sólo se pregunta por los que alguna deja pasar: ver canTake)
	method routeFor(item) = routes.find({ route => route.accepts(item) })

	// ¿Alguna de sus salidas deja pasar a ese item?
	method canTake(item) = routes.any({ route => route.accepts(item) })

	override method outputSideFor(item) = self.routeFor(item).output().sideFor(inputSide)

	// ¿Toma un item de ese kind? Sirve para preguntarle cómo está configurado sin saber cómo guarda sus salidas
	method takes(kind) = self.canTake(new Item(kind = kind))

	// El lado por el que saldría un item de ese kind (sólo se pregunta por los que toma: ver takes)
	method exitSideFor(kind) = self.routeFor(new Item(kind = kind)).output().sideFor(inputSide)

	// No toma lo que no tiene por dónde salir
	override method canReceive(item) = super(item) && self.canTake(item)

	// ----------- EL PANEL DEL BRAZO (ver armMenu) -----------
	// Un casillero por ingrediente. Cada clic lo manda al lado siguiente del tablero. Un ingrediente sale
	// por un solo lado: se guarda en el filtro de esa salida (los de "Recto", "Izq." y "Der." de siempre).

	override method editTitle() = "BRAZO INTELIGENTE"
	override method editHint() = "CLIC: CAMBIA HACIA DÓNDE"
	override method editBoxImage() = "menu/arm_box_smart_" + inputSide.name() + ".png"
	override method editChoices() = kinds.map({ kind => new ArmKindChoice(arm = self, kind = kind) })
	// Los ingredientes del panel, en el orden de sus casilleros
	method editKinds() = kinds

	// El lado del tablero por el que sale ese ingrediente (noSide si no lo agarra)
	method sideOf(kind) = routes.findOrDefault({ route => route.filter().contains(kind) }, noRoute).sideFor(inputSide)

	// Lo manda al lado siguiente: nada → ↑ → → → ↓ → ← → nada (sin el lado de donde agarra)
	method cycle(kind) {
		const options = [noSide] + [up, right, down, left].filter({ side => side != inputSide })
		const index = (0 .. options.size() - 1).find({ i => options.get(i) == self.sideOf(kind) })
		self.sendTo(kind, options.get((index + 1).rem(options.size())))
	}

	// Que ese ingrediente salga sólo por ese lado del tablero (noSide: que no lo agarre)
	method sendTo(kind, side) {
		routes.forEach({ route => route.filter().remove(kind) })
		routes.findOrDefault({ route => route.sideFor(inputSide) == side }, noRoute).filter().add(kind)
	}

	override method sendsTo(side) = !self.kindsTo(side).isEmpty()
	override method kindsTo(side) = kinds.filter({ kind => self.sideOf(kind) == side })
}
