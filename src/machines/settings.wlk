// Buffet Albert Einstein - las configuraciones de las máquinas (lo que se cambia editando la máquina, con X).
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

// Las configuraciones de las máquinas (lo que se cambia editando la máquina, con X).

import directions.*
import food.recipes.*
import menu.drawing.visuals.*
import menu.drawing.texts.*
// ----------- CATEGORIAS -----------
object production {
	method name() = "Produccion"
}

object movement {
	method name() = "Movimiento"
}

// ----------- OPCIONES -----------
class SettingOption {
	const property value
	// energía que suma a la máquina mientras esta opción esté elegida
	const property energyCost = 0

	// El visual que la dibuja en esa posición del panel de edit
	method visualAt(position)
}

class ImageOption inherits SettingOption {
	const property image

	override method visualAt(position) = new Picture(image = image, position = position)
}

class LabelOption inherits SettingOption {
	const property label

	override method visualAt(position) = new MenuText(text = label, position = position)
}

// ----------- SETTINGS -----------
class Setting {
	var property value

	// ----------- ABSTRACTOS -----------
	method name()
	method category()
	method options()

	// ¿Va en una columna del panel (con sus opciones una debajo de la otra) y editMenu) o se dibuja con los demás, de a 4 opciones por fila?
	method isColumned() = false

	// ----------- ELECCION -----------
	method select(option) {
		value = option.value()
	}

	method isSelected(option) = option.value() == value

	// ----------- ENERGIA -----------
	method energyCost() = self.options().filter({ option => self.isSelected(option) }).sum({ option => option.energyCost() })
}

// Qué ingrediente produce una máquina.
class ProductSetting inherits Setting {
	const kinds = []

	override method name() = "Ingrediente"
	override method category() = production
	override method options() = kinds.map({ kind => new ImageOption(value = kind, image = kind.image()) })
}

// Qué tan rápido trabaja una máquina, como multiplicador de su ritmo normal.
class SpeedSetting inherits Setting {
	override method name() = "Velocidad"
	override method category() = production
	override method options() = [
		new LabelOption(value = 0.5, label = "x0.5", energyCost = 1),
		new LabelOption(value = 1, label = "x1", energyCost = 2),
		new LabelOption(value = 2, label = "x2", energyCost = 4)
	]
}

// Hacia dónde entrega una máquina, RELATIVO al lado por el que recibe.
class OutputSideSetting inherits Setting {
	override method name() = "Salida"
	override method category() = movement
	override method options() = [
		new LabelOption(value = straightOut, label = "Recto"),
		new LabelOption(value = leftOut, label = "Izq."),
		new LabelOption(value = rightOut, label = "Der.")
	]
}

// Qué plato arma un Assembler.
class RecipeSetting inherits Setting {
	override method name() = "Receta"
	override method category() = production
	override method options() = recipeBook.available().map({ recipe =>
		new ImageOption(value = recipe, image = recipe.result().image())
	})
}

// El lado por el que entrega una máquina que recibió por inputSide.
object straightOut {
	method sideFor(inputSide) = inputSide.invert()
}

object leftOut {
	method sideFor(inputSide) = inputSide.invert().previous()
}

object rightOut {
	method sideFor(inputSide) = inputSide.invert().next()
}

// ----------- FILTROS DE ITEMS -----------
class ItemSetSetting inherits Setting {
	const outputName
	const columnIndex
	const kinds = []

	override method name() = outputName
	override method category() = movement
	override method isColumned() = true
	method column() = columnIndex

	override method options() = kinds.map({
		kind => new ImageOption(value = kind, image = kind.image()) })

	// Prende o apaga ese kind.
	override method select(option) {
		value = if (self.isSelected(option)) value.filter({ kind => kind != option.value() }) else value + [option.value()]
	}

	override method isSelected(option) = value.contains(option.value())

	method accepts(item) = value.any({ kind => kind.accepts(item) })

	// Para el panel del brazo: sumar o sacar un kind.
	method contains(kind) = value.contains(kind)
	method add(kind) { if (!value.contains(kind)) value = value + [kind] }
	method remove(kind) { value = value.filter({ each => each != kind }) }
}
