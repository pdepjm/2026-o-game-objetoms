import food.recipesClasses.*
import food.foodTypes.*


object burgerRecipe inherits Recipe(result = burger){
    override method initialize() {
        requirements.add(new Requirement(kind = cutBun, amount = 1))
        requirements.add(new Requirement(kind = cutLettuce, amount = 1))
        requirements.add(new Requirement(kind = cutTomato, amount = 1))
        requirements.add(new Requirement(kind = cookedMeat, amount = 2))
    }
}