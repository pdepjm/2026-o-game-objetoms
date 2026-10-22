import wollok.game.*
import menu.menuManager.*
import board.*

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
    }

    // Aplica la opción clickeada a su setting, si se clickeó una
    method onClick(pos) {
        const slot = self.slotAt(pos)

        if (slot != null) {
            slot.setting().select(slot.option())
            self.updateMarkers()
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

    // La opción dibujada en esa posición (null si el click cayó afuera de todas)
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
            self.addText(category.name().toUpperCase(), row)
            row -= 1

            self.settings().filter({ setting => setting.category() == category }).forEach({ setting =>
                self.addText(setting.name(), row)
                row -= 1
                row = self.renderOptions(setting, row)
            })
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

    method addText(text, row) {
        const label = new MenuText(text = text, position = menuManager.interactiveZone().at(0, row))

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

// Un texto: el título de una categoría, el nombre de un setting o una opción sin imagen
class MenuText {
    const property text
    const property position

    method textColor() = "FFFFFFFF"
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
