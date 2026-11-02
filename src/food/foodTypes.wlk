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

    // Si se queda en la freidora, se quema
    override method initialize() {
        self.turnsInto(burning, burntPotato)
    }
}
object burntPotato inherits IngredientKind {
    override method image() = potatoFamily.image("burnt")
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
    override method initialize() {
        self.turnsInto(cooking, toastedBun)
    }
}

object toastedBun inherits IngredientKind {
    override method image() = bunFamily.image("cooked")
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

// -------------------------------- CHEESES --------------------------------------------
object cheese inherits IngredientKind {
    override method image() = cheeseFamily.image("raw")
    override method initialize() {
        self.turnsInto(cutting, cheeseCutted)
    }
}   
object cheeseCutted inherits IngredientKind {
    override method image() = cheeseFamily.image("cutted")
    override method initialize() {
        self.turnsInto(cutting, cheeseFeta)
    }
}
object cheeseFeta inherits IngredientKind {
    override method image() = cheeseFamily.image("feta")
}
// ---------------------------------------------------------------------------------------

// -------------------------------- SALAMIS --------------------------------------------
object salami inherits IngredientKind {
    override method image() = salamiFamily.image("raw")
    override method initialize() {
        self.turnsInto(cutting, salamiCutted)
    }
}
object salamiCutted inherits IngredientKind {
    override method image() = salamiFamily.image("cutted")
}
// ---------------------------------------------------------------------------------------

// -------------------------------- PIZZA-DOUGH --------------------------------------------
object pizzaDough inherits IngredientKind {
    override method image() = pizzaDoughFamily.image("raw")
    override method initialize() {
        self.turnsInto(cooking, pizzaDoughCooked)
    }
}
object pizzaDoughCooked inherits IngredientKind {
    override method image() = pizzaDoughFamily.image("cooked")
}
// ---------------------------------------------------------------------------------------

// -------------------------------- EGGS --------------------------------------------
object egg inherits IngredientKind {
    override method image() = eggFamily.image("raw")
    override method initialize() {
        self.turnsInto(frying, eggFryed)
    }
}
object eggFryed inherits IngredientKind {
    override method image() = eggFamily.image("fryed")
}
// ---------------------------------------------------------------------------------------

// -------------------------------- SAUSAGES --------------------------------------------
object sausage inherits IngredientKind {
    override method image() = sausageFamily.image("raw")
    override method initialize() {
        self.turnsInto(cooking, sausageCooked)
    }
}
object sausageCooked inherits IngredientKind {
    override method image() = sausageFamily.image("cooked")
}
// ---------------------------------------------------------------------------------------

// -------------------------------- BACONS --------------------------------------------
object bacon inherits IngredientKind {
    override method image() = baconFamily.image("raw")
    override method initialize() {
        self.turnsInto(cooking, baconCooked)
    }
}
object baconCooked inherits IngredientKind {
    override method image() = baconFamily.image("cooked")
}
// ---------------------------------------------------------------------------------------

// -------------------------------- HAM --------------------------------------------
object ham inherits IngredientKind {
  override method image() = hamFamily.image("raw")
  override method initialize(){
    self.turnsInto(cutting, hamCutted)
  }
}
object hamCutted inherits IngredientKind {
    override method image() = hamFamily.image("cutted")
}

// ---------------------------------------------------------------------------------------

// -------------------------------- BURGER --------------------------------------------
object burger inherits DishKind {
    override method image() = "food/Dishes/burgers/burger.png"
}
// ---------------------------------------------------------------------------------------

// -------------------------------- CHEESE BURGER --------------------------------------------
object cheeseBurger inherits DishKind {
    override method image() = "food/Dishes/burgers/cheeseburger.png"
}
// ---------------------------------------------------------------------------------------

// -------------------------------- DOUBLE BURGER --------------------------------------------
object doubleBurger inherits DishKind {
    override method image() = "food/Dishes/burgers/double-burger.png"
}
// ---------------------------------------------------------------------------------------

// -------------------------------- HOT DOG --------------------------------------------
object hotDog inherits DishKind {
    override method image() = "food/Dishes/hot-dog/hot-dog.png"
}
// ---------------------------------------------------------------------------------------

// -------------------------------- PIZZA PEPPERONI --------------------------------------------
object pizzaPepperoni inherits DishKind {
    override method image() = "food/Dishes/pizzas/pizza-pepperoni.png"
}
// ---------------------------------------------------------------------------------------

// -------------------------------- SALAD --------------------------------------------
object salad inherits DishKind {
    override method image() = "food/Dishes/salad/salad.png"
}
// ---------------------------------------------------------------------------------------

// -------------------------------- TOMATO SOUP --------------------------------------------
object tomatoSoup inherits DishKind {
    override method image() = "food/Dishes/tomato-soup/tomato-soup.png"
}

// ---------------------------------------------------------------------------------------

// -------------------------------- HAM AND CHEESE TOAST --------------------------------------------
object toast inherits DishKind {
    override method image() = "food/Dishes/toast/hamAndCheeseToast.png"
}
// ---------------------------------------------------------------------------------------

// -------------------------------- CLASSIC BREAKFAST --------------------------------------------
object breakfast inherits DishKind {
    override method image() = "food/Dishes/breakfasts/classicBreakfast.png"
}