// Buffet Albert Einstein - conoce los menús y reenvía a cada uno lo que pasa en el juego.
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

import src.cellPosition.CellPosition
import menu.placeMenu.*
import menu.editMenu.*
import menu.toolBar.*
import tools.toolsManager.*
import tools.userTools.*
import sound.sfx.*
import wollok.game.*
import board.*

// Único que conoce los menús: el resto del juego le avisa lo que pasó (eventos)
// y él se lo reenvía al menú que corresponda.
//
// Los paneles de la zona interactiva (placeMenu, editMenu y emptyMenu) responden a los
// mismos mensajes, así el manager no tiene que preguntar de cuál se trata:
// show(), hide() y onClick(pos).
// Lo que sólo tiene sentido en place (cambiar de página y refrescar las imágenes de las
// máquinas) se lo manda directo a placeMenu, que lo ignora si no se está viendo.

object menuManager {
    const levelInfoZone = new Zone(
        minX = 0,
        maxX = 4,
        minY = 1,
        maxY = 14
    )
    const toolBarZone = new Zone(
        minX = 21,
        maxX = 24,
        minY = 15,
        maxY = 15
    )
    const interactiveZone = new Zone(
        minX = 21,
        maxX = 24,
        minY = 0,
        maxY = 14
    )

    // Panel que se ve en la zona interactiva
    var activePanel = emptyMenu

    // Qué panel le toca a cada herramienta (delete y rotate no muestran nada, ver panelFor)
    const panels = new Dictionary()

    method initialize() {
        panels.put(place, placeMenu)
        panels.put(edit, editMenu)
    }

    // Lo llama main al arrancar: muestra la barra y el panel de la herramienta elegida
    method setUp() {
        toolBar.show()
        self.toolChanged(toolsManager.selectedTool())
    }

    // EVENTOS

    // Cambió la herramienta (toolsManager.select)
    method toolChanged(tool) {
        toolBar.refresh()

        const newPanel = self.panelFor(tool)
        if (newPanel != activePanel) {
            activePanel.hide()
            activePanel = newPanel
            activePanel.show()
        }
    }

    // Cambió la dirección con la que se colocan las máquinas (toolsManager.currentDirection)
    method directionChanged() {
        placeMenu.updateImages()
    }

    // Pasar de página (teclas Q y E). Sólo el panel de place tiene páginas.
    method prevPage() {
        placeMenu.prev()
        sfx.pageChange()
    }

    method nextPage() {
        placeMenu.next()
        sfx.pageChange()
    }

    // Click dentro de la zona interactiva (toolsManager.onClick)
    method onClick(pos) {
        activePanel.onClick(pos)
    }

    // Sin herramienta (null) o sin panel propio (delete y rotate), la zona queda vacía
    method panelFor(tool) = if (tool == null) emptyMenu else panels.getOrElse(tool, { => emptyMenu })

    // Metodo para saber si se clickeo en la zona interactiva
    method inInteractiveMenu(pos) = interactiveZone.contains(pos)

    // Getters
    method levelInfoZone() = levelInfoZone
    method toolBarZone() = toolBarZone
    method interactiveZone() = interactiveZone
}

// Panel sin contenido: lo usan las herramientas que todavía no muestran nada
object emptyMenu {
    method show() {}
    method hide() {}
    method onClick(pos) {}
}
