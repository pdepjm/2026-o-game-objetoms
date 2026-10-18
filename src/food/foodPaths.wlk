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
