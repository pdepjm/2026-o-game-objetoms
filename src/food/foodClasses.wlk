// Buffet Albert Einstein - las clases de la comida (ingredientes y platos) y los procesos que pueden sufrir.
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

// Las clases de la comida y los procesos que puede sufrir.
// Un Item es lo que circula por el tablero; su kind dice qué es:
// un ingrediente (IngredientKind), que se puede procesar, o un plato (DishKind), que no.
// Los kinds concretos (potato, cutPotato, burger...) están en foodTypes.wlk
import simulation.animationEngine.*

// Objetos de transformación: sirven para definir los procesos que pueden sufrir los ingredientes.
// Actualmente están vacíos, pero podrían tener el tiempo de procesamiento.

object cutting {}
object frying {}
// Quemarse por quedarse demasiado tiempo en la freidora
object burning {}
object cooking {}

// Clase para los ingredientes
class IngredientKind{
    const transitions = new Dictionary()

    method image()

    // Un kind también es un filtro de items: deja pasar a los que son de ese kind (ver settings.wlk)
    method accepts(item) = item.kind() == self

    // Pasos de simulación que tarda en procesarse. Sobrescribirlo sólo si tarda distinto.
    method processTime() = 5


    // Agrega un proceso como 'cutting' junto al objeto ya convertido
    // Ejemplo:
    // (cutting, cutPotato)
    method turnsInto(aProcess, aKind) {
        transitions.put(aProcess, aKind)
    }

    // Verifica si al ingrediente se le puede aplicar un proceso, por ejemplo, freírlo
    method canProcess(aProcess) = transitions.containsKey(aProcess)



    // Aplica el proceso y devuelve el objeto ya convertido.
    // Las máquinas preguntan canProcess antes, así que el error solo salta si hay un bug.
    method process(aProcess) =
        transitions.getOrElse(aProcess, { self.error("No se le puede aplicar " + aProcess) })
}

// Clase para los platos finales: ningún proceso se les puede aplicar
class DishKind {
    method image()
    method accepts(item) = item.kind() == self
    method canProcess(_) = false
}

// Lo que circula por el tablero. Delega en su kind, que cambia cuando lo procesan
class Item inherits Animado {
    var kind

    // Getter
    method kind() = kind
    method image() = kind.image()
    method canProcess(aProcess) = kind.canProcess(aProcess)

    // Cuánto tarda en procesarse: lo dice su kind de origen
    method processTime() = kind.processTime()
    
    method process(aProcess) {
        kind = kind.process(aProcess)
    }
}
