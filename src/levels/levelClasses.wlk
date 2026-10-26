class DeliveryGoal {
	const kind
	const amount
	const label          // cómo se muestra: "Papas cortadas"
	var delivered = 0

	method delivered(item) { if (kind.accepts(item)) delivered += 1 }
	method isMet() = delivered >= amount
	method progressText() = label + ": " + delivered.min(amount) + "/" + amount
	method reset() { delivered = 0 }
}

// Es modo libre, es preferible que entienda los mismos mensajes y nos ahorramos tener que definir sus atributos
object noGoal{
    method isMet() = false
    method progressText() = ""
    method delivered(_) {}
    method reset() {}
}

