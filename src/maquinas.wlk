// Maneja el que es cada cosa

import wollok.game.*

// Clase de máquina
// Hay que agregar los métodos de rotar, de procesar, etc.
// Tiene que haber una posicion de salida. Un "item actual" para tener el objeto que le toca procesar.
class Maquina {
  var property position = game.origin()
}

class Cinta inherits Maquina{
  method image() = "maquinas/cinta.png"

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

