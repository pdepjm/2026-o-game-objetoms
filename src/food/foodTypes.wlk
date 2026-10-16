// Los kinds concretos. Cada uno hereda de IngredientKind (si se puede procesar)
// o de DishKind (si es un plato) y siempre define image()
import food.foodClasses.*


// --------------------------------- POTATOES --------------------------------------------
object potatoBaseImagePath {
    method image(state) = "food/potatoes/potato_" + state + ".png"
}
object potato inherits IngredientKind {
    override method image() = potatoBaseImagePath.image("raw")
    
    // Dentro de initialize, se definen los procesos aceptados y su objeto transformado
    override method initialize() {
        self.turnsInto(cutting, cutPotato)
    }
}
object cutPotato inherits IngredientKind {
    override method image() = potatoBaseImagePath.image("cut")
    
    /*
        override method initialize() {
            self.turnsInto(frying, friedPotato)
        }
    */
}
object friedPotato inherits DishKind {
    override method image() = potatoBaseImagePath.image("cooked")
}


// ---------------------------------------------------------------------------------------