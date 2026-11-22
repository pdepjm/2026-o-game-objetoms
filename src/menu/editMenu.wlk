// Buffet Albert Einstein - el panel de edición de las máquinas.
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

import machines.machineClasses.*
import wollok.game.*
import menu.menuManager.*
import menu.texts.*
import board.*
import levels.levelManager.*
import sound.sfx.*
import cellPosition.*
import menu.visuals.*

// Panel de la zona interactiva mientras el jugador está EDITANDO una máquina (X sobre la elegida).
// Responde a show, hide y onClick, igual que el resto de los paneles (ver menuManager).
// Muestra los settings de la máquina elegida (la del cursor), agrupados por categoría,
// y al clickear una opción se la aplica al setting. No sabe de qué máquina se trata: sólo le pide
// settings() y trabaja con lo que devuelve (ver machines/settings.wlk).
object editMenu{
    var selectedMachine = noMachine

    // Todo lo que hay dibujado en el panel (títulos, nombres de settings y opciones), y las marcas de las elegidas
    const drawn = new VisualGroup()
    const markers = new VisualGroup()
    // Cada opción dibujada, para saber qué se clickeó
    var slots = []
    // La opción marcada para el teclado (flechas y Enter): su índice en slots
    var focusIndex = 0

    // Sólo se dibuja mientras es el panel activo (EDITANDO)
    var visible = false

    // Mensajes que le manda menuManager

    method show() {
        visible = true
        self.render()
    }

    method hide() {
        visible = false
        selectedMachine = noMachine
        self.clear()
    }

    // Lo llama la acción edit (X sobre la máquina elegida): elige la máquina y muestra sus settings
    method selectMachine(pos) {
        selectedMachine = board.machineAt(pos)
        if (visible) self.render()
        sfx.menuSelect()
    }

    // Aplica la opción clickeada a su setting, si se clickeó una
    method onClick(pos) {
        self.slotAt(pos).selectIn(self)
    }

    // Aplica esa opción a su setting (lo llama la opción clickeada, ver OptionSlot)
    method choose(slot) {
        slot.setting().select(slot.option())
        self.updateMarkers()
        levelManager.settingChanged(selectedMachine, slot.setting())
        sfx.menuSelect()
    }

    // DISTRIBUCION
    /*
        De arriba hacia abajo, una línea por vez. Por cada categoría:
            CATEGORIA              ← título
            Nombre del setting     ← uno por cada setting de la categoría
            [op][op][op][op]       ← sus opciones, de a 4 por fila (el ancho de la zona)
            [op]
    */
    method columns() = 4
    method topRow() = 11

    // La opción dibujada en esa posición (noSlot si el click cayó afuera de todas).
    // Como las opciones se alinean con las celdas enteras de la cuadrícula de Wollok (x: 18 a 21),
    // la comparación exacta x == pos.x() e y == pos.y() garantiza que cualquier click dentro del
    // casillero de 50x50 px active la opción correcta sin importar si se clickea a la izquierda o derecha.
    method slotAt(pos) = slots.findOrDefault({ slot => slot.position().x() == pos.x() && slot.position().y() == pos.y() }, noSlot)

    // Los settings de la máquina elegida (ninguno si no hay máquina elegida)
    method settings() = selectedMachine.settings()

    // Las categorías de esos settings, sin repetir y en el orden en que aparecen
    method categories() {
        const found = []
        self.settings().forEach({ setting => if (!found.contains(setting.category())) found.add(setting.category()) })
        return found
    }

    // -------------------------------------------------------------

    // Dibuja las categorías con sus settings. Se llama sólo cuando cambia la máquina elegida.
    method render() {
        self.clear()

        var row = self.topRow()

        self.categories().forEach({ category =>
            self.addText(category.name().toUpperCase(), row, 1.5, "FFD700FF")
            row -= 1

            const inCategory = self.settings().filter({ setting => setting.category() == category })

            inCategory.filter({ setting => !setting.isColumned() }).forEach({ setting =>
                self.addText(setting.name(), row)
                row -= 1
                row = self.renderOptions(setting, row)
            })

            const columned = inCategory.filter({ setting => setting.isColumned() })
            if (!columned.isEmpty()) row = self.renderColumns(columned, row)
        })

        self.updateMarkers()
        focusIndex = 0
        self.updateFocus()
    }

    // ----------- TECLADO -----------

    // Las flechas mueven la marca por las opciones, en el orden en que se dibujan
    method moveFocus(direction) {
        if (!slots.isEmpty()) {
            focusIndex = (focusIndex + direction.listStep() + slots.size()).rem(slots.size())
            self.updateFocus()
            sfx.directionChange()
        }
    }

