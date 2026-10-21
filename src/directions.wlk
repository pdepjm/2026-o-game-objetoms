// Este archivo maneja las direcciones de las maquinas
import wollok.game.*
object right {
	method name() = "right"		// Este metodo se utiliza para obtener las imagenes de las maquinas rotadas
    method next() = down		// Este metodo se utiliza para rotar las maquinas que ya fueron colocadas
	method move(position) = position.right(1)		// Es metodo esta pensado para dirigir los ingredientes hacia algun lugar
	method invert() = left
	method output(startPoint, width, height) = startPoint.right(width)
}
object down {
	method name() = "down"
    method next() = left
	method move(position) = position.down(1)
	method invert() = up
	method output(startPoint, width, height) = startPoint.down(1)
}
object left {
	method name() = "left"
    method next() = up
	method move(position) = position.left(1)
	method invert() = right
	method output(startPoint, width, height) = startPoint.left(1)
}
object up {
	method name() = "up"
    method next() = right
	method move(position) = position.up(1)
	method invert() = down
	method output(startPoint, width, height) = startPoint.up(height)
}
