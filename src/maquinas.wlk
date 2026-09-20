// Maneja el que es cada cosa

import wollok.game.*
import userController.Tools

// Clase de máquina
// Hay que agregar los métodos de rotar, de procesar, etc.
// Tiene que haber una posicion de salida. Un "item actual" para tener el objeto que le toca procesar.
class Maquina {
  var property position = game.origin()

  method name() = "Maquina"

  // Las máquinas con orientación (ej: Cinta) lo redefinen; para el resto no hace nada.
  // indice: 0 = right, 1 = down, 2 = left, 3 = up

  const direcciones = ["right", "down", "left", "up"]
  const indiceDireccion = Tools.currentRotation()



  method image() = "maquinas/"+self.name()+"/"+direcciones.get(indiceDireccion) + ".gif"

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

