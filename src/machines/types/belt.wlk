import machines.machineClasses.*

// Cinta: lleva de a un item hacia la máquina a la que apunta.
// Todo su flujo de items es el comportamiento por defecto de Machine:
// recibe, el item viaja a su celda, y se entrega a la siguiente.
class Belt inherits Machine {

	override method name() = "Belt"

	// La cinta se anima con GIF mientras la simulación corre
	override method runningImage() = self.gifImage()
}
