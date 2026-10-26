import food.recipesClasses.*
import food.foodTypes.*


object burgerRecipe inherits Recipe(result = burger){
    override method initialize() {
        requirements.add(new Requirement(kind = cutBun, amount = 1))
        requirements.add(new Requirement(kind = cutLettuce, amount = 1))
        requirements.add(new Requirement(kind = cutTomato, amount = 1))
        requirements.add(new Requirement(kind = cookedMeat, amount = 1))
    }
}

object cheeseBurgerRecipe inherits Recipe(result = cheeseBurger){
    override method initialize() {
        requirements.add(new Requirement(kind = cutBun, amount = 1))
        requirements.add(new Requirement(kind = cutLettuce, amount = 1))
        requirements.add(new Requirement(kind = cutTomato, amount = 1))
        requirements.add(new Requirement(kind = cookedMeat, amount = 1))
        requirements.add(new Requirement(kind = cheeseFeta, amount = 1))
    }
}

object pizzaPepperoniRecipe inherits Recipe(result = pizzaPepperoni) {
    override method initialize() {
        requirements.add(new Requirement(kind = pizzaDoughCooked, amount = 1))
        requirements.add(new Requirement(kind = cheeseCutted, amount = 1))
        requirements.add(new Requirement(kind = salamiCutted, amount = 1))
    }
}

object doubleBurgerRecipe inherits Recipe(result = doubleBurger) {
    override method initialize() {
        requirements.add(new Requirement(kind = cutBun, amount = 1))
        requirements.add(new Requirement(kind = cutLettuce, amount = 1))
        requirements.add(new Requirement(kind = cutTomato, amount = 1))
        requirements.add(new Requirement(kind = cookedMeat, amount = 2))
        requirements.add(new Requirement(kind = cheeseFeta, amount = 1))
    }
}

object saladRecipe inherits Recipe(result = salad) {
    override method initialize() {
        requirements.add(new Requirement(kind = cutTomato, amount = 1))
        requirements.add(new Requirement(kind = cutLettuce, amount = 1))
    }
}

object hotDogRecipe inherits Recipe(result = hotDog) {
    override method initialize() {
        requirements.add(new Requirement(kind = cutBun, amount = 1))
        requirements.add(new Requirement(kind = sausageCooked, amount = 1))
    }
}