// ACÁ SE DEFINEN LOS INGREDIENTES
// Un ingrediente es toda parte indivisible de una receta.
// Un ingrediente puede estar procesado o no.
import simulation.animationEngine.*

class Ingrediente{
    
}

class Carne inherits Animado and Ingrediente{
    var name = "Carne"
    var tiempoDeCoccion = 0

    method cocinar(tiempo) {
        tiempoDeCoccion += tiempo
        
    }

    method image() = "pepita.png"
}