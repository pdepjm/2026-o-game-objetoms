// Buffet Albert Einstein - las configuraciones de las máquinas (lo que se cambia con la herramienta de editar).
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

// Las configuraciones de las máquinas (lo que se cambia con la herramienta edit).
//
// Cada máquina declara los settings que acepta en settings() (por defecto, ninguno).
// Un Setting guarda el valor elegido para ESA máquina y sabe qué opciones ofrece, en qué
// categoría va (para agrupar en el menú) y cuánta energía suma. Es configuración, no estado
// de la simulación: apagar la simulación no la toca.
//
// Las opciones se calculan cuando se piden (options()), no se guardan. Lo que identifica
// a la elegida es su value, así que se compara por value y no por objeto.

import directions.*
import food.recipes.*
import menu.editMenu.*
import menu.menuText.*
// ----------- CATEGORIAS -----------
// Sólo sirven para agrupar los settings en el menú

object production {
	method name() = "Produccion"
}

object movement {
	method name() = "Movimiento"
}

// ----------- OPCIONES -----------
// Una opción de un setting. Se dibuja con su imagen (ImageOption) o con su texto (LabelOption).
class SettingOption {
	const property value
	// energía que suma a la máquina mientras esta opción esté elegida
	const property energyCost = 0

	// El visual que la dibuja en esa posición del panel de edit
	method visualAt(position)
}

class ImageOption inherits SettingOption {
	const property image

	override method visualAt(position) = new OptionImage(image = image, position = position)
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

	// ¿Va en una columna del panel (con sus opciones una debajo de la otra, ver column() y editMenu) o se dibuja
	// con los demás, de a 4 opciones por fila?
	method isColumned() = false

	// ----------- ELECCION -----------
	method select(option) {
		value = option.value()
	}

	method isSelected(option) = option.value() == value

	// ----------- ENERGIA -----------
	// La de la opción elegida (0 si el valor no es una de las opciones)
	method energyCost() = self.options().filter({ option => self.isSelected(option) }).sum({ option => option.energyCost() })
}

// Qué ingrediente produce una máquina. kinds son los que se ofrecen en el menú.
class ProductSetting inherits Setting {
	const kinds = []

	override method name() = "Ingrediente"
	override method category() = production
	override method options() = kinds.map({ kind => new ImageOption(value = kind, image = kind.image()) })
}

// Qué tan rápido trabaja una máquina, como multiplicador de su ritmo normal.
// Más rápido consume más energía.
// Se utilizan etiquetas concisas ("x0.5", "x1", "x2") para que entren holgadas
// en los 50 px de cada casilla del menú sin desbordar el texto.
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
// Las opciones son straightOut, leftOut y rightOut.
// Se usan abreviaturas ("Recto", "Izq.", "Der.") para evitar que palabras largas
// como "Izquierda" y "Derecha" desborden los 50 px y se superpongan entre sí.
class OutputSideSetting inherits Setting {
	override method name() = "Salida"
	override method category() = movement
	override method options() = [
		new LabelOption(value = straightOut, label = "Recto"),
		new LabelOption(value = leftOut, label = "Izq."),
		new LabelOption(value = rightOut, label = "Der.")
	]
}


// Qué plato arma un Assembler. Las opciones son las recetas del nivel (recipeBook), con la imagen de su plato.
class RecipeSetting inherits Setting {
	override method name() = "Receta"
	override method category() = production
	override method options() = recipeBook.available().map({ recipe =>
		new ImageOption(value = recipe, image = recipe.result().image())
	})
}

// El lado por el que entrega una máquina que recibió por inputSide. Si el item entra por la
// izquierda viaja hacia la derecha, y desde ahí "izquierda" y "derecha" son las del recorrido.
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
// Qué items deja salir una máquina por una de sus salidas: los de los kinds elegidos (un kind es un
// filtro de sí mismo, ver accepts en foodClasses.wlk). Cada opción prende o apaga un kind, y sin
// ninguno elegido no sale nada por esa salida. Se dibuja en una columna del panel (ver column()).
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

	// Prende o apaga ese kind. Arma una lista nueva: la inicial puede estar compartida con otra salida.
	override method select(option) {
		value = if (self.isSelected(option)) value.filter({ kind => kind != option.value() }) else value + [option.value()]
	}

	override method isSelected(option) = value.contains(option.value())

	method accepts(item) = value.any({ kind => kind.accepts(item) })
}
