import food.recipesClasses.*
import food.foodTypes.*

object recipeBook {
	// Todas las recetas del juego, en el orden en que se muestran en el panel de edit
	const all = [burgerRecipe, cheeseBurgerRecipe, doubleBurgerRecipe, pizzaPepperoniRecipe, saladRecipe, hotDogRecipe, tomatoSoupRecipe]
	// Las que se pueden elegir ahora (las del nivel). Al arrancar, todas.
	var available = all

	method all() = all
	method available() = available

	// La receta con la que arranca un Assembler: la primera disponible, o noRecipe si el nivel no ofrece ninguna
	method firstAvailable() = if (available.isEmpty()) noRecipe else available.first()

	// Lo llama levelManager.load con las recetas del nivel
	method changeAvailable(recipes) {
		available = recipes
	}
}

// La receta de un Assembler cuando el nivel no ofrece ninguna: no pide nada y nunca arma un plato.
// Es un objeto nulo (como noGoal): así un nivel sin recetas no rompe al crear un Assembler,
// por ejemplo al dibujarlo en el menú. No es una de las opciones del panel de edit.
object noRecipe {
	method totalItems() = 0
	method stillNeeds(item, items) = false
	method canBeMadeWith(items) = false
}

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
        requirements.add(new Requirement(kind = cookedMeat, amount = 1))
        requirements.add(new Requirement(kind = cheeseFeta, amount = 2))
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
        requirements.add(new Requirement(kind = cheeseFeta, amount = 2))
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

object tomatoSoupRecipe inherits Recipe(result = tomatoSoup) {
    override method initialize() {
        requirements.add(new Requirement(kind = cutTomato, amount = 2))
    }
}