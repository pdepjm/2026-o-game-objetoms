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

// El menú de colocar, en la zona interactiva (x 18 a 21, y 0 a 11) mientras el jugador está COLOCANDO
// (ver toolsManager: se va mientras edita una máquina).
//
//   [ cinta  ][cortadora]   ← filas 10 y 11: los casilleros 1 y 2
//   [freidora][  brazo  ]   ← filas 8 y 9: los casilleros 3 y 4
//   Clic: elegir ...        ← la ayuda (place_help.png), debajo
//   HACIA DÓNDE MIRA        ← fila 4: ← ↑ ↓ →, una celda cada una (dir_pad.png); también W A S D
//
// Cada casillero mide 2x2 celdas: es una imagen con la máquina en chico y su nombre abajo
// (Machine.menuImage, las genera assets/menu/makePlaceSlots.py). Encima van los marcos: amarillo en la
// elegida (selectionFrame), uno que titila en la que pide el tutorial (highlight) y uno rojo un momento
// en la que eligió el jugador si no es la que pide (flashError).
object placeMenu{
    var currentPage = 0
    var renderedItems = []
    // Las máquinas (fábricas) que pide el paso del tutorial: su casillero titila
    var wanted = []
    var hintFrames = []
    var errorFrames = []

    // Sólo se dibuja mientras es el panel activo (COLOCANDO)
    var visible = false

    // La fila de abajo de los casilleros de arriba (los de abajo, 2 filas menos)
    const firstRow = 10
    // La fila de los botones de dirección, y la dirección de cada columna (x 18 a 21)
    const directionRow = 4
    const directions = [left, up, down, right]
    const errorMillis = 600

    method currentPage() = currentPage

    // Mensajes que le manda menuManager

    method show() {
        visible = true
        self.renderItems()
    }

    method hide() {
        visible = false
        self.vaciarRenders()
        self.removeFrames()
    }

    // Selecciona la máquina del casillero clickeado, si hay una en ese casillero, o la dirección del botón
    // clickeado
    method onClick(pos) {
        if (pos.y() == directionRow) toolsManager.currentDirection(self.directionAt(pos))
        else {
            const slot = self.slotAt(pos)
            const pageMachines = machineManager.machinesOfPage(currentPage)
            if (slot > 0 && slot <= pageMachines.size()) self.choose(pageMachines.get(slot - 1))
        }
    }

    // El botón de dirección de esa celda (la fila de los botones va de x 18 a 21)
    method directionAt(pos) = directions.get(pos.x() - menuManager.interactiveZone().origin().x())

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
    method highlight(factories) {
        wanted = factories
        if (visible) self.updateFrames()
    }

    // La máquina elegida no es la que pide el tutorial: su casillero se pone rojo un momento
    method flashError(factory) {
        const slot = self.slotOf(factory)
        if (visible && slot > 0) {
            const frame = new SlotFrame(image = "menu/slot_error.png", position = self.slotPosition(slot))
            game.addVisual(frame)
            errorFrames.add(frame)
            game.schedule(errorMillis, { self.removeErrorFrame(frame) })
        }
    }

    method removeErrorFrame(frame) {
        if (errorFrames.contains(frame)) {
            errorFrames.remove(frame)
            if (game.hasVisual(frame)) game.removeVisual(frame)
        }
    }

