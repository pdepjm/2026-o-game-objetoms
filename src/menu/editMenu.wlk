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

import wollok.game.*
import menu.menuManager.*
import menu.menuText.*
import board.*
import levels.levelManager.*
import sound.sfx.*

// Panel de la zona interactiva mientras la herramienta activa es edit.
// Responde a show, hide y onClick, igual que el resto de los paneles (ver menuManager).
// Muestra los settings de la máquina elegida con la herramienta edit, agrupados por categoría,
// y al clickear una opción se la aplica al setting. No sabe de qué máquina se trata: sólo le pide
// settings() y trabaja con lo que devuelve (ver machines/settings.wlk).
object editMenu{
    var selectedMachine = null

    // Todo lo que hay dibujado en el panel (títulos, nombres de settings, opciones y marcas)
    var renderedItems = []
    // Cada opción dibujada, para saber qué se clickeó
    var slots = []
    var markers = []

    // Sólo se dibuja mientras es el panel activo (herramienta edit)
    var visible = false

    // Mensajes que le manda menuManager

    method show() {
        visible = true
        self.render()
    }

    method hide() {
        visible = false
        selectedMachine = null
        self.vaciarRenders()
    }

    // Lo llama la herramienta edit al clickear el tablero: elige la máquina (si hay una) y
    // muestra sus settings
    method selectMachine(pos) {
        selectedMachine = board.machineAt(pos)
        if (visible) self.render()
        sfx.menuSelect()
    }

    // Aplica la opción clickeada a su setting, si se clickeó una
    method onClick(pos) {
        const slot = self.slotAt(pos)

        if (slot != null) {
            slot.setting().select(slot.option())
            self.updateMarkers()
            levelManager.settingChanged(selectedMachine, slot.setting())
            sfx.menuSelect()
        }
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
    method topRow() = 14

    // La opción dibujada en esa posición (null si el click cayó afuera de todas).
    // Como las opciones se alinean con las celdas enteras de la cuadrícula de Wollok (x: 21 a 24),
    // la comparación exacta x == pos.x() e y == pos.y() garantiza que cualquier click dentro del
    // casillero de 50x50 px active la opción correcta sin importar si se clickea a la izquierda o derecha.
    method slotAt(pos) = slots.findOrDefault({ slot => slot.position().x() == pos.x() && slot.position().y() == pos.y() }, null)

    // Los settings de la máquina elegida (ninguno si no hay máquina elegida)
    method settings() = if (selectedMachine == null) [] else selectedMachine.settings()

    // Las categorías de esos settings, sin repetir y en el orden en que aparecen
    method categories() {
        const found = []
        self.settings().forEach({ setting => if (!found.contains(setting.category())) found.add(setting.category()) })
        return found
    }

    // -------------------------------------------------------------

    // Dibuja las categorías con sus settings. Se llama sólo cuando cambia la máquina elegida.
    method render() {
        self.vaciarRenders()

        var row = self.topRow()

        self.categories().forEach({ category =>
            self.addCategoryTitle(category.name().toUpperCase(), row)
            row -= 1

            const inCategory = self.settings().filter({ setting => setting.category() == category })

            inCategory.filter({ setting => setting.column() == null }).forEach({ setting =>
                self.addSettingTitle(setting.name(), row)
                row -= 1
                row = self.renderOptions(setting, row)
            })

            const columned = inCategory.filter({ setting => setting.column() != null })
            if (!columned.isEmpty()) row = self.renderColumns(columned, row)
        })

        self.updateMarkers()
    }

    // Dibuja las opciones del setting de a self.columns() por fila, empezando en esa fila.
    // Devuelve la primera fila que queda libre.
    method renderOptions(setting, firstRow) {
        var index = 0

        setting.options().forEach({ option =>
            const position = menuManager.interactiveZone().at(index.rem(self.columns()), firstRow - index.div(self.columns()))
            const visual = if (option.hasImage()) new OptionImage(image = option.image(), position = position)
                else new MenuText(text = option.label(), position = position)

            game.addVisual(visual)
            renderedItems.add(visual)
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
                const visual = new OptionImage(image = option.image(), position = position)

                game.addVisual(visual)
                renderedItems.add(visual)
                slots.add(new OptionSlot(setting = setting, option = option, position = position))
                index += 1
            })
            lastRow = lastRow.min(firstRow - 1 - setting.options().size())
        })

        return lastRow
    }

    // Título principal de la categoría (ej: "PRODUCCION", "MOVIMIENTO").
    // Se ubica en column = 1.5 para quedar centrado en el panel (que mide 4 columnas: 0 a 3)
    // y se destaca con color dorado (FFD700FF).
    method addCategoryTitle(text, row) {
        const label = new MenuText(
            text = text,
            position = menuManager.interactiveZone().at(1.5, row),
            textColor = "FFD700FF"
        )
        game.addVisual(label)
        renderedItems.add(label)
    }

    // Título de un setting específico (ej: "Ingrediente", "Velocidad", "Salida").
    // También centrado en column = 1.5, en color blanco para distinguirlo de la categoría.
    method addSettingTitle(text, row) {
        const label = new MenuText(
            text = text,
            position = menuManager.interactiveZone().at(1.5, row),
            textColor = "FFFFFF"
        )
        game.addVisual(label)
        renderedItems.add(label)
    }

    // SOBRECARGA DE MÉTODOS POR ARIDAD (distinta cantidad de parámetros):
    // Wollok distingue métodos por su nombre y cantidad de argumentos. No es un error tener dos 'addText';
    // es un patrón clásico de delegación con valor por defecto:
    
    // 1) Versión de 2 parámetros: atajo conveniente para dibujar un texto centrado (columna 1.5 por defecto).
    // En lugar de duplicar código, delega en la versión de 3 parámetros.
    method addText(text, row) {
        self.addText(text, row, 1.5)
    }

    // 2) Versión de 3 parámetros: método general que recibe explícitamente la columna (ej: en renderColumns
    // para ubicar "Izq.", "Recto" y "Der." exactamente sobre sus columnas 0, 1 y 2).
    method addText(text, row, column) {
        const label = new MenuText(text = text, position = menuManager.interactiveZone().at(column, row))

        game.addVisual(label)
        renderedItems.add(label)
    }

    // Una marca sobre la opción elegida de cada setting. Se llama sólo cuando cambia algo.
    method updateMarkers() {
        markers.forEach({ marker => game.removeVisual(marker) })
        markers = slots.filter({ slot => slot.setting().isSelected(slot.option()) })
            .map({ slot => new OptionMarker(position = slot.position()) })
        markers.forEach({ marker => game.addVisual(marker) })
    }

    // Remueve de la pantalla todo lo dibujado hasta ese momento
    method vaciarRenders() {
        renderedItems.forEach({ item => game.removeVisual(item) })
        markers.forEach({ marker => game.removeVisual(marker) })
        renderedItems = []
        markers = []
        slots = []
    }

    // La dirección no cambia las imágenes de las opciones, pero toolsManager puede avisar igual
    method updateImages() {}

}

// Una opción dibujada con su imagen
class OptionImage {
    const property image
    const property position
}

// Qué opción de qué setting hay dibujada en una posición
class OptionSlot {
    const property setting
    const property option
    const property position
}

// Marca la opción elegida: un recuadro del tamaño de una celda (el overlay de place mide 4x4)
class OptionMarker {
    const property position

    method image() = "overlay_cell.png"
}
