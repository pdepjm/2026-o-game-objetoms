// Buffet Albert Einstein - los ingredientes y platos concretos del juego.
//
// Copyright (C) 2026  grupo objeTOMs (Mateo Bustos, Carlos Aramis Chambi Flores,
// Facundo Ramounat, Federico Scalise Giussani, Mateo Silva)
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

// Los kinds concretos. Cada uno hereda de IngredientKind (si se puede procesar)
// o de DishKind (si es un plato) y siempre define image().
// Cada kind sabe cuál es su imagen (la ruta dentro de assets/, ver la convención en assets/README.md)
import food.foodClasses.*

// --------------------------------- POTATOES --------------------------------------------
object potato inherits IngredientKind {
    override method image() = "food/Ingredients/potatoes/potato_raw.png"
    
    // Dentro de initialize, se definen los procesos aceptados y su objeto transformado
    override method initialize() {
        self.turnsInto(cutting, cutPotato)
    }
}
object cutPotato inherits IngredientKind {
    override method image() = "food/Ingredients/potatoes/potato_cut.png"
    
    override method initialize() {
        self.turnsInto(frying, friedPotato)
    }
}
object friedPotato inherits IngredientKind {
    override method image() = "food/Ingredients/potatoes/potato_cooked.png"

    // Si se queda en la freidora, se quema
    override method initialize() {
        self.turnsInto(burning, burntPotato)
    }
}
object burntPotato inherits IngredientKind {
    override method image() = "food/Ingredients/potatoes/potato_burnt.png"
}
// ---------------------------------------------------------------------------------------

// -------------------------------- LETTUCES --------------------------------------------
object lettuce inherits IngredientKind {
    override method image() = "food/Ingredients/lettuces/lettuce_whole.png"
    override method initialize() {
        self.turnsInto(cutting, cutLettuce)
    }
}
object cutLettuce inherits IngredientKind {
    override method image() = "food/Ingredients/lettuces/lettuce_cut.png"
}
// ---------------------------------------------------------------------------------------

// -------------------------------- TOMATOES --------------------------------------------
object tomato inherits IngredientKind {
    override method image() = "food/Ingredients/tomatoes/tomato_whole.png"
    override method processTime() = 4
    override method initialize() {
        self.turnsInto(cutting, cutTomato)
    }
}
object cutTomato inherits IngredientKind {
    override method image() = "food/Ingredients/tomatoes/tomato_cut.png"
}
// ---------------------------------------------------------------------------------------

// -------------------------------- BUNS --------------------------------------------
object bun inherits IngredientKind {
    override method image() = "food/Ingredients/buns/bun_whole.png"
    override method initialize() {
        self.turnsInto(cutting, cutBun)
    }
}
object cutBun inherits IngredientKind {
    override method image() = "food/Ingredients/buns/bun_cut.png"
    override method initialize() {
        self.turnsInto(cooking, toastedBun)
    }
}

object toastedBun inherits IngredientKind {
    override method image() = "food/Ingredients/buns/bun_cooked.png"
}
// ---------------------------------------------------------------------------------------

// -------------------------------- MEATS --------------------------------------------
object meat inherits IngredientKind {
    override method image() = "food/Ingredients/meats/meat_raw.png"
    override method processTime() = 8
    override method initialize() {
        self.turnsInto(cooking, cookedMeat)
    }
}
object cookedMeat inherits IngredientKind {
    override method image() = "food/Ingredients/meats/meat_cooked.png"
}
// ---------------------------------------------------------------------------------------

// -------------------------------- CHEESES --------------------------------------------
object cheese inherits IngredientKind {
    override method image() = "food/Ingredients/cheeses/cheese_raw.png"
    override method initialize() {
        self.turnsInto(cutting, cheeseCutted)
    }
}   
object cheeseCutted inherits IngredientKind {
    override method image() = "food/Ingredients/cheeses/cheese_cutted.png"
    override method initialize() {
        self.turnsInto(cutting, cheeseFeta)
    }
}
object cheeseFeta inherits IngredientKind {
    override method image() = "food/Ingredients/cheeses/cheese_feta.png"
}
// ---------------------------------------------------------------------------------------

// -------------------------------- SALAMIS --------------------------------------------
object salami inherits IngredientKind {
    override method image() = "food/Ingredients/salamis/salami_raw.png"
    override method initialize() {
        self.turnsInto(cutting, salamiCutted)
    }
}
object salamiCutted inherits IngredientKind {
    override method image() = "food/Ingredients/salamis/salami_cutted.png"
}
// ---------------------------------------------------------------------------------------

// -------------------------------- PIZZA-DOUGH --------------------------------------------
object pizzaDough inherits IngredientKind {
    override method image() = "food/Ingredients/pizza-doughs/pizza-dough_raw.png"
    override method initialize() {
        self.turnsInto(cooking, pizzaDoughCooked)
    }
}
object pizzaDoughCooked inherits IngredientKind {
    override method image() = "food/Ingredients/pizza-doughs/pizza-dough_cooked.png"
}
// ---------------------------------------------------------------------------------------

// -------------------------------- EGGS --------------------------------------------
object egg inherits IngredientKind {
    override method image() = "food/Ingredients/eggs/egg_raw.png"
    override method initialize() {
        self.turnsInto(frying, eggFryed)
    }
}
object eggFryed inherits IngredientKind {
    override method image() = "food/Ingredients/eggs/egg_fryed.png"
}
// ---------------------------------------------------------------------------------------

// -------------------------------- SAUSAGES --------------------------------------------
object sausage inherits IngredientKind {
    override method image() = "food/Ingredients/sausages/sausage_raw.png"
    override method initialize() {
        self.turnsInto(cooking, sausageCooked)
    }
}
object sausageCooked inherits IngredientKind {
    override method image() = "food/Ingredients/sausages/sausage_cooked.png"
}
// ---------------------------------------------------------------------------------------

// -------------------------------- BACONS --------------------------------------------
object bacon inherits IngredientKind {
    override method image() = "food/Ingredients/bacons/bacon_raw.png"
    override method initialize() {
        self.turnsInto(cooking, baconCooked)
    }
}
object baconCooked inherits IngredientKind {
    override method image() = "food/Ingredients/bacons/bacon_cooked.png"
}
// ---------------------------------------------------------------------------------------

// -------------------------------- HAM --------------------------------------------
object ham inherits IngredientKind {
  override method image() = "food/Ingredients/Ham/ham_raw.png"
  override method initialize(){
    self.turnsInto(cutting, hamCutted)
  }
}
object hamCutted inherits IngredientKind {
    override method image() = "food/Ingredients/Ham/ham_cutted.png"
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