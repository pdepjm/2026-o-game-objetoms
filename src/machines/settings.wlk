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

// ----------- CATEGORIAS -----------
// Sólo sirven para agrupar los settings en el menú

object production {
	method name() = "Produccion"
}

object movement {
	method name() = "Movimiento"
}

// ----------- OPCIONES -----------
// Una opción de un setting. Se dibuja con su image si tiene; si no, con su label.
class SettingOption {
	const property value
	const property image = null
	const property label = ""
	// energía que suma a la máquina mientras esta opción esté elegida
	const property energyCost = 0

	method hasImage() = image != null
}

// ----------- SETTINGS -----------
class Setting {
	var property value

	// ----------- ABSTRACTOS -----------
	method name()
	method category()
	method options()

	// null: el panel lo dibuja con los demás, de a 4 opciones por fila. Un número: el panel lo dibuja
	// en esa columna, con sus opciones una debajo de la otra (ver editMenu).
	method column() = null

	// ----------- ELECCION -----------
	method select(option) {
		value = option.value()
	}

	method isSelected(option) = option.value() == value

	// ----------- ENERGIA -----------
	// La de la opción elegida (0 si el valor no es una de las opciones)
	method energyCost() {
		const chosen = self.options().findOrDefault({ option => self.isSelected(option) }, null)
		return if (chosen == null) 0 else chosen.energyCost()
	}
}

// Qué ingrediente produce una máquina. kinds son los que se ofrecen en el menú.
class ProductSetting inherits Setting {
	const kinds = []

	override method name() = "Ingrediente"
	override method category() = production
	override method options() = kinds.map({ kind => new SettingOption(value = kind, image = kind.image()) })
}

// Qué tan rápido trabaja una máquina, como multiplicador de su ritmo normal.
// Más rápido consume más energía.
class SpeedSetting inherits Setting {
	override method name() = "Velocidad"
	override method category() = production
	override method options() = [
		new SettingOption(value = 0.5, label = "Lenta", energyCost = 1),
		new SettingOption(value = 1, label = "Normal", energyCost = 2),
		new SettingOption(value = 2, label = "Rapida", energyCost = 4)
	]
}

// Hacia dónde entrega una máquina, RELATIVO al lado por el que recibe.
// Las opciones son straightOut, leftOut y rightOut.
class OutputSideSetting inherits Setting {
	override method name() = "Salida"
	override method category() = movement
	override method options() = [
		new SettingOption(value = straightOut, label = "Recto"),
		new SettingOption(value = leftOut, label = "Izquierda"),
		new SettingOption(value = rightOut, label = "Derecha")
	]
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
	override method column() = columnIndex

	override method options() = kinds.map({ kind => new SettingOption(value = kind, image = kind.image()) })

	// Prende o apaga ese kind. Arma una lista nueva: la inicial puede estar compartida con otra salida.
	override method select(option) {
		value = if (self.isSelected(option)) value.filter({ kind => kind != option.value() }) else value + [option.value()]
	}

	override method isSelected(option) = value.contains(option.value())

	method accepts(item) = value.any({ kind => kind.accepts(item) })
}
