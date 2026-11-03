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
// Con decimales también sirve, y es la forma de dibujar algo fijo entre dos celdas (los textos y las
// imágenes de los menús, la flecha del tutorial sobre una máquina de 2x2): como round() devuelve self,
// la posición se respeta, mientras que la de game.at se redondea a la celda. Para lo que se mueve está
// PosicionSuave (animationEngine.wlk). Sus vecinas (right, up, etc.) suman de a una celda, sin redondear.
class CellPosition inherits Position {
	override method round() = self
	// las posiciones vecinas (right, up, etc.) también son de celda
	override method createPosition(_x, _y) = new CellPosition(x = _x, y = _y)
}
