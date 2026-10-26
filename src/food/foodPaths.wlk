// Las familias de ingredientes: dónde están sus imágenes.
// Cada familia arma la ruta de una imagen a partir del estado ("raw", "cut", "whole"...).
// Están pensadas para los ingredientes que tienen más de un estado.

object potatoFamily {
    method image(state) = "food/Ingredients/potatoes/potato_" + state + ".png"
}
object lettuceFamily {
    method image(state) = "food/Ingredients/lettuces/lettuce_" + state + ".png"
}
object bunFamily {
    method image(state) = "food/Ingredients/buns/bun_" + state + ".png"
}
object meatFamily {
    method image(state) = "food/Ingredients/meats/meat_" + state + ".png"
}
object tomatoFamily {
    method image(state) = "food/Ingredients/tomatoes/tomato_" + state + ".png"
}

object cheeseFamily {
    method image(state) = "food/Ingredients/cheeses/cheese_" + state + ".png"
}

object sausageFamily {
    method image(state) = "food/Ingredients/sausages/sausage_" + state + ".png"
}

object salamiFamily {
    method image(state) = "food/Ingredients/salamis/salami_" + state + ".png"
}

object pizzaDoughFamily {
    method image(state) = "food/Ingredients/pizza-doughs/pizza-dough_" + state + ".png"
}

object eggFamily {
    method image(state) = "food/Ingredients/eggs/egg_" + state + ".png"
}

object baconFamily {
    method image(state) = "food/Ingredients/bacons/bacon_" + state + ".png"
}


