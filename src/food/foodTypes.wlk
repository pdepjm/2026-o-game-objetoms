// Los kinds concretos. Cada uno hereda de IngredientKind (si se puede procesar)
// o de DishKind (si es un plato) y siempre define image().
// Las imágenes de los ingredientes las arman sus familias (foodPaths.wlk)
import food.foodClasses.*
import food.foodPaths.*

// --------------------------------- POTATOES --------------------------------------------
object potato inherits IngredientKind {
    override method image() = potatoFamily.image("raw")
    
    // Dentro de initialize, se definen los procesos aceptados y su objeto transformado
    override method initialize() {
        self.turnsInto(cutting, cutPotato)
    }
}
object cutPotato inherits IngredientKind {
    override method image() = potatoFamily.image("cut")
    
    override method initialize() {
        self.turnsInto(frying, friedPotato)
    }
}
object friedPotato inherits IngredientKind {
    override method image() = potatoFamily.image("cooked")
}
// ---------------------------------------------------------------------------------------

// -------------------------------- LETTUCES --------------------------------------------
object lettuce inherits IngredientKind {
    override method image() = lettuceFamily.image("whole")
    override method initialize() {
        self.turnsInto(cutting, cutLettuce)
    }
}
object cutLettuce inherits IngredientKind {
    override method image() = lettuceFamily.image("cut")
}
// ---------------------------------------------------------------------------------------

// -------------------------------- TOMATOES --------------------------------------------
object tomato inherits IngredientKind {
    override method image() = tomatoFamily.image("whole")
    override method processTime() = 4
    override method initialize() {
        self.turnsInto(cutting, cutTomato)
    }
}
object cutTomato inherits IngredientKind {
    override method image() = tomatoFamily.image("cut")
}
// ---------------------------------------------------------------------------------------

// -------------------------------- BUNS --------------------------------------------
object bun inherits IngredientKind {
    override method image() = bunFamily.image("whole")
    override method initialize() {
        self.turnsInto(cutting, cutBun)
    }
}
object cutBun inherits IngredientKind {
    override method image() = bunFamily.image("cut")
}
// ---------------------------------------------------------------------------------------

// -------------------------------- MEATS --------------------------------------------
object meat inherits IngredientKind {
    override method image() = meatFamily.image("raw")
    override method processTime() = 8
    override method initialize() {
        self.turnsInto(cooking, cookedMeat)
    }
}
object cookedMeat inherits IngredientKind {
    override method image() = meatFamily.image("cooked")
}
// ---------------------------------------------------------------------------------------

// -------------------------------- BURGER --------------------------------------------
object burger inherits DishKind {
    override method image() = "food/Dishes/burgers/burger.png"
}