object right {
	method name() = "right"
    method next() = down
	method move(position) = position.right(1)
}
object down {
	method name() = "down"
    method next() = left
	method move(position) = position.down(1)
}
object left {
	method name() = "left"
    method next() = up
	method move(position) = position.left(1)
}
object up {
	method name() = "up"
    method next() = right
	method move(position) = position.up(1)
}