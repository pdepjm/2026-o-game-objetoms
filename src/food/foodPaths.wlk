// Buffet Albert Einstein - las familias de ingredientes: dónde están las imágenes de cada estado.
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

object hamFamily {
    method image(state) = "food/Ingredients/Ham/ham_" + state + ".png"
}

