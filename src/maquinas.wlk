// Maneja el que es cada cosa

import wollok.game.*

class Personaje {
  var property position = game.origin()

  method image() = "pepitaa.png"
}

// Clase de máquina
// Hay que agregar los métodos de rotar, de procesar, etc.
// Tiene que haber una posicion de salida. Un "item actual" para tener el objeto que le toca procesar.
class Maquina {
  var property position = game.origin()
}

class Cinta inherits Maquina{
  method image() = "cinta.png"

}

class Horno inherits Maquina{
  method image() = "horno.png"

}

class Freidora inherits Maquina{

}

class Cortadora inherits Maquina{

}

class Ensambladora inherits Maquina{

}