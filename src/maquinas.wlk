// Maneja el que es cada cosa

import wollok.game.*
import userController.Tools
import menu.*

// Clase de máquina
// Hay que agregar los métodos de rotar, de procesar, etc.
// Tiene que haber una posicion de salida. Un "item actual" para tener el objeto que le toca procesar.
class Maquina {
  var property position = game.origin()

  method name() = "Maquina"

  // Las máquinas con orientación (ej: Cinta) lo redefinen; para el resto no hace nada.
  // indice: 0 = right, 1 = down, 2 = left, 3 = up

  const direcciones = ["right", "down", "left", "up"]
  const direccion = Tools.currentRotation()



  method image() = "maquinas/"+self.name()+"/"+direcciones.get(direccion) + ".gif"

}

class Cinta inherits Maquina{
  override method name() = "Cinta"

}

class Horno inherits Maquina{
  override method name() = "Horno"
}

class Freidora inherits Maquina{
  override method name() = "Freidora"

}

class Cortadora inherits Maquina{
  override method name() = "Cortadora"
}

class Ensambladora inherits Maquina{
  override method name() = "Ensambladora"
}

class Dispensadora inherits Maquina{
  // Dispensa un item cada un determinado tiempo
  override method name() = "Dispensadora"
}




// Maneja cual es la Machine Seleccionada actual
object MachineManager{
	// selectedTool va a devolver una nueva instancia de la herramienta seleccionada.
	// chooseMachine va a validar el click y va a actualizar selectedTool segun corresponda.

	const herramientas = new Dictionary()

  method maquinas() = herramientas

	var selectedTool =  {=> new Cinta()}

	method initialize() {
		herramientas.put(1, {=> new Cinta()})
    herramientas.put(2, {=> new Ensambladora()})
		herramientas.put(3, {=> new Horno()})
    herramientas.put(4, {=> new Cortadora()})
		herramientas.put(5, {=> new Freidora()})
		herramientas.put(6, {=> new Dispensadora()})
	}

	method selectedTool() = selectedTool.apply()


    // TO-DO: Esto no es responsabilidad del MachineManager. Al hacer click en el menu, el menu debe notificar la maquina seleccionada
	method chooseMachine(pos){
		const elemento = menu.elementoEn(pos)

		if (herramientas.containsKey(elemento)) {
			selectedTool = herramientas.get(elemento)
			menu.seleccionar(elemento)
		}
	}
}