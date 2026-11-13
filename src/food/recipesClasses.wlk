// Buffet Albert Einstein - las clases de las recetas y sus requisitos.
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

// Las clases de las recetas. Las recetas concretas están en recipes.wlk
import food.foodClasses.*

// Un requisito de una receta: un kind y cuántos hacen falta.
class Requirement {
    const kind 
    const amount 
    method amount() = amount

    // ¿Este item es del kind que pide?
    method isSatisfiedBy(anItem) = anItem.kind() == kind

    // ¿Entre estos items hay suficientes?
    method isCoveredBy(items) = items.count({ item => self.isSatisfiedBy(item) }) >= amount

    // ¿Le sirve este item, sabiendo lo que ya se juntó?
    method stillNeeds(anItem, items) = self.isSatisfiedBy(anItem) && !self.isCoveredBy(items)
}
// Una receta: qué requisitos tiene y qué plato sale.
class Recipe {
    const requirements = []
    const result

    method result() = result

    // Cuántos items hacen falta en total
    method totalItems() = requirements.sum({r => r.amount()})

    // ¿Alcanza con estos items para prepararla?
    method canBeMadeWith(items) = requirements.all({ r => r.isCoveredBy(items) })

    // ¿Le sirve este item a algún requisito?
    method stillNeeds(anItem, items) = requirements.any({ r => r.stillNeeds(anItem, items) })

    // Crea un plato nuevo de esta receta
    method prepare() = new Item(kind = result)

    // Tiempo que tarda en armarse (Medido en ticks ~100ms)
    method assembleTime() = 20 // Por defecto 2 segundos
}