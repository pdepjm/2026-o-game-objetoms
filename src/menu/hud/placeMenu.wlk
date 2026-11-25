// Buffet Albert Einstein - el panel para elegir y colocar máquinas.
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
import tools.toolsManager.*
import machines.machineManager.*
import menu.hud.hud.*
import menu.screenClasses.*
import levels.levelManager.*
import cellPosition.*
import sound.sfx.*
import directions.*
import menu.drawing.visuals.*

object placeMenu {
    var currentPage = 0
    // Todo lo dibujado en el panel (menos los marcos)
    const drawn = new VisualGroup()
    // Los casilleros que se ven (MenuItem) y lo que se clickea en ellos: un CellArea por casillero
    var items = []
    var slotAreas = []
    // Las máquinas (fábricas) que pide el paso del tutorial: su casillero titila
    var wanted = []
    const hintFrames = new VisualGroup()
    var errorFrames = []

    // Sólo se dibuja mientras es el panel activo (COLOCANDO)
    var visible = false

    // La fila de abajo de los casilleros de arriba (los de abajo, 2 filas menos)
    const firstRow = 10
    // La brújula de "hacia dónde mira": un botón por dirección (x 18 a 21, filas 2 a 5)
    const compassTiles = [
        new CompassTile(direction = up, zone = rectangle.of(19, 5, 2, 1)),
        new CompassTile(direction = down, zone = rectangle.of(19, 2, 2, 1)),
        new CompassTile(direction = left, zone = rectangle.of(18, 3, 1, 2)),
        new CompassTile(direction = right, zone = rectangle.of(21, 3, 1, 2))
    ]
    const errorMillis = 600

    method currentPage() = currentPage

    // Mensajes que le manda rightPanel

    method show() {
        visible = true
        self.renderItems()
    }

    method hide() {
        visible = false
        self.clear()
        self.removeFrames()
    }

    // Los clics del panel: los casilleros de las máquinas y la brújula (cada uno sabe qué hace)
    method clickableAreas() = slotAreas + compassTiles

    // Q y E: la máquina anterior o la siguiente del catálogo (pasa de página si hace falta)
    method chooseNext(step) {
        const catalog = machineManager.catalog()
        const index = (0 .. catalog.size() - 1).findOrDefault({ i => machineManager.selects(catalog.get(i)) }, 0)
        self.choose(catalog.get((index + step + catalog.size()).rem(catalog.size())))
    }

    // Elige esa máquina (fábrica), en la página donde está.
    method choose(factory) {
        machineManager.select(factory)
        const page = machineManager.pageOf(factory)
        if (page != currentPage) {
            currentPage = page
            if (visible) self.renderItems()
        } else self.updateFrames()
        compassMachine.updateImage()
        sfx.menuSelect()
        levelManager.machineSelected(factory)
    }

    // Avanzan o retroceden de a una página (sólo redibujan si el panel se está viendo)
    method prev(){
        currentPage = (currentPage - 1).max(0)
        if (visible) self.renderItems()
    }

    method next(){
        currentPage = (currentPage + 1).min(machineManager.pageCount() - 1)
        if (visible) self.renderItems()
    }

    method resetPage() {
        currentPage = 0
        if (visible) self.renderItems()
    }

    // ----------- DÓNDE VA CADA CASILLERO -----------

    // La celda de abajo a la izquierda del casillero (1 a 4): de a 2 por fila
    method slotPosition(slot) = hud.interactiveZone().at((slot - 1).rem(2) * 2, firstRow - (slot - 1).div(2) * 2)

    // El casillero de esa máquina (fábrica) en la página que se ve, o 0 si no está en esta página
    method slotOf(factory) {
        var slot = 0
        var position = 0

        machineManager.machinesOfPage(currentPage).forEach({ each =>
            position += 1
            if (each == factory) slot = position
        })

        return slot
    }

    // ¿En qué casillero está la máquina que tengo elegida?
    method selectedSlot() {
        var slot = 0
        var position = 0

        machineManager.machinesOfPage(currentPage).forEach({ factory =>
            position += 1
            if (machineManager.selects(factory)) slot = position
        })

        return slot
    }

    // ----------- MARCOS -----------

    // Las máquinas que pide el tutorial (lo avisa levelManager con cada paso)
    method highlight(factories) {
        if (factories != wanted) {
            wanted = factories
            if (visible) self.updateFrames()
        }
    }

    // La máquina elegida no es la que pide el tutorial: su casillero se pone rojo un momento
    method flashError(factory) {
        const slot = self.slotOf(factory)
        if (visible && slot > 0) {
            const frame = new Picture(image = "menu/slot_error.png", position = self.slotPosition(slot))
            frame.show()
            errorFrames.add(frame)
            game.schedule(errorMillis, { self.removeErrorFrame(frame) })
        }
    }

