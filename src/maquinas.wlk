// Maneja el que es cada cosa

import wollok.game.*

// Clase de máquina
// Hay que agregar los métodos de rotar, de procesar, etc.
// Tiene que haber una posicion de salida. Un "item actual" para tener el objeto que le toca procesar.
class Maquina {
  var property position = game.origin()

  // Las máquinas con orientación (ej: Cinta) lo redefinen; para el resto no hace nada.
  // indice: 0 = right, 1 = down, 2 = left, 3 = up
  method orientar(indice) {}
}

class Cinta inherits Maquina{
  const direcciones = ["right", "down", "left", "up"]
  var indice = 0

  method direccion() = direcciones.get(indice)

  override method orientar(nuevoIndice) {
    indice = nuevoIndice
  }

  method image() = "maquinas/Cinta/Cinta_" + self.direccion() + ".gif"
}

class Horno inherits Maquina{
  method image() = "maquinas/horno.png"
}

class Freidora inherits Maquina{
  method image() = "maquinas/freidora.png"

}

class Cortadora inherits Maquina{
  method image() = "maquinas/cortadora.png"
}

class Ensambladora inherits Maquina{
  method image() = "maquinas/ensambladora.png"
}

class Dispensadora inherits Maquina{
  // Dispensa un item cada un determinado tiempo
  method image() = "maquinas/dispensadora.png"
}

