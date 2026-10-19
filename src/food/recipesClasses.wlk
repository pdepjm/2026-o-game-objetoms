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

    // Cuántos items hacen falta en total
    method totalItems() = requirements.sum({r => r.amount()})

    // ¿Alcanza con estos items para prepararla?
    method canBeMadeWith(items) = requirements.all({ r => r.isCoveredBy(items) })

    // ¿Le sirve este item a algún requisito?
    method stillNeeds(anItem, items) = requirements.any({ r => r.stillNeeds(anItem, items) })

    // Crea un plato nuevo de esta receta
    method prepare() = new Item(kind = result)
}