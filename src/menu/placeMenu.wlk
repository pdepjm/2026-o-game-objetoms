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
import menu.menuManager.*
import levels.levelManager.*
import cellPosition.*
import sound.sfx.*
import directions.*
import menu.visuals.*

// El menú de colocar, en la zona interactiva (x 18 a 21, y 0 a 11) mientras el jugador está COLOCANDO
// (ver toolsManager: se va mientras edita una máquina).
//
//   [ cinta  ][cortadora]   ← filas 10 y 11: los casilleros 1 y 2
//   [freidora][  brazo  ]   ← filas 8 y 9: los casilleros 3 y 4
//   Clic: elegir ...        ← fila 7: la ayuda (place_help.png)
//   HACIA DÓNDE MIRA        ← fila 6 (dir_label.png)
//         [  ↑  ]           ← filas 2 a 5: la brújula (compassTiles). Arriba y abajo, 2 celdas de ancho;
//   [←] [máquina] [→]          izquierda y derecha, 2 de alto; en el centro, la máquina elegida mirando
//         [  ↓  ]              hacia donde va a quedar (compassMachine). También con W A S D.
//
// Cada casillero mide 2x2 celdas: es una imagen con la máquina en chico y su nombre abajo
// (Machine.menuImage, las genera assets/menu/makePlaceSlots.py). Encima van los marcos: amarillo en la
// elegida (selectionFrame), uno que titila en la que pide el tutorial (highlight) y uno rojo un momento
// en la que eligió el jugador si no es la que pide (flashError).
// Lo que se clickea (los casilleros y la brújula) son botones (CellArea): cada uno sabe qué hace.
object placeMenu{
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
        new CompassTile(direction = up, position = new CellPosition(x = 19, y = 5), width = 2),
        new CompassTile(direction = down, position = new CellPosition(x = 19, y = 2), width = 2),
        new CompassTile(direction = left, position = new CellPosition(x = 18, y = 3), height = 2),
        new CompassTile(direction = right, position = new CellPosition(x = 21, y = 3), height = 2)
    ]
    const errorMillis = 600

    method currentPage() = currentPage

    // Mensajes que le manda menuManager

    method show() {
        visible = true
        self.renderItems()
    }

    method hide() {
        visible = false
        self.clear()
        self.removeFrames()
    }

    // Lo que hay en la celda clickeada: elige la máquina de ese casillero o esa dirección de la brújula
    method onClick(pos) {
        (slotAreas + compassTiles).findOrDefault({ each => each.contains(pos) }, noButton).press()
    }

    // Q y E: la máquina anterior o la siguiente del catálogo (pasa de página si hace falta)
    method chooseNext(step) {
        const catalog = machineManager.catalog()
        const index = (0 .. catalog.size() - 1).findOrDefault({ i => machineManager.selects(catalog.get(i)) }, 0)
        self.choose(catalog.get((index + step + catalog.size()).rem(catalog.size())))
    }

    // Elige esa máquina (fábrica), en la página donde está. Le avisa a levelManager: si no es la que pide el
    // tutorial, el cocinero lo dice.
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

    // Cambiar de página sólo redibuja si el panel se está viendo
    // Avanzan o retroceden de a una página, sin pasarse de la primera ni de la última
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

    // La celda de abajo a la izquierda del casillero (1 a 4): de a 2 por fila, el primero arriba a la izquierda
    method slotPosition(slot) = menuManager.interactiveZone().at((slot - 1).rem(2) * 2, firstRow - (slot - 1).div(2) * 2)

    // El casillero (1 a 4) en el que cayó el click, o 0 si no cayó en ninguno
    method slotAt(pos) {
        const dx = pos.x() - menuManager.interactiveZone().origin().x()
        const row = if (pos.y().between(firstRow, firstRow + 1)) 0 else if (pos.y().between(firstRow - 2, firstRow - 1)) 1 else -1
        return if (row >= 0 && dx.between(0, 3)) row * 2 + dx.div(2) + 1 else 0
    }

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

    // ¿En qué casillero está la máquina que tengo elegida? (0 si no está en la página que se ve)
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

    // Las máquinas que pide el tutorial (lo avisa levelManager con cada paso): su casillero titila
    // Si el paso pide las mismas que antes (por ejemplo, con cada entrega mientras se cocina), no hace nada
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

    // El marco amarillo va en la elegida (si está en la página que se ve) y el que titila en las que pide el
    // tutorial, menos la elegida. Se llama sólo cuando cambia algo (al elegir, cambiar de página o de paso).
    // selectedSlot() es caro (crea máquinas para comparar nombres), así que NO hay que llamarlo desde algo que se dibuja.
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

    // Renderiza en pantalla las maquinas que pertenecen a la pagina, y la ayuda debajo
    // Para cambiar el orden de las maquinas, modificar el orden de la lista "machines" (machineManager).
    method renderItems() {
        self.clear()

        var slot = 0

        machineManager.machinesOfPage(currentPage).forEach({ factory =>
            slot += 1
            // una máquina de muestra: da el nombre y la imagen del menú (queda guardada en el MenuItem)
            const sample = factory.apply()
            const item = new MenuItem(name = sample.name(), machine = sample, position = self.slotPosition(slot))
            item.updateImage()
            items.add(drawn.add(item))
            // el casillero ocupa 2x2 celdas: clickearlo elige esa máquina
            slotAreas.add(new CellArea(position = item.position(), width = 2, height = 2, action = { self.choose(factory) }))
        })

        // la ayuda, debajo de los casilleros, y el título de la brújula
        drawn.add(new Picture(image = "menu/place_help.png", position = menuManager.interactiveZone().at(0, firstRow - 3)))
        drawn.add(new Picture(image = "menu/dir_label.png", position = menuManager.interactiveZone().at(0, firstRow - 4)))
        drawn.add(new Picture(image = "menu/compass_center.png", position = compassMachine.position()))

        // la brújula: un botón por dirección (la elegida, en amarillo) y la máquina en el centro
        (compassTiles + [compassMachine]).forEach({ visual =>
            visual.updateImage()
            drawn.add(visual)
        })

        // los marcos van encima de los casilleros
        self.updateFrames()
    }

    // Actualiza las imágenes que muestran hacia dónde mira la máquina a colocar. Lo llama toolsManager
    // cuando cambia la dirección (W/A/S/D o la brújula), que es lo único que las cambia.
    method updateImages() {
        (items + compassTiles + [compassMachine]).forEach({ visual => visual.updateImage() })
    }

    method compassTiles() = compassTiles

    // Los casilleros que se ven, en orden (para los tests)
    method items() = items

}