    // Los casilleros que titilan (para los tests)
    method hintedSlots() = hintFrames.map({ frame => frame.position() })

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
        hintFrames = wanted
            .filter({ factory => !machineManager.selects(factory) && self.slotOf(factory) > 0 })
            .map({ factory => new SlotFrame(image = "menu/slot_hint.gif", position = self.slotPosition(self.slotOf(factory))) })
        hintFrames.forEach({ frame => game.addVisual(frame) })
    }

    method removeFrames() {
        if (game.hasVisual(selectionFrame)) game.removeVisual(selectionFrame)
        hintFrames.forEach({ frame => if (game.hasVisual(frame)) game.removeVisual(frame) })
        hintFrames = []
        errorFrames.forEach({ frame => if (game.hasVisual(frame)) game.removeVisual(frame) })
        errorFrames = []
    }

    // ----------- DIBUJAR LAS MAQUINAS EN EL MENU -----------

    // Remueve de la pantalla todos los items dibujados hasta ese momento
    method vaciarRenders() {
        renderedItems.forEach({item => game.removeVisual(item)})
        renderedItems = []
    }

    // Renderiza en pantalla las maquinas que pertenecen a la pagina, y la ayuda debajo
    // Para cambiar el orden de las maquinas, modificar el orden de la lista "machines" (machineManager).
    method renderItems() {
        if (renderedItems.size() > 0) self.vaciarRenders()

        var slot = 0

        machineManager.machinesOfPage(currentPage).forEach({ factory =>
            slot += 1
            // una máquina de muestra: da el nombre y la imagen del menú (queda guardada en el MenuItem)
            const maquina = factory.apply()

            const renderedMenuItem = new MenuItem(
                name = maquina.name(),
                machine = maquina,
                position = self.slotPosition(slot)
            )
            renderedMenuItem.updateImage()
            game.addVisual(renderedMenuItem)
            renderedItems.add(renderedMenuItem)
        })

        // la ayuda, debajo de los casilleros (con Q/E si hay más de una página)
        const help = new SlotFrame(
            image = if (machineManager.pageCount() > 1) "menu/place_help_pages.png" else "menu/place_help.png",
            position = new CellPosition(x = menuManager.interactiveZone().origin().x(), y = firstRow - 4)
        )
        game.addVisual(help)
        renderedItems.add(help)

        // los botones de dirección, con un marco en la elegida (directionFrame)
        const pad = new SlotFrame(image = "menu/dir_pad.png", position = menuManager.interactiveZone().at(0, directionRow))
        game.addVisual(pad)
        renderedItems.add(pad)
        directionFrame.updateImage()
        game.addVisual(directionFrame)
        renderedItems.add(directionFrame)

        // los marcos van encima de los casilleros
        self.updateFrames()
    }

    // Actualiza la imagen de los items del menú. Lo llama toolsManager cuando cambia
    // la dirección (W/A/S/D), que es lo único que cambia esas imágenes.
    method updateImages() {
        renderedItems.forEach({ item => item.updateImage() })
    }

    // La celda del botón de esa dirección (para el marco)
    method directionCell(direction) = menuManager.interactiveZone().at((0 .. 3).find({ i => directions.get(i) == direction }), directionRow)

}


class MenuItem{
    var property name = "item"
    var property position = game.center()

    // Una máquina del tipo que muestra: es la que sabe qué imagen va en el menú
    // (por ejemplo, el brazo automático no rota y muestra siempre la misma).
    const machine

    // La imagen se guarda y se recalcula sólo cuando cambia la dirección (ver updateImage).
    // Sin setter: desde afuera sólo se le puede pedir que se actualice (updateImage).
    var image = "no_texture.png"

    method image() = image
    method isMenuItem() = true

    method updateImage() {
        image = machine.menuImage(toolsManager.currentDirection())
    }
}

// El marco del botón de la dirección elegida. Guarda su posición: la cambia updateImage, que se llama
// sólo cuando cambia la dirección (W/A/S/D o un clic en los botones).
object directionFrame {
    var position = placeMenu.directionCell(right)

    method position() = position
    method image() = "menu/dir_selected.png"
    method isMenuItem() = false
    method updateImage() { position = placeMenu.directionCell(toolsManager.currentDirection()) }
}

// Un marco o una imagen fija del menú (la ayuda): no cambia, sólo se agrega y se saca
class SlotFrame {
    const property image
    const property position

    method isMenuItem() = false
    method updateImage() {}
}

object selectionFrame {
    // EL MARCO AMARILLO DE LA MÁQUINA ELEGIDA
    // La posición se guarda y placeMenu.updateFrames() la cambia cuando hace falta (no se calcula en cada frame).
    // Sin setter: desde afuera sólo se lo puede mover a un casillero (moveToSlot).
    var position = placeMenu.slotPosition(1)

    method position() = position
    method image() = "menu/slot_selected.png"
    method isMenuItem() = false

    // Se ubica sobre el casillero (1 a 4) de la máquina seleccionada
    method moveToSlot(slot) {
        position = placeMenu.slotPosition(slot)
    }
}
