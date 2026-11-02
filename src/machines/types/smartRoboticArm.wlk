import machines.types.automaticArm.*
import machines.settings.*
import food.foodTypes.*
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

	override method name() = "SmartRoboticArm"

	override method staticImage() = "machines/AutomaticArm-Smart/" + direction.name() + "_game.png"
	
	override method menuImage(aDirection) = "machines/AutomaticArm-Smart/down_menu.png"

	override method settings() = routes.map({ route => route.filter() })

	// La salida que deja pasar a ese item (null si ninguna)
	method routeFor(item) = routes.findOrDefault({ route => route.accepts(item) }, null)

	override method outputSideFor(item) = self.routeFor(item).output().sideFor(inputSide)

	// No toma lo que no tiene por dónde salir
	override method canReceive(item) = super(item) && self.routeFor(item) != null
}
