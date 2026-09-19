// ACÁ SE DEFINEN LOS INGREDIENTES
// Un ingrediente es toda parte indivisible de una receta.
// Un ingrediente puede estar procesado o no.


class Ingrediente{
    
}

class Carne inherits Ingrediente{
    var name = "Carne"
    var tiempoDeCoccion = 0

    method cocinar(tiempo) {
        tiempoDeCoccion += tiempo
        
    }

    // hay que hacer un redraw del sprite por cada cambio de estado.
    // Seguramente tengamos que matar al self y crear uno nuevo con el neuvo sprite.
}