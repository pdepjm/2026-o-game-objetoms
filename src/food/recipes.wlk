import food.recipesClasses.*
import food.foodTypes.*

object friedPotatoRecipe inherits Recipe(result = friedPotato){
    override method initialize() {
        requirements.add(new Requirement(kind = cutPotato, amount = 1))
    }
}