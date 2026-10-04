import wollok.game.*

// Posición fija en una celda (coordenadas enteras), para las cosas que no se mueven:
// máquinas, items del menú, overlay.
//
// POR QUÉ EXISTE
// Wollok Game dibuja ~60 veces por segundo, y en cada frame le pide a cada visual
// position().round(). En una Position común, round() crea una posición nueva cada vez,
// y eso hacía que dibujar una máquina costara ~2.5 veces más.
// Como las coordenadas ya son enteras, redondear no cambia nada: se devuelve self.
//
// OJO: sólo usarla con coordenadas enteras. Para posiciones con decimales está
// PosicionSuave (animationEngine.wlk), que hace lo mismo para los items que se mueven.
class CellPosition inherits Position {
	override method round() = self
	// las posiciones vecinas (right, up, etc.) también son de celda
	override method createPosition(_x, _y) = new CellPosition(x = _x, y = _y)
}
