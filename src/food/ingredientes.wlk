// ACÁ SE DEFINEN LOS INGREDIENTES
// Un ingrediente es toda parte indivisible de una receta.
// Un ingrediente puede estar procesado o no.
import simulation.animationEngine.*

class Ingrediente{
    
}

class Carne inherits Animado and Ingrediente{
    var name = "Carne"
    var tiempoDeCoccion = 0
    var image = "pepita.png"

    method cocinar(tiempo) {
        tiempoDeCoccion += tiempo
    }

    method image() = image
    method cortar() {
        image = "pepita_cortada.png"
    }
}