    // Enter: aplica la opción marcada
    method chooseFocused() {
        if (!slots.isEmpty()) self.choose(slots.get(focusIndex))
    }

    method focusIndex() = focusIndex
    // Cuántas opciones hay dibujadas, y las marcas de las elegidas (para los tests)
    method slotCount() = slots.size()
    method markers() = markers.visuals()

    // La marca va sobre la opción marcada (y arriba de todo). Sólo se llama cuando cambia.
    method updateFocus() {
        if (game.hasVisual(optionFocus)) game.removeVisual(optionFocus)
        if (!slots.isEmpty()) {
            optionFocus.moveTo(slots.get(focusIndex).position())
            game.addVisual(optionFocus)
        }
    }

    // Dibuja las opciones del setting de a self.columns() por fila, empezando en esa fila.
    // Devuelve la primera fila que queda libre.
    method renderOptions(setting, firstRow) {
        var index = 0

        setting.options().forEach({ option =>
            const position = menuManager.interactiveZone().at(index.rem(self.columns()), firstRow - index.div(self.columns()))
            drawn.add(option.visualAt(position))
            slots.add(new OptionSlot(setting = setting, option = option, position = position))
            index += 1
        })

        return firstRow - (index / self.columns()).roundUp()
    }

    // Dibuja los settings que van en columna: el nombre arriba y sus opciones una debajo de la otra.
    // Devuelve la primera fila que queda libre.
    method renderColumns(settings, firstRow) {
        var lastRow = firstRow

        settings.forEach({ setting =>
            self.addText(setting.name(), firstRow, setting.column())

            var index = 0

            setting.options().forEach({ option =>
                const position = menuManager.interactiveZone().at(setting.column(), firstRow - 1 - index)
                drawn.add(option.visualAt(position))
                slots.add(new OptionSlot(setting = setting, option = option, position = position))
                index += 1
            })
            lastRow = lastRow.min(firstRow - 1 - setting.options().size())
        })

        return lastRow
    }

    // Los textos del panel. Wollok distingue los métodos por cantidad de parámetros: las versiones cortas
    // completan lo que falta. Por defecto, centrado en el panel (column 1.5: mide 4 columnas, 0 a 3) y en blanco;
    // los títulos de las categorías ("PRODUCCION", "MOVIMIENTO") van en dorado (FFD700FF), y los nombres de
    // los settings en columna ("Izq.", "Recto", "Der.") sobre su columna.
    method addText(text, row) { self.addText(text, row, 1.5) }

    method addText(text, row, column) { self.addText(text, row, column, "FFFFFFFF") }

    method addText(text, row, column, color) {
        drawn.add(new MenuText(text = text, position = menuManager.interactiveZone().at(column, row), textColor = color))
    }

    // Una marca sobre la opción elegida de cada setting (un recuadro del tamaño de una celda). Se llama sólo
    // cuando cambia algo.
    method updateMarkers() {
        markers.clear()
        slots.filter({ slot => slot.setting().isSelected(slot.option()) })
            .forEach({ slot => markers.add(new Picture(image = "overlay_cell.png", position = slot.position())) })
        // la marca del teclado, arriba de las marcas
        if (game.hasVisual(optionFocus)) {
            game.removeVisual(optionFocus)
            game.addVisual(optionFocus)
        }
    }

    // Saca de la pantalla todo lo dibujado
    method clear() {
        drawn.clear()
        markers.clear()
        slots = []
        if (game.hasVisual(optionFocus)) game.removeVisual(optionFocus)
    }

    // La dirección no cambia las imágenes de las opciones, pero toolsManager puede avisar igual
    method updateImages() {}

}

// La marca de la opción elegida con el teclado. Guarda su posición: se mueve sólo con las flechas.
object optionFocus {
    var position = new CellPosition(x = 0, y = 0)

    method position() = position
    method image() = "menu/option_focus.png"
    method moveTo(aPosition) { position = aPosition }
}

// Qué opción de qué setting hay dibujada en una posición
class OptionSlot {
    const property setting
    const property option
    const property position

    // ¿Es la opción con ese valor de ese setting?
    method matches(aSetting, value) = setting == aSetting && option.value() == value
    method selectIn(menu) { menu.choose(self) }
}

// "No hay opción ahí": lo que hay en una posición donde se clickeó afuera de todas las opciones
object noSlot {
    method matches(aSetting, value) = false
    method selectIn(menu) {}
}

