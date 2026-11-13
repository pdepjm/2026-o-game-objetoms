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
}

// Brazo inteligente: igual que el automático, pero tiene tres salidas (izquierda, recta y derecha)
// y cada una deja salir sólo los ingredientes que se eligieron para ella (una columna en el panel de edit).
// Una salida sin ingredientes no usa: por ahí no sale nada.
// Entrega cada item por la primera salida que lo acepta, en el orden recta, izquierda, derecha.
// Si ninguna lo acepta, no lo toma: se queda donde está.
// Por defecto sólo sale por la recta, y deja pasar todo (como el automático).
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
		new ArmRoute(output = straightOut, filter = new ItemSetSetting(outputName = "Recto", columnIndex = 1, kinds = kinds, value = kinds)),
		new ArmRoute(output = leftOut, filter = new ItemSetSetting(outputName = "Izq.", columnIndex = 0, kinds = kinds, value = [])),
		new ArmRoute(output = rightOut, filter = new ItemSetSetting(outputName = "Der.", columnIndex = 2, kinds = kinds, value = []))
	]

	override method name() = "AutomaticArm"
	override method baseEnergy() = 3

	override method staticImage() = "machines/AutomaticArm/" + direction.name() + "_game.png"
	
	override method menuImage(aDirection) = "machines/AutomaticArm/down_menu.png"

	override method settings() = routes.map({ route => route.filter() })

	// La salida que deja pasar a ese item (null si ninguna)
	method routeFor(item) = routes.findOrDefault({ route => route.accepts(item) }, null)

	override method outputSideFor(item) = self.routeFor(item).output().sideFor(inputSide)

	// El lado por el que saldría un item de ese kind (null si no lo toma). Sirve para preguntarle
	// cómo está configurado sin saber cómo guarda sus salidas (lo usa el tutorial).
	method exitSideFor(kind) {
		const route = self.routeFor(new Item(kind = kind))
		return if (route == null) null else route.output().sideFor(inputSide)
	}

	// No toma lo que no tiene por dónde salir
	override method canReceive(item) = super(item) && self.routeFor(item) != null
}
