// Maneja el que es cada cosa

import wollok.game.*

class Personaje {
  var property position = game.origin()

  method image() = "pepitaa.png"
}


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