// Un casillero: la máquina en chico, con su nombre. La imagen se guarda y se recalcula sólo cuando cambia
// la dirección (ver updateImage).
class MenuItem inherits Picture(image = "no_texture.png") {
    const property name
    // Una máquina del tipo que muestra: es la que sabe qué imagen va en el menú
    // (por ejemplo, el brazo automático no rota y muestra siempre la misma).
    const machine

    method updateImage() {
        image = machine.menuImage(toolsManager.currentDirection())
    }
}

// Un botón de la brújula de "hacia dónde mira" (assets/menu/compass_*.png, ver makeArmAndTicket.py). Guarda
// su imagen: la cambia updateImage, que se llama sólo cuando cambia la dirección.
class CompassTile inherits Button(image = "menu/compass_right.png") {
    const property direction

    override method press() { toolsManager.currentDirection(direction) }

    method updateImage() {
        image = "menu/compass_" + direction.name() + (if (toolsManager.currentDirection() == direction) "_on" else "") + ".png"
    }
}

// La máquina elegida, en el centro de la brújula, mirando hacia donde va a quedar. Se recalcula sólo al
// cambiar la dirección o la máquina (crea una máquina de muestra: no hay que llamarlo al dibujar).
object compassMachine inherits Picture(image = "no_texture.png", position = new CellPosition(x = 19, y = 3)) {
    method updateImage() { image = machineManager.createMachine().menuImage(toolsManager.currentDirection()) }
}

object selectionFrame {
    // EL MARCO AMARILLO DE LA MÁQUINA ELEGIDA
    // La posición se guarda y placeMenu.updateFrames() la cambia cuando hace falta (no se calcula en cada frame).
    // Sin setter: desde afuera sólo se lo puede mover a un casillero (moveToSlot).
    var position = placeMenu.slotPosition(1)

    method position() = position
    method image() = "menu/slot_selected.png"

    // Se ubica sobre el casillero (1 a 4) de la máquina seleccionada
    method moveToSlot(slot) {
        position = placeMenu.slotPosition(slot)
    }
}
