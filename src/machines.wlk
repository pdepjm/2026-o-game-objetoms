// Maneja el que es cada cosa

import wollok.game.*
import userTools.toolsManager
import menu.placeMenu.*

// Clase de máquina
// Hay que agregar los métodos de rotar, de procesar, etc.
// Tiene que haber una position de salida. Un "item actual" para tener el objeto que le toca procesar.
class Maquina {
  var property position = game.origin()

  method name() = "Maquina"

  // Cada máquina guarda su propia dirección (un objeto de directions.wlk).
  // Nace con la dirección seleccionada al momento de colocarla.
  var direction = toolsManager.currentDirection()

  method rotate() {
    direction = direction.next()
  }

  method image() = "machines/"+self.name()+"/"+direction.name() + ".gif"

}

class Belt inherits Maquina{
  override method name() = "Belt"

}

class Oven inherits Maquina{
  override method name() = "Oven"
}

class Fryer inherits Maquina{
  override method name() = "Fryer"

}

class CuttingMachine inherits Maquina{
  override method name() = "CuttingMachine"
}

class Assembler inherits Maquina{
  override method name() = "Assembler"
}

class Dispenser inherits Maquina{
  // Dispensa un item cada un determinado tiempo
  override method name() = "Dispenser"
}




// Maneja cual es la Machine Seleccionada actual
object machineManager{
	// selectedTool va a devolver una nueva instancia de la herramienta seleccionada.
	// chooseMachine va a validar el click y va a actualizar selectedTool segun corresponda.

	const machines = new Dictionary()

  method machines() = machines

	var selectedMachine =  {=> new Belt()}

	method initialize() {
		machines.put(1, {=> new Belt()})
    machines.put(2, {=> new Assembler()})
		machines.put(3, {=> new Oven()})
    machines.put(4, {=> new CuttingMachine()})
		machines.put(5, {=> new Fryer()})
		machines.put(6, {=> new Dispenser()})
	}

	method selectedMachine() = selectedMachine.apply()


    // TO-DO: Esto no es responsabilidad del machineManager. Al hacer click en el menu, el menu debe notificar la maquina seleccionada
	method chooseMachine(pos){
		const element = placeMenu.elementEn(pos)

		if (machines.containsKey(element)) {
			selectedMachine = machines.get(element)
			placeMenu.seleccionar(element)
		}
	}
}