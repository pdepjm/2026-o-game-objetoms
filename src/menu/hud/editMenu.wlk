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
import menu.hud.hud.*
import input.clickManager.*
import menu.drawing.texts.*
import board.*
import levels.levelManager.*
import sound.sfx.*
import cellPosition.*
import menu.drawing.visuals.*

// Panel de la zona interactiva mientras el jugador está EDITANDO una máquina (X sobre la elegida).
object editMenu inherits ClickTargets {
    var selectedMachine = noMachine

    // Todo lo que hay dibujado en el panel (títulos, nombres de settings y opciones)
    const drawn = new VisualGroup()
    const markers = new VisualGroup()
    // Cada opción dibujada, para saber qué se clickeó
    var slots = []
    // La opción marcada para el teclado (flechas y Enter): su índice en slots
    var focusIndex = 0

    // Sólo se dibuja mientras es el panel activo (EDITANDO)
    var visible = false

    // Mensajes que le manda rightPanel

    method show() {
        visible = true
        self.render()
    }

    method hide() {
        visible = false
        selectedMachine = noMachine
        self.clear()
    }

    // Lo llama rightPanel cuando una máquina con ajustes pide que la editen
    method selectMachine(machine) {
        selectedMachine = machine
        if (visible) self.render()
        sfx.menuSelect()
    }

    // Los clics del panel: cada opción dibujada tiene su celda
    override method zones() = [hud.interactiveZone()]
    override method clickTargets() = slots

    // Aplica esa opción a su setting
    method choose(slot) {
        slot.setting().select(slot.option())
        selectedMachine.settingChanged()
        self.updateMarkers()
        levelManager.settingChanged(selectedMachine, slot.setting())
        sfx.menuSelect()
    }

    method columns() = 4
    method topRow() = 11

    // La opción dibujada en esa celda (noSlot si no hay ninguna).
    method slotAt(pos) = slots.findOrDefault({ slot => slot.handlesClick(pos) }, noSlot)

    // Los settings de la máquina elegida (ninguno si no hay máquina elegida)
    method settings() = selectedMachine.settings()

    // Las categorías de esos settings, sin repetir y en el orden en que aparecen
    method categories() {
        const found = []
        self.settings().forEach({ setting => if (!found.contains(setting.category())) found.add(setting.category()) })
        return found
    }

    // -------------------------------------------------------------

    // Dibuja las categorías con sus settings.
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

    // La marca va sobre la opción marcada (y arriba de todo).
    method updateFocus() {
        if (game.hasVisual(optionFocus)) game.removeVisual(optionFocus)
        if (!slots.isEmpty()) {
            optionFocus.moveTo(slots.get(focusIndex).position())
            game.addVisual(optionFocus)
        }
    }

    // Dibuja las opciones del setting de a self.columns() por fila, empezando en esa fila.
    method renderOptions(setting, firstRow) {
        var index = 0

        setting.options().forEach({ option =>
            const position = hud.interactiveZone().at(index.rem(self.columns()), firstRow - index.div(self.columns()))
            drawn.add(option.visualAt(position))
            slots.add(new OptionSlot(setting = setting, option = option, position = position))
            index += 1
        })

        return firstRow - (index / self.columns()).roundUp()
    }

    // Dibuja los settings que van en columna: el nombre arriba y sus opciones una debajo de la otra.
    method renderColumns(settings, firstRow) {
        var lastRow = firstRow

        settings.forEach({ setting =>
            self.addText(setting.name(), firstRow, setting.column())

            var index = 0

            setting.options().forEach({ option =>
                const position = hud.interactiveZone().at(setting.column(), firstRow - 1 - index)
                drawn.add(option.visualAt(position))
                slots.add(new OptionSlot(setting = setting, option = option, position = position))
                index += 1
            })
            lastRow = lastRow.min(firstRow - 1 - setting.options().size())
        })

        return lastRow
    }

    // Los textos del panel.
    method addText(text, row) { self.addText(text, row, 1.5) }

    method addText(text, row, column) { self.addText(text, row, column, "FFFFFFFF") }

    method addText(text, row, column, color) {
        drawn.add(new MenuText(text = text, position = hud.interactiveZone().at(column, row), textColor = color))
    }

    // Una marca sobre la opción elegida de cada setting (un recuadro del tamaño de una celda).
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

// La marca de la opción elegida con el teclado.
object optionFocus {
    var position = new CellPosition(x = 0, y = 0)

    method position() = position
    method image() = "menu/option_focus.png"
    method moveTo(aPosition) { position = aPosition }
}

// Qué opción de qué setting hay dibujada en una celda.
class OptionSlot {
    const property setting
    const property option
    const property position
    var zone = nowhere

    override method initialize() {
        super()
        zone = rectangle.cell(position)
    }

    method handlesClick(pos) = zone.contains(pos)
    method onClick(pos) { editMenu.choose(self) }

    // ¿Es la opción con ese valor de ese setting?
    method matches(aSetting, value) = setting == aSetting && option.value() == value
}

// "No hay opción ahí": lo que hay en una posición donde se clickeó afuera de todas las opciones
object noSlot {
    method matches(aSetting, value) = false
    method handlesClick(pos) = false
    method onClick(pos) {}
}