    method removeErrorFrame(frame) {
        if (errorFrames.contains(frame)) {
            errorFrames.remove(frame)
            frame.hide()
        }
    }

    // Los casilleros que titilan (para los tests)
    method hintedSlots() = hintFrames.visuals().map({ frame => frame.position() })

    // El marco amarillo va en la elegida
    method updateFrames() {
        self.removeFrames()
        const slot = self.selectedSlot()
        if (slot > 0) {
            selectionFrame.moveToSlot(slot)
            game.addVisual(selectionFrame)
        }
        wanted
            .filter({ factory => !machineManager.selects(factory) && self.slotOf(factory) > 0 })
            .forEach({ factory => hintFrames.add(new Picture(image = "menu/slot_hint.gif", position = self.slotPosition(self.slotOf(factory)))) })
    }

    method removeFrames() {
        if (game.hasVisual(selectionFrame)) game.removeVisual(selectionFrame)
        hintFrames.clear()
        errorFrames.forEach({ frame => frame.hide() })
        errorFrames = []
    }

    // ----------- DIBUJAR LAS MAQUINAS EN EL MENU -----------

    // Saca de la pantalla todo lo dibujado (menos los marcos)
    method clear() {
        drawn.clear()
        items = []
        slotAreas = []
    }

    // Renderiza en pantalla las maquinas que pertenecen a la pagina
    method renderItems() {
        self.clear()

        var slot = 0

        machineManager.machinesOfPage(currentPage).forEach({ factory =>
            slot += 1
            // la máquina de muestra (guardada en machineManager): da el nombre y la imagen del menú
            const sample = machineManager.sampleOf(factory)
            const item = new MenuItem(name = sample.name(), machine = sample, position = self.slotPosition(slot))
            item.updateImage()
            items.add(drawn.add(item))
            // el casillero ocupa 2x2 celdas: clickearlo elige esa máquina
            slotAreas.add(new CellArea(zone = rectangle.of(item.position().x(), item.position().y(), 2, 2), action = { self.choose(factory) }))
        })

        // la ayuda, debajo de los casilleros, y el título de la brújula
        drawn.add(new Picture(image = "menu/place_help.png", position = hud.interactiveZone().at(0, firstRow - 3)))
        drawn.add(new Picture(image = "menu/dir_label.png", position = hud.interactiveZone().at(0, firstRow - 4)))
        drawn.add(new Picture(image = "menu/compass_center.png", position = compassMachine.position()))

        // la brújula: un botón por dirección (la elegida, en amarillo) y la máquina en el centro
        (compassTiles + [compassMachine]).forEach({ visual =>
            visual.updateImage()
            drawn.add(visual)
        })

        // los marcos van encima de los casilleros
        self.updateFrames()
    }

    // Actualiza las imágenes que muestran hacia dónde mira la máquina a colocar.
    method updateImages() {
        (items + compassTiles + [compassMachine]).forEach({ visual => visual.updateImage() })
    }

    method compassTiles() = compassTiles

    // Los casilleros que se ven, en orden (para los tests)
    method items() = items

}

// Un casillero: la máquina en chico, con su nombre.
class MenuItem inherits Picture(image = "no_texture.png") {
    const property name
    // Una máquina del tipo que muestra: es la que sabe qué imagen va en el menú
    const machine

    method updateImage() {
        image = machine.menuImage(toolsManager.currentDirection())
    }
}

// Un botón de la brújula de "hacia dónde mira" (assets/menu/compass_*.png).
class CompassTile inherits Button(image = "menu/compass_right.png") {
    const property direction

    override method onClick(pos) { toolsManager.currentDirection(direction) }

    method updateImage() {
        image = "menu/compass_" + direction.name() + (if (toolsManager.currentDirection() == direction) "_on" else "") + ".png"
    }
}

// La máquina elegida, en el centro de la brújula, mirando hacia donde va a quedar.
object compassMachine inherits Picture(image = "no_texture.png", position = new CellPosition(x = 19, y = 3)) {
    method updateImage() { image = machineManager.selectedSample().menuImage(toolsManager.currentDirection()) }
}

object selectionFrame {
    // El marco amarillo de la máquina elegida
    var position = placeMenu.slotPosition(1)

    method position() = position
    method image() = "menu/slot_selected.png"

    // Se ubica sobre el casillero (1 a 4) de la máquina seleccionada
    method moveToSlot(slot) {
        position = placeMenu.slotPosition(slot)
    }
